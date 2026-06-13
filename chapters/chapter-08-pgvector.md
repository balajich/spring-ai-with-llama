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
