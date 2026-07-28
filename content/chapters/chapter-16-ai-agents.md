# Chapter 16 — AI Agents: Autonomous Workflows and Tool Chaining

> **What you will build:** A monthly HR report agent — you give it a goal, and it decides for itself which data to gather, calls five different tools in an order it chooses, and writes the finished report.

---

## The Problem We Are Solving

Every month Sarah spends a day compiling the HR report: headcount changes, open roles, new hires, attrition, policy updates. The data lives in five different places.

> "Can the AI gather all this and write the report? I just want to trigger it and come back to something finished."

That is the jump from an assistant to an **agent**.

---

## What You Will Learn

- What separates an AI agent from a single AI call
- The Reason → Act → Observe loop, and who runs it
- How to build a multi-tool agent in Spring AI
- How to make an agent's decisions **observable** — and why that matters more than it sounds
- What actually controls an agent (it is not a config setting)

---

## A Single Call vs an Agent

Chapter 10 gave the bot one tool and told it when to use it. An agent is different: it receives a **goal** and works out the steps.

```
Goal: "Produce the monthly HR report for 2026-06"
        │
        ▼
The model decides:
  → getHeadcount("2026-06")
  → getOpenPositions("2026-06")
  → getAttrition("2026-06")
  → getPolicyUpdates("2026-06")
  → getRecentHires("2026-06")
  → I have enough. Write the report.
        │
        ▼
Finished report
```

**You provide the tools. The model provides the plan.**

---

## The Reason → Act → Observe Loop

```
REASON:  "I need headcount first"
ACT:     getHeadcount("2026-06")
OBSERVE: { total: 342, changeFromLastMonth: 12 }

REASON:  "Now the open roles"
ACT:     getOpenPositions("2026-06")
OBSERVE: [ "Staff Engineer (critical)", ... ]

… repeat …

REASON:  "That's enough to write the report"
DONE
```

The important detail: **Spring AI runs this loop for you.** When the model asks for a tool, Spring executes it, feeds the result back, and lets the model decide what to do next. You do not write the loop.

---

## The Toolbox

Five independent `@Tool` methods — in a real system, five different services:

```java
@Service
public class HrDataService {

    @Tool(description = "Get total employee headcount and the change from last month for a given month")
    public HrSnapshot.Headcount getHeadcount(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) {
        record("getHeadcount");
        return snapshot(month).headcount();
    }

    @Tool(description = "Get all currently open job positions for a given month")
    public List<String> getOpenPositions(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) { ... }

    // getRecentHires, getAttrition, getPolicyUpdates — same shape
}
```

Registering them is a single line — note that nothing here says *when* to call them:

```java
this.chatClient = builder
        .defaultSystem(SYSTEM_PROMPT)
        .defaultTools(hrData)     // all five become available
        .build();
```

---

## Give It a Goal, Not Instructions

The system prompt sets the **role and output format**. Deciding the steps is the agent's job:

```java
private static final String SYSTEM_PROMPT = """
        You are TechCorp's HR reporting agent. You are given a goal, not instructions.

        You have tools that return HR data for a month. Decide for yourself which
        tools you need, call them, and use ONLY the values they return — never
        invent numbers. When you have gathered enough data, write the report.
        ...
        """;
```

```java
String report = chatClient
        .prompt()
        .options(ChatOptions.builder().temperature(0.0))   // repeatable planning
        .user("""
              Produce the complete monthly HR report for %s.
              Gather whatever data you need using your tools first.
              """.formatted(month))
        .call()
        .content();
```

That is the whole agent. No orchestration code, no step list.

---

## Make the Agent Observable

Here is the part most agent tutorials skip. An agent that *works* is not the same as an agent you can *trust* — because you cannot see what it did.

So each tool records its own invocation, and the endpoint returns the trace next to the report:

```java
public record ReportResponse(
        String month,
        String report,
        List<String> toolsInvoked,   // ← what the agent actually chose to do
        Integer toolCallCount,
        Long tookMillis
) {}
```

A real run:

```json
{
  "toolsInvoked": ["getHeadcount","getOpenPositions","getAttrition","getPolicyUpdates","getRecentHires"],
  "toolCallCount": 5,
  "tookMillis": 13937
}
```

Look at that order. It is **neither** the order the tools are declared in **nor** the order they appear in the finished report. That is the model's own plan — and without the trace you would never know it existed.

This also solves a testing problem. The report is LLM prose, so you can only assert it is non-empty. But the trace is structured data, so you can assert the thing that actually matters: **that the agent chained multiple tools without being told which.**

---

## What Actually Controls an Agent

There is **no `maxToolCalls` setting** in Spring AI 2.0. The loop ends when the model stops asking for tools. You bound an agent by design instead:

| Lever | Effect |
|---|---|
| **Tool descriptions** | The main steering wheel — vague descriptions cause wrong or missed calls |
| **System prompt** | Role and output format; "use only values the tools return" curbs invention |
| **`temperature(0.0)`** | Makes planning repeatable |
| **The set of tools you register** | An agent can only do what you give it — your real safety boundary |
| **A recorded trace** | Not control, but you cannot debug what you cannot see |

That last row is the honest lesson of this chapter: with agents, **observability is the safety feature.**

---

## Try It

```bash
cd code/chapter-16-ai-agents
mvn spring-boot:run
```

```bash
curl -s -X POST http://localhost:8080/hr/report/generate \
  -H "Content-Type: application/json" \
  -d '{"month": "2026-06"}'
```

Real output (trimmed):

```
toolsInvoked : getHeadcount, getOpenPositions, getAttrition, getPolicyUpdates, getRecentHires
toolCallCount: 5

**2026-06 HR Report**
**Headcount**   Total employees: 342   Change from last month: +12
**New Hires**   Priya Sharma - Senior Engineer; Tom Baker - Data Scientist
```

`342` and `+12` came from the tools — the agent did not invent them.

Run the tests:

```bash
cd code/tests
./run-tests.sh chapter-16
```

---

## Summary

In this chapter you:

- Saw the difference between a single AI call and an autonomous agent
- Registered five tools and let the model plan its own sequence
- Learned that Spring AI runs the Reason → Act → Observe loop for you
- Made the agent's decisions observable with an execution trace
- Learned what really bounds an agent — tools, descriptions and prompt, not a config knob

---

## What's Next

In **Chapter 17**, we tackle evaluation — how do you know if your AI is actually giving good answers? We build an automated QA pipeline that uses a second AI call to judge the quality of the SmartHR bot's responses.

*Code for this chapter: [`code/chapter-16-ai-agents/`](../../code/chapter-16-ai-agents/)*
