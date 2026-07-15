# Chapter 8 — Your Vector Store Shouldn't Forget Everything When You Restart

In Chapter 7 we built a RAG system that answers employee questions from TechCorp's HR policy documents. It worked beautifully. Vectors in memory, answers grounded in real documents.

Then Sarah restarted the app.

> "It forgot everything. I had to re-ingest all the documents again. And our legal team just added 200 more PDFs. This isn't going to work."

Two problems with `SimpleVectorStore`:

1. **It lives in JVM heap.** Restart the app → all vectors are gone.
2. **It does a brute-force scan.** Every query iterates over every stored chunk — O(N). Fine for a handful of documents. Unusable at scale.

The fix is **pgvector** — a PostgreSQL extension that adds a native `vector` column type and an HNSW index for fast approximate nearest-neighbour search.

---

## The Swap Is One Bean

This is the headline of this chapter. The controller, the `QuestionAnswerAdvisor`, the `TikaDocumentReader`, the `TokenTextSplitter` — none of it changes. The only difference is one `@Bean`:

**Chapter 7:**
```java
SimpleVectorStore.builder(embeddingModel).build()
```

**Chapter 8:**
```java
PgVectorStore.builder(jdbcTemplate, embeddingModel)
        .initializeSchema(true)
        .dimensions(768)
        .distanceType(PgVectorStore.PgDistanceType.COSINE_DISTANCE)
        .indexType(PgVectorStore.PgIndexType.HNSW)
        .build()
```

Spring AI's `VectorStore` interface is the abstraction. The caller never knows which backend is running.

---

## Two Things We Learned the Hard Way

### 1. PgVectorStore must be fully initialised before you can INSERT

`PgVectorStore` implements Spring's `InitializingBean`. When Spring creates the bean, it calls `afterPropertiesSet()` — which registers the pgvector JDBC type and runs `CREATE EXTENSION IF NOT EXISTS vector`. If you try to call `store.add()` inside the `@Bean` method before Spring has done this, you get:

```
PSQLException: Unknown type vector.
```

The fix is an `ApplicationRunner` — it fires after all beans are fully initialised:

```java
@Bean
public ApplicationRunner ingestPolicy(VectorStore vectorStore, JdbcTemplate jdbcTemplate) {
    return args -> {
        // skip if already ingested
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM vector_store", Integer.class);
        if (Objects.requireNonNullElse(count, 0) > 0) return;

        List<Document> chunks = new TokenTextSplitter()
                .apply(new TikaDocumentReader(policyResource).read());
        vectorStore.add(chunks);
    };
}
```

### 2. Ingestion must be idempotent

Without the COUNT check, every app restart re-ingests the policy documents. PostgreSQL grows. Queries slow down. The `ApplicationRunner` checks first — if rows already exist, it returns immediately. First startup ingests. Every restart after that is instant.

---

## pgvector under the hood

PostgreSQL with pgvector stores each chunk as a row with a native `vector(768)` column:

```sql
CREATE TABLE vector_store (
    id        uuid PRIMARY KEY,
    content   text,
    metadata  json,
    embedding vector(768)
);

CREATE INDEX ON vector_store USING hnsw (embedding vector_cosine_ops);
```

At query time, a single SQL statement does the similarity search:

```sql
SELECT content
FROM vector_store
ORDER BY embedding <=> $query_vector
LIMIT 4;
```

The `<=>` operator is cosine distance. The HNSW index makes this O(log N) instead of O(N). Spring AI generates this query automatically — you never write it yourself.

---

## Docker setup in 30 seconds

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
```

```bash
docker-compose up -d
mvn spring-boot:run
```

Spring AI creates the `vector_store` table automatically on first startup. Nothing else to configure.

---

## SimpleVectorStore vs PgVectorStore

| | SimpleVectorStore | PgVectorStore |
|-|-------------------|---------------|
| Storage | JVM heap | PostgreSQL |
| Persistence | Lost on restart | Survives restarts |
| Search | O(N) brute-force | O(log N) HNSW |
| Duplicate ingestion | Safe | Prevented by COUNT check |
| Setup | Zero | Docker |
| Production-ready | No | Yes |

---

## What's Next — Chapter 9: Graph RAG with Neo4j

Chapter 8 solves persistence and scale. But flat vector search still has a blindspot.

An employee asks: *"What happens if my parental leave runs out and I'm still unwell?"*

A flat vector search retrieves the parental leave chunk OR the sick leave chunk — not both. It has no concept of the relationship between them.

**Chapter 9** uses Neo4j — a graph database where policy sections are connected by edges. Graph RAG traverses those edges and returns both chunks. Same `VectorStore` interface. One bean swap. Completely different retrieval behaviour.

---

## The Series So Far

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- [Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.](https://www.linkedin.com/pulse/chapter-6-your-ai-bot-has-goldfish-memory-heres-how-fix-chopparapu-ck0hc/?trackingId=m0DOW59LgPkGihFvJDxZBA%3D%3D)
- [Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.](https://www.linkedin.com/pulse/chapter-7-your-ai-guessing-rag-makes-read-manual-balaji-chopparapu-ararc/?trackingId=4L5yf1FX4CspOTawv4ddmw%3D%3D)
- **Chapter 8 — Your Vector Store Shouldn't Forget Everything When You Restart** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, Ollama, and PostgreSQL with pgvector — runs entirely on your laptop, no paid APIs.*
