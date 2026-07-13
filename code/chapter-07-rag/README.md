# Chapter 7 — RAG: Answering Questions from Your Own Documents

Give the SmartHR Assistant knowledge of TechCorp's actual HR policies — so employees get answers grounded in real company documents, not generic AI guesses.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |

---

## Setup

### 1. Pull the models

```bash
ollama pull llama3.2
ollama pull nomic-embed-text
```

Two models are needed because they do fundamentally different jobs:

<svg viewBox="0 0 640 280" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>RAG High-Level Architecture</title>
  <desc>Spring AI in the JVM calls nomic-embed-text for embeddings and llama3.2 for answers, both running in Ollama.</desc>
  <rect width="640" height="280" fill="#f8f9fa" rx="12"/>
  <rect x="40" y="80" width="180" height="120" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="130" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="130" y="128" text-anchor="middle" font-size="11" fill="#999">JVM</text>
  <text x="130" y="155" text-anchor="middle" font-size="10" fill="#555">QuestionAnswerAdvisor</text>
  <text x="130" y="171" text-anchor="middle" font-size="10" fill="#555">SimpleVectorStore</text>
  <text x="130" y="187" text-anchor="middle" font-size="10" fill="#555">ChatClient</text>
  <rect x="420" y="40" width="180" height="200" rx="10" fill="white" stroke="#adb5bd" stroke-width="2"/>
  <text x="510" y="72" text-anchor="middle" font-size="13" font-weight="700" fill="#333">Ollama</text>
  <text x="510" y="90" text-anchor="middle" font-size="11" fill="#999">localhost:11434</text>
  <rect x="440" y="104" width="140" height="52" rx="8" fill="#e0f0ff" stroke="#5ba3d9" stroke-width="1.5"/>
  <text x="510" y="126" text-anchor="middle" font-size="11" font-weight="700" fill="#1a5f96">nomic-embed-text</text>
  <text x="510" y="144" text-anchor="middle" font-size="10" fill="#2d6fa4">Embedding Model</text>
  <rect x="440" y="172" width="140" height="52" rx="8" fill="#e8f5e9" stroke="#5aaa6b" stroke-width="1.5"/>
  <text x="510" y="194" text-anchor="middle" font-size="11" font-weight="700" fill="#1b6b2f">llama3.2</text>
  <text x="510" y="212" text-anchor="middle" font-size="10" fill="#2a7d40">Generative Model</text>
  <path d="M 220 118 L 440 130" fill="none" stroke="#5ba3d9" stroke-width="1.8" stroke-dasharray="6,3" marker-end="url(#arr-blue)"/>
  <text x="330" y="110" text-anchor="middle" font-size="10" fill="#1a5f96">embed text</text>
  <path d="M 440 142 L 220 132" fill="none" stroke="#5ba3d9" stroke-width="1.8" marker-end="url(#arr-blue)"/>
  <text x="330" y="152" text-anchor="middle" font-size="10" fill="#1a5f96">float[ ]</text>
  <path d="M 220 162 L 440 186" fill="none" stroke="#5aaa6b" stroke-width="1.8" stroke-dasharray="6,3" marker-end="url(#arr-green)"/>
  <text x="330" y="168" text-anchor="middle" font-size="10" fill="#1b6b2f">prompt + context</text>
  <path d="M 440 200 L 220 176" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#arr-green)"/>
  <text x="330" y="204" text-anchor="middle" font-size="10" fill="#1b6b2f">answer</text>
  <defs>
    <marker id="arr-blue" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5ba3d9"/></marker>
    <marker id="arr-green" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
  </defs>
</svg>

- **`llama3.2`** — the generative model. It reads the retrieved policy chunks and composes a natural language answer.
- **`nomic-embed-text`** — the embedding model. It converts text into a float array (a vector) that captures semantic meaning. This runs in Ollama; Spring AI cannot produce embeddings on its own.

`SimpleVectorStore` only stores the resulting float arrays in the JVM — it never computes them. Every embed call (at ingest time and at query time) goes to Ollama:

```
Text / Question
      │
      ▼
Ollama (nomic-embed-text)   ← neural network runs here, returns float[]
      │
      ▼
SimpleVectorStore (JVM)     ← stores or searches the float[]
```

