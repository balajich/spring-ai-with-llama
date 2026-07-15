# Chapter 11 — MCP Integration (multi-module)

A multi-module Maven project demonstrating how to expose an **existing REST API** as **MCP tools** and consume them from an LLM-backed chat application — three independent Spring Boot apps, each with a single responsibility.

| Module | Port | Role |
|--------|------|------|
| [`calendar-service`](calendar-service/) | **8082** | The pre-existing REST API (`/api/calendar/*`). No knowledge of MCP or LLMs. |
| [`mcp-server`](mcp-server/) | **8081** | Wraps `calendar-service` as MCP tools (`checkAvailability`, `bookInterview`) and serves them over MCP (SSE). Calls `calendar-service` via REST. |
| [`mcp-client`](mcp-client/) | **8080** | The SmartHR scheduling chatbot. No `@Tool` methods of its own — discovers tools from `mcp-server` at runtime. |

```
┌──────────────┐   POST /hr/schedule/chat   ┌──────────────┐   MCP (SSE)   ┌──────────────┐   REST   ┌──────────────────┐
│  Hiring      │ ─────────────────────────► │  mcp-client  │ ────────────► │  mcp-server  │ ───────► │  calendar-service │
│  manager     │                            │  :8080       │  discover &   │  :8081       │  GET/POST│  :8082             │
│  (curl / UI) │                            │  ChatClient  │  invoke tools │  @Tool       │  /api/   │  CalendarService   │
└──────────────┘                            └──────────────┘               │  methods     │  calendar│  (existing logic)  │
                                                     │                     └──────────────┘          └──────────────────┘
                                                     ▼
                                              ┌──────────────┐
                                              │    Ollama    │
                                              │  llama3.2    │
                                              │  :11434      │
                                              └──────────────┘
```

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

### 1. Pull the model and start Ollama

```bash
ollama pull llama3.2
ollama serve
```

### 2. Build all three modules

```bash
cd code/chapter-11-mcp-integration
mvn clean package -DskipTests
```

---

## Start All Three Apps

Open **three terminals**. Start in this order — each app depends on the one before it being reachable:

**Terminal 1 — `calendar-service` (port 8082)**
```bash
cd code/chapter-11-mcp-integration/calendar-service
mvn spring-boot:run
```

**Terminal 2 — `mcp-server` (port 8081)**
```bash
cd code/chapter-11-mcp-integration/mcp-server
mvn spring-boot:run
```

Wait for `Started McpServerApplication` before continuing.

**Terminal 3 — `mcp-client` (port 8080)**
```bash
cd code/chapter-11-mcp-integration/mcp-client
mvn spring-boot:run
```

On startup, `mcp-client`'s log should show a line confirming the MCP handshake with `mcp-server`:

```
Server response with Protocol: 2024-11-05, ... Info: Implementation[name=smarthr-calendar-mcp-server, ...]
```

That confirms `mcp-client` discovered `checkAvailability` and `bookInterview` from `mcp-server` at runtime — it never defines those tools itself.

---

## Verify Each App Individually

```bash
# calendar-service — the existing REST API
curl -s "http://localhost:8082/api/calendar/availability?date=2025-06-03&time=14:00"

curl -s -X POST http://localhost:8082/api/calendar/bookings \
  -H "Content-Type: application/json" \
  -d '{"date": "2025-06-03", "time": "14:00", "candidateInfo": "Java Dev - Priya Sharma"}'

# mcp-server — the MCP SSE endpoint (confirms it's accepting MCP connections)
curl -N http://localhost:8081/sse
# Expect: event:endpoint  /  data:/mcp/message?sessionId=<uuid>

# mcp-client — the chatbot
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Can you check if Tuesday 2025-06-03 at 2pm is free for a Java developer interview with Priya Sharma?"}'

curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Yes, please book it."}'
```

---

## Run the Karate Tests

The Karate suite lives in [`code/tests/`](../tests/) and exercises `mcp-client` (port 8080), with a couple of sanity checks against `calendar-service` (port 8082) directly.

**Option A — one command, fully automated** (builds and starts all three apps, runs tests, stops everything):

```bash
cd code/tests
./run-tests.sh chapter-11
```

