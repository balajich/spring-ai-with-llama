# Chapter 2 — Core Concepts

Tokens, messages, and per-request model options for the SmartHR Assistant.

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

### 1. Install Ollama

Download from https://ollama.ai and install it.

### 2. Pull the Llama model

```bash
ollama pull llama3.2
```

### 3. Start Ollama

Ollama may already be running as a background service. Verify with:

```bash
curl -s http://localhost:11434/api/tags
```

If you get a JSON response, Ollama is up. If not, start it:

```bash
ollama serve
```

---

## Run the Application

```bash
cd code/chapter-02-core-concepts
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/ask` | Standard Q&A (temp 0.3, max 500 tokens) |
| `POST` | `/hr/ask/precise` | Short, deterministic answers (temp 0.0, max 150 tokens) |
| `POST` | `/hr/ask/creative` | Longer, varied answers (temp 0.9, max 800 tokens) |
| `GET` | `/hr/model/info` | Active model name, URL, temperature, max tokens |

---

## Example curl Commands

### Standard — balanced Q&A

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many vacation days do new employees get?"}'
```

**Response:**
```json
{
  "question": "How many vacation days do new employees get?",
  "answer": "At TechCorp, new employees typically receive 15 days of paid vacation per year...",
  "mode": "standard"
}
```

---

### Precise — short, consistent policy answers

```bash
curl -s -X POST http://localhost:8080/hr/ask/precise \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the remote work policy?"}'
```

**Response:**
```json
{
  "question": "What is the remote work policy?",
  "answer": "TechCorp supports hybrid remote work. Employees may work remotely up to 3 days per week with manager approval.",
  "mode": "precise"
}
```

---

### Creative — brainstorming and open-ended writing

```bash
curl -s -X POST http://localhost:8080/hr/ask/creative \
  -H "Content-Type: application/json" \
  -d '{"question": "Write a welcome message for new TechCorp employees."}'
```

**Response:**
```json
{
  "question": "Write a welcome message for new TechCorp employees.",
  "answer": "Welcome to TechCorp! We are thrilled to have you join our team...",
  "mode": "creative"
}
```

---


### Model info — inspect active configuration

```bash
curl -s http://localhost:8080/hr/model/info
```

**Response:**
```json
{
  "model": "llama3.2",
  "ollamaUrl": "http://localhost:11434",
  "defaultTemperature": 0.3,
  "defaultMaxTokens": 500,
  "hint": "llama3.2 is active. Switch model in application.yml."
}
```

---

## Switch Models

Change the model in `src/main/resources/application.yml` — no code changes needed:

```yaml
spring:
  ai:
    ollama:
      chat:
        options:
          model: mistral        # or llama3.2, phi3:mini, gemma2
          temperature: 0.3
          num-predict: 500
```

Pull the model first, then restart the app:

```bash
ollama pull mistral
mvn spring-boot:run
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |
| Response is very slow | Model too large for RAM | Switch to `phi3:mini` |

---

## What's New in Chapter 2

| Endpoint | Temperature | Max Tokens | Use case |
|----------|-------------|------------|----------|
| `/ask` | 0.3 | 500 | General HR Q&A |
| `/ask/precise` | 0.0 | 150 | Policy facts — short and consistent |
| `/ask/creative` | 0.9 | 800 | Writing, brainstorming, job descriptions |

---

## Project Structure

```
chapter-02-core-concepts/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   ├── HrChatController.java       ← 4 ask endpoints
    │   │   └── ModelInfoController.java    ← model info endpoint
    │   └── model/
    │       ├── HrRequest.java
    │       └── HrResponse.java             ← now includes a "mode" field
    └── resources/
        └── application.yml
```

---

*Full chapter write-up: [`content/chapters/chapter-02-core-concepts.md`](../../content/chapters/chapter-02-core-concepts.md)*
