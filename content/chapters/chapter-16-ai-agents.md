# Chapter 16 — AI Agents: Autonomous Workflows and Tool Chaining

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** A monthly HR report agent — Dev triggers it once and it autonomously gathers headcount data, open positions, recent hires, policy updates, and produces a formatted HR summary report without further instruction.

---

## The Problem We Are Solving

Every month, Sarah spends a full day compiling the HR report: headcount changes, open roles, new hires, attrition, training completions. The data lives in five different systems.

> "Can the AI gather all this data and write the report for me? I just want to trigger it and come back to a finished report."

This is an AI agent — it plans, acts, observes results, and repeats until the task is complete.

---

## What You Will Learn

- What an AI agent is vs a simple AI call
- The ReAct loop: Reason → Act → Observe → Repeat
- How to build a multi-tool agent in Spring AI
- How to chain multiple tool calls across a single request
- How to give the agent a goal and let it plan

---

## What Is an AI Agent?

A single AI call takes one input and produces one output. An agent takes a **goal** and figures out the steps itself:

```
Goal: "Generate the monthly HR report for May 2025"
        │
        ▼
Llama plans:
  Step 1 → call getHeadcount("2025-05")
  Step 2 → call getOpenPositions()
  Step 3 → call getRecentHires("2025-05")
  Step 4 → call getAttritionRate("2025-05")
  Step 5 → call getPolicyUpdates("2025-05")
  Step 6 → compile all results into a formatted report
        │
        ▼
Returns completed HR report
```

The AI decides the steps. You provide the tools.

---

## The ReAct Loop

```
REASON:  "I need headcount data first"
ACT:     call getHeadcount("2025-05")
OBSERVE: { "total": 342, "change": "+12 from last month" }

REASON:  "Now I need open positions"
ACT:     call getOpenPositions()
OBSERVE: { "count": 18, "critical": ["Staff Engineer", "Data Scientist"] }

REASON:  "I have enough data to write the report now"
ACT:     compile report
OBSERVE: report text

DONE
```

Spring AI handles this loop automatically when tools are registered.

---

## Registering Agent Tools

```java
@Service
public class HrDataService {

    @Tool(description = "Get total employee headcount and change for a given month")
    public HeadcountData getHeadcount(
            @ToolParam(description = "Month in yyyy-MM format") String month) {
        return hrDatabase.getHeadcount(month);
    }

    @Tool(description = "Get all currently open job positions and their urgency")
    public List<OpenPosition> getOpenPositions() {
        return hrDatabase.getOpenPositions();
    }

    @Tool(description = "Get list of employees who joined in a given month")
    public List<NewHire> getRecentHires(
            @ToolParam(description = "Month in yyyy-MM format") String month) {
        return hrDatabase.getRecentHires(month);
    }

    @Tool(description = "Get attrition rate and departures for a given month")
    public AttritionData getAttritionRate(
            @ToolParam(description = "Month in yyyy-MM format") String month) {
        return hrDatabase.getAttritionRate(month);
    }
}
```

---

## What You Will Build — Monthly Report Agent

```java
@PostMapping("/hr/report/generate")
public String generateMonthlyReport(@RequestParam String month) {
    return chatClient
            .prompt()
            .user("Generate a complete HR monthly report for " + month + ". " +
                  "Gather all relevant data using the available tools and compile " +
                  "a professional report with sections for headcount, new hires, " +
                  "open positions, attrition, and a summary.")
            .call()
            .content();
}
```

The agent calls all tools it needs, in whatever order it decides, and returns the completed report.

---

## Controlling Agent Behaviour

| Option | Purpose |
|--------|---------|
| `maxToolCalls` | Prevent infinite loops |
| System prompt | Define the agent's persona and output format |
| Tool descriptions | Guide which tools the agent selects |
| `temperature=0.0` | More deterministic planning |

---

## Summary

In this chapter you will:

- Understand the difference between a single AI call and an autonomous agent
- Build a multi-tool agent using Spring AI's tool registration
- Implement the ReAct loop (Reason, Act, Observe)
- Build a monthly HR report agent that gathers data from multiple sources

---

## What's Next

In **Chapter 17**, we tackle evaluation — how do you know if your AI is giving good answers? We build an automated QA pipeline that uses another AI call to judge the quality of the SmartHR bot's responses.

*Code for this chapter: [`code/chapter-16-ai-agents/`](../../code/chapter-16-ai-agents/)*
