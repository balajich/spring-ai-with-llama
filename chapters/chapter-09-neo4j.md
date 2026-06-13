# Chapter 9 — Graph RAG with Neo4j

> **What you will build:** Upgrade the policy Q&A to Neo4j — a graph database where policy sections are connected by relationships, enabling Graph RAG to answer multi-topic questions that flat vector search cannot handle.

---

## The Problem We Are Solving

PgVector from Chapter 8 handles single-topic questions well. But Sarah gets a report from the legal team:

> "An employee asked: 'What happens if my parental leave runs out and I'm still unwell?' The bot answered about parental leave but completely missed the sick leave continuation clause. These policies are connected — the bot needs to know that."

This is the limitation of flat vector search. Each chunk is retrieved independently. There is no awareness that "parental leave policy" and "sick leave continuation" are related — and that a question about one should also surface the other.

**Graph RAG** solves this by storing relationships between policy sections. When Neo4j retrieves the parental leave chunk, it also traverses the graph edge to the sick leave chunk — because we told it they are connected.

---

## What You Will Learn

- What Graph RAG is and when it outperforms plain RAG
- How Neo4j stores documents as nodes and relationships as edges
- How Spring AI's `Neo4jVectorStore` plugs into the same `VectorStore` interface
- How to run Neo4j locally with Docker
- How to model policy relationships in the graph
- The one-line bean swap that upgrades from PgVector to Neo4j

---

## Plain RAG vs Graph RAG

```
Plain RAG (Chapter 7 & 8):

  Question ──► embed ──► find top-K similar chunks ──► inject into prompt

  Problem: each chunk is isolated. No awareness of connections.

Graph RAG (Chapter 9):

  Question ──► embed ──► find top-K similar chunks
                               │
                               ▼
                    traverse graph edges
                               │
                               ▼
                    retrieve connected chunks too ──► inject all into prompt

  Benefit: related policy sections surface automatically.
```

**Example:**

| Question | Plain RAG retrieves | Graph RAG retrieves |
|----------|--------------------|--------------------|
| "What if parental leave runs out and I'm still ill?" | Parental leave chunk only | Parental leave chunk + sick leave chunk (connected by edge) |
| "What laptop do engineers get and how do I request it?" | IT equipment chunk only | IT equipment chunk + onboarding chunk (connected) |

---

## The Only Code That Changes

**Chapter 8 — PgVectorStore:**
```java
@Bean
public VectorStore vectorStore(EmbeddingModel embeddingModel, JdbcTemplate jdbcTemplate) {
    return PgVectorStore.builder(jdbcTemplate, embeddingModel)
            .initializeSchema(true)
            .build();
}
```

**Chapter 9 — Neo4jVectorStore:**
```java
@Bean
public VectorStore vectorStore(EmbeddingModel embeddingModel, Driver driver) {
    return Neo4jVectorStore.builder(driver, embeddingModel)
            .initializeSchema(true)
            .build();
}
```

```yaml
# application.yml
spring:
  neo4j:
    uri: bolt://localhost:7687
    authentication:
      username: neo4j
      password: smarthr
  ai:
    vectorstore:
      neo4j:
        initialize-schema: true
        embedding-dimension: 768
        distance-type: COSINE
```

The controller, `QuestionAnswerAdvisor`, `TikaDocumentReader`, and `TokenTextSplitter` remain **identical to Chapters 7 and 8**.

---

## Docker Setup

```yaml
# docker-compose.yml
services:
  neo4j:
    image: neo4j:5
    environment:
      NEO4J_AUTH: neo4j/smarthr
      NEO4J_PLUGINS: '["apoc"]'
    ports:
      - "7474:7474"   # Neo4j Browser UI
      - "7687:7687"   # Bolt protocol
    volumes:
      - neo4jdata:/data

volumes:
  neo4jdata:
```

```bash
docker-compose up -d
```

