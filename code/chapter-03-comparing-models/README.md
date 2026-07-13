# Chapter 3 — Running and Comparing Multiple Models with Ollama

Send the same HR question to two different models side-by-side and compare their answers.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |

---

## Setup

### 1. Install Ollama

Download from https://ollama.ai and install it.

### 2. Pull the models you want to compare

```bash
ollama pull llama3.2
ollama pull mistral
```

Other options:

```bash
ollama pull phi3:mini    # lightweight — runs on 4 GB RAM
ollama pull gemma2       # Google's open model
ollama pull codellama    # optimised for technical questions
```

List what you have installed:

```bash
ollama list
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
cd code/chapter-03-comparing-models
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/ask/compare` | Send the same question to two models and get both answers |

---

## Example curl Commands

### Compare llama3.2 vs mistral

```bash
curl -s -X POST http://localhost:8080/hr/ask/compare \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is a good onboarding plan for a new software engineer?",
    "modelA": "llama3.2",
    "modelB": "mistral"
  }'
```

**Response:**
```json
{
  "question": "What is a good onboarding plan for a new software engineer?",
  "modelA": "llama3.2",
  "answerA": "A good onboarding plan for a new software engineer at TechCorp includes...",
  "modelB": "mistral",
  "answerB": "For a new software engineer joining TechCorp, I recommend a structured..."
}
```

---

### Compare llama3.2 vs phi3:mini (lightweight)

```bash
curl -s -X POST http://localhost:8080/hr/ask/compare \
  -H "Content-Type: application/json" \
  -d '{
    "question": "How many days of annual leave do employees get?",
    "modelA": "llama3.2",
    "modelB": "phi3:mini"
  }'
```

---

### Compare for a technical HR question

```bash
curl -s -X POST http://localhost:8080/hr/ask/compare \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the remote work policy for engineers?",
    "modelA": "llama3.2",
    "modelB": "mistral"
  }'
```

---

## Switch the Default Model

The default model used when the app falls back to config is set in `application.yml`. Change it to try a different baseline:

```yaml
spring:
  ai:
    ollama:
      chat:
        options:
          model: mistral        # or llama3.2, phi3:mini, gemma2
```

Pull the model first, then restart:

```bash
ollama pull mistral
mvn spring-boot:run
```

---

## Model Cheat Sheet

| Model | RAM Required | Best for | Speed |
|-------|-------------|----------|-------|
| `llama3.2` (3B) | 4 GB | General Q&A | Fast |
| `llama3.2:8b` | 8 GB | Better reasoning | Medium |
| `mistral` | 5 GB | Instruction following | Fast |
| `codellama` | 4 GB | Code, technical docs | Fast |
| `phi3:mini` | 2 GB | Lightweight, constrained env | Very fast |
| `gemma2` | 5 GB | Multi-language | Medium |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull <model>` |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |
| Response is very slow | Model too large for RAM | Switch to `phi3:mini` |

---

## Project Structure

```
chapter-03-comparing-models/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── HrChatController.java       ← /hr/ask/compare endpoint
    │   └── model/
    │       ├── CompareRequest.java
    │       └── CompareResponse.java
    └── resources/
        └── application.yml
```

---

*Full chapter write-up: [`chapters/chapter-03-comparing-models.md`](../../chapters/chapter-03-comparing-models.md)*
