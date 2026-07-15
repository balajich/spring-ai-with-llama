# Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.

Lisa, TechCorp's hiring manager, asks the SmartHR bot:

> "Can you schedule an interview for the Java developer candidate next Tuesday at 2pm?"

Every chapter so far in this series gives the bot one superpower: it can *answer questions* — about policies, onboarding, anything in its knowledge base. But Lisa isn't asking a question. She's asking it to **do something**.

The bot has no hands. It can talk about interview scheduling all day, but it cannot touch the calendar.

**Function calling** fixes that. It lets the model call real Java methods as part of its reasoning — check availability, book a slot, return a confirmation — without you writing a single line of "if user wants to book, then call bookInterview()" logic yourself.

---

## How It Actually Works

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
          │   Java method returns: { available: true }
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

The model decides *when* to call a tool and *what* arguments to pass. You just write the Java method and describe it in plain English.

---

## Two Annotations Is All It Takes

```java
@Service
public class CalendarService {

    private final Set<String> bookedSlots = new HashSet<>();

    @Tool(description = "Check if a specific date and time slot is available for scheduling an interview")
    public CalendarSlot checkAvailability(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time) {
        boolean available = !bookedSlots.contains(slot(date, time));
        return new CalendarSlot(date, time, available);
    }

    @Tool(description = "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available.")
    public BookingConfirmation bookInterview(
            @ToolParam(description = "Date in yyyy-MM-dd format") String date,
            @ToolParam(description = "Time in HH:mm 24-hour format") String time,
            @ToolParam(description = "Candidate name and role being interviewed for") String candidateInfo) {
        // ... books the slot, returns a confirmation
    }
}
```

`@Tool` marks the method as callable. `@ToolParam` tells the model what each argument means. Spring AI turns this into a JSON schema, sends it to Llama alongside the prompt, and routes any tool-call request straight back to this method — automatically.

---

## Register It, and Memory Still Works

```java
this.chatClient = builder
        .defaultSystem(SYSTEM_PROMPT)
        .defaultTools(calendarService)
        .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
        .build();
```

This builds directly on **Chapter 6**'s chat memory. `.defaultTools(calendarService)` is the only new line — multi-turn conversation and tool calling compose cleanly because they're both just configuration on the same `ChatClient`.

---

## Watch It Work Across Two Turns

```bash
# Turn 1 — the model calls checkAvailability
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Can you check if Tuesday 2025-06-03 at 2pm is free for a Java developer interview with Priya Sharma?"}'

# Turn 2 — the model calls bookInterview, having remembered Turn 1's context
curl -s -X POST http://localhost:8080/hr/schedule/chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "lisa-001", "message": "Yes, please go ahead and book it."}'
```

Your controller code never touches the tool-calling mechanics. It looks identical to every chat endpoint in this series — `chatClient.prompt().user(message).call().content()`.

---

## The One Thing That Actually Matters: Tool Descriptions

The model has no idea what your Java method does. It only knows what you wrote in `@Tool` and `@ToolParam`. A vague description means a confused model — guessing wrong, calling the wrong tool, or skipping the tool entirely.

| Too vague | Better |
|-----------|--------|
| "Check calendar" | "Check if a specific date and time slot is available for scheduling an interview" |
| "Book meeting" | "Book an interview slot in the calendar for a candidate. Only call this after confirming the slot is available." |

That last phrase — *"Only call this after confirming the slot is available"* — isn't filler. It's the instruction that keeps the model from skipping straight to booking without checking first. Write tool descriptions like you're briefing a junior developer who has never seen your codebase, because that's effectively what the model is.

---

## What's Next — Chapter 11: MCP

Function calling works great inside one app. But what happens when the Slack bot, the careers portal, and three other internal tools all need to book interviews too? Do you copy-paste `CalendarService` into every one of them?

In **Chapter 11**, we pull these tools out into a standalone **MCP (Model Context Protocol) server** — wrapping TechCorp's existing calendar REST API so any MCP-compatible client can discover and call it, not just this one chatbot.

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
- **Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #FunctionCalling #ToolUse #LLM #GenerativeAI #AIEngineering #LocalAI #NoPayAPI #JavaDeveloper #SpringFramework #Llama
