# Chapter 13 — Streaming API: Real-Time Token-by-Token Responses

> **What you will build:** A live-streaming HR chat interface — instead of waiting 10 seconds for a full response, employees see the answer appearing word-by-word as Llama generates it, just like ChatGPT.

---

## The Problem We Are Solving

The SmartHR bot works well but feels slow. For long answers, the UI shows a spinner for 8-10 seconds, then the full text appears at once. Employees complain it feels unresponsive.

Dev tells Sarah:

> "The model is actually generating the answer token-by-token the whole time. We're just not showing it until it finishes. We can stream it instead."

The key insight: **streaming does not make generation faster — it makes it *feel* faster.** The total time is unchanged, but the user starts reading in ~200ms instead of staring at a spinner for ten seconds.

---

## What You Will Learn

- How token-by-token streaming works
- Spring AI's streaming API using `Flux<String>`
- Server-Sent Events (SSE) for pushing tokens to a browser
- How to stream metadata (finish reason) alongside tokens
- How to handle streaming errors gracefully

---

## Blocking vs Streaming

Every endpoint so far has been **blocking** — `.call().content()` waits for the entire answer before returning anything:

```java
// Blocking — waits for the full response (Chapters 1-12)
String answer = chatClient.prompt().user(question).call().content();
// User waits 8 seconds → sees the full text at once

// Streaming — emits each token as it is generated
Flux<String> stream = chatClient.prompt().user(question).stream().content();
// User sees text appear word-by-word immediately
```

The only change is `.call()` → `.stream()`. The return type changes from a plain `String` to a **`Flux<String>`** — Project Reactor's type for "a stream of values arriving over time." (Spring MVC returns reactive types natively; `reactor-core` arrives transitively with Spring AI, so no extra dependency is needed.)

---

## Building a Streaming Endpoint (SSE)

Server-Sent Events (SSE) is the standard way to push a stream from a Spring Boot controller to a browser. Set the response content type to `text/event-stream` and return the `Flux`:

```java
@GetMapping(value = "/ask/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<String> streamAnswer(@RequestParam String question) {
    return chatClient
            .prompt()
            .user(question)
            .stream()
            .content()
            .onErrorResume(e -> Flux.just("[stream error: " + e.getMessage() + "]"));
}
```

That is the entire endpoint. Spring's `Flux<String>` and `TEXT_EVENT_STREAM_VALUE` do the rest — each emitted token becomes one `data:` event on the wire.

> **Note on GET vs POST:** streaming endpoints are `GET` with a query parameter because the browser's `EventSource` API only issues GET requests.

---

## Consuming the Stream in a Browser

The browser's built-in `EventSource` connects once and receives each token as it arrives:

```javascript
const source = new EventSource(
    '/hr/ask/stream?question=' + encodeURIComponent('What is the leave policy?')
);

source.onmessage = (event) => {
    document.getElementById('answer').textContent += event.data;
};

// EventSource fires onerror on normal completion too — close to stop reconnects.
source.onerror = () => source.close();
```

A working demo page ships at [`src/main/resources/static/index.html`](../code/chapter-13-streaming-api/src/main/resources/static/index.html) — run the app and open [http://localhost:8080](http://localhost:8080) to watch answers type themselves out.

---

## Streaming with Metadata

Raw text is enough for a chat UI. When you also need the **finish reason** or token usage, stream the full `ChatResponse` instead of just its content, then map it to your own shape:

```java
@GetMapping(value = "/ask/stream/tokens", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<StreamChunk> streamTokens(@RequestParam String question) {
    return chatClient
            .prompt()
            .user(question)
            .stream()
            .chatResponse()                 // Flux<ChatResponse>, not Flux<String>
            .map(response -> {
                var result = response.getResult();
                String token = result != null && result.getOutput() != null
                        ? result.getOutput().getText() : "";
                String finishReason = result != null && result.getMetadata() != null
                        ? result.getMetadata().getFinishReason() : null;
                return new StreamChunk(token, finishReason);
            });
}
```

```java
public record StreamChunk(String token, String finishReason) {}
```

The `finishReason` is `null` on every chunk until the final one, where it becomes `"stop"` — a clean signal that the answer is complete.

---

## Error Handling in Streams

Because a stream is already flowing when an error occurs, you cannot just throw — the client may have received half an answer. `onErrorResume` lets you emit a final fallback value on the same stream instead of dropping the connection:

```java
.stream()
.content()
.onErrorResume(e -> Flux.just("[stream error: " + e.getMessage() + "]"));
```

If Ollama is down, the client sees one clean `data:[stream error: ...]` event rather than a broken connection.

---

## When to Use Streaming

| Use Streaming | Use Blocking |
|--------------|-------------|
| UI-facing chat interfaces | Backend-to-backend calls |
| Long answers (>3 seconds) | Short answers (<1 second) |
| When UX responsiveness matters | When you need the full text before processing |
| Real-time dashboards | Batch processing, structured-output parsing |

Note the last row: if you need to parse the whole answer (e.g. `BeanOutputConverter` from Chapter 5), stay blocking — you can't convert JSON you haven't finished receiving.

---

## Try It

```bash
cd code/chapter-13-streaming-api
mvn spring-boot:run
```

```bash
# Watch tokens arrive one at a time (-N disables curl buffering)
curl -N "http://localhost:8080/hr/ask/stream?question=What+is+the+parental+leave+policy%3F"

# Stream with metadata
curl -N "http://localhost:8080/hr/ask/stream/tokens?question=How+many+vacation+days+do+new+employees+get%3F"
```

Or open [http://localhost:8080](http://localhost:8080) in a browser for the live-typing chat page.

Run the Karate tests:

```bash
cd code/tests
./run-tests.sh chapter-13
```

---

## Summary

In this chapter you:

- Learned how token streaming works and why it improves *perceived* speed
- Used Spring AI's `stream().content()` to get a `Flux<String>`
- Built an SSE streaming endpoint for real-time browser display
- Streamed metadata (finish reason) with `stream().chatResponse()`
- Handled streaming errors gracefully with `onErrorResume`

---

## What's Next

In **Chapter 14**, we add document intelligence — the ability to ingest PDFs, Word documents, and web pages, making the SmartHR assistant able to read and analyse any document Sarah uploads.

*Code for this chapter: [`code/chapter-13-streaming-api/`](../code/chapter-13-streaming-api/)*
