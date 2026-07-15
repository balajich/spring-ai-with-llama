# Chapter 11 — MCP: Exposing an Existing REST API as Tools

> **What you will build:** Split Chapter 10's interview-scheduling tools out of the chatbot and into a standalone MCP server — wrapping TechCorp's existing calendar REST API so it can be discovered and called by any MCP-compatible LLM client, not just this one app.

---

## The Problem We Are Solving

Chapter 10 gave the SmartHR bot tools — `checkAvailability` and `bookInterview` — written as `@Tool` methods living inside the same Spring Boot app as the chatbot.

That works, but it does not scale past one app. Suppose the recruiting team also wants a Slack bot that can book interviews. And the careers portal wants a self-service booking widget. Do you copy-paste `CalendarService` into every app that needs it?

There is also a more basic problem: TechCorp's calendar logic already exists as a REST API (`calendar-service`), used today by the HR team's internal tools. Chapter 10 didn't reuse it — it re-implemented the same logic as in-process Java methods.

**MCP (Model Context Protocol)** solves both problems. It lets you expose tools from a single, independent server process — wrapping whatever already exists (a REST API, in this case) — and any MCP-compatible client can discover and call them, without ever seeing your Java code.

---

## What You Will Learn

- What MCP is and how it differs from Chapter 10's in-process `@Tool` methods
- How to wrap an existing REST API as MCP tools using `spring-ai-starter-mcp-server-webmvc`
- How an MCP client discovers tools at runtime using `spring-ai-starter-mcp-client`
- How `ToolCallbackProvider` plugs MCP tools into `ChatClient` exactly like `defaultTools()` did in Chapter 10
- Why splitting "tool implementation" from "tool consumer" into separate processes is the point of MCP

---

## One Process Becomes Three

This chapter is a **multi-module Maven project** — `code/chapter-11-mcp-integration/` — with three independent Spring Boot apps:

```
Chapter 10 (one process):

  ┌─────────────────────────────────┐
  │  Spring Boot app                │
  │  ChatClient ──► @Tool methods   │
  │              CalendarService    │
  └─────────────────────────────────┘

Chapter 11 (three processes):

  ┌──────────────┐   MCP (SSE)   ┌──────────────┐   REST   ┌───────────────────┐
  │  mcp-client  │◄─────────────►│  mcp-server  │ ───────► │  calendar-service │
  │  :8080       │  discover &   │  :8081       │ /api/    │  :8082            │
  │  ChatClient  │  invoke tools │  @Tool methods│ calendar │  CalendarService  │
  │  (no @Tool)  │               │ (CalendarMcpTools)│      │  (pre-existing)   │
  └──────────────┘               └──────────────┘          └───────────────────┘
```

Each app has exactly one responsibility:

1. **`calendar-service`** (port 8082) — the **pre-existing REST API** (`CalendarRestController` → `CalendarService`). Unchanged, unaware of LLMs. It would exist with or without MCP.
2. **`mcp-server`** (port 8081) — a thin **MCP adapter** (`CalendarMcpTools`) whose `@Tool` methods call `calendar-service` over HTTP — the same way any other REST client would.
3. **`mcp-client`** (port 8080) — the chatbot. Connects to `mcp-server` over MCP and discovers its tools at runtime.

---

## `calendar-service` — The Existing REST API (Unchanged)

```java
@RestController
@RequestMapping("/api/calendar")
public class CalendarRestController {

    private final CalendarService calendarService;

    public CalendarRestController(CalendarService calendarService) {
        this.calendarService = calendarService;
    }

    @GetMapping("/availability")
    public CalendarSlot checkAvailability(@RequestParam String date, @RequestParam String time) {
        return calendarService.checkAvailability(date, time);
    }

    @PostMapping("/bookings")
    public BookingConfirmation bookInterview(@RequestBody BookingRequest request) {
        return calendarService.bookInterview(request.date(), request.time(), request.candidateInfo());
    }
}
```

This is exactly what existed before MCP entered the picture — a normal Spring `@RestController`. No `@Tool` annotations, no Spring AI imports.

---

## `mcp-server` — Wrapping It as an MCP Tool

```java
@Component
public class CalendarMcpTools {

    private final RestClient restClient;

    public CalendarMcpTools(@Value("${calendar-service.base-url}") String calendarServiceBaseUrl) {
        this.restClient = RestClient.builder().baseUrl(calendarServiceBaseUrl + "/api/calendar").build();
    }

    @Tool(description = "Check if a specific date and time slot is available for scheduling an interview")
    public CalendarSlot checkAvailability(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time) {
        return restClient.get()
                .uri(uriBuilder -> uriBuilder.path("/availability")
                        .queryParam("date", date)
                        .queryParam("time", time)
                        .build())
                .retrieve()
                .body(CalendarSlot.class);
    }

    @Tool(description = "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available.")
    public BookingConfirmation bookInterview(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time,
            @ToolParam(description = "Candidate name and role being interviewed for") String candidateInfo) {
        return restClient.post()
                .uri("/bookings")
                .body(new BookingRequest(date, time, candidateInfo))
                .retrieve()
                .body(BookingConfirmation.class);
    }
}
```

