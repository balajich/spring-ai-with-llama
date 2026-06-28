# Chapter 11 — Your Calendar Tool Shouldn't Live Inside Your Chatbot

Chapter 10 gave the SmartHR bot hands — it could check calendar availability and book interviews by calling real Java methods, not just talking about it.

Then the recruiting team asked Sarah a reasonable question:

> "Our Slack bot needs to book interviews too. And the careers portal wants a self-service booking widget. Do we copy-paste the calendar logic into every app that needs it?"

There was a second, quieter problem. TechCorp's calendar logic already existed as a REST API — used today by the HR team's internal tools. Chapter 10 didn't reuse it. It re-implemented the same logic as Java methods living inside the chatbot.

Both problems have the same root cause: **the tool and the tool's consumer were welded into one process.**

**MCP (Model Context Protocol)** unwelds them — and it's worth understanding *why* its architecture looks the way it does, not just how to wire it up.

---

## Three Roles, Not Two

Most explanations of MCP jump straight to code. The more useful starting point is the three roles the protocol defines:

- **Host** — the application the human actually interacts with. In this chapter, that's the SmartHR chatbot. The host owns the conversation and decides, via the LLM, when a tool is needed.
- **Client** — the component embedded inside the host that speaks the MCP protocol. It's the thing that opens a connection to a server, asks "what tools do you have?", and forwards tool-call requests. Spring AI's `spring-ai-starter-mcp-client` *is* this role.
- **Server** — a separate process that exposes a set of tools (or data, or prompts) over the MCP protocol. It doesn't know or care what host is calling it. Spring AI's `spring-ai-starter-mcp-server-webmvc` implements this role.

This three-way split is the entire point. A function-calling setup (Chapter 10) only has two roles baked together: the host *is* the tool owner. MCP separates "who decides to call a tool" from "who implements the tool" — and that separation is what lets the same tool serve more than one host.

---

## Exposing an Existing REST API as MCP Tools — Without Touching It

TechCorp's calendar capability already exists as a REST API. The pattern that matters here: you don't rewrite that API to "speak MCP." You put a thin MCP server **in front of it** that translates MCP tool calls into ordinary HTTP calls against the API that's already running.

```
                 (unchanged, pre-existing)
   HR Calendar UI ──────► Calendar REST API ──────► Calendar business logic


                          MCP SERVER (new)
                  wraps the REST API as tools,
                does not reimplement any logic
                              │
                              │  MCP protocol
                              ▼
        ┌─────────────┐              ┌──────────────┐
        │  HOST: chat  │              │  HOST: Slack  │   ...any other
        │  CLIENT      │              │  CLIENT       │   MCP-aware agent
        └─────────────┘              └──────────────┘
```

The REST API never finds out MCP exists. The MCP server's only job is translation: receive a tool call, make an HTTP request, return the result in the shape MCP expects. Because the *tool* lives outside any one host, **any number of agents can be hosts against the same server** — a chatbot, a Slack bot, an autonomous agent doing multi-step planning, a careers-portal widget — all without duplicating a single line of calendar logic. That's the actual business case for this architecture: write the integration once, let every current and future agent in the organization reuse it.

---

## Where SSE Fits, and Why Async Matters Here

MCP needs the server to be able to push things to the client without being asked first — a tool's result, a notification that the available tool list changed, progress updates on a long-running call. A plain request/response HTTP call can't do that; the server can only ever reply to a request that already arrived.

This is the job of **SSE (Server-Sent Events)**. The client opens one long-lived HTTP connection to the server and keeps it open. The server can write events down that connection at any time, whenever it has something to say — not just when polled. It's one-directional (server → client), which is exactly the shape MCP needs for results and notifications.

The other direction — client → server, "call this tool with these arguments" — travels as a normal HTTP POST, on its own URL, decoupled from the SSE stream. So a complete MCP exchange over this transport looks like:

1. Client opens the SSE connection. Server immediately replies with a session-specific URL for sending requests *to* it.
2. Client asks "what tools do you exist?" by POSTing to that session URL.
3. Server's answer — the tool list, with descriptions and parameter schemas — arrives back as an event on the open SSE stream, not as the POST's direct response.
4. Later, when a tool actually needs calling, the client POSTs the call to the same session URL, and the result again arrives asynchronously over SSE.

The two channels — POST out, SSE in — are why this is genuinely asynchronous rather than just "HTTP with extra steps." The server is free to take its time, call other systems, even push intermediate progress, and the client just keeps listening on the one open connection. (Newer Spring AI versions also support a "Streamable HTTP" transport that folds both directions into a single connection — same underlying idea, fewer moving parts.)

---

## What This Costs You

Nothing here is free. Compared to Chapter 10's single process:

| | Function Calling (Ch. 10) | MCP (Ch. 11) |
|-|---|---|
| Where the tool lives | Inside the host | A separate server process |
| Who can reuse it | Only that one host | Any MCP host that connects |
| Reuses existing systems | No — reimplemented | Yes — wraps the REST API as-is |
| Extra moving parts | None | A server process, a transport (SSE), session lifecycle |

You're trading one extra network hop and one more process to operate, for a tool that doesn't belong to any single agent anymore. That trade is worth making the moment a second consumer shows up — and not worth making before that.

---

## What's Next — Chapter 12: Multimodality

The bot can talk, remember, retrieve, and now act through tools shared across agents. Next it learns to see — an employee uploads a photo of a workplace hazard, and the AI analyses the image and files a report.

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
- [Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.](chapter-10-function-calling.md)
- **Chapter 11 — Your Calendar Tool Shouldn't Live Inside Your Chatbot** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 21, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java21 #Ollama #MCP #ModelContextProtocol #ToolUse #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #SpringFramework #Llama
