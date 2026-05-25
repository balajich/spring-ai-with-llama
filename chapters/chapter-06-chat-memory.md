# Chapter 6 — Chat Memory: Multi-Turn Conversations

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** An onboarding chatbot for Raj — a stateful `/hr/onboard/chat` endpoint that remembers the full conversation so Raj can ask follow-up questions without repeating himself.

---

## The Problem We Are Solving

Raj uses the SmartHR bot on his first day and asks:

> "What tools do I need to set up?"

The bot answers. Then he asks:

> "And what about the security training?"

The bot responds as if it is a brand new conversation — no context, no memory of what was just discussed. Raj has to repeat himself every message. He tells Sarah: "This bot has goldfish memory."

The fix is `ChatMemory`.

---

## What You Will Learn

- Why stateless AI calls lose context between messages
- How `InMemoryChatMemory` works in Spring AI
- How to maintain conversation history per session
- How to build a stateful multi-turn chat endpoint
- Memory limits and when to clear history

---

## Why AI Calls Are Stateless by Default

Each call to Llama is independent. Llama does not remember your previous message. Spring AI sends exactly what you put in the `Prompt` — nothing more.

To simulate memory, you append the conversation history to every new request:

```
Turn 1 — You send:
  System: "You are an HR assistant..."
  User:   "What tools do I need?"

Turn 2 — You send:
  System:    "You are an HR assistant..."
  User:      "What tools do I need?"       ← repeated from Turn 1
  Assistant: "You will need Slack, Jira..."  ← Turn 1 response
  User:      "And what about security training?"  ← new question
```

`InMemoryChatMemory` manages this history for you automatically.

---

## How InMemoryChatMemory Works

```java
ChatMemory memory = new InMemoryChatMemory();

ChatClient chatClient = ChatClient.builder(chatModel)
        .defaultSystem(SYSTEM_PROMPT)
        .defaultAdvisors(new MessageChatMemoryAdvisor(memory))
        .build();
```

The `MessageChatMemoryAdvisor` intercepts every call and:
1. Loads previous messages from memory for this conversation ID
2. Appends them to the prompt before sending to Llama
3. Saves the new user + assistant messages back to memory

---

## What You Will Build — Stateful Onboarding Chatbot

```java
// POST /hr/onboard/chat
public record OnboardRequest(String sessionId, String message) {}

@PostMapping("/onboard/chat")
public HrResponse chat(@RequestBody OnboardRequest request) {
    String answer = chatClient
            .prompt()
            .user(request.message())
            .advisors(a -> a.param(CHAT_MEMORY_CONVERSATION_ID_KEY, request.sessionId()))
            .call()
            .content();
    return new HrResponse(request.message(), answer, "onboard");
}

// DELETE /hr/onboard/chat/{sessionId} — clear memory for a session
@DeleteMapping("/onboard/chat/{sessionId}")
public void clearSession(@PathVariable String sessionId) {
    memory.clear(sessionId);
}
```

**Test a multi-turn conversation:**
```bash
# Turn 1
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -d '{"sessionId": "raj-001", "message": "What laptop should I request?"}'

# Turn 2 — bot remembers the laptop context
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -d '{"sessionId": "raj-001", "message": "And what software comes pre-installed?"}'

# Turn 3 — still in context
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -d '{"sessionId": "raj-001", "message": "How long does setup usually take?"}'
```

---

## Memory Limits

`InMemoryChatMemory` keeps history in the JVM heap. For production:

| Concern | Solution |
|---------|----------|
| Memory grows unbounded | Limit history with `MessageWindowChatMemory` |
| History lost on restart | Use a persistent store (Redis, database) |
| Multiple instances | Shared cache or database-backed memory |

Chapter 6 uses in-memory for simplicity. Chapter 17 covers production-ready persistence.

---

## Summary

In this chapter you will:

- Understand why AI calls are stateless and how to add memory
- Use `InMemoryChatMemory` and `MessageChatMemoryAdvisor`
- Build a stateful onboarding chatbot with session IDs
- Clear conversation history when a session ends

---

## What's Next

In **Chapter 7**, we build the most powerful feature yet — RAG (Retrieval Augmented Generation). Sarah uploads TechCorp's policy documents and employees can ask questions that are answered from the actual company policies, not from Llama's general training.

*Code for this chapter: [`code/chapter-06-chat-memory/`](../code/chapter-06-chat-memory/)*