Notice this is **the same `@Tool`/`@ToolParam` annotations from Chapter 10** — MCP doesn't introduce a new tool-definition API. What's different is the method *body*: instead of touching `CalendarService` directly, it makes an HTTP call to the REST API. The adapter has no scheduling logic of its own.

Register it with the MCP server's auto-configuration:

```java
@Bean
public ToolCallbackProvider calendarToolCallbackProvider(CalendarMcpTools calendarMcpTools) {
    return MethodToolCallbackProvider.builder()
            .toolObjects(calendarMcpTools)
            .build();
}
```

That's the entire `mcp-server` module. `spring-ai-starter-mcp-server-webmvc` handles the protocol — exposing an SSE endpoint at `/sse`, advertising the tool schema, and routing incoming tool-call requests to the matching `@Tool` method. The `calendar-service.base-url` property points at `calendar-service` (port 8082) — the two apps know about each other only through configuration, not compiled-in references.

---

## `mcp-client` — Discovering Tools at Runtime

The chatbot app (`mcp-client`) has zero `@Tool` methods. It connects to `mcp-server` and gets a `ToolCallbackProvider` for free:

```java
public ScheduleController(ChatClient.Builder builder, ToolCallbackProvider toolCallbackProvider) {
    this.chatClient = builder
            .defaultSystem(SYSTEM_PROMPT)
            .defaultToolCallbacks(toolCallbackProvider)
            .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
            .build();
}
```

Compare this to Chapter 10's `defaultTools(calendarService)` — same `ChatClient` builder, same multi-turn `MessageChatMemoryAdvisor` pattern from Chapter 6. Only the *source* of the tools changed: a local object versus a remote MCP connection.

The connection is configured declaratively, no Java code required:

```yaml
spring:
  ai:
    mcp:
      client:
        sse:
          connections:
            calendar:
              url: http://localhost:8081
              sse-endpoint: /sse
```

At startup, `spring-ai-starter-mcp-client` opens the SSE connection, performs the MCP handshake, and asks the server "what tools do you have?" The server answers with `checkAvailability` and `bookInterview` — including their descriptions and parameter schemas — exactly as if they had been written as `@Tool` methods in this app.

---

## Running It

Three terminals, started in order — each app depends on the previous one being reachable:

```bash
# Terminal 1 — the pre-existing REST API
cd code/chapter-11-mcp-integration/calendar-service
mvn spring-boot:run        # port 8082

# Terminal 2 — the MCP adapter
cd code/chapter-11-mcp-integration/mcp-server
mvn spring-boot:run        # port 8081

# Terminal 3 — the chatbot
cd code/chapter-11-mcp-integration/mcp-client
mvn spring-boot:run        # port 8080
```

```bash
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Can you check if Tuesday 2025-06-03 at 2pm is free for a Java developer interview with Priya Sharma?"}'
```

Under the hood: `mcp-client` asks the model what to do, the model decides to call `checkAvailability`, the client sends that request over the SSE connection to `mcp-server`, which invokes `CalendarMcpTools.checkAvailability()`, which calls the REST API at `http://localhost:8082/api/calendar/availability` on `calendar-service`, which calls `CalendarService` — three processes, two network hops beyond what Chapter 10 needed, in exchange for tool reuse across any number of clients, and a calendar API that can be deployed and scaled independently of the chatbot.

---

## Chapter 10 vs Chapter 11

| | Chapter 10 — Function Calling | Chapter 11 — MCP |
|-|-------------------------------|-------------------|
| Tool implementation | `@Tool` methods inside the chatbot app | `@Tool` methods in a separate `mcp-server` app |
| Tool discovery | Compile-time — `defaultTools(calendarService)` | Runtime — `ToolCallbackProvider` via SSE handshake |
| Reusable by other apps | No — copy-paste required | Yes — any MCP client can connect to `mcp-server` |
| Underlying logic reused | No — reimplemented as Java methods | Yes — `mcp-server` wraps `calendar-service`'s existing REST API |
| Processes | 1 | 3 |

---

## Summary

In this chapter you:

- Split a single chatbot app into three independently deployable Spring Boot apps: `calendar-service`, `mcp-server`, `mcp-client`
- Wrapped a pre-existing REST API (`CalendarRestController` in `calendar-service`) as MCP tools using `CalendarMcpTools` and `MethodToolCallbackProvider` in `mcp-server`
- Connected an LLM-facing app (`mcp-client`) to `mcp-server` with `spring-ai-starter-mcp-client`, with zero `@Tool` methods of its own
- Saw that `defaultTools(localObject)` and `defaultToolCallbacks(mcpProvider)` are the same `ChatClient` mechanism, fed from different sources
- Understood the trade-off: one extra network hop, in exchange for tools that any MCP client — not just this app — can use

---

## What's Next

In **Chapter 12**, we go multimodal — the AI can now see images. We build a workplace safety inspector where an employee uploads a photo of a potential hazard and the AI analyses it and files a report.

*Code for this chapter: [`code/chapter-11-mcp-integration/`](../../code/chapter-11-mcp-integration/)*
