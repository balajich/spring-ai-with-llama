# Chapter 9 — Graph RAG with Neo4j

Upgrade the SmartHR policy Q&A to Neo4j — a graph database where policy sections are connected by relationships, enabling Graph RAG to answer multi-topic questions that flat vector search cannot handle.

<svg viewBox="0 0 580 360" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 9 — Spring AI, Ollama and Neo4j Architecture</title>
  <desc>Spring AI in the JVM communicates with Ollama (nomic-embed-text and llama3.2) and Neo4j Neo4jVectorStore, arranged in two columns.</desc>
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
  <rect x="350" y="210" width="190" height="120" rx="10" fill="white" stroke="#008CC1" stroke-width="2"/>
  <text x="445" y="236" text-anchor="middle" font-size="13" font-weight="700" fill="#006a94">Neo4j</text>
  <text x="445" y="253" text-anchor="middle" font-size="10" fill="#999">localhost:7687</text>
  <rect x="368" y="264" width="154" height="50" rx="7" fill="#e0f5fb" stroke="#008CC1" stroke-width="1.5"/>
  <text x="445" y="285" text-anchor="middle" font-size="11" font-weight="700" fill="#006a94">Neo4jVectorStore</text>
  <text x="445" y="302" text-anchor="middle" font-size="10" fill="#008CC1">nodes + RELATED_TO edges</text>
  <path d="M 210 155 L 350 107" fill="none" stroke="#5ba3d9" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#b9)"/>
  <text x="278" y="120" text-anchor="middle" font-size="9" fill="#1a5f96">embed text</text>
  <path d="M 350 118 L 210 165" fill="none" stroke="#5ba3d9" stroke-width="1.8" marker-end="url(#b9)"/>
  <text x="278" y="152" text-anchor="middle" font-size="9" fill="#1a5f96">float[768]</text>
  <path d="M 210 175 L 350 158" fill="none" stroke="#5aaa6b" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#g9)"/>
  <text x="278" y="175" text-anchor="middle" font-size="9" fill="#1b6b2f">prompt + context</text>
  <path d="M 350 168 L 210 185" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#g9)"/>
  <text x="278" y="196" text-anchor="middle" font-size="9" fill="#1b6b2f">answer</text>
  <path d="M 210 220 L 350 275" fill="none" stroke="#008CC1" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#n9)"/>
  <text x="268" y="240" text-anchor="middle" font-size="9" fill="#006a94">store / search</text>
  <path d="M 350 288 L 210 232" fill="none" stroke="#008CC1" stroke-width="1.8" marker-end="url(#n9)"/>
  <text x="268" y="272" text-anchor="middle" font-size="9" fill="#006a94">top-K chunks + edges</text>
  <defs>
    <marker id="b9" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5ba3d9"/></marker>
    <marker id="g9" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="n9" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#008CC1"/></marker>
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
