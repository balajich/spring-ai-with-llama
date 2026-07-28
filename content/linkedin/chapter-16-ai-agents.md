# Chapter 16 — I Gave the AI a Goal Instead of Instructions. It Wrote Its Own Plan.

Every month Sarah spends a day building the HR report. Headcount, new hires, open roles, attrition, policy changes — five different systems, one deadline.

So I stopped telling the AI what to do, and told it what I **wanted**:

> "Produce the complete monthly HR report for 2026-06. Gather whatever data you need using your tools first."

That's the entire instruction. No step list. No orchestration code.

---

## What came back

It called five tools, in an order I never specified, and wrote the report:

```
toolsInvoked : getHeadcount → getOpenPositions → getAttrition
               → getPolicyUpdates → getRecentHires
toolCallCount: 5
tookMillis   : 13937
```

Look closely at that order. It's **not** the order I declared the tools in. It's **not** the order they appear in the finished report. That's the model's own plan.

That's the line between an assistant and an **agent**: an assistant answers a question, an agent works out the steps.

---

## The code is almost anticlimactic

Chapter 10 gave the bot one tool and told it when to use it. An agent just gets *several* tools and no sequence:

```java
this.chatClient = builder
        .defaultSystem(SYSTEM_PROMPT)
        .defaultTools(hrData)      // five @Tool methods
        .build();
```

Spring AI runs the **Reason → Act → Observe** loop for you. The model asks for a tool, Spring executes it, feeds the result back, and the model decides what's next — repeating until it has enough to answer. You never write that loop.

---

## The part most agent demos skip

An agent that *works* is not the same as an agent you can *trust*, because you can't see what it did. The report looks equally confident whether the numbers came from your database or the model's imagination.

So every tool records its own invocation, and the endpoint returns the **trace** alongside the report:

```java
public record ReportResponse(
        String month,
        String report,
        List<String> toolsInvoked,   // ← what it actually chose to do
        Integer toolCallCount,
        Long tookMillis
) {}
```

Now "342 employees, +12 from last month" is verifiable — I can see `getHeadcount` was called, and compare against the raw data.

It also solves a testing problem. Report text is LLM prose, so a test can only check it isn't empty. But the trace is structured data — so the test can assert the thing that actually matters: **the agent chained multiple tools without being told which**.

---

## One thing I got wrong

I assumed there'd be a `maxToolCalls` setting to stop runaway loops. **There isn't one in Spring AI 2.0.** The loop ends when the model stops asking for tools.

That felt alarming until I realised you bound an agent differently:

- **The tools you register** — an agent can only do what you hand it. That's the real safety boundary.
- **Tool descriptions** — the actual steering wheel. Vague descriptions cause wrong or skipped calls.
- **The system prompt** — "use only values the tools return" curbs invention.
- **`temperature(0.0)`** — makes planning repeatable.

With agents, **observability is the safety feature**. You can't put a guardrail on reasoning you can't see.

---

## What's Next — Chapter 17: Evaluation

The bot can now plan and act on its own. Which raises an uncomfortable question: how do you know its answers are any *good*? Next we build an automated QA pipeline where a second AI call judges the first one's output.

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
- [Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.](https://www.linkedin.com/pulse/chapter-10-your-ai-bot-can-talk-now-let-take-action-balaji-chopparapu-f6rgc/?trackingId=Pe9bd8VwA8dBxQHP1T609w%3D%3D)
- [Chapter 11 — Exposing an Existing REST API as MCP Tools](https://www.linkedin.com/pulse/chapter-11-exposing-existing-rest-api-mcp-tools-balaji-chopparapu-ptegc/?trackingId=XPZnicIu%2BcI9hiU3DrfK1A%3D%3D)
- [Chapter 12 — Your AI Bot Just Learned to See](https://www.linkedin.com/pulse/chapter-12-your-ai-bot-just-learned-see-balaji-chopparapu-ooulc/)
- [Chapter 13 — Your AI Answers in 8 Seconds. Make It Feel Like 200ms.](https://www.linkedin.com/pulse/chapter-13-your-ai-answers-8-seconds-make-feel-like-200ms-chopparapu-0frsc/)
- [Chapter 14 — Your AI Can Read a Document and Answer in Exactly the Format You Ask For](https://www.linkedin.com/pulse/chapter-14-your-ai-can-read-document-answer-exactly-you-chopparapu-k8hac/)
- [Chapter 15 — When Keyword Search Fails, Try Semantic Search](https://www.linkedin.com/pulse/chapter-15-when-keyword-search-fails-try-semantic-balaji-chopparapu-fn92c/)
- **Chapter 16 — I Gave the AI a Goal Instead of Instructions. It Wrote Its Own Plan.** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #AIAgents #AgenticAI #ToolCalling #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #Llama
