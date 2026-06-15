# Chapter 8 — Persistent Vector Store with PgVector

> **What you will build:** Upgrade the SmartHR policy Q&A from an in-memory vector store to PostgreSQL with the pgvector extension — so policy knowledge survives restarts and scales to thousands of documents.

---

## The Problem We Are Solving

Chapter 7's `SimpleVectorStore` works perfectly in development. But Sarah notices a problem:

> "Every time I restart the app, I have to re-ingest all the policy documents. And our legal team just added 200 more PDFs. Is there a better way?"

Two problems:
1. **Persistence** — in-memory vectors are lost on every restart
2. **Scale** — O(N) brute-force scan over thousands of chunks is too slow

The fix is a real vector database. And since TechCorp already runs PostgreSQL, the answer is **pgvector** — a PostgreSQL extension that adds a native vector type and efficient similarity search using HNSW indexes.

---

## Architecture

<svg viewBox="0 0 580 360" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 8 — Spring AI, Ollama and PgVector Architecture</title>
  <desc>Spring AI in the JVM communicates with Ollama (nomic-embed-text and llama3.2) and PostgreSQL PgVectorStore, arranged in two columns.</desc>
  <rect width="580" height="360" fill="#f8f9fa" rx="12"/>
  <rect x="30" y="110" width="180" height="140" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="120" y="138" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="120" y="156" text-anchor="middle" font-size="10" fill="#999">JVM</text>
  <text x="120" y="182" text-anchor="middle" font-size="10" fill="#555">QuestionAnswerAdvisor</text>
  <text x="120" y="198" text-anchor="middle" font-size="10" fill="#555">ChatClient</text>
  <text x="120" y="214" text-anchor="middle" font-size="10" fill="#555">ApplicationRunner</text>
  <rect x="350" y="30" width="190" height="160" rx="10" fill="white" stroke="#adb5bd" stroke-width="2"/>
  <text x="445" y="57" text-anchor="middle" font-size="13" font-weight="700" fill="#333">Ollama</text>
  <text x="445" y="74" text-anchor="middle" font-size="10" fill="#999">localhost:11434</text>
  <rect x="368" y="84" width="154" height="42" rx="7" fill="#e0f0ff" stroke="#5ba3d9" stroke-width="1.5"/>
  <text x="445" y="101" text-anchor="middle" font-size="11" font-weight="700" fill="#1a5f96">nomic-embed-text</text>
  <text x="445" y="117" text-anchor="middle" font-size="10" fill="#2d6fa4">Embedding Model</text>
  <rect x="368" y="136" width="154" height="42" rx="7" fill="#e8f5e9" stroke="#5aaa6b" stroke-width="1.5"/>
  <text x="445" y="153" text-anchor="middle" font-size="11" font-weight="700" fill="#1b6b2f">llama3.2</text>
  <text x="445" y="169" text-anchor="middle" font-size="10" fill="#2a7d40">Generative Model</text>
  <rect x="350" y="210" width="190" height="120" rx="10" fill="white" stroke="#5b6abf" stroke-width="2"/>
  <text x="445" y="236" text-anchor="middle" font-size="13" font-weight="700" fill="#2d3494">PostgreSQL</text>
  <text x="445" y="253" text-anchor="middle" font-size="10" fill="#999">localhost:5432</text>
  <rect x="368" y="264" width="154" height="50" rx="7" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.5"/>
  <text x="445" y="285" text-anchor="middle" font-size="11" font-weight="700" fill="#2d3494">PgVectorStore</text>
  <text x="445" y="302" text-anchor="middle" font-size="10" fill="#3d4db0">vector(768) + HNSW</text>
  <path d="M 210 155 L 350 107" fill="none" stroke="#5ba3d9" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#b8c)"/>
  <text x="278" y="120" text-anchor="middle" font-size="9" fill="#1a5f96">embed text</text>
  <path d="M 350 118 L 210 165" fill="none" stroke="#5ba3d9" stroke-width="1.8" marker-end="url(#b8c)"/>
  <text x="278" y="152" text-anchor="middle" font-size="9" fill="#1a5f96">float[768]</text>
  <path d="M 210 175 L 350 158" fill="none" stroke="#5aaa6b" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#g8c)"/>
  <text x="278" y="175" text-anchor="middle" font-size="9" fill="#1b6b2f">prompt + context</text>
  <path d="M 350 168 L 210 185" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#g8c)"/>
  <text x="278" y="196" text-anchor="middle" font-size="9" fill="#1b6b2f">answer</text>
  <path d="M 210 220 L 350 275" fill="none" stroke="#5b6abf" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#p8c)"/>
  <text x="268" y="240" text-anchor="middle" font-size="9" fill="#2d3494">store / search</text>
  <path d="M 350 288 L 210 232" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#p8c)"/>
  <text x="268" y="272" text-anchor="middle" font-size="9" fill="#2d3494">top-K chunks</text>
  <defs>
    <marker id="b8c" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5ba3d9"/></marker>
    <marker id="g8c" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="p8c" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
  </defs>