`nomic-embed-text` is used instead of `llama3.2` for embeddings because embedding models are purpose-built to map text into a semantic vector space — they are smaller, faster, and far better at similarity search. `llama3.2` is a generative model; using it for embeddings would give poor results.

### 2. Start Ollama

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
cd code/chapter-07-rag
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

At startup it automatically reads `policies/techcorp-hr-policy.txt`, splits it into chunks, embeds each chunk, and loads them into the in-memory vector store — ready to answer questions immediately.

`SimpleVectorStore` is backed by a `ConcurrentHashMap<String, Document>` where each entry holds a policy chunk and its embedding vector. When a question arrives, it embeds the question, iterates over every entry in the map, computes cosine similarity against each stored vector, and returns the top-K closest chunks. It is a brute-force linear scan — no index, no approximate nearest-neighbour — which is fine for a small policy document but will not scale to thousands of chunks. Production systems swap it for a proper vector database such as PgVector or Pinecone.

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/policy/ask` | Ask a question grounded in policy documents |
| `POST` | `/hr/policy/ingest` | Add new policy text to the vector store at runtime |

**Ask request shape:**
```json
{
  "question": "How many days of annual leave do I get?"
}
```

**Ask response shape:**
```json
{
  "question": "How many days of annual leave do I get?",
  "answer": "..."
}
```

**Ingest request shape:**
```json
{
  "text": "TechCorp Bonus Policy: All employees are eligible for an annual bonus of up to 15%."
}
```

**Ingest response shape:**
```json
{
  "chunksIngested": 1,
  "message": "Ingested 1 chunk(s) into the policy store."
}
```

---

## Example — Asking About Policy

```bash
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many days of annual leave do I get?"}'
```

```bash
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the remote work policy?"}'
```

```bash
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many weeks of parental leave does a primary caregiver receive?"}'
```

## Example — Ingesting New Policy

```bash
curl -s -X POST http://localhost:8080/hr/policy/ingest \
  -H "Content-Type: application/json" \
  -d '{"text": "TechCorp Sabbatical Policy: Employees with 5 or more years of service are eligible for a 6-week paid sabbatical."}'
```

After ingesting, the new policy is immediately queryable:

```bash
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "Am I eligible for a sabbatical after 5 years?"}'
```

---

## How RAG Works

```
Question: "How many days of annual leave do I get?"

Step 1 — Embed the question:
  question → [0.12, -0.84, 0.33, ...]  (vector)

Step 2 — Retrieve top-K matching chunks from the vector store:
  "All full-time employees are entitled to 20 days of paid annual leave..."

Step 3 — Augment the prompt:
  System:  "You are an HR assistant. Answer based only on the context below."
  Context: "All full-time employees are entitled to 20 days..."
  User:    "How many days of annual leave do I get?"

Step 4 — Generate a grounded answer:
  "Full-time employees at TechCorp are entitled to 20 days of paid annual leave per year."
```

`QuestionAnswerAdvisor` handles Steps 1–3 automatically. It intercepts every `ChatClient` call, embeds the question, retrieves relevant chunks from `SimpleVectorStore`, and injects them into the prompt as context.

---

## Limitations

| Concern | This chapter | Production approach |
|---------|-------------|---------------------|
| Vector store | `SimpleVectorStore` — in-memory, lost on restart | Use PgVector, Redis, or Pinecone |
| Document formats | Plain text via `TikaDocumentReader` | Tika supports PDF, Word, HTML, and more |
| Chunk size | Default `TokenTextSplitter` settings | Tune chunk size and overlap for your docs |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` and `ollama pull nomic-embed-text` |
| Answers lack policy detail | Embedding model not running | Confirm `nomic-embed-text` is pulled and Ollama is running |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-07-rag/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrApplication.java
    │   ├── config/
    │   │   └── RagConfig.java              ← SimpleVectorStore + startup ingestion
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
            └── techcorp-hr-policy.txt      ← bundled HR policy document
```

---

*Full chapter write-up: [`chapters/chapter-07-rag.md`](../../chapters/chapter-07-rag.md)*
