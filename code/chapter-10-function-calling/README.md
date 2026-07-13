# Chapter 10 — Function Calling: Tool Use and Java Method Binding

Upgrade the SmartHR bot from a Q&A assistant to a doer — the AI calls real Java methods mid-conversation to check calendar availability and book interview slots, instead of just talking about them.

<svg viewBox="0 0 580 300" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 10 — Spring AI, Ollama and Tool Calling Architecture</title>
  <desc>Spring AI in the JVM communicates with Ollama llama3.2 and invokes CalendarService Java methods as tools.</desc>
  <rect width="580" height="300" fill="#f8f9fa" rx="12"/>
  <rect x="30" y="80" width="180" height="140" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="120" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="120" y="126" text-anchor="middle" font-size="10" fill="#999">JVM</text>
  <text x="120" y="152" text-anchor="middle" font-size="10" fill="#555">ChatClient</text>
  <text x="120" y="168" text-anchor="middle" font-size="10" fill="#555">MessageChatMemoryAdvisor</text>
  <text x="120" y="184" text-anchor="middle" font-size="10" fill="#555">defaultTools(...)</text>
  <rect x="350" y="20" width="190" height="100" rx="10" fill="white" stroke="#5aaa6b" stroke-width="2"/>
  <text x="445" y="47" text-anchor="middle" font-size="13" font-weight="700" fill="#1b6b2f">Ollama</text>
  <text x="445" y="64" text-anchor="middle" font-size="10" fill="#999">localhost:11434</text>
  <rect x="368" y="74" width="154" height="34" rx="7" fill="#e8f5e9" stroke="#5aaa6b" stroke-width="1.5"/>
  <text x="445" y="95" text-anchor="middle" font-size="11" font-weight="700" fill="#1b6b2f">llama3.2</text>
  <rect x="350" y="150" width="190" height="120" rx="10" fill="white" stroke="#5b6abf" stroke-width="2"/>
  <text x="445" y="176" text-anchor="middle" font-size="13" font-weight="700" fill="#2d3494">CalendarService</text>
  <text x="445" y="193" text-anchor="middle" font-size="10" fill="#999">@Service (in-JVM)</text>
  <rect x="368" y="204" width="154" height="24" rx="6" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.5"/>
  <text x="445" y="220" text-anchor="middle" font-size="10" font-weight="700" fill="#2d3494">checkAvailability()</text>
  <rect x="368" y="234" width="154" height="24" rx="6" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.5"/>
  <text x="445" y="250" text-anchor="middle" font-size="10" font-weight="700" fill="#2d3494">bookInterview()</text>
  <path d="M 210 130 L 350 75" fill="none" stroke="#5aaa6b" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#g10)"/>
  <text x="278" y="90" text-anchor="middle" font-size="9" fill="#1b6b2f">prompt + tool schema</text>
  <path d="M 350 88 L 210 145" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#g10)"/>
  <text x="278" y="125" text-anchor="middle" font-size="9" fill="#1b6b2f">"call checkAvailability"</text>
  <path d="M 210 195 L 350 210" fill="none" stroke="#5b6abf" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#p10)"/>
  <text x="278" y="195" text-anchor="middle" font-size="9" fill="#2d3494">invoke Java method</text>
  <path d="M 350 222 L 210 207" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#p10)"/>
  <text x="278" y="232" text-anchor="middle" font-size="9" fill="#2d3494">method result (JSON)</text>
  <defs>
    <marker id="g10" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="p10" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
  </defs>
</svg>

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
cd code/chapter-10-function-calling
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## How It Works

`CalendarService` exposes two Java methods as tools using `@Tool`:

```java
@Tool(description = "Check if a specific date and time slot is available for scheduling an interview")
public CalendarSlot checkAvailability(
        @ToolParam(description = "Date in yyyy-MM-dd format") String date,
        @ToolParam(description = "Time in HH:mm 24-hour format") String time) {
    boolean available = !bookedSlots.contains(key(date, time));
    return new CalendarSlot(date, time, available);
}

@Tool(description = "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available.")
public BookingConfirmation bookInterview(
        @ToolParam(description = "Date in yyyy-MM-dd format") String date,
        @ToolParam(description = "Time in HH:mm 24-hour format") String time,
        @ToolParam(description = "Candidate name and role being interviewed for") String candidateInfo) {
    ...
}
```

The `ScheduleController` registers the service as a tool source on the `ChatClient`:

```java
this.chatClient = builder
        .defaultSystem(SYSTEM_PROMPT)
        .defaultTools(calendarService)
        .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
        .build();
```

Spring AI converts the `@Tool` methods into a JSON schema, sends it to Ollama alongside the prompt, and — when the model decides a tool is needed — invokes the matching Java method and feeds the result back into the conversation, transparently to the caller.

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/schedule/chat` | Stateful chat — the LLM may call `CalendarService` tools mid-conversation |
| `DELETE` | `/hr/schedule/chat/{sessionId}` | Clear a session's conversation memory |

---

## Example Usage

```bash
# Turn 1 — check availability
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Can you check if Tuesday 2025-06-03 at 2pm is free for a Java developer interview with Priya Sharma?"}'

# Turn 2 — confirm and book
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Yes, please book it."}'

# Clear the session
curl -s -X DELETE http://localhost:8080/hr/schedule/chat/lisa-001
```

---

## Why Tool Descriptions Matter

The model has no idea what your Java method actually does — only what the `@Tool` and `@ToolParam` descriptions tell it. Vague descriptions lead to the model guessing wrong, calling the wrong tool, or not calling a tool at all.

| Too vague | Better |
|-----------|--------|
| "Check calendar" | "Check if a specific date and time slot is available for scheduling an interview" |
| "Book meeting" | "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available." |

Write descriptions as if explaining the method to a developer who has never seen your codebase.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` |
| Model never calls the tool | Tool description too vague, or the model doesn't think it needs the tool | Make `@Tool`/`@ToolParam` descriptions more specific |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-10-function-calling/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── ScheduleController.java     ← /hr/schedule/chat + tool registration
    │   ├── service/
    │   │   └── CalendarService.java        ← @Tool methods: checkAvailability, bookInterview
    │   └── model/
    │       ├── ScheduleRequest.java
    │       ├── HrResponse.java
    │       ├── CalendarSlot.java
    │       └── BookingConfirmation.java
    └── resources/
        └── application.yml
```

---

*Full chapter write-up: [`chapters/chapter-10-function-calling.md`](../../chapters/chapter-10-function-calling.md)*
