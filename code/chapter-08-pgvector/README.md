# Chapter 8 — Persistent Vector Store with PgVector

Upgrade the SmartHR policy Q&A from an in-memory vector store to PostgreSQL with pgvector — so policy knowledge survives restarts and scales to thousands of documents.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 21+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |
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

At startup it reads `policies/techcorp-hr-policy.txt`, chunks it, embeds each chunk via `nomic-embed-text`, and stores the vectors in PostgreSQL. On the next restart, the vectors are already there — no re-ingestion needed.

---

## What Changed from Chapter 7

The controller, `QuestionAnswerAdvisor`, `TikaDocumentReader`, and `TokenTextSplitter` are **identical to Chapter 7**. The only difference is one `@Bean` and four lines of config:

**Chapter 7 — SimpleVectorStore (in-memory):**
```java
SimpleVectorStore.builder(embeddingModel).build()
```

**Chapter 8 — PgVectorStore (PostgreSQL):**
```java
PgVectorStore.builder(jdbcTemplate, embeddingModel)
        .initializeSchema(true)
        .build()
```

Spring AI's `VectorStore` interface abstracts the backend completely.

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
    │   │   └── RagConfig.java              ← PgVectorStore bean + startup ingestion
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