Open **http://localhost:7474** to access the Neo4j Browser — you can visually explore the policy graph, see nodes, and traverse relationships.

---

## How Neo4j Stores Documents

In Neo4j, each policy chunk becomes a **node** in the graph:

```
(:Document {
  id: "abc-123",
  text: "Primary caregivers are entitled to 16 weeks of fully paid parental leave.",
  embedding: [0.12, -0.84, 0.33, ...],
  source: "techcorp-hr-policy.txt"
})
```

Relationships between related policy sections are edges:

```
(:Document {text: "...parental leave..."})
  -[:RELATED_TO]->
(:Document {text: "...sick leave continuation..."})
```

Spring AI's `Neo4jVectorStore` handles the vector similarity search with Cypher:

```cypher
MATCH (doc:Document)
WITH doc, vector.similarity.cosine(doc.embedding, $queryEmbedding) AS score
WHERE score > 0.7
RETURN doc ORDER BY score DESC LIMIT 4
```

---

## Modelling Policy Relationships

The `RagConfig` adds relationships between related policy sections after ingestion:

```java
@Bean
public VectorStore vectorStore(EmbeddingModel embeddingModel, Driver driver) {
    Neo4jVectorStore store = Neo4jVectorStore.builder(driver, embeddingModel)
            .initializeSchema(true)
            .build();
    ingestWithRelationships(store, driver);
    return store;
}

private void ingestWithRelationships(Neo4jVectorStore store, Driver driver) {
    // Ingest chunks
    List<Document> chunks = new TokenTextSplitter()
            .apply(new TikaDocumentReader(policyResource).read());
    store.add(chunks);

    // Add relationships between related policy areas
    try (Session session = driver.session()) {
        session.run("""
            MATCH (a:Document), (b:Document)
            WHERE a.text CONTAINS 'parental leave'
              AND b.text CONTAINS 'sick leave'
            MERGE (a)-[:RELATED_TO]->(b)
            """);
        session.run("""
            MATCH (a:Document), (b:Document)
            WHERE a.text CONTAINS 'onboarding'
              AND b.text CONTAINS 'IT equipment'
            MERGE (a)-[:RELATED_TO]->(b)
            """);
    }
}
```

---

## Comparing All Three Vector Stores

| Concern | SimpleVectorStore | PgVectorStore | Neo4jVectorStore |
|---------|-------------------|---------------|------------------|
| Storage | JVM heap | PostgreSQL | Neo4j graph |
| Persistence | No | Yes | Yes |
| Search | O(N) brute-force | O(log N) HNSW | O(log N) + graph traversal |
| Relationships | None | None | First-class |
| Multi-topic queries | Poor | Poor | Excellent |
| Visual exploration | No | psql only | Neo4j Browser UI |
| Setup | Zero | Docker | Docker |

---

## What You Will Build

Same two endpoints as Chapters 7 and 8 — the API does not change:

```
POST /hr/policy/ask     — ask a question; Graph RAG retrieves connected chunks
POST /hr/policy/ingest  — ingest new policy text at runtime
```

**Test a multi-topic question:**
```bash
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What happens if my parental leave runs out and I am still unwell?"}'
```

With plain RAG this returns only the parental leave policy. With Graph RAG it returns parental leave **and** sick leave continuation — because the graph knows they are connected.

---

## Summary

In this chapter you will:

- Understand why graph relationships improve multi-topic retrieval
- Run Neo4j locally with Docker and explore the policy graph in the browser
- Swap `PgVectorStore` for `Neo4jVectorStore` by changing one `@Bean` and four lines of config
- Model relationships between policy sections as graph edges
- See Graph RAG answer a cross-policy question that plain vector search gets wrong

---

## What's Next

In **Chapter 10**, we add Function Calling — the SmartHR bot will call actual Java methods mid-conversation to look up real employee data, check calendar availability, and perform actions, not just answer questions.

*Code for this chapter: [`code/chapter-09-neo4j/`](../code/chapter-09-neo4j/)*
