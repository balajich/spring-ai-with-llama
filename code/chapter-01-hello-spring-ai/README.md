# Chapter 1 — Hello, Spring AI!

First working HR Q&A endpoint for the SmartHR Assistant.

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
cd code/chapter-01-hello-spring-ai
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/ask` | Ask an HR question (JSON body) |

---

## Example curl Commands

### Ask a question (POST)

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How many vacation days do new employees get?"}'
```

**Response:**
```json
{
  "question": "How many vacation days do new employees get?",
  "answer": "At TechCorp, new employees typically receive 15 days of paid vacation per year..."
}
```

### More example questions

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the remote work policy?"}'
```

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "When does health insurance start for new hires?"}'
```

```bash
curl -s -X POST http://localhost:8080/hr/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I submit a leave request?"}'
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

## Project Structure

```
chapter-01-hello-spring-ai/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── HrChatController.java
    │   └── model/
    │       ├── HrRequest.java
    │       └── HrResponse.java
    └── resources/
        └── application.yml
```

---

*Full chapter write-up: [`content/chapters/chapter-01-hello-spring-ai.md`](../../content/chapters/chapter-01-hello-spring-ai.md)*
