# Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.

Sarah, the HR manager at TechCorp, spots a problem after a few weeks of running the SmartHR bot.

Employees are asking about specific TechCorp policies — parental leave weeks, notice periods, health insurance provider — and the bot is answering confidently. Confidently and **wrongly**.

> "It told someone they get 20 days parental leave. Our policy is 16 weeks. Can we make it answer from our actual documents?"

This is the fundamental limitation of every LLM. It answers from training data — general knowledge baked in months ago. It has never read TechCorp's HR policy. When it guesses, it sounds authoritative. That is exactly what makes it dangerous.

**RAG (Retrieval-Augmented Generation)** is the fix.

---

## What RAG Actually Does

Instead of asking the model to recall something it never knew, RAG gives it the relevant page to read — right before it answers.

```
Employee asks: "How many weeks of parental leave does TechCorp offer?"

Step 1 — Embed the question into a vector:
  [0.12, -0.84, 0.33, ...]

Step 2 — Search the vector store for similar chunks:
  "Primary caregivers are entitled to 16 weeks of fully paid parental leave..."

Step 3 — Build the prompt:
  System: "Answer only from the context below."
  Context: "Primary caregivers are entitled to 16 weeks..."
  User: "How many weeks of parental leave does TechCorp offer?"

Step 4 — Model answers from the document:
  "TechCorp offers 16 weeks of fully paid parental leave for primary caregivers."
```

The model is not recalling from training. It is reading the relevant section and summarising it. No guessing. No hallucination.

---

## Two Phases: Ingest Once, Query Many Times

### Phase 1 — Ingest (runs at startup)

The app reads the HR policy file, splits it into chunks, converts each chunk into a vector using `nomic-embed-text`, and stores both the vector and the original text in `SimpleVectorStore`:

```java
@Bean
public SimpleVectorStore vectorStore(EmbeddingModel embeddingModel) {
    SimpleVectorStore store = SimpleVectorStore.builder(embeddingModel).build();
    TikaDocumentReader reader = new TikaDocumentReader(policyResource);
    List<Document> chunks = new TokenTextSplitter().apply(reader.read());
    store.add(chunks);
    return store;
}
```

### Phase 2 — Query (every request)

`QuestionAnswerAdvisor` intercepts every `ChatClient` call, embeds the question, retrieves the top matching chunks, and injects them into the prompt — automatically:

```java
ChatClient chatClient = ChatClient.builder(chatModel)
        .defaultSystem(SYSTEM_PROMPT)
        .defaultAdvisors(QuestionAnswerAdvisor.builder(vectorStore).build())
        .build();

// The controller just calls this — the advisor does the RAG work
String answer = chatClient.prompt().user(question).call().content();
```

The controller has no idea RAG is happening. It makes a normal `ChatClient` call.

---

## What the Vector Store Actually Is

A common question: if the vectors are stored in the JVM, what is running the embedding computation?

Two things work together:

| Component | Role |
|-----------|------|
| `nomic-embed-text` (Ollama) | Converts text to float arrays — the neural network runs here |
| `SimpleVectorStore` (JVM) | Stores the float arrays in a `ConcurrentHashMap` |

`SimpleVectorStore` is just a map. It cannot produce embeddings. Every embed call — at ingest time and at query time — goes to Ollama.

At query time, `SimpleVectorStore` embeds the question, iterates over every stored vector, computes cosine similarity against each one, and returns the top-K matches. It is a brute-force O(N) scan — fine for a small document set, but not for thousands of chunks. That is exactly what the next two chapters address.

---

## The Two Endpoints

```bash
# Ask a question grounded in TechCorp's HR policy
curl -s -X POST http://localhost:8080/hr/policy/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many weeks of parental leave does TechCorp offer?"}'

# Ingest new policy text at runtime — no restart needed
curl -s -X POST http://localhost:8080/hr/policy/ingest \
  -H "Content-Type: application/json" \
  -d '{"text": "TechCorp Bonus Policy: All employees are eligible for an annual bonus of up to 15%."}'
```

The app ships with `techcorp-hr-policy.txt` bundled in resources and ingests it automatically at startup. No manual setup needed.

---

## What's Coming Next

Chapter 7 uses `SimpleVectorStore` — an in-memory store that is lost every time the app restarts. Every restart means re-ingesting the documents. And with an O(N) brute-force scan, it will not scale beyond a few hundred chunks.

**Chapter 8** fixes both problems by swapping in `PgVectorStore` — PostgreSQL with the pgvector extension. Vectors persist across restarts. The HNSW index brings search from O(N) to O(log N). And the beautiful part: the controller does not change at all.

**Chapter 9** goes further — Neo4j as a graph database where policy sections are connected by relationships. Graph RAG can traverse those connections to answer questions that span multiple policy areas. A flat vector search cannot do that.

Same `VectorStore` interface. One bean swap. Completely different backend.

---

## The Series So Far

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- [Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.](https://www.linkedin.com/pulse/chapter-6-your-ai-bot-has-goldfish-memory-heres-how-fix-chopparapu-ck0hc/?trackingId=m0DOW59LgPkGihFvJDxZBA%3D%3D)
- **Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 21, and Ollama — runs entirely on your laptop, no paid APIs.*
