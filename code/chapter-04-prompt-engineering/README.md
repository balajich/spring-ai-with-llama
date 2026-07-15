# Chapter 4 — Prompt Engineering: PromptTemplate and Dynamic Prompts

Build a personalised HR assistant that addresses employees by name, department, and role — using Spring AI's `PromptTemplate` with classpath-loaded `.st` template files.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25.0.3 | `java -version` |
| Maven | 3.9.16 | `mvn -version` |
| Ollama | 0.31.1 | `ollama --version` |

> **Versions:** These tutorials should work on the most recent versions of these tools. They were built and tested on **Java 25.0.3**, **Maven 3.9.16**, and **Ollama 0.31.1**.

---

## Setup

### 1. Pull the model

```bash
ollama pull llama3.2
```

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
cd code/chapter-04-prompt-engineering
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/ask/personalised` | Personalised HR answer using `hr-assistant.st` template |
| `POST` | `/hr/ask/onboarding` | Onboarding-specific answer using `onboarding.st` template |

**Request shape (both endpoints):**
```json
{
  "name": "Raj",
  "department": "Engineering",
  "role": "Software Engineer",
  "question": "How do I get my development tools set up on my first day?"
}
```

**Response shape:**
```json
{
  "question": "...",
  "answer": "...",
  "mode": "personalised"
}
```

---

## Example curl Commands

### Personalised HR answer

```bash
curl -s -X POST http://localhost:8080/hr/ask/personalised \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Raj",
    "department": "Engineering",
    "role": "Software Engineer",
    "question": "How do I get my development tools set up on my first day?"
  }'
```

**Response:**
```json
{
  "question": "How do I get my development tools set up on my first day?",
  "answer": "Hi Raj! Welcome to TechCorp's Engineering team. On your first day, you'll want to...",
  "mode": "personalised"
}
```

---

### Onboarding answer

```bash
curl -s -X POST http://localhost:8080/hr/ask/onboarding \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Raj",
    "department": "Engineering",
    "role": "Software Engineer",
    "question": "What should I do on my first day at TechCorp?"
  }'
```

**Response:**
```json
{
  "question": "What should I do on my first day at TechCorp?",
  "answer": "Welcome to TechCorp, Raj! Here's a step-by-step guide for your first day as a Software Engineer...",
  "mode": "onboarding"
}
```

---

### Different employee and department

```bash
curl -s -X POST http://localhost:8080/hr/ask/personalised \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Lisa",
    "department": "Product",
    "role": "Product Manager",
    "question": "How do I apply for annual leave?"
  }'
```

---

## Prompt Templates

Templates live in `src/main/resources/prompts/` and are loaded via `@Value("classpath:prompts/...")`.

| File | Used by | Purpose |
|------|---------|---------|
| `hr-assistant.st` | `/hr/ask/personalised` | General personalised HR answers |
| `onboarding.st` | `/hr/ask/onboarding` | First-day and onboarding guidance |

**Variables injected into every template:**

| Variable | Example value |
|----------|---------------|
| `{name}` | `Raj` |
| `{department}` | `Engineering` |
| `{role}` | `Software Engineer` |
| `{question}` | `How do I request leave?` |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` |
| `Could not resolve placeholder` | Missing template variable | Check all four fields are in the request body |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-04-prompt-engineering/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── HrChatController.java       ← /ask/personalised + /ask/onboarding
    │   └── model/
    │       ├── PersonalisedRequest.java
    │       └── HrResponse.java
    └── resources/
        ├── application.yml
        └── prompts/
            ├── hr-assistant.st             ← general personalised HR template
            └── onboarding.st               ← onboarding-specific template
```

---

*Full chapter write-up: [`chapters/chapter-04-prompt-engineering.md`](../../chapters/chapter-04-prompt-engineering.md)*