</svg>

---

## What You Will Learn

- Why `SimpleVectorStore` is not suitable for production
- How pgvector extends PostgreSQL with native vector support
- How to run pgvector locally with Docker
- How Spring AI's `PgVectorStore` replaces `SimpleVectorStore` with zero controller changes
- How HNSW indexing brings search from O(N) to O(log N)

---

## The Only Code That Changes

This is the key message of this chapter. Compare the two configurations:

**Chapter 7 — SimpleVectorStore:**
```java
@Bean
public SimpleVectorStore vectorStore(EmbeddingModel embeddingModel) {
    return SimpleVectorStore.builder(embeddingModel).build();
}
```

```yaml
# application.yml — nothing extra needed
```

**Chapter 8 — PgVectorStore:**
```java
// import org.springframework.ai.vectorstore.pgvector.PgVectorStore;

@Bean
public VectorStore vectorStore(EmbeddingModel embeddingModel, JdbcTemplate jdbcTemplate) {
    return PgVectorStore.builder(jdbcTemplate, embeddingModel)
            .initializeSchema(true)
            .build();
}
```

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/smarthr
    username: smarthr
    password: smarthr
  ai:
    vectorstore:
      pgvector:
        initialize-schema: true
        index-type: HNSW
        distance-type: COSINE_DISTANCE
        dimensions: 768
```

The controller, `QuestionAnswerAdvisor`, `TikaDocumentReader`, and `TokenTextSplitter` are **identical to Chapter 7**. Spring AI's `VectorStore` interface abstracts the backend completely.

---

## Docker Setup

```yaml
# docker-compose.yml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: smarthr
      POSTGRES_USER: smarthr
      POSTGRES_PASSWORD: smarthr
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

```bash
docker-compose up -d
```

pgvector is a PostgreSQL extension — it runs inside Postgres, not as a separate service. Spring AI creates the `vector_store` table automatically when `initialize-schema: true` is set.

---

## How pgvector Stores and Searches Vectors

PostgreSQL with pgvector adds a native `vector` column type:

```sql
CREATE TABLE vector_store (
    id          uuid PRIMARY KEY,
    content     text,
    metadata    json,
    embedding   vector(768)   -- native vector column
);

-- HNSW index for fast approximate nearest-neighbour search
CREATE INDEX ON vector_store USING hnsw (embedding vector_cosine_ops);
```

At query time, pgvector runs a similarity search entirely inside Postgres:

```sql
SELECT content, metadata,
       1 - (embedding <=> query_vector) AS similarity
FROM vector_store
ORDER BY embedding <=> query_vector
LIMIT 4;
```

The `<=>` operator is the cosine distance operator added by pgvector. The HNSW index makes this O(log N) instead of O(N).

---

## SimpleVectorStore vs PgVectorStore

| Concern | SimpleVectorStore | PgVectorStore |
|---------|-------------------|---------------|
| Storage | JVM heap (`ConcurrentHashMap`) | PostgreSQL table |
| Persistence | Lost on restart | Survives restarts |
| Search | O(N) brute-force | O(log N) HNSW index |
| Max chunks | Hundreds (heap-bound) | Millions |
| Setup | Zero | Docker + config |
| Production-ready | No | Yes |

---

## What You Will Build

Same two endpoints as Chapter 7 — the API does not change:

```
POST /hr/policy/ask     — ask a question grounded in policy documents
POST /hr/policy/ingest  — ingest new policy text at runtime
```

The difference is invisible to the caller: vectors are now stored in PostgreSQL and survive restarts.

**Test it:**
```bash
# Start PostgreSQL
docker-compose up -d

# Start the app
mvn spring-boot:run

# Ingest once — survives restarts
curl -s -X POST http://localhost:8080/hr/policy/ingest \
  -H "Content-Type: application/json" \
  -d '{"text": "TechCorp parental leave policy: primary caregivers receive 16 weeks fully paid."}'

# Restart the app — vectors are still there
# Ask a question
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many weeks of parental leave does TechCorp offer?"}'
```

---

## Summary

In this chapter you will:

- Understand why `SimpleVectorStore` is development-only
- Run pgvector locally with Docker in under two minutes
- Swap `SimpleVectorStore` for `PgVectorStore` by changing one `@Bean` and four lines of config
- See how HNSW indexing replaces O(N) brute-force with O(log N) search
- Confirm that the controller, advisor, and API remain completely unchanged

---

## What's Next

In **Chapter 9**, we upgrade again — this time to Neo4j. Beyond persistence, Neo4j is a graph database. Policy sections can be connected by relationships, and Graph RAG can traverse those connections to answer questions that span multiple policy areas — something a flat vector search cannot do.

*Code for this chapter: [`code/chapter-08-pgvector/`](../code/chapter-08-pgvector/)*
