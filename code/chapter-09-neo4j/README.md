# Chapter 9 — Graph RAG with Neo4j

Upgrade the SmartHR policy Q&A to Neo4j — a graph database where policy sections are connected by relationships, enabling Graph RAG to answer multi-topic questions that flat vector search cannot handle.

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

### 2. Start Neo4j

```bash
docker-compose up -d
```

Open the Neo4j Browser at **http://localhost:7474** to visually explore the policy graph.
Login: `neo4j` / `smarthr123`

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
cd code/chapter-09-neo4j
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

At startup it ingests the policy document into Neo4j and creates graph edges between related policy sections (parental leave ↔ sick leave, onboarding ↔ IT equipment, performance ↔ learning).

---

## What Changed from Chapter 8

Again, only one `@Bean` changes. The controller and API are identical to Chapters 7 and 8:

**Chapter 8 — PgVectorStore:**
```java
PgVectorStore.builder(jdbcTemplate, embeddingModel)
        .initializeSchema(true)
        .build()
```

**Chapter 9 — Neo4jVectorStore:**
```java
Neo4jVectorStore.builder(driver, embeddingModel)
        .initializeSchema(true)
        .build()
```

The additional step in Chapter 9 is creating graph relationships between policy sections after ingestion.

---

## Plain RAG vs Graph RAG

| Question | Plain RAG retrieves | Graph RAG retrieves |
|----------|--------------------|--------------------|
| "What if parental leave runs out and I'm still ill?" | Parental leave chunk only | Parental leave + sick leave (connected) |
| "What laptop do engineers get and how do I request it?" | IT equipment chunk only | IT equipment + onboarding (connected) |

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/policy/ask` | Ask a question; Graph RAG retrieves connected chunks |
| `POST` | `/hr/policy/ingest` | Add new policy text to the graph at runtime |

---

## Example Usage

```bash
# Multi-topic question — Graph RAG surfaces connected policy sections
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What happens if my parental leave runs out and I am still unwell?"}'

# Single-topic question
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many weeks of parental leave does a primary caregiver receive?"}'

# Ingest new policy text
curl -s -X POST http://localhost:8080/hr/policy/ingest \
  -H "Content-Type: application/json" \
  -d '{"text": "TechCorp Sabbatical Policy: Employees with 5+ years of service are eligible for a 6-week paid sabbatical."}'
```

---

## Explore the Graph

Open **http://localhost:7474** and run this Cypher query to see the policy graph:

```cypher
MATCH (a:Document)-[:RELATED_TO]->(b:Document)
RETURN a, b LIMIT 25
```

You can visually see which policy sections are connected.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:7687` | Neo4j not running | Run `docker-compose up -d` |
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` and `ollama pull nomic-embed-text` |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-09-neo4j/
├── docker-compose.yml
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrApplication.java
    │   ├── config/
    │   │   └── RagConfig.java              ← Neo4jVectorStore bean + graph edges
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

*Full chapter write-up: [`chapters/chapter-09-neo4j.md`](../../chapters/chapter-09-neo4j.md)*
