# Spring AI with Llama

A practical, code-first guide to building AI-powered Java applications using **Spring AI** and **Llama** — no paid APIs, runs entirely on your laptop.

---

## About the Book

Most Spring AI tutorials assume you have an OpenAI account. This book does not. Every example runs locally using [Ollama](https://ollama.ai) and the open-source Llama model — free, private, and no internet required.

The book is built around one evolving real-world project: **SmartHR Assistant**, an AI-powered HR platform for a fictional company called TechCorp. Each chapter adds a new capability to the same Spring Boot application, so you always have something working and something to build on.

---

## What's Covered

| Chapter | Topic | Concept |
|---------|-------|---------|
| 1 | Hello, Spring AI! | ChatClient, Ollama setup |
| 2 | Core Concepts | Tokens, Messages, ChatOptions |
| 3 | Connecting to Llama | Model switching, Ollama config |
| 4 | Prompt Engineering | PromptTemplate, system messages |
| 5 | Structured Output | BeanOutputConverter, JSON responses |
| 6 | Chat Memory | Multi-turn conversations |
| 7 | RAG | Vector stores, embeddings, document Q&A |
| 8 | Function Calling | Tool use, Java method binding |
| ... | ...and more through Chapter 17 | |

---

## Code

Each chapter has its own self-contained, runnable Spring Boot project under `code/`:

```
code/
├── chapter-01-hello-spring-ai/
├── chapter-02-core-concepts/
└── ...
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

---

## Prerequisites

- Java 21+
- Maven 3.8+
- [Ollama](https://ollama.ai) with `llama3.2` pulled