**Option B — manual** (if you already have all three apps running from the steps above):

```bash
cd code/tests
mvn test -Dtest=Chapter11Test
```

Test report: `code/tests/target/karate-reports/karate-summary.html`

---

## How It Works

`calendar-service` is unmodified, ordinary Spring MVC — it would exist with or without MCP:

```java
@RestController
@RequestMapping("/api/calendar")
public class CalendarRestController {
    @GetMapping("/availability")
    public CalendarSlot checkAvailability(@RequestParam String date, @RequestParam String time) { ... }

    @PostMapping("/bookings")
    public BookingConfirmation bookInterview(@RequestBody BookingRequest request) { ... }
}
```

`mcp-server` wraps it — the `@Tool` method bodies call the REST API over HTTP, not the service layer directly:

```java
@Tool(description = "Check if a specific date and time slot is available for scheduling an interview")
public CalendarSlot checkAvailability(
        @ToolParam(description = "Date in yyyy-MM-dd format") String date,
        @ToolParam(description = "Time in HH:mm 24-hour format") String time) {
    return restClient.get()
            .uri(uriBuilder -> uriBuilder.path("/availability")
                    .queryParam("date", date).queryParam("time", time).build())
            .retrieve()
            .body(CalendarSlot.class);
}
```

```java
@Bean
public ToolCallbackProvider calendarToolCallbackProvider(CalendarMcpTools calendarMcpTools) {
    return MethodToolCallbackProvider.builder().toolObjects(calendarMcpTools).build();
}
```

`mcp-client` never sees a `@Tool` annotation. It gets a `ToolCallbackProvider` for free from `spring-ai-starter-mcp-client`, configured declaratively:

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

```java
public ScheduleController(ChatClient.Builder builder, ToolCallbackProvider toolCallbackProvider) {
    this.chatClient = builder
            .defaultSystem(SYSTEM_PROMPT)
            .defaultToolCallbacks(toolCallbackProvider)
            .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
            .build();
}
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `mcp-server` fails to start with `RestClient$Builder` not found | (Fixed) `CalendarMcpTools` builds its own `RestClient` rather than relying on an autoconfigured builder bean | Already handled in the code — no action needed |
| `mcp-client` hangs or errors on startup | `mcp-server` isn't running yet | Start `mcp-server` first, wait for `Started McpServerApplication` |
| `mcp-server`'s tool calls fail / connection refused on :8082 | `calendar-service` isn't running | Start `calendar-service` first |
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| Model never calls a tool | Tool descriptions too vague, or `mcp-server` unreachable | Verify `curl http://localhost:8081/sse` responds |
| Port already in use (8080 / 8081 / 8082) | Another app running | Change `server.port` in the relevant module's `application.yml` |

---

## Project Structure

```
chapter-11-mcp-integration/
├── pom.xml                          ← aggregator (packaging=pom, lists the 3 modules)
├── README.md
├── calendar-service/                ← :8082 — the pre-existing REST API
│   ├── pom.xml
│   └── src/main/java/com/techcorp/smarthr/
│       ├── CalendarServiceApplication.java
│       ├── controller/CalendarRestController.java
│       ├── service/CalendarService.java
│       └── model/{CalendarSlot,BookingRequest,BookingConfirmation}.java
├── mcp-server/                      ← :8081 — MCP adapter over calendar-service
│   ├── pom.xml
│   └── src/main/java/com/techcorp/smarthr/
│       ├── McpServerApplication.java       ← registers ToolCallbackProvider
│       ├── tool/CalendarMcpTools.java      ← @Tool methods, call calendar-service via REST
│       └── model/{CalendarSlot,BookingRequest,BookingConfirmation}.java
└── mcp-client/                      ← :8080 — the SmartHR scheduling chatbot
    ├── pom.xml
    └── src/main/java/com/techcorp/smarthr/
        ├── SmartHrAssistantApplication.java
        ├── controller/ScheduleController.java   ← defaultToolCallbacks(toolCallbackProvider)
        └── model/{ScheduleRequest,HrResponse}.java
```

---

*Full chapter write-up: [`content/chapters/chapter-11-mcp.md`](../../content/chapters/chapter-11-mcp.md)*
