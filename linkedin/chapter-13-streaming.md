# Chapter 13 — Your AI Answers in 8 Seconds. Make It Feel Like 200ms.

The SmartHR Assistant gives good answers. It just makes you wait for them.

An employee asks about parental leave, and the UI shows a spinner for eight, nine, ten seconds — then the whole answer drops in at once. It works. It also feels broken. Sarah put it plainly:

> "It feels like it froze every time. People think it's not working and ask again."

Here's the frustrating part Dev pointed out: the model was producing that answer **the entire time** — one token at a time, "At" → "TechCorp" → "," → "new" → "employees" — and we were hiding every one of them until the last token landed.

Chapter 13 stops hiding them.

---

## The One-Line Change

Every endpoint in the series so far has been *blocking*:

```java
String answer = chatClient.prompt().user(question).call().content();
```

`.call().content()` waits for the full answer, then returns a `String`. Switch two words:

```java
Flux<String> stream = chatClient.prompt().user(question).stream().content();
```

`.stream().content()` returns a **`Flux<String>`** — a stream of tokens arriving over time. Each one is emitted the instant Llama generates it.

The critical thing to understand: **this does not make generation faster.** The model takes exactly as long as before. What changes is *perceived* speed — the user starts reading in ~200ms instead of watching a spinner for ten seconds. In UX terms, that's the entire difference between "frozen" and "alive."

---

## Getting Tokens to the Browser: SSE

A `Flux` on the server is only half the story — you need a transport that can push tokens to the browser as they arrive. That's **Server-Sent Events (SSE)**: one long-lived HTTP connection down which the server writes events whenever it has something to say.

In Spring, the whole endpoint is this:

```java
@GetMapping(value = "/ask/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<String> streamAnswer(@RequestParam String question) {
    return chatClient.prompt().user(question).stream().content();
}
```

`TEXT_EVENT_STREAM_VALUE` is the switch — Spring turns each emitted token into one `data:` event. The browser consumes it with the built-in `EventSource`, no library required:

```javascript
const source = new EventSource('/hr/ask/stream?question=' + encodeURIComponent(q));
source.onmessage = (e) => { answer.textContent += e.data; };
```

That's the ChatGPT-style typing effect, in about six lines of JavaScript.

*(If you read Chapter 11 on MCP, SSE will look familiar — same transport, completely different job. There it carried tool-call results between server and client; here it carries generated tokens to a browser.)*

---

## Two Things That Bite You

**1. Errors mid-stream.** You can't just throw — the user may already have half an answer on screen. The stream is already flowing. Spring's reactive operators handle it cleanly:

```java
.stream().content()
.onErrorResume(e -> Flux.just("[stream error: " + e.getMessage() + "]"));
```

If Ollama drops, the client gets one clean final event instead of a severed connection.

**2. Don't stream everything.** Streaming is for humans reading text. If your next step is to *parse* the answer — structured JSON via `BeanOutputConverter`, a backend-to-backend call, batch processing — stay blocking. You can't convert JSON you haven't finished receiving. Streaming is a UX tool, not a default.

---

## The Takeaway

One method call, one content-type, six lines of browser JS — and a bot that felt broken now feels instant. No new infrastructure, no faster hardware, no bigger model. Just showing the work as it happens instead of hiding it until the end.

Sometimes the highest-leverage change isn't making the system faster. It's making it *honest* about the progress it's already making.

---

## What's Next — Chapter 14: Document Intelligence

The bot can talk, remember, retrieve, act, see, and now stream. Next it learns to read arbitrary documents — Sarah uploads a PDF, a Word doc, a web page, and the assistant ingests and analyses it.

---

## The Series So Far

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- [Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.](https://www.linkedin.com/pulse/chapter-6-your-ai-bot-has-goldfish-memory-heres-how-fix-chopparapu-ck0hc/?trackingId=m0DOW59LgPkGihFvJDxZBA%3D%3D)
- [Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.](https://www.linkedin.com/pulse/chapter-7-your-ai-guessing-rag-makes-read-manual-balaji-chopparapu-ararc/?trackingId=4L5yf1FX4CspOTawv4ddmw%3D%3D)
- [Chapter 8 — Your Vector Store Shouldn't Forget Everything When You Restart](https://www.linkedin.com/pulse/chapter-8-your-vector-store-shouldnt-forget-when-you-chopparapu-fbd2c/?trackingId=sJN7GdS8osG3cLtvf7i3Bg%3D%3D)
- [Chapter 9 — Neo4j Graph RAG: When Vector Search Isn't Enough](https://www.linkedin.com/pulse/chapter-9-neo4j-graph-rag-when-vector-search-isnt-balaji-chopparapu-xiutc/?trackingId=ubMaVVYy7Z70TynlVV8IeA%3D%3D)
- [Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.](https://www.linkedin.com/pulse/chapter-10-your-ai-bot-can-talk-now-let-take-action-balaji-chopparapu-f6rgc/?trackingId=Pe9bd8VwA8dBxQHP1T609w%3D%3D)
- [Chapter 11 — Exposing an Existing REST API as MCP Tools](https://www.linkedin.com/pulse/chapter-11-exposing-existing-rest-api-mcp-tools-balaji-chopparapu-ptegc/?trackingId=XPZnicIu%2BcI9hiU3DrfK1A%3D%3D)
- [Chapter 12 — Your AI Bot Just Learned to See](https://www.linkedin.com/pulse/chapter-12-your-ai-bot-just-learned-see-balaji-chopparapu-ooulc/)
- **Chapter 13 — Your AI Answers in 8 Seconds. Make It Feel Like 200ms.** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #Streaming #SSE #ServerSentEvents #ReactiveProgramming #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #Llama
