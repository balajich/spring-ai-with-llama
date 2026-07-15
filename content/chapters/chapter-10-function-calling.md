# Chapter 10 — Function Calling: Tool Use and Java Method Binding

> **What you will build:** An interview scheduling assistant — the AI converses with Lisa the Hiring Manager, checks calendar availability and books interview slots by calling real Java methods, instead of just talking about them.

---

## The Problem We Are Solving

Lisa asks the SmartHR bot:

> "Can you schedule an interview for the Java developer candidate next Tuesday at 2pm?"

Every chatbot so far in this book can only answer questions — it cannot take actions. Lisa still has to open the calendar herself and book it manually.

**Function calling** (also called tool use) lets the AI call Java methods as part of its reasoning. The bot can now *do things*, not just *say things*.

---

## What You Will Learn

- What function calling (tool use) is and how it works
- How to expose Java methods as tools with `@Tool` and `@ToolParam`
- How to register tools on a `ChatClient` with `defaultTools()`
- How the model decides when to call a tool vs. answer directly
- How to combine tool calling with chat memory for multi-turn scheduling conversations

---

## How Function Calling Works

```
Lisa: "Schedule an interview for next Tuesday at 2pm"
          │
          ▼
        Llama
          │
          ├── "I need to check if Tuesday 2pm is available"
          │         │
          │         ▼
          │   calls checkAvailability("2025-06-03", "14:00")
          │         │
          │         ▼
          │   Java method returns: { date: "2025-06-03", time: "14:00", available: true }
          │
          ├── "Tuesday 2pm is free. Booking now."
          │         │
          │         ▼
          │   calls bookInterview("2025-06-03", "14:00", "Java Dev - Priya Sharma")
          │         │
          │         ▼
          │   Java method returns: { meetingId: "MTG-4821AB3F", confirmed: true }
          │
          ▼
"Interview booked! Tuesday June 3rd at 2:00 PM (Meeting ID: MTG-4821AB3F)"
```

The model orchestrates the tool calls. You write the Java methods. Spring AI handles converting the method signature into a JSON schema, sending it to the model, parsing the model's tool-call request, invoking the method, and feeding the result back into the conversation.

---

## Exposing Java Methods as Tools

```java
@Service
public class CalendarService {

    private final Set<String> bookedSlots = ConcurrentHashMap.newKeySet();

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
        String slotKey = key(date, time);
        if (!bookedSlots.add(slotKey)) {
            return new BookingConfirmation(null, date, time, false);
        }
        String meetingId = "MTG-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return new BookingConfirmation(meetingId, date, time, true);
    }

    private String key(String date, String time) {
        return date + "T" + time;
    }
}
```

`@Tool` marks the method as callable by the model. `@ToolParam` describes each argument so the model knows what to pass.

---

## Registering Tools on the ChatClient

```java
@RestController
@RequestMapping("/hr")
public class ScheduleController {

    private static final String SYSTEM_PROMPT = """
            You are a scheduling assistant for TechCorp's hiring team. You help hiring
            managers schedule candidate interviews.

            You have tools to check calendar availability and book interview slots.
            Always check availability before booking. Only book a slot once the hiring
            manager has explicitly confirmed they want to proceed. Be concise.
            """;

    private final ChatClient chatClient;
    private final ChatMemory chatMemory;

    public ScheduleController(ChatClient.Builder builder, CalendarService calendarService) {
        this.chatMemory = MessageWindowChatMemory.builder()
                .chatMemoryRepository(new InMemoryChatMemoryRepository())
                .maxMessages(20)
                .build();

        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultTools(calendarService)
                .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
                .build();
    }

    @PostMapping("/schedule/chat")
    public HrResponse chat(@RequestBody ScheduleRequest request) {
        String answer = chatClient
                .prompt()
                .user(request.message())
                .advisors(a -> a.param(ChatMemory.CONVERSATION_ID, request.sessionId()))
                .call()
                .content();
        return new HrResponse(request.message(), answer, "schedule");
    }

    @DeleteMapping("/schedule/chat/{sessionId}")
    public ResponseEntity<Void> clearSession(@PathVariable String sessionId) {
        chatMemory.clear(sessionId);
        return ResponseEntity.noContent().build();
    }
}
```

Notice this builds directly on **Chapter 6**'s `MessageWindowChatMemory` + `MessageChatMemoryAdvisor` pattern. The only addition is `.defaultTools(calendarService)` — tool calling and chat memory compose cleanly because they are both just advisors/configuration on the same `ChatClient`.

---

## Testing a Full Scheduling Conversation

```bash
# Turn 1 — check availability
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Can you check if Tuesday 2025-06-03 at 2pm is free for a Java developer interview with Priya Sharma?"}'

# Turn 2 — confirm the booking
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Yes, please go ahead and book it."}'
```

In Turn 1, the model calls `checkAvailability`. In Turn 2, having seen the result and the hiring manager's confirmation, it calls `bookInterview`. Both calls happen transparently inside `chatClient.prompt().call()` — your controller code never touches the tool-calling mechanics.

---

## When Does the Model Call a Tool?

The model decides based entirely on the descriptions you write. Good descriptions are critical:

| Too vague | Better |
|-----------|--------|
| "Check calendar" | "Check if a specific date and time slot is available for scheduling an interview" |
| "Book meeting" | "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available." |

Write tool descriptions as if you are explaining the method to a junior developer who has never seen your codebase. The phrase *"Only call this after confirming the slot is available"* in `bookInterview`'s description is doing real work — it is what keeps the model from skipping straight to booking without checking availability first.

---

## Summary

In this chapter you:

- Understood how function calling lets the model invoke Java methods as part of its reasoning
- Exposed `CalendarService` methods as tools using `@Tool` and `@ToolParam`
- Registered tools on a `ChatClient` with `defaultTools()`
- Combined tool calling with `MessageWindowChatMemory` for a multi-turn scheduling conversation
- Learned that tool descriptions — not your Java code — are what guide the model's decisions

---

## What's Next

In **Chapter 11**, we revisit tool calling from a different angle: instead of writing `@Tool` methods inside the app, we expose `CalendarService` as a standalone REST API and wrap it in an MCP (Model Context Protocol) server — so any MCP-compatible LLM client, not just this app, can discover and call the same scheduling tools.

*Code for this chapter: [`code/chapter-10-function-calling/`](../code/chapter-10-function-calling/)*
