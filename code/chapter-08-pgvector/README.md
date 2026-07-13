# Chapter 8 — Persistent Vector Store with PgVector

Upgrade the SmartHR policy Q&A from an in-memory vector store to PostgreSQL with pgvector — so policy knowledge survives restarts and scales to thousands of documents.

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
  <path d="M 210 155 L 350 107" fill="none" stroke="#5ba3d9" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#b8)"/>
  <text x="278" y="120" text-anchor="middle" font-size="9" fill="#1a5f96">embed text</text>
  <path d="M 350 118 L 210 165" fill="none" stroke="#5ba3d9" stroke-width="1.8" marker-end="url(#b8)"/>
  <text x="278" y="152" text-anchor="middle" font-size="9" fill="#1a5f96">float[768]</text>
  <path d="M 210 175 L 350 158" fill="none" stroke="#5aaa6b" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#g8)"/>
  <text x="278" y="175" text-anchor="middle" font-size="9" fill="#1b6b2f">prompt + context</text>
  <path d="M 350 168 L 210 185" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#g8)"/>
  <text x="278" y="196" text-anchor="middle" font-size="9" fill="#1b6b2f">answer</text>
  <path d="M 210 220 L 350 275" fill="none" stroke="#5b6abf" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#p8)"/>
  <text x="268" y="240" text-anchor="middle" font-size="9" fill="#2d3494">store / search</text>
  <path d="M 350 288 L 210 232" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#p8)"/>
  <text x="268" y="272" text-anchor="middle" font-size="9" fill="#2d3494">top-K chunks</text>
  <defs>
    <marker id="b8" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5ba3d9"/></marker>
    <marker id="g8" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="p8" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
  </defs>
</svg>

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25.0.3 | `java -version` |
| Maven | 3.9.16 | `mvn -version` |
| Ollama | 0.31.1 | `ollama --version` |

> **Versions:** These tutorials should work on the most recent versions of these tools. They were built and tested on **Java 25.0.3**, **Maven 3.9.16**, and **Ollama 0.31.1**.
| Docker | latest | `docker --version` |

---

## Setup

### 1. Pull the models

```bash
ollama pull llama3.2
ollama pull nomic-embed-text
```

### 2. Start PostgreSQL with pgvector

```bash
cd code/chapter-08-pgvector
docker-compose up -d
```

Verify it is running:

```bash
docker-compose ps
```

### 3. Start Ollama

```bash
curl -s http://localhost:11434/api/tags
```

If no response, start it:

```bash
ollama serve
```

---

## Run the Application

```bash
cd code/chapter-08-pgvector
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

**First startup:** reads `policies/techcorp-hr-policy.txt`, splits it into chunks, embeds each chunk via `nomic-embed-text`, and stores the vectors in PostgreSQL.

**Subsequent restarts:** detects that the `vector_store` table already has rows and skips ingestion entirely — no duplicate chunks, no re-embedding cost.

---

## What Changed from Chapter 7

The controller, `QuestionAnswerAdvisor`, `TikaDocumentReader`, and `TokenTextSplitter` are **identical to Chapter 7**. Only `RagConfig` changes:

**Chapter 7 — SimpleVectorStore (in-memory):**
```java
@Bean
public SimpleVectorStore vectorStore(EmbeddingModel embeddingModel) {
    SimpleVectorStore store = SimpleVectorStore.builder(embeddingModel).build();
    // ingest called directly — works because SimpleVectorStore needs no afterPropertiesSet()
    ingestPolicy(store);
    return store;
}
```

**Chapter 8 — PgVectorStore (PostgreSQL):**
```java
// import org.springframework.ai.vectorstore.pgvector.PgVectorStore;

@Bean
public VectorStore vectorStore(EmbeddingModel embeddingModel, JdbcTemplate jdbcTemplate) {
    return PgVectorStore.builder(jdbcTemplate, embeddingModel)
            .initializeSchema(true)
            .dimensions(768)
            .distanceType(PgVectorStore.PgDistanceType.COSINE_DISTANCE)
            .indexType(PgVectorStore.PgIndexType.HNSW)
            .build();
}

@Bean
public ApplicationRunner ingestPolicy(VectorStore vectorStore, JdbcTemplate jdbcTemplate) {
    return args -> {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM vector_store", Integer.class);
        if (Objects.requireNonNullElse(count, 0) > 0) {
            return; // already ingested — skip
        }
        List<Document> chunks = new TokenTextSplitter()
                .apply(new TikaDocumentReader(policyResource).read());
        vectorStore.add(chunks);
    };
}
```

Two important differences from Chapter 7:

1. **`ApplicationRunner` instead of direct call** — `PgVectorStore` implements `InitializingBean`. Spring calls `afterPropertiesSet()` on it after the `@Bean` method returns — that is when it registers the pgvector JDBC type and creates the schema. Calling `store.add()` inside the `@Bean` method would run before that initialisation, causing `PSQLException: Unknown type vector`. `ApplicationRunner` fires after all beans are fully initialised.

2. **Idempotent ingestion** — a `SELECT COUNT(*)` check skips ingestion if rows already exist, so restarting the app never creates duplicate chunks.

Spring AI's `VectorStore` interface abstracts the backend completely — the `PolicyController` and `QuestionAnswerAdvisor` are unchanged.

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/policy/ask` | Ask a question grounded in policy documents |
| `POST` | `/hr/policy/ingest` | Add new policy text to the vector store at runtime |

---

## Example Usage

```bash
# Ask a question
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many days of annual leave do I get?"}'

# Ingest new policy text
curl -s -X POST http://localhost:8080/hr/policy/ingest \
  -H "Content-Type: application/json" \
  -d '{"text": "TechCorp Bonus Policy: All employees are eligible for an annual bonus of up to 15%."}'
```

---

## SimpleVectorStore vs PgVectorStore

| Concern | SimpleVectorStore | PgVectorStore |
|---------|-------------------|---------------|
| Storage | JVM heap | PostgreSQL table |
| Persistence | Lost on restart | Survives restarts |
| Duplicate ingestion | Safe (overwritten) | Prevented by COUNT check |
| Search | O(N) brute-force | O(log N) HNSW index |
| Setup | Zero | Docker |
| Production-ready | No | Yes |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:5432` | PostgreSQL not running | Run `docker-compose up -d` |
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` and `ollama pull nomic-embed-text` |
| `Unknown type vector` | pgvector type not registered | Ensure ingestion runs via `ApplicationRunner`, not inside `@Bean` |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-08-pgvector/
├── docker-compose.yml
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrApplication.java
    │   ├── config/
    │   │   └── RagConfig.java              ← PgVectorStore bean + idempotent ingestion
    │   ├── controller/
    │   │   └── PolicyController.java       ← /hr/policy/ask + /hr/policy/ingest
    │   └── model/
    │       ├── PolicyAskRequest.java
    │       ├── PolicyIngestRequest.java
    │       ├── PolicyResponse.java
    │       └── IngestResponse.java
    └── resources/
        ├── application.yml
        └── policies/
            └── techcorp-hr-policy.txt
```

---

*Full chapter write-up: [`chapters/chapter-08-pgvector.md`](../../chapters/chapter-08-pgvector.md)*
