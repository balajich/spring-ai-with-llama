# Chapter 8 — Function Calling: Tool Use and Java Method Binding

> **What you will build:** An interview scheduling assistant — the AI converses with Lisa the Hiring Manager, checks real calendar availability by calling a Java method, and books interview slots automatically.

---

## The Problem We Are Solving

Lisa asks the SmartHR bot:

> "Can you schedule an interview for the Java developer candidate next Tuesday at 2pm?"

Currently, the bot can only answer questions — it cannot take actions. Lisa still has to open the calendar herself and book it manually.

Function calling lets the AI call Java methods as part of its reasoning. The bot can now *do things*, not just *say things*.

---

## What You Will Learn

- What function calling (tool use) is and how it works
- How to register Java methods as tools in Spring AI
- How the AI decides when to call a tool vs answer directly
- How to build a tool-enabled interview scheduling assistant
- How to handle multi-step tool chains

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
          │   Java method returns: { "available": true }
          │
          ├── "Tuesday 2pm is free. Booking now."
          │         │
          │         ▼
          │   calls bookInterview("2025-06-03", "14:00", "Java Dev - Priya Sharma")
          │         │
          │         ▼
          │   Java method returns: { "confirmed": true, "meetingId": "MTG-4821" }
          │
          ▼
"Interview booked! Tuesday June 3rd at 2:00 PM (Meeting ID: MTG-4821)"
```

The AI orchestrates the tool calls. You write the Java methods.

---

## Registering Tools in Spring AI

```java
@Service
public class CalendarService {

    @Tool(description = "Check if a time slot is available for an interview")
    public CalendarSlot checkAvailability(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm format") String time) {
        // call your real calendar API here
        boolean available = calendarApi.isAvailable(date, time);
        return new CalendarSlot(date, time, available);
    }

    @Tool(description = "Book an interview slot in the calendar")
    public BookingConfirmation bookInterview(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm format") String time,
            @ToolParam(description = "Candidate name and role") String candidateInfo) {
        String meetingId = calendarApi.book(date, time, candidateInfo);
        return new BookingConfirmation(meetingId, date, time, true);
    }
}
```

```java
// Register the tools with ChatClient
ChatClient chatClient = ChatClient.builder(chatModel)
        .defaultTools(calendarService)
        .defaultSystem(SCHEDULING_SYSTEM_PROMPT)
        .build();
```

---

## What You Will Build — Interview Scheduling Endpoint

```java
// POST /hr/schedule/chat
public record ScheduleRequest(String sessionId, String message) {}

@PostMapping("/schedule/chat")
public HrResponse scheduleChat(@RequestBody ScheduleRequest request) {
    String answer = chatClient
            .prompt()
            .user(request.message())
            .advisors(a -> a.param(CHAT_MEMORY_CONVERSATION_ID_KEY, request.sessionId()))
            .call()
            .content();
    return new HrResponse(request.message(), answer, "schedule");
}
```

**Test a full scheduling conversation:**
```bash
# Step 1 — request an interview
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -d '{"sessionId": "lisa-001", "message": "I need to schedule an interview for Priya Sharma for the senior Java role. Can you check Tuesday 3rd June at 2pm?"}'

# Step 2 — confirm the booking
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -d '{"sessionId": "lisa-001", "message": "Yes, go ahead and book it."}'
```

---

## When Does the AI Call a Tool?

The AI decides based on the tool descriptions you write. Good descriptions are critical:

| Too vague | Better |
|-----------|--------|
| "Check calendar" | "Check if a specific date and time slot is available for scheduling an interview" |
| "Book meeting" | "Create a calendar booking for an interview with a candidate at a specified date and time" |

Write tool descriptions as if you are explaining the function to a junior developer who has never seen your codebase.

---

## Summary

In this chapter you will:

- Understand how function calling lets the AI invoke Java methods
- Register `@Tool` methods and bind them to a `ChatClient`
- Build an interview scheduling assistant that checks and books calendar slots
- Write effective tool descriptions that guide the AI's decisions

---

## What's Next

In **Chapter 9**, we go multimodal — the AI can now see images. We build a workplace safety inspector where an employee uploads a photo of a potential hazard and the AI analyses it and files a report.

*Code for this chapter: [`code/chapter-08-function-calling/`](../code/chapter-08-function-calling/)*
