# Chapter 7 — RAG: Retrieval Augmented Generation

> **What you will build:** A policy document Q&A system — Sarah uploads TechCorp's HR policy PDFs and employees get answers that cite the actual company policy, not generic AI guesses.

---

## The Problem We Are Solving

After a few weeks, Sarah notices a worrying pattern. Employees ask about TechCorp's specific policies — parental leave weeks, notice period, health insurance provider — and the bot confidently gives wrong answers because it is drawing from general knowledge, not TechCorp's actual documents.

> "It told someone they get 20 days parental leave. Our policy is 16. Can we make it answer from our actual documents?"

This is what RAG was built for.

---

## What You Will Learn

- What RAG is and why it solves hallucination for domain-specific queries
- How embeddings convert documents into searchable vectors
- How vector stores (in-memory and PGVector) work
- How to ingest PDF documents into a vector store
- How Spring AI's `QuestionAnswerAdvisor` wires it all together
- How to build a policy Q&A endpoint with source citations

---

## What Is RAG?

RAG (Retrieval Augmented Generation) is a pattern that grounds the AI's answer in your documents.

Spring AI orchestrates two Ollama models with completely different roles:

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

- **`nomic-embed-text`** — converts text into vectors (float arrays). Called at ingest time for each chunk and at query time for each question.
- **`llama3.2`** — receives the question plus the retrieved policy chunks as context and generates a grounded answer.

Both models run inside Ollama. Spring AI never produces embeddings itself — it delegates to Ollama for all model calls.

```
                    ┌─────────────────────────┐
                    │   TechCorp Policy PDFs   │
                    │  (ingested at startup)   │
                    └───────────┬─────────────┘
                                │ chunked + embedded
                                ▼
Employee asks:          ┌───────────────┐
"How many days of  ──►  │  Vector Store  │  ← stores meaning vectors
 parental leave?"       └───────┬───────┘
                                │ similarity search
                                ▼
                    ┌─────────────────────────┐
                    │  Top 3 relevant chunks   │
                    │  from policy documents   │
                    └───────────┬─────────────┘
                                │ injected into prompt
                                ▼
                    ┌─────────────────────────┐
                    │         Llama            │
                    │  "Based on TechCorp's   │
                    │   policy document,       │
                    │   parental leave is      │
                    │   16 weeks..."           │
                    └─────────────────────────┘
```

The model does not guess — it reads the relevant section of your document and summarises it.

---

## The Two Phases

### Phase 1 — Ingestion (run once)

```java
// Read PDF → chunk into paragraphs → embed each chunk → store in vector DB
List<Document> documents = new TokenTextSplitter()
        .apply(new PagePdfDocumentReader("classpath:policies/hr-policy.pdf")
        .get());

vectorStore.add(documents);
```

### Phase 2 — Retrieval (every query)

```java
// Find the most relevant document chunks for the question
// Inject them into the prompt alongside the question
ChatClient chatClient = ChatClient.builder(chatModel)
        .defaultAdvisors(new QuestionAnswerAdvisor(vectorStore))
        .build();

String answer = chatClient.prompt().user(question).call().content();
```

Spring AI's `QuestionAnswerAdvisor` handles the retrieval and injection automatically.

---

## Vector Store Options

| Store | Setup | Best for |
|-------|-------|----------|
| `SimpleVectorStore` | In-memory, no DB needed | Development, small datasets |
| `PgVectorStore` | PostgreSQL + pgvector extension | Production, large datasets |
| `ChromaVectorStore` | Chroma DB | Standalone vector DB |
| `RedisVectorStore` | Redis with vector support | High-throughput queries |

Chapter 7 starts with `SimpleVectorStore` then migrates to `PgVectorStore`.

---

## What You Will Build — Policy Q&A Endpoint

```java
// POST /hr/policy/ask
@PostMapping("/policy/ask")
public PolicyResponse askPolicy(@RequestBody HrRequest request) {
    String answer = chatClient
            .prompt()
            .user(request.question())
            .call()
            .content();
    return new PolicyResponse(request.question(), answer);
}

// POST /hr/policy/ingest — upload a policy document
@PostMapping("/policy/ingest")
public String ingest(@RequestParam MultipartFile file) throws IOException {
    List<Document> docs = new TokenTextSplitter()
            .apply(new TikaDocumentReader(file.getResource()).get());
    vectorStore.add(docs);
    return "Ingested " + docs.size() + " chunks from " + file.getOriginalFilename();
}
```

**Test it:**
```bash
# Ingest a policy PDF
curl -s -X POST http://localhost:8080/hr/policy/ingest \
  -F "file=@techcorp-hr-policy.pdf"

# Ask a question grounded in the document
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -d '{"question": "How many weeks of parental leave does TechCorp offer?"}'
```

---

## PGVector Setup (Docker)

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
```

---

## Summary

In this chapter you will:

- Understand what RAG is and why it prevents hallucination on company-specific questions
- Ingest PDF policy documents into a vector store
- Use `QuestionAnswerAdvisor` to automatically retrieve and inject relevant context
- Build a policy Q&A endpoint backed by real TechCorp documents
- Migrate from in-memory to PGVector for production

---

## What's Next

In **Chapter 8**, we upgrade the vector store to PostgreSQL with pgvector — persisting policy embeddings across restarts and replacing the O(N) brute-force scan with an efficient HNSW index. The controller and API stay completely unchanged.

*Code for this chapter: [`code/chapter-07-rag/`](../../code/chapter-07-rag/)*
