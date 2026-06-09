# Chapter 6 — Chat Memory: Multi-Turn Conversations

Give the SmartHR onboarding bot a memory — so Raj can ask follow-up questions without repeating himself every message.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 21+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |

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
cd code/chapter-06-chat-memory
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/onboard/chat` | Send a message in a stateful session |
| `DELETE` | `/hr/onboard/chat/{sessionId}` | Clear conversation history for a session |

**Request shape:**
```json
{
  "sessionId": "raj-001",
  "message": "What tools do I need to set up?"
}
```

**Response shape:**
```json
{
  "question": "What tools do I need to set up?",
  "answer": "...",
  "mode": "onboard"
}
```

---

## Example — Multi-Turn Conversation

Each request uses the same `sessionId`. The bot remembers the full conversation history within that session.

### Turn 1

```bash
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "raj-001", "message": "What laptop should I request on my first day?"}'
```

### Turn 2 — bot remembers the laptop context

```bash
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "raj-001", "message": "And what software comes pre-installed?"}'
```

### Turn 3 — still in context

```bash
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "raj-001", "message": "How long does the full setup usually take?"}'
```

### Different user — separate session, no shared memory

```bash
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Who do I contact about onboarding new hires?"}'
```

### Clear a session when done

```bash
curl -s -X DELETE http://localhost:8080/hr/onboard/chat/raj-001
```

---

## How Memory Works

```
Turn 1 — You send:
  System:  "You are an onboarding assistant..."
  User:    "What laptop should I request?"

Turn 2 — You send:
  System:    "You are an onboarding assistant..."
  User:      "What laptop should I request?"      ← Turn 1 (from memory)
  Assistant: "You can request a MacBook Pro..."   ← Turn 1 response (from memory)
  User:      "And what software comes pre-installed?" ← new message
```

`MessageWindowChatMemory` manages this history automatically. The `MessageChatMemoryAdvisor` intercepts every call, loads the previous messages for the session ID, appends them to the prompt, then saves the new exchange back to memory.

---

## Memory Limits

| Concern | This chapter | Production approach |
|---------|-------------|---------------------|
| History size | `maxMessages(20)` — keeps last 20 messages | Tune based on context window |
| Lost on restart | Yes — in-memory only | Use Redis or database-backed store |
| Multiple instances | Not shared | Shared cache or database |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` |
| Bot loses context | Different `sessionId` used | Use the same `sessionId` across turns |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-06-chat-memory/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── OnboardChatController.java   ← /hr/onboard/chat + DELETE
    │   └── model/
    │       ├── OnboardRequest.java
    │       └── HrResponse.java
    └── resources/
        └── application.yml
```

---

*Full chapter write-up: [`chapters/chapter-06-chat-memory.md`](../../chapters/chapter-06-chat-memory.md)*
