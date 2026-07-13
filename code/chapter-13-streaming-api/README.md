# Chapter 13 — Streaming API: Real-Time Token-by-Token Responses

Stop making users wait for the full answer. Switch `.call()` to `.stream()` and push each token to the browser the instant Llama generates it — the live-typing experience users expect from modern AI chat.

<svg viewBox="0 0 580 300" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 13 — Spring AI streaming over Server-Sent Events</title>
  <desc>Ollama streams tokens to Spring AI, which pushes them one at a time to the browser over SSE.</desc>
  <rect width="580" height="300" fill="#f8f9fa" rx="12"/>
  <rect x="30" y="110" width="150" height="80" rx="10" fill="white" stroke="#5b6abf" stroke-width="2"/>
  <text x="105" y="140" text-anchor="middle" font-size="13" font-weight="700" fill="#2d3494">Browser</text>
  <text x="105" y="158" text-anchor="middle" font-size="10" fill="#999">EventSource</text>
  <text x="105" y="176" text-anchor="middle" font-size="10" fill="#555">types word-by-word</text>
  <rect x="215" y="90" width="170" height="120" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="300" y="120" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="300" y="138" text-anchor="middle" font-size="10" fill="#999">JVM</text>
  <text x="300" y="162" text-anchor="middle" font-size="10" fill="#555">.stream().content()</text>
  <text x="300" y="180" text-anchor="middle" font-size="10" fill="#555">Flux&lt;String&gt;</text>
  <rect x="420" y="110" width="140" height="80" rx="10" fill="white" stroke="#5aaa6b" stroke-width="2"/>
  <text x="490" y="140" text-anchor="middle" font-size="13" font-weight="700" fill="#1b6b2f">Ollama</text>
  <text x="490" y="158" text-anchor="middle" font-size="10" fill="#999">llama3.2</text>
  <text x="490" y="176" text-anchor="middle" font-size="10" fill="#555">generates tokens</text>
  <path d="M 420 150 L 385 150" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#s13a)"/>
  <path d="M 215 150 L 180 150" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#s13b)"/>
  <text x="300" y="235" text-anchor="middle" font-size="10" fill="#777">token ← token ← token   (Server-Sent Events: text/event-stream)</text>
  <text x="300" y="255" text-anchor="middle" font-size="10" fill="#aaa">one HTTP connection, many data: events</text>
  <defs>
    <marker id="s13a" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="s13b" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
  </defs>
</svg>

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |

---

## Setup

```bash
ollama pull llama3.2
ollama serve   # if not already running
```

---

## Run the Application

```bash
cd code/chapter-13-streaming-api
mvn spring-boot:run
```

The app starts on **http://localhost:8080**. Open it in a browser for the live-streaming chat demo page.

---

## How It Works

The only change from a blocking endpoint is `.call()` → `.stream()`, and returning a `Flux<String>` with the `text/event-stream` content type:

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

Spring turns each emitted token into one `data:` Server-Sent Event. Streaming does not speed up generation — it removes the wait before the *first* token appears.

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `GET` | `/hr/ask/stream?question=...` | Raw token stream — `Flux<String>` over SSE |
| `GET` | `/hr/ask/stream/tokens?question=...` | Token stream with metadata (`finishReason`) — `Flux<StreamChunk>` over SSE |
| `GET` | `/` | Browser demo page (live-typing chat) |

> Streaming endpoints are `GET` because the browser's `EventSource` API only issues GET requests.

---

## Example Usage

```bash
# -N disables curl's buffering so you see tokens arrive live
curl -N "http://localhost:8080/hr/ask/stream?question=What+is+the+parental+leave+policy%3F"

# With metadata — finishReason is null until the final chunk ("stop")
curl -N "http://localhost:8080/hr/ask/stream/tokens?question=How+many+vacation+days+do+new+employees+get%3F"
```

Raw stream output looks like:

```
data:Tech
data:Corp
data: offers
data: a
data: 401
data:(k
...
```

---

## When to Use Streaming

| Use Streaming | Use Blocking |
|--------------|-------------|
| UI-facing chat interfaces | Backend-to-backend calls |
| Long answers (>3 seconds) | Short answers (<1 second) |
| When UX responsiveness matters | When you need the full text before processing |
| Real-time dashboards | Batch processing, structured-output parsing |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| Browser reconnects in a loop | `EventSource` fires `onerror` on normal completion | Call `source.close()` in `onerror` |
| curl shows nothing until the end | curl is buffering | Add the `-N` flag |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port` or run with `--server.port=8090` |

---

## Project Structure

```
chapter-13-streaming-api/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── StreamController.java       ← /hr/ask/stream + /hr/ask/stream/tokens
    │   └── model/
    │       └── StreamChunk.java            ← token + finishReason
    └── resources/
        ├── application.yml
        └── static/
            └── index.html                  ← browser EventSource demo page
```

---

*Full chapter write-up: [`chapters/chapter-13-streaming-api.md`](../../chapters/chapter-13-streaming-api.md)*
