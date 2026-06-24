# Chapter 13 — Streaming API: Real-Time Token-by-Token Responses

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** A live-streaming HR chat interface — instead of waiting 10 seconds for a full response, employees see the answer appearing word-by-word as Llama generates it, just like ChatGPT.

---

## The Problem We Are Solving

The SmartHR bot works well but feels slow. For long answers, the UI shows a spinner for 8-10 seconds, then the full text appears at once. Employees complain it feels unresponsive.

Dev tells Sarah:

> "The model is actually generating the answer token-by-token the whole time. We're just not showing it until it finishes. We can stream it instead."

---

## What You Will Learn

- How token-by-token streaming works
- Spring AI's streaming API using `Flux<String>`
- Server-Sent Events (SSE) for pushing tokens to a browser
- How to build a streaming endpoint
- How to handle streaming errors

---

## Blocking vs Streaming

```java
// Blocking — waits for the full response (current approach)
String answer = chatClient.prompt().user(question).call().content();
// User waits 8 seconds → sees full text at once

// Streaming — emits each token as it is generated
Flux<String> stream = chatClient.prompt().user(question).stream().content();
// User sees text appear word-by-word immediately
```

---

## Building a Streaming Endpoint (SSE)

Server-Sent Events (SSE) is the standard way to push streaming data from a Spring Boot controller to a browser.

```java
@GetMapping(value = "/hr/ask/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<String> streamAnswer(@RequestParam String question) {
    return chatClient
            .prompt()
            .user(question)
            .stream()
            .content();
}
```

That is the entire endpoint. Spring's `Flux<String>` and `TEXT_EVENT_STREAM_VALUE` do the rest.

---

## Consuming the Stream in a Browser

```javascript
const source = new EventSource(
    '/hr/ask/stream?question=What+is+the+leave+policy%3F'
);

source.onmessage = (event) => {
    document.getElementById('answer').innerText += event.data;
};

source.onerror = () => source.close();
```

---

## Streaming with Metadata

```java
@GetMapping(value = "/hr/ask/stream/full", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<ChatResponse> streamFull(@RequestParam String question) {
    return chatClient
            .prompt()
            .user(question)
            .stream()
            .chatResponse();  // full ChatResponse per token, includes metadata
}
```

The full `ChatResponse` stream includes finish reason, token usage, and model metadata alongside each token chunk.

---

## Error Handling in Streams

```java
return chatClient.prompt().user(question)
        .stream()
        .content()
        .onErrorResume(e -> Flux.just("[Error: " + e.getMessage() + "]"));
```

---

## When to Use Streaming

| Use Streaming | Use Blocking |
|--------------|-------------|
| UI-facing chat interfaces | Backend-to-backend calls |
| Long answers (>3 seconds) | Short answers (<1 second) |
| When UX responsiveness matters | When you need the full text before processing |
| Real-time dashboards | Batch processing |

---

## Summary

In this chapter you will:

- Understand how token streaming works in language models
- Use Spring AI's `stream().content()` to get a `Flux<String>`
- Build an SSE streaming endpoint for real-time browser display
- Handle streaming errors gracefully

---

## What's Next

In **Chapter 14**, we add document intelligence — the ability to ingest PDFs, Word documents, and web pages, making the SmartHR assistant able to read and analyse any document Sarah uploads.

*Code for this chapter: [`code/chapter-13-streaming-api/`](../code/chapter-13-streaming-api/)*
