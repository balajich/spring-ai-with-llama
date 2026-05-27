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
- Use familiar Spring patterns (dependency injection, `application.yml`, autoconfiguration)
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
        └── application.yml                      ← Ollama config
```

---

## The Code

### 1. Maven Dependencies (`pom.xml`)

The only Spring AI dependency we need for Chapter 1 is the Ollama starter:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.0-RC1</version>
    <relativePath/>
</parent>

<properties>
    <java.version>21</java.version>
    <spring-ai.version>2.0.0-M6</spring-ai.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>

    <!-- This one line connects Spring AI to Ollama -->
    <dependency>
        <groupId>org.springframework.ai</groupId>
        <artifactId>spring-ai-starter-model-ollama</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.ai</groupId>
            <artifactId>spring-ai-bom</artifactId>
            <version>${spring-ai.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

The BOM (Bill of Materials) manages Spring AI version compatibility across all its modules. Note the artifact name changed in Spring AI 2.x — it is now `spring-ai-starter-model-ollama` instead of the older `spring-ai-ollama-spring-boot-starter`.

### 2. Configuration (`application.yml`)

```yaml
spring:
  application:
    name: SmartHR Assistant

  ai:
    ollama:
      base-url: http://localhost:11434
      chat:
        options:
          model: llama3.2 # or phi3:mini, gemma2, mistral
          temperature: 0.3

server:
  port: 8080
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
  "answer": "At TechCorp, new employees typically receive 15 days of paid vacation per year during their first year of employment."
}
```

**Quick browser test (GET endpoint)**
```
http://localhost:8080/hr/ask?question=When+does+health+insurance+start+for+new+hires?
```

---

## What Just Happened?

```
Sarah types: "How many vacation days do I get?"
     │
     ▼
POST /hr/ask  {"question": "..."}
     │
     ▼
HrChatController.ask()
     ├── System prompt: "You are an HR assistant for TechCorp..."
     └── User message:  "How many vacation days do I get?"
     │
     ▼
ChatClient → Spring AI → Ollama HTTP API → Llama 3.2
     │
     ▼
HrResponse { question: "...", answer: "..." }
     │
     ▼
Sarah reads the answer. No Slack message needed.
```

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

## Where This Chatbot Falls Short

The assistant works — but take a close look at that first response:

```json
{
  "answer": "At TechCorp, new employees typically receive 15 days of paid vacation per year during their first year of employment."
}
```

**That number is invented.** Llama has never seen TechCorp's employee handbook. It answered based on patterns from its public training data — millions of generic HR articles scraped from the internet. It sounded confident and professional, but it could be completely wrong for TechCorp.

This is the core problem with the Chapter 1 approach:

| Shortcoming | What happens | Real impact |
|---|---|---|
| **Responses from public data** | The model answers from general internet knowledge, not TechCorp's actual policies | Employees get plausible-sounding but potentially wrong information |
| **Hallucinated specifics** | Policy numbers, dates, and thresholds are guessed | "15 days" — TechCorp may actually give 20 |
| **No TechCorp context** | The model knows nothing about TechCorp's org chart, systems, or internal processes | Questions like "Who approves my leave?" get generic answers |
| **No memory between calls** | Each question is independent — the model forgets previous exchanges | Users cannot ask follow-up questions naturally |
| **No audit trail** | There is no record of what the model told employees | HR cannot verify or correct bad advice |

### A Concrete Example

Ask the chatbot something TechCorp-specific:

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is TechCorp'\''s parental leave policy?"}'
```

The model will answer confidently. It might say 12 weeks. It might say 16 weeks. Whatever it says, it is a guess — because the system prompt tells Llama it is an HR assistant for TechCorp, but it has never actually read TechCorp's parental leave policy document.

The system prompt shapes tone and persona. It does not give the model knowledge it does not have.

### The Fix Coming in Later Chapters

The solution is **Retrieval-Augmented Generation (RAG)**: instead of asking the model to remember policies, you retrieve the relevant policy text from a document store and inject it directly into the prompt at query time.

```
Employee question → Search TechCorp policy docs → Inject matching text → Ask Llama
```

That is Chapter 4. But before we get there, Chapter 2 covers how the model processes text (tokens) and how to control its response behaviour precisely — both of which you will need to build RAG well.

---

## What's Next

In **Chapter 2**, we go under the hood — learning how tokens control response length, how Spring AI's message architecture works, and how to tune the model per request with `ChatOptions`.

*Code for this chapter: [`code/chapter-01-hello-spring-ai/`](../code/chapter-01-hello-spring-ai/)*
