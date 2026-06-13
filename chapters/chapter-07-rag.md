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

RAG (Retrieval Augmented Generation) is a pattern that grounds the AI's answer in your documents:

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

*Code for this chapter: [`code/chapter-07-rag/`](../code/chapter-07-rag/)*
