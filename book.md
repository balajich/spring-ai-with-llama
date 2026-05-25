# Spring AI with Llama

> A practical, open-source guide to building AI-powered Java applications using Spring AI and Llama — zero API costs, runs entirely on your laptop.

[![Java](https://img.shields.io/badge/Java-21+-orange?style=flat-square&logo=java)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3+-brightgreen?style=flat-square&logo=springboot)](https://spring.io/projects/spring-boot)
[![Spring AI](https://img.shields.io/badge/Spring%20AI-1.0+-brightgreen?style=flat-square&logo=spring)](https://spring.io/projects/spring-ai)
[![Ollama](https://img.shields.io/badge/Ollama-Llama%203.2-blue?style=flat-square)](https://ollama.ai)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## What is This?

This is the companion repository for the book **"Spring AI with Llama — A Practical Guide"**.

Most Spring AI tutorials default to OpenAI. This book is different:

- **100% open source** — uses Llama via Ollama, no paid APIs
- **Runs on your laptop** — no cloud account, no credit card, no vendor lock-in
- **One real project** — every chapter builds on a single evolving HR Assistant app
- **Practical over theoretical** — every concept introduced through a real problem

The project we build throughout the book is **SmartHR Assistant** — an AI-powered HR platform for a fictional company called TechCorp. By the end, it handles resume parsing, policy Q&A, onboarding chatbots, interview scheduling, and automated HR reports.

---

## Meet the Characters

| Character | Role | Their Problem |
|-----------|------|--------------|
| **Sarah** | HR Manager | Drowning in repetitive questions every Monday |
| **Dev** | Java Developer | Building the system chapter by chapter |
| **Raj** | New Hire | Confused during onboarding, needs guidance |
| **Lisa** | Hiring Manager | Wants resumes shortlisted automatically |

Every chapter solves a real problem one of these people faces.

---

## The SmartHR Assistant — What We Build

```
Chapter 1      Chapter 4       Chapter 6        Chapter 7          Chapter 8             Chapter 13
    │               │               │                │                  │                     │
 Ask Any  →   Branded HR  →   Multi-turn   →   Policy RAG   →   Auto-schedule   →    Full Autonomous
 Question      Replies         Chatbot           Q&A            Interviews              HR Agent
```

A single Spring Boot application that grows smarter with every chapter.

---

## Book Chapters

| # | Chapter | Spring AI Concept | Real Feature Built |
|---|---------|------------------|-------------------|
| 1 | [Hello, Spring AI!](#chapter-1--hello-spring-ai) | ChatClient, Ollama setup | First working HR Q&A endpoint |
| 2 | [Core Concepts](#chapter-2--core-concepts-tokens-messages-and-the-ai-abstraction) | Tokens, ChatModel, OllamaOptions | Precise vs Creative HR response modes |
| 3 | Connecting to Llama | Ollama config, model switching | Multi-model support |
| 4 | Prompt Engineering | PromptTemplate, system messages | TechCorp-branded responses |
| 5 | Structured Output | BeanOutputConverter | Resume parser → JSON |
| 6 | Chat Memory | InMemoryChatMemory | Onboarding chatbot |
| 7 | RAG | Vector store, embeddings, PGVector | Policy document Q&A |
| 8 | Function Calling | Tool use, Java method binding | Auto interview scheduler |
| 9 | Multimodality | Image + text | Product defect detector |
| 10 | Streaming API | SSE, Flux | Real-time response streaming |
| 11 | Document Intelligence | PDF, Word, web ingestion | Contract analyzer |
| 12 | Semantic Search | Similarity search, filters | Skill-based job search |
| 13 | AI Agents | Agentic workflows, tool chaining | Monthly HR report agent |
| 14 | Evaluation | Prompt testing, evaluators | Automated QA pipeline |
| 15 | Performance & Caching | Prompt caching, batch processing | Bulk description generator |
| 16 | Security & Safety | Input sanitization, PII handling | Secure HR platform |
| 17 | Production Deployment | Docker, Ollama containers, observability | Production-ready app |

---

## Quick Start

### 1. Prerequisites

```bash
# Java 21+
java -version

# Maven 3.8+
mvn -version

# Install Ollama
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Windows — download from https://ollama.ai
```

### 2. Download Llama and Start Ollama

```bash
ollama pull llama3.2
ollama serve
```

### 3. Clone and Run

```bash
git clone https://github.com/your-username/spring-ai-with-llama.git
cd spring-ai-with-llama/code/chapter-01-hello-spring-ai

mvn spring-boot:run
```

### 4. Ask Your First Question

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is a standard maternity leave policy?"}'
```

```json
{
  "question": "What is a standard maternity leave policy?",
  "answer": "Standard maternity leave policies typically provide 12-16 weeks of paid leave..."
}
```

**That's it.** No API key. No cloud. Just Java and a local AI model.

---

## Repository Structure

```
spring-ai-with-llama/
│
├── book.md                              ← You are here (all chapters)
│
└── code/                                ← Runnable Spring Boot projects (one folder per chapter)
    ├── chapter-01-hello-spring-ai/      ← Chapter 1 — ChatClient + basic Q&A
    ├── chapter-04-prompt-engineering/   ← Chapter 4 — PromptTemplate
    ├── chapter-07-rag/                  ← Chapter 7 — RAG + PGVector
    └── ...
```

Each chapter folder is a self-contained, runnable Spring Boot project.

---

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Java | 21 | Language |
| Spring Boot | 3.3+ | Application framework |
| Spring AI | 1.0+ | AI abstraction layer |
| Ollama | Latest | Local model runner |
| Llama 3.2 | 3B / 8B | AI model |
| PGVector | Latest | Vector store for RAG (Chapter 7+) |
| PostgreSQL | 16 | Database (Chapter 6+) |
| Docker | Latest | Containerization (Chapter 17) |

---

## Why Local Llama Instead of OpenAI?

| | OpenAI / Paid APIs | This Book (Llama + Ollama) |
|--|-------------------|--------------------------|
| **Cost** | Pay per token | Free forever |
| **Privacy** | Data leaves your machine | Stays on your laptop |
| **Internet** | Required | Not required |
| **Vendor lock-in** | Yes | None |
| **Switching models** | Change API key + config | Change one config line |
| **Learning curve** | Need account + billing | Just install Ollama |

> **Note:** Spring AI's abstraction means everything you learn here works with OpenAI, Anthropic, Google, or any other provider. You're not learning a Llama-specific skill — you're learning Spring AI properly, with freedom to switch providers later.

---

## Model Options

All examples use `llama3.2` by default. You can switch with one config change:

```properties
# application.properties
spring.ai.ollama.chat.options.model=llama3.2      # Default — fast, 4GB RAM
spring.ai.ollama.chat.options.model=llama3.2:8b   # Better quality, needs 8GB RAM
spring.ai.ollama.chat.options.model=mistral        # Great alternative
spring.ai.ollama.chat.options.model=phi3:mini      # Ultra-light, runs on 4GB RAM
```

---

## Who Is This For?

This book is for you if:

- You are a **Java developer** comfortable with Spring Boot basics
- You want to add **AI features** to your applications without switching to Python
- You want **practical, runnable examples** — not theoretical overviews
- You want to learn **Spring AI properly** with a real project, not toy demos
- You care about **privacy and cost** — you don't want to send data to OpenAI

You do **not** need prior AI/ML knowledge. Everything is explained from first principles.

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

The written content is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) — free to share with attribution, not for commercial use.

---

## Acknowledgements

- [Spring AI Team](https://github.com/spring-projects/spring-ai) — for building an incredible abstraction layer
- [Ollama](https://ollama.ai) — for making local LLMs accessible to every developer
- [Meta AI](https://ai.meta.com/llama/) — for open-sourcing the Llama model family

---

---

# Chapter 1 — Hello, Spring AI!

> **What you will build:** A working HR Q&A endpoint for TechCorp's SmartHR Assistant.
> Sarah the HR Manager types a question. Llama answers. No OpenAI account needed.

---

## The Problem We Are Solving

It is Monday morning at TechCorp. Sarah, the HR Manager, has 27 unread Slack messages waiting:

- "How many vacation days do I get in my first year?"
- "What's the policy on remote work?"
- "Can I carry over unused PTO?"
- "When does health insurance kick in for new hires?"

These are the same questions. Every week. Sarah spends two hours every Monday answering them instead of doing actual HR work.

**Dev** (that's us — the Java developer on the team) gets a Jira ticket:

> **SMARTHR-001:** Build an AI assistant that can answer common HR questions so Sarah can stop copy-pasting the same answers every Monday.

This chapter builds the foundation. By the end, we will have a Spring Boot app that accepts an HR question and returns an intelligent answer — powered entirely by a local Llama model.

---

## What Is Spring AI?

Spring AI is Spring's official abstraction layer for AI models. It does for AI what Spring Data did for databases — it gives you a consistent, framework-native API so you can:

- Switch AI providers (Ollama, OpenAI, Anthropic, Google) by changing config, not code
- Use familiar Spring patterns (dependency injection, `application.properties`, autoconfiguration)
- Build AI features without learning Python or a new framework

```
Your Spring Boot App
        │
        ▼
   Spring AI API       ← one consistent interface
        │
   ┌────┴────┐
   │         │
Ollama    OpenAI      ← swap providers via config
(Llama)   (GPT-4)
```

We will use Ollama because it runs Llama entirely on your laptop. Free. Private. No API key.

---

## How Ollama Works

Ollama is a tool that downloads and runs open-source LLMs locally. Think of it as Docker for AI models.

```
┌─────────────────────┐
│   Your Laptop        │
│                     │
│  Spring Boot App    │
│        │            │
│        │ HTTP       │
│        ▼            │
│  Ollama Server      │  ← runs on localhost:11434
│  (llama3.2 model)   │
└─────────────────────┘
```

Spring AI talks to Ollama over HTTP — the same way your app might call any REST API.

---

## Setting Up Ollama

### Step 1 — Install Ollama

| OS | Command |
|----|---------|
| macOS | `brew install ollama` |
| Linux | `curl -fsSL https://ollama.ai/install.sh \| sh` |
| Windows | Download installer from https://ollama.ai |

### Step 2 — Download the Llama Model

```bash
ollama pull llama3.2
```

This downloads the Llama 3.2 model (~2GB). It only happens once.

> **RAM requirements:**
> - `llama3.2` (3B) → needs ~4GB RAM
> - `llama3.2:8b` → needs ~8GB RAM
> - `llama3.1:70b` → needs ~48GB RAM (skip this one for now)

### Step 3 — Start Ollama

```bash
ollama serve
```

Verify it is working:

```bash
curl -s http://localhost:11434/api/tags
```

You should see `llama3.2` in the list.

---

## Project Structure

```
code/chapter-01-hello-spring-ai/
├── pom.xml
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java     ← entry point
    │   ├── controller/
    │   │   └── HrChatController.java            ← REST endpoints
    │   └── model/
    │       ├── HrRequest.java                   ← request body
    │       └── HrResponse.java                  ← response body
    └── resources/
        └── application.properties               ← Ollama config
```

---

## The Code

### 1. Maven Dependencies (`pom.xml`)

The only Spring AI dependency we need for Chapter 1 is the Ollama starter:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.ai</groupId>
            <artifactId>spring-ai-bom</artifactId>
            <version>1.0.0</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- This one line connects Spring AI to Ollama -->
    <dependency>
        <groupId>org.springframework.ai</groupId>
        <artifactId>spring-ai-ollama-spring-boot-starter</artifactId>
    </dependency>
</dependencies>
```

The BOM (Bill of Materials) manages Spring AI version compatibility across all its modules.

### 2. Configuration (`application.properties`)

```properties
spring.application.name=SmartHR Assistant
server.port=8080

spring.ai.ollama.base-url=http://localhost:11434
spring.ai.ollama.chat.options.model=llama3.2
spring.ai.ollama.chat.options.temperature=0.3
```

**What is temperature?**

Temperature controls how creative (or random) the model's response is:

| Temperature | Behaviour | Good for |
|-------------|-----------|----------|
| `0.0` | Deterministic — same input always gives same output | Factual lookups |
| `0.3` | Slightly varied — mostly consistent | HR policies, Q&A |
| `0.7` | Creative — varied responses | Writing, brainstorming |
| `1.0` | Very random | Creative fiction |

We use `0.3` for HR — we want consistent, professional answers.

### 3. The Request and Response Models

```java
// HrRequest.java
public record HrRequest(String question) {}

// HrResponse.java
public record HrResponse(String question, String answer) {}
```

Java records are a clean fit here — immutable, no boilerplate, auto-generated constructors and getters.

### 4. The Controller — where the magic happens

```java
@RestController
@RequestMapping("/hr")
public class HrChatController {

    private static final String SYSTEM_PROMPT = """
            You are an HR assistant for TechCorp, a mid-sized technology company.
            Your job is to answer employee questions about HR policies, benefits,
            leave, onboarding, and workplace guidelines clearly and professionally.
            Keep answers concise and factual. If you do not know the answer,
            say so honestly and suggest contacting the HR department directly.
            """;

    private final ChatClient chatClient;

    public HrChatController(ChatClient.Builder builder) {
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
    }

    @PostMapping("/ask")
    public HrResponse ask(@RequestBody HrRequest request) {
        String answer = chatClient
                .prompt()
                .user(request.question())
                .call()
                .content();
        return new HrResponse(request.question(), answer);
    }
}
```

---

## Understanding the Code — Three Key Concepts

### Concept 1: The System Prompt

```java
private static final String SYSTEM_PROMPT = """
        You are an HR assistant for TechCorp...
        """;
```

A **system prompt** is a set of instructions you give the model before the conversation starts. It defines:
- Who the model is (HR assistant, not a general chatbot)
- What it should and shouldn't do
- Tone and style (professional, concise)

Without a system prompt, Llama would answer anything. With one, it stays in character as an HR assistant.

Think of it as the job description you hand to a new employee on their first day.

### Concept 2: ChatClient and ChatClient.Builder

Spring AI auto-configures a `ChatClient.Builder` bean. You inject the builder, not the client directly, because the builder lets you set defaults:

```java
// ChatClient.Builder is auto-configured by Spring AI — just inject it
public HrChatController(ChatClient.Builder builder) {
    this.chatClient = builder
            .defaultSystem(SYSTEM_PROMPT)   // applied to every call
            .build();
}
```

`defaultSystem()` means every request to this `ChatClient` will automatically include the system prompt. You set it once, use it everywhere.

### Concept 3: The Fluent Prompt API

```java
chatClient
    .prompt()               // start building a prompt
    .user(question)         // set the user's message
    .call()                 // send to Llama, wait for response
    .content();             // extract the response text
```

This is Spring AI's fluent API. Each method call adds to the prompt or processes the response:

```
.prompt()   →  creates a PromptSpec
.user()     →  adds the user message
.call()     →  sends the HTTP request to Ollama
.content()  →  extracts the String from the response
```

---

## Run the Application

### Step 1 — Start Ollama

```bash
ollama serve
```

### Step 2 — Run the Spring Boot App

```bash
cd code/chapter-01-hello-spring-ai
mvn spring-boot:run
```

You will see:

```
  .   ____          _
 /\\ / ___'_ __ _ _(_)_ __
( ( )\___ | '_ | '_| | '_ \/ _` |
 \\/  ___)| |_)| | | | | || (_| |
  '  |____| .__|_| |_|_| |_\__, |
 =========|_|==============|___/
 :: Spring Boot ::               (v3.3.5)

SmartHR Assistant started on port 8080
```

### Step 3 — Ask Sarah's Monday Questions

**Question 1: Vacation policy**
```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many vacation days do new employees get?"}'
```

```json
{
  "question": "How many vacation days do new employees get?",
  "answer": "At TechCorp, new employees typically receive 15 days of paid vacation per year during their first year of employment. This may vary based on your employment contract and department. For exact details specific to your role, I recommend reviewing your offer letter or contacting the HR department directly."
}
```

**Question 2: Remote work**
```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the remote work policy?"}'
```

**Quick browser test (GET endpoint)**
```
http://localhost:8080/hr/ask?question=When+does+health+insurance+start+for+new+hires?
```

---

## What Just Happened?

Let's trace a single request through the entire system:

```
Sarah types: "How many vacation days do I get?"
     │
     ▼
POST /hr/ask
{"question": "How many vacation days do I get?"}
     │
     ▼
HrChatController.ask()
     │
     ├── System prompt: "You are an HR assistant for TechCorp..."
     ├── User message:  "How many vacation days do I get?"
     │
     ▼
ChatClient → Spring AI → Ollama HTTP API
     │
     ▼
Llama 3.2 model (running locally)
     │
     ▼
"At TechCorp, new employees typically receive 15 days..."
     │
     ▼
HrResponse { question: "...", answer: "..." }
     │
     ▼
Sarah reads the answer. No Slack message needed.
```

---

## Switching Models

The system prompt is in your code. The model is in your config. Swap models without touching Java:

```properties
# Try different models — no code changes needed
spring.ai.ollama.chat.options.model=llama3.2      # fast, good for Q&A
spring.ai.ollama.chat.options.model=llama3.1:8b   # better quality
spring.ai.ollama.chat.options.model=mistral        # great alternative
spring.ai.ollama.chat.options.model=phi3:mini      # lightweight, 4GB RAM
```

Pull the model first: `ollama pull mistral`, then restart the app.

---

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port=8081` |
| Response is very slow | Model too large for RAM | Switch to `phi3:mini` |

---

## Summary

In this chapter you:

- Installed Ollama and downloaded the Llama 3.2 model
- Created a Spring Boot project with the Spring AI Ollama starter
- Learned three core Spring AI concepts: system prompts, `ChatClient`, and the fluent prompt API
- Built TechCorp's first HR endpoint: `POST /hr/ask`
- Traced a request from HTTP call all the way through Llama and back

Sarah can now point employees to the HR chatbot. Her Monday mornings just got better.

---

## What's Next

In **Chapter 2**, we go under the hood — learning how tokens control response length, how Spring AI's message architecture works, and how to tune the model's behaviour per request with `OllamaOptions`.

```java
// Chapter 2 preview — per-request options
OllamaOptions preciseOptions = OllamaOptions.builder()
        .temperature(0.0)
        .numPredict(150)
        .build();

chatClient.prompt().user(question).options(preciseOptions).call().content();
```

*Code for this chapter: [`code/chapter-01-hello-spring-ai/`](code/chapter-01-hello-spring-ai/)*

---

---

# Chapter 2 — Core Concepts: Tokens, Messages, and the AI Abstraction

> **What you will build:** Two new HR endpoints — `/hr/ask/precise` for short, consistent policy answers and `/hr/ask/creative` for open-ended brainstorming. Plus a `/hr/model/info` endpoint that exposes the active model configuration.

---

## The Problem We Are Solving

Dev demos the SmartHR bot to Sarah after its first week live. She has two questions:

> "It answered the same question twice and gave me completely different lengths. One was two sentences, the next was six paragraphs. Can we control that?"

> "I asked it the leave policy and it gave me a very confident wrong answer. And when I asked again, the answer was different. Is that a bug?"

These are not bugs. They are features — and misfeatures — of how language models work. Understanding them is what separates developers who fight the AI from those who bend it to their will.

This chapter explains what is actually happening inside the model when you call `.call().content()`, and gives you the tools to control it.

---

## What Is a Token?

A **token** is the basic unit of text that a language model reads and writes. It is not a word. It is not a character. It is something in between — a chunk of commonly occurring text.

| Text | Approximate Tokens |
|------|-------------------|
| `"Hello"` | 1 |
| `"Hello, how are you?"` | 5 |
| `"maternity leave"` | 3 |
| `"How many vacation days do new employees get?"` | 9 |
| A typical HR policy paragraph (~75 words) | ~100 |

A rough rule of thumb: **1 token ≈ 0.75 words** in English.

### Why Do Tokens Matter?

Tokens drive three things:

```
Input tokens   → how much of your question the model reads
Output tokens  → how long the response is
Context window → total tokens (input + output) the model can hold in memory
```

For Llama 3.2 (3B), the context window is around **128,000 tokens** — plenty for HR Q&A. But output token limits are what control response length. If you do not set a limit, the model decides how long to write. That is why Sarah got six paragraphs sometimes.

### The Token Lifecycle of One Request

```
You send:
  System:  "You are an HR assistant for TechCorp..."    (~40 tokens)
  User:    "How many vacation days do I get?"           (~9 tokens)

Total input: ~49 tokens

Llama generates response tokens one at a time:
  "At" → "TechCorp" → "," → "new" → "employees" → ...

Until it decides to stop (or hits your numPredict limit).
```

The model generates **one token at a time** — which is why streaming responses appear word-by-word (more on this in Chapter 10).

---

## Controlling Response Length with `numPredict`

`numPredict` is the Ollama parameter that caps how many tokens the model is allowed to generate:

```java
OllamaOptions preciseOptions = OllamaOptions.builder()
        .temperature(0.0)
        .numPredict(150)   // stop after 150 output tokens (~100 words)
        .build();
```

This does not make the model dumber — it just forces it to be concise. Think of it as telling an employee "answer in two sentences max".

---

## Temperature Revisited — Why Sarah Got Different Answers

In Chapter 1 we set `temperature=0.3` without explaining why. Now we go deeper.

At each step, the model calculates a probability distribution over all possible next tokens. Temperature scales this distribution:

```
temperature = 0.0 (cold)
  "The" → 95% probability
  "At"  → 4%
  "For" → 1%
  → Always picks "The". Deterministic.

temperature = 0.7 (warm)
  "The" → 60%
  "At"  → 25%
  "For" → 15%
  → Picks randomly from the distribution. Different output each time.

temperature = 1.5 (hot)
  All tokens become almost equally likely → incoherent output.
```

This is why the same question gives different answers — the model is rolling a weighted die on every token.

### Choosing Temperature for HR Use Cases

| Use Case | Recommended Temperature |
|----------|------------------------|
| Policy lookup ("How many leave days?") | `0.0` – `0.1` |
| Standard Q&A | `0.3` |
| Writing job descriptions | `0.7` |
| Brainstorming team-building ideas | `0.8` – `0.9` |
| Creative HR campaigns | `0.9` |

---

## The Message Architecture

When you call `chatClient.prompt().user(question).call()`, Spring AI builds a **Prompt** made of **Messages** behind the scenes. There are three message types:

```
┌─────────────────────────────────────────────┐
│                  Prompt                      │
│                                             │
│  SystemMessage   "You are an HR assistant…" │
│  UserMessage     "How many vacation days…"  │
│  AssistantMessage "At TechCorp, you get…"   │  ← used in multi-turn (Ch. 6)
└─────────────────────────────────────────────┘
```

| Message Type | Who writes it | Purpose |
|---|---|---|
| `SystemMessage` | Developer | Instructions, persona, constraints |
| `UserMessage` | End user | The actual question |
| `AssistantMessage` | The model | Previous AI response (for conversation history) |

`ChatClient.defaultSystem()` is shorthand for adding a `SystemMessage` to every prompt. Under the hood, it creates exactly this structure.

### Using the Low-Level API Directly

`ChatClient` is the high-level, fluent wrapper. `ChatModel` is the lower-level interface it wraps. Sometimes you need direct access to messages:

```java
// Low-level: build messages yourself
List<Message> messages = List.of(
        new SystemMessage(SYSTEM_PROMPT),
        new UserMessage(request.question())
);

ChatResponse response = chatModel.call(new Prompt(messages));
String answer = response.getResult().getOutput().getText();
```

This is what Spring AI calls internally when you use `ChatClient`. Knowing it exists matters when you need fine-grained control over conversation history (Chapter 6).

### The Spring AI Abstraction Layers

```
Your Code
   │
   ├── ChatClient          ← high-level: fluent API, advisors, defaults
   │       │
   │       └── ChatModel   ← low-level: send Prompt, get ChatResponse
   │               │
   │               └── OllamaChatModel  ← Ollama-specific implementation
   │                       │
   │                       └── Ollama HTTP API → Llama 3.2
```

You write against `ChatClient` or `ChatModel`. Spring AI provides the `OllamaChatModel` implementation. If you later switch to OpenAI, only the implementation changes — your code stays identical.

---

## Project Structure (Chapter 2 additions)

```
code/chapter-02-core-concepts/
├── pom.xml
└── src/main/java/com/techcorp/smarthr/
    ├── SmartHrAssistantApplication.java
    ├── controller/
    │   ├── HrChatController.java       ← adds /ask/precise, /ask/creative, /ask/raw
    │   └── ModelInfoController.java    ← NEW: /hr/model/info
    └── model/
        ├── HrRequest.java
        └── HrResponse.java             ← updated: adds "mode" field
```

---

## The Code

### 1. Updated `HrResponse` — adds a `mode` field

```java
public record HrResponse(String question, String answer, String mode) {}
```

The `mode` field tells callers which endpoint profile was used (`standard`, `precise`, `creative`, `raw`).

### 2. `HrChatController` — three new endpoints

```java
// PRECISE: policy questions — short, deterministic, capped at ~150 tokens
@PostMapping("/ask/precise")
public HrResponse askPrecise(@RequestBody HrRequest request) {
    OllamaOptions preciseOptions = OllamaOptions.builder()
            .temperature(0.0)
            .numPredict(150)
            .build();

    String answer = chatClient
            .prompt()
            .user(request.question())
            .options(preciseOptions)
            .call()
            .content();
    return new HrResponse(request.question(), answer, "precise");
}

// CREATIVE: brainstorming — warm temperature, generous token budget
@PostMapping("/ask/creative")
public HrResponse askCreative(@RequestBody HrRequest request) {
    OllamaOptions creativeOptions = OllamaOptions.builder()
            .temperature(0.9)
            .numPredict(800)
            .build();

    String answer = chatClient
            .prompt()
            .user(request.question())
            .options(creativeOptions)
            .call()
            .content();
    return new HrResponse(request.question(), answer, "creative");
}

// RAW: bypass ChatClient, use ChatModel directly — exposes Message architecture
@PostMapping("/ask/raw")
public HrResponse askRaw(@RequestBody HrRequest request) {
    var messages = List.of(
            new SystemMessage(SYSTEM_PROMPT),
            new UserMessage(request.question())
    );
    var response = chatModel.call(new Prompt(messages));
    String answer = response.getResult().getOutput().getText();
    return new HrResponse(request.question(), answer, "raw");
}
```

Note that `chatModel` is injected alongside `chatClient.builder`. Spring AI autoconfigures both:

```java
public HrChatController(ChatClient.Builder builder, ChatModel chatModel) {
    this.chatClient = builder.defaultSystem(SYSTEM_PROMPT).build();
    this.chatModel = chatModel;
}
```

### 3. `ModelInfoController` — inspect active model config

```java
@RestController
@RequestMapping("/hr/model")
public class ModelInfoController {

    @Value("${spring.ai.ollama.chat.options.model}")
    private String modelName;

    @Value("${spring.ai.ollama.base-url}")
    private String ollamaBaseUrl;

    @Value("${spring.ai.ollama.chat.options.temperature:0.3}")
    private double defaultTemperature;

    @Value("${spring.ai.ollama.chat.options.num-predict:500}")
    private int defaultMaxTokens;

    @GetMapping("/info")
    public ModelInfo info() {
        return new ModelInfo(modelName, ollamaBaseUrl, defaultTemperature, defaultMaxTokens,
                "Switch model in application.properties — no code changes needed.");
    }

    public record ModelInfo(String model, String ollamaUrl,
                            double defaultTemperature, int defaultMaxTokens, String hint) {}
}
```

### 4. `application.properties` — expose new defaults

```properties
spring.application.name=SmartHR Assistant
server.port=8080

spring.ai.ollama.base-url=http://localhost:11434
spring.ai.ollama.chat.options.model=llama3.2
spring.ai.ollama.chat.options.temperature=0.3
spring.ai.ollama.chat.options.num-predict=500
```

`num-predict` is the default max tokens for the standard `/ask` endpoint. The precise and creative endpoints override this per-request.

---

## Run the Application

```bash
cd code/chapter-02-core-concepts
mvn spring-boot:run
```

---

## Test All Four Endpoints

### Check what model is running

```bash
curl -s http://localhost:8080/hr/model/info
```

```json
{
  "model": "llama3.2",
  "ollamaUrl": "http://localhost:11434",
  "defaultTemperature": 0.3,
  "defaultMaxTokens": 500,
  "hint": "Switch model in application.properties — no code changes needed."
}
```

### Standard (Chapter 1 behaviour)

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the maternity leave policy?"}'
```

### Precise — short, deterministic

```bash
curl -s -X POST http://localhost:8080/hr/ask/precise \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the maternity leave policy?"}'
```

```json
{
  "question": "What is the maternity leave policy?",
  "answer": "Maternity leave at TechCorp provides 16 weeks of paid leave for primary caregivers. Contact HR for details.",
  "mode": "precise"
}
```

Notice how the answer is capped — two sentences instead of a paragraph.

### Creative — brainstorming

```bash
curl -s -X POST http://localhost:8080/hr/ask/creative \
  -H "Content-Type: application/json" \
  -d '{"question": "Give me 5 ideas for a fun team-building activity for a remote engineering team."}'
```

### Raw — using ChatModel directly

```bash
curl -s -X POST http://localhost:8080/hr/ask/raw \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I submit a leave request?"}'
```

`/ask/raw` produces the same result as `/ask` — it just demonstrates that `ChatModel` is the engine underneath `ChatClient`.

---

## What Is an Embedding? (Preview for Chapter 7)

You have heard the word "embedding" mentioned in the context of AI. Here is the one-paragraph explanation you need now, before it becomes central in Chapter 7.

An **embedding** is a list of numbers (a vector) that represents a piece of text's *meaning*. Similar meanings produce similar vectors.

```
"maternity leave"      → [0.82, 0.14, -0.33, 0.91, ...]  (384 numbers)
"parental leave"       → [0.80, 0.16, -0.31, 0.89, ...]  ← very close!
"office parking spot"  → [0.12, 0.67,  0.44, 0.02, ...]  ← very different
```

This is how RAG (Chapter 7) finds relevant documents — not by keyword matching, but by measuring the distance between meaning vectors.

You do not need to understand the math. You need to understand the idea: **embeddings turn text into numbers so we can do maths on meaning.**

---

## Concepts Summary

| Concept | What It Means | How to Control It |
|---------|--------------|-------------------|
| Token | The basic unit of text a model reads/writes | Count with ~0.75 tokens per word |
| Temperature | How random the output is | `OllamaOptions.builder().temperature(x)` |
| numPredict | Max tokens in the response | `OllamaOptions.builder().numPredict(x)` |
| SystemMessage | Developer instructions sent before every user turn | `chatClient.defaultSystem(...)` |
| UserMessage | The user's actual question | `chatClient.prompt().user(...)` |
| ChatModel | Low-level Spring AI interface | Inject `ChatModel` directly |
| ChatClient | High-level fluent wrapper around ChatModel | Inject `ChatClient.Builder` |

---

## Summary

In this chapter you:

- Learned what tokens are and why they control speed and response length
- Understood temperature and why the same question gives different answers
- Explored Spring AI's message architecture: `SystemMessage`, `UserMessage`, `AssistantMessage`
- Saw the abstraction layers: `ChatClient` → `ChatModel` → `OllamaChatModel`
- Built three new HR endpoints with distinct behaviour profiles using `OllamaOptions`
- Added a `/hr/model/info` endpoint to inspect the active model configuration

Sarah now has consistent, short answers for policy lookups and richer answers for creative tasks. The same system prompt, different options — the model adapts.

---

## What's Next

In **Chapter 3**, we go deeper into the Ollama connection — learning how to switch between models (`llama3.2`, `mistral`, `codellama`) at runtime and how to benchmark them against each other on real HR questions.

```java
// Chapter 3 preview — dynamic model switching
OllamaOptions modelOptions = OllamaOptions.builder()
        .model("mistral")          // override the default model per-request
        .temperature(0.3)
        .build();
```

*Code for this chapter: [`code/chapter-02-core-concepts/`](code/chapter-02-core-concepts/)*

---

