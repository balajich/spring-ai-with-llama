# Spring AI with Llama

A practical, code-first guide to building AI-powered Java applications using **Spring AI** and **Llama** — no paid APIs, runs entirely on your laptop.

---

## About the Book

Most Spring AI tutorials assume you have an OpenAI account. This book does not. Every example runs locally using [Ollama](https://ollama.ai) and the open-source Llama model — free, private, and no internet required.

The book is built around one evolving real-world project: **SmartHR Assistant**, an AI-powered HR platform for a fictional company called TechCorp. Each chapter adds a new capability to the same Spring Boot application, so you always have something working and something to build on.

---

## What's Covered

| Chapter | Topic | Concept | Status |
|---------|-------|---------|--------|
| 1 | Hello, Spring AI! | ChatClient, Ollama setup | ✅ Complete |
| 2 | Core Concepts | Tokens, Messages, ChatOptions | ✅ Complete |
| 3 | Running and Comparing Multiple Models with Ollama | Model switching, side-by-side comparison | ✅ Complete |
| 4 | Prompt Engineering | PromptTemplate, system messages | ✅ Complete |
| 5 | Structured Output — Asking the AI to Serve JSON Instead of Raw Text | BeanOutputConverter, JSON responses | ✅ Complete |
| 6 | Chat Memory | Multi-turn conversations, session IDs | ✅ Complete |
| 7 | RAG with SimpleVectorStore | Embeddings, in-memory vector store, document Q&A | ✅ Complete |
| 8 | Persistent Vector Store with PgVector | PostgreSQL + pgvector, HNSW index, idempotent ingestion | ✅ Complete |
| 9 | Graph RAG with Neo4j | Graph database, policy relationships, cross-topic retrieval | ✅ Complete |
| 10 | Function Calling | Tool use, Java method binding | ✅ Complete |
| 11 | MCP — Exposing an Existing REST API as Tools | Model Context Protocol, MCP server/client, tool discovery | ✅ Complete |
| 12 | Multimodality | Images and text, vision models | 🚧 In progress |
| 13 | Streaming API | Real-time token-by-token responses | 🚧 In progress |
| 14 | Document Intelligence | PDFs, Word docs, web pages | 🚧 In progress |
| 15 | Semantic Search | Embeddings, vector similarity | 🚧 In progress |
| 16 | AI Agents | Autonomous workflows, tool chaining | 🚧 In progress |
| 17 | Evaluation | Testing and scoring AI responses | 🚧 In progress |
| 18 | Performance and Caching | Virtual threads, response caching | 🚧 In progress |
| 19 | Security and Safety | Prompt injection, PII scrubbing | 🚧 In progress |
| 20 | Production Deployment | Docker, Ollama container, observability | 🚧 In progress |

---

## Vector Store Progression (Chapters 7 → 8 → 9)

One of the key themes of this book is showing how Spring AI's `VectorStore` interface lets you swap backends with a single bean change:

| Chapter | Store | Persistence | Search | Extra Setup |
|---------|-------|-------------|--------|-------------|
| 7 | `SimpleVectorStore` | In-memory — lost on restart | O(N) brute-force | None |
| 8 | `PgVectorStore` | PostgreSQL — survives restarts | O(log N) HNSW index | Docker |
| 9 | `Neo4jVectorStore` | Neo4j — graph + vector | O(log N) + graph traversal | Docker |

The controller, `QuestionAnswerAdvisor`, and API endpoints are **identical across all three chapters**.

---

## Code

Each chapter has its own self-contained, runnable Spring Boot project under `code/`:

```
code/
├── chapter-01-hello-spring-ai/
├── chapter-02-core-concepts/
├── chapter-03-comparing-models/
├── chapter-04-prompt-engineering/
├── chapter-05-structured-output/
├── chapter-06-chat-memory/
├── chapter-07-rag/
├── chapter-08-pgvector/          ← requires Docker (PostgreSQL + pgvector)
├── chapter-09-neo4j/             ← requires Docker (Neo4j)
├── chapter-10-function-calling/
├── chapter-11-mcp-integration/   ← multi-module: calendar-service (8082), mcp-server (8081), mcp-client (8080)
└── tests/                        ← Karate BDD API tests for all chapters
```

### Quick Start (Chapter 1)

```bash
# 1. Install Ollama and pull the model
ollama pull llama3.2
ollama serve

# 2. Run the app
cd code/chapter-01-hello-spring-ai
mvn spring-boot:run

# 3. Ask a question
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the maternity leave policy?"}'
```

### Running Tests

From the `code/tests/` directory:

```bash
./run-tests.sh chapter-01
./run-tests.sh chapter-07
./run-tests.sh chapter-08   # requires Docker: docker-compose up -d in chapter-08-pgvector/
./run-tests.sh chapter-09   # requires Docker: docker-compose up -d in chapter-09-neo4j/
./run-tests.sh chapter-10
./run-tests.sh chapter-11   # starts calendar-service, mcp-server, AND mcp-client
```

---

## Prerequisites

| Tool | Required for | Install |
|------|-------------|---------|
| Java 21+ | All chapters | [adoptium.net](https://adoptium.net) |
| Maven 3.8+ | All chapters | [maven.apache.org](https://maven.apache.org) |
| Ollama | All chapters | [ollama.ai](https://ollama.ai) |
| Docker | Chapters 8, 9 | [docker.com](https://docker.com) |

```bash
ollama pull llama3.2          # chapters 1–11
ollama pull nomic-embed-text  # chapters 7–9 (embedding model)
```

---

## LinkedIn Article Series

Each chapter also has a companion LinkedIn article walking through the concept in plain language:

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- [Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.](https://www.linkedin.com/pulse/chapter-6-your-ai-bot-has-goldfish-memory-heres-how-fix-chopparapu-ck0hc/?trackingId=m0DOW59LgPkGihFvJDxZBA%3D%3D)
- [Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.](https://www.linkedin.com/pulse/chapter-7-your-ai-guessing-rag-makes-read-manual-balaji-chopparapu-ararc/?trackingId=4L5yf1FX4CspOTawv4ddmw%3D%3D)
- [Chapter 8 — Your Vector Store Shouldn't Forget Everything When You Restart](https://www.linkedin.com/pulse/chapter-8-your-vector-store-shouldnt-forget-when-you-chopparapu-fbd2c/?trackingId=sJN7GdS8osG3cLtvf7i3Bg%3D%3D)
- [Chapter 9 — Neo4j Graph RAG: When Vector Search Isn't Enough](https://www.linkedin.com/pulse/chapter-9-neo4j-graph-rag-when-vector-search-isnt-balaji-chopparapu-xiutc/?trackingId=ubMaVVYy7Z70TynlVV8IeA%3D%3D)
- [Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.](linkedin/chapter-10-function-calling.md) *(publishing soon)*

---

## Source Code

Full source code for all chapters: [github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)
- Please leave a star if you found it helpful. 
