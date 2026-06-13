# Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.

Raj is a new engineer at TechCorp. On his first day he opens the SmartHR chatbot and asks:

> "What tools do I need to set up?"

The bot answers. Then he asks:

> "And what about the security training?"

The bot responds as if it has never spoken to him before. No context. No memory. A completely fresh start.

Raj tells Sarah: **"This bot has goldfish memory."**

Every AI call is stateless by default. Llama does not remember your previous message. Spring AI sends exactly what you put in the prompt — nothing more. If you want the bot to remember, you have to send the full conversation history on every request.

That sounds painful. It is not, because Spring AI handles it for you.

---

## The Fix — MessageChatMemoryAdvisor

Instead of manually building conversation history, you attach an advisor that does it automatically:

```java
ChatMemory chatMemory = MessageWindowChatMemory.builder()
        .chatMemoryRepository(new InMemoryChatMemoryRepository())
        .maxMessages(20)
        .build();

ChatClient chatClient = ChatClient.builder(chatModel)
        .defaultSystem(SYSTEM_PROMPT)
        .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
        .build();
```

On every call, `MessageChatMemoryAdvisor` intercepts the request and:
1. Loads all previous messages for this session ID from memory
2. Appends them to the prompt before sending to Llama
3. Saves the new user + assistant messages back to memory

Your controller does not change at all. The advisor does the heavy lifting invisibly.

---

## What the Prompt Looks Like Under the Hood

Turn 1 — you send:
```
System:  "You are an HR onboarding assistant..."
User:    "What laptop should I request?"
```

Turn 2 — the advisor builds this automatically:
```
System:    "You are an HR onboarding assistant..."
User:      "What laptop should I request?"        ← from memory
Assistant: "You can request a MacBook Pro..."     ← from memory
User:      "And what software comes pre-installed?" ← new message
```

Llama sees the full conversation history. It can answer follow-up questions naturally.

---

## The Endpoint

```java
@PostMapping("/onboard/chat")
public HrResponse chat(@RequestBody OnboardRequest request) {
    String answer = chatClient
            .prompt()
            .user(request.message())
            .advisors(a -> a.param(ChatMemory.CONVERSATION_ID, request.sessionId()))
            .call()
            .content();
    return new HrResponse(request.message(), answer, "onboard");
}

@DeleteMapping("/onboard/chat/{sessionId}")
public ResponseEntity<Void> clearSession(@PathVariable String sessionId) {
    chatMemory.clear(sessionId);
    return ResponseEntity.noContent().build();
}
```

The `sessionId` in the request body is the key that separates one user's conversation from another. Raj's questions do not bleed into Lisa's session.

---

## Try It — Multi-Turn Conversation

```bash
# Turn 1
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "raj-001", "message": "What laptop should I request on my first day?"}'

# Turn 2 — bot remembers the laptop context
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "raj-001", "message": "And what software comes pre-installed?"}'

# Turn 3 — still in context
curl -s -X POST http://localhost:8080/hr/onboard/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "raj-001", "message": "How long does setup usually take?"}'

# Clear the session when done
curl -s -X DELETE http://localhost:8080/hr/onboard/chat/raj-001
```

Three turns, one session, full context maintained. The bot remembers everything Raj said.

---

## Important: Memory Lives in the JVM

`InMemoryChatMemoryRepository` stores history in a `ConcurrentHashMap` on the heap. That means:

- **Restart the app → all history is gone**
- **Multiple instances → sessions are not shared**
- **Long-running conversations → heap grows**

`MessageWindowChatMemory` with `maxMessages(20)` caps the history to the last 20 messages, keeping token counts and memory usage under control.

For production you would back this with Redis or a database. Chapter 6 uses in-memory to keep the focus on the concept.

---

## What's Next — Chapter 7: RAG

Memory makes the bot stateful. But it still only knows what Llama was trained on.

In Chapter 7, we give the SmartHR Assistant knowledge of TechCorp's actual HR policies. Sarah uploads the policy documents. Employees ask questions. The bot answers from the real documents — not from generic AI training data.

That is **Retrieval Augmented Generation (RAG)**, and it is the most powerful chapter yet.

---

## The Series So Far

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- **Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 21, and Ollama — runs entirely on your laptop, no paid APIs.*
