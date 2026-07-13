# Chapter 9 — Neo4j Graph RAG: When Vector Search Isn't Enough

In Chapter 8 we gave the SmartHR bot a persistent memory with pgvector. Policy documents survive restarts. Search is O(log N). The legal team is happy.

Then the HR director calls.

> "An employee asked what happens if their parental leave runs out and they're still unwell. The bot answered about parental leave. It said nothing about sick leave continuation. Those two policies are directly connected — the bot needs to know that."

This is the fundamental limit of flat vector search. Each chunk is retrieved in isolation. There is no concept of relationships between chunks. The top-K results are the most similar chunks to the question — but "similar" and "related" are not the same thing.

**Graph RAG** solves this. Policy sections are stored as nodes. Relationships between them are edges. When Neo4j retrieves the parental leave chunk, it also traverses the edge to the sick leave chunk — because we told it they are connected.

---

## Plain RAG vs Graph RAG

```
Plain RAG (Chapters 7 & 8):

  Question ──► embed ──► find top-K similar chunks ──► answer

  Problem: chunks are isolated. Parental leave and sick leave
           are separate chunks. The bot picks one.

Graph RAG (Chapter 9):

  Question ──► embed ──► find top-K similar chunks
                               │
                               ▼
                    traverse graph edges
                               │
                               ▼
                    retrieve connected chunks too ──► answer

  Result: parental leave chunk + sick leave chunk — both surface.
```

| Question | Plain RAG returns | Graph RAG returns |
|----------|------------------|------------------|
| "What if parental leave runs out and I'm still ill?" | Parental leave only | Parental leave + sick leave (connected) |
| "What laptop do engineers get and how do I request it?" | IT equipment only | IT equipment + onboarding (connected) |

---

## The Bean Swap

The controller, `QuestionAnswerAdvisor`, `TikaDocumentReader`, and API endpoints are identical to Chapter 8. The only production code change is the `@Bean`:

**Chapter 8 — PgVectorStore:**
```java
PgVectorStore.builder(jdbcTemplate, embeddingModel)
        .initializeSchema(true)
        .dimensions(768)
        .distanceType(PgVectorStore.PgDistanceType.COSINE_DISTANCE)
        .indexType(PgVectorStore.PgIndexType.HNSW)
        .build()
```

**Chapter 9 — Neo4jVectorStore:**
```java
Neo4jVectorStore.builder(driver, embeddingModel)
        .initializeSchema(true)
        .build()
```

And four lines of config:

```yaml
spring:
  neo4j:
    uri: bolt://localhost:7687
    authentication:
      username: neo4j
      password: smarthr123
```

That is the entire migration from a relational vector store to a graph vector store.

---

## Modelling Policy Relationships

After ingestion, we run Cypher to connect related policy sections as bidirectional edges:

```java
private void addPolicyRelationships(Driver driver) {
    try (Session session = driver.session()) {
        session.run("""
                MATCH (a:Document), (b:Document)
                WHERE a.text CONTAINS 'parental leave'
                  AND b.text CONTAINS 'sick leave'
                  AND a <> b
                MERGE (a)-[:RELATED_TO]->(b)
                MERGE (b)-[:RELATED_TO]->(a)
                """);
        session.run("""
                MATCH (a:Document), (b:Document)
                WHERE a.text CONTAINS 'onboarding'
                  AND b.text CONTAINS 'IT'
                  AND a <> b
                MERGE (a)-[:RELATED_TO]->(b)
                MERGE (b)-[:RELATED_TO]->(a)
                """);
        session.run("""
                MATCH (a:Document), (b:Document)
                WHERE a.text CONTAINS 'performance'
                  AND b.text CONTAINS 'learning'
                  AND a <> b
                MERGE (a)-[:RELATED_TO]->(b)
                MERGE (b)-[:RELATED_TO]->(a)
                """);
    }
}
```

`AND a <> b` prevents self-loops — without it, if two keywords land in the same chunk, Neo4j would create a relationship from a node to itself. The `MERGE` ensures relationships are idempotent — safe to run multiple times.

---

## One Thing We Learned the Hard Way: Chunk Size Matters

Neo4j Browser showed only 2 nodes and no edges. The policy file (~660 tokens) was being split into 2 large chunks by the default `TokenTextSplitter` (800 tokens per chunk). Both "parental leave" and "sick leave" landed in the same node — so the relationship query matched the same node for `a` and `b`, and no edge was created.

The fix: use 150-token chunks so each policy section (Annual Leave, Sick Leave, Parental Leave, etc.) becomes its own node:

```java
List<Document> chunks = TokenTextSplitter.builder()
        .withChunkSize(150)
        .withMinChunkSizeChars(50)
        .build()
        .apply(reader.read());
```

Result: 7–9 nodes in the graph, each representing one policy section, with visible edges between related sections in Neo4j Browser.

---

## Explore the Graph Visually

Neo4j ships with a browser UI at **http://localhost:7474**. After startup, run:

```cypher
MATCH (a:Document)-[:RELATED_TO]->(b:Document)
RETURN a, b LIMIT 25
```

You can literally see which policy sections are connected — something no relational database or plain vector store can show you.

---

## Comparing All Three Vector Stores

| | SimpleVectorStore | PgVectorStore | Neo4jVectorStore |
|-|-------------------|---------------|-----------------|
| Storage | JVM heap | PostgreSQL | Neo4j graph |
| Persistence | Lost on restart | Survives restarts | Survives restarts |
| Search | O(N) brute-force | O(log N) HNSW | O(log N) + graph traversal |
| Relationships | None | None | First-class |
| Multi-topic queries | Poor | Poor | Excellent |
| Visual exploration | No | psql only | Neo4j Browser |
| Setup | Zero | Docker | Docker |

The abstraction that makes all of this possible is Spring AI's `VectorStore` interface. The caller — the controller, the `QuestionAnswerAdvisor`, the rest of your application — never knows which backend is running.

---

## Docker Setup

```yaml
services:
  neo4j:
    image: neo4j:5
    environment:
      NEO4J_AUTH: neo4j/smarthr123
    ports:
      - "7474:7474"
      - "7687:7687"
    volumes:
      - neo4jdata:/data

volumes:
  neo4jdata:
```

```bash
docker-compose up -d
mvn spring-boot:run
```

Neo4j creates the schema, ingests the policy, and builds the graph on first startup. Every restart after that skips ingestion — guarded by a node-count check.

---

## The Series So Far

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- [Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.](https://www.linkedin.com/pulse/chapter-6-your-ai-bot-has-goldfish-memory-heres-how-fix-chopparapu-ck0hc/?trackingId=m0DOW59LgPkGihFvJDxZBA%3D%3D)
- [Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.](https://www.linkedin.com/pulse/chapter-7-your-ai-guessing-rag-makes-read-manual-balaji-chopparapu-ararc/?trackingId=4L5yf1FX4CspOTawv4ddmw%3D%3D)
- [Chapter 8 — Your Vector Store Shouldn't Forget Everything When You Restart](https://www.linkedin.com/pulse/chapter-8-your-vector-store-shouldnt-forget-everything-chopparapu)
- **Chapter 9 — Neo4j Graph RAG: When Vector Search Isn't Enough** ← you are here

Full source code: [github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama) — drop a star if you find it useful!

---

#SpringAI #SpringBoot #Java25 #Ollama #Neo4j #GraphRAG #RAG #LLM #GenerativeAI #AIEngineering #LocalAI #NoPayAPI #JavaDeveloper #SpringFramework #Llama
