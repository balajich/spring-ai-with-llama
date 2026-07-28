# Chapter 16 — AI Agents: Autonomous Workflows and Tool Chaining · YouTube Description

> 📋 **Paste everything below the line into the YouTube description box.**
> Attach thumbnail: **`chapter-16-youtube-thumbnail.png`** (1280×720).
>
> ⚠️ YouTube does **not** render markdown — the block below is deliberately plain text
> with emoji only, so it pastes exactly as it looks. Timestamps are placeholders:
> adjust them to your real cut points before publishing (YouTube turns them into chapters).

---

```
🤖 Spring AI with Llama #16 — AI Agents: Give It a Goal, Not Instructions

Every month Sarah spends a day compiling the HR report from five different systems. So we stop telling the AI what to do, and tell it what we want: "Produce the monthly HR report for 2026-06. Gather whatever data you need using your tools first."

That's the whole instruction. No step list, no orchestration code. The agent calls five tools in an order it chooses, then writes the report — and we make it show its working, so you can see exactly what it decided to do.

🎯 WHAT YOU'LL LEARN
• What separates an AI agent from a single AI call
• The Reason → Act → Observe loop — and why you never write it yourself
• Registering multiple @Tool methods and letting the model plan the sequence
• Making an agent observable with an execution trace (the part most demos skip)
• What actually bounds an agent — there is no maxToolCalls setting in Spring AI 2.0

🔗 RESOURCES
💻 Source code (all chapters): https://github.com/balajich/spring-ai-with-llama
📝 Written notes / tutorial:   https://prompttoapps.com/tutorials/spring-ai-llama/chapter-16-ai-agents
🧠 Test yourself — quiz:       https://prompttoapps.com/quiz/#springai/ch16

📺 WATCH THE SERIES IN ORDER
▶ Series Introduction: https://youtu.be/RW9g99Uk_7w
▶ Chapter 1: https://youtu.be/FvLBKbXxrdk
▶ Chapter 2: https://youtu.be/JsAo7xYcaNk

🧰 TECH STACK
Spring Boot 4.1 · Spring AI 2.0 · Java 25 · Ollama · Llama 3.2
Built and tested on Java 25.0.3, Maven 3.9.16, Ollama 0.31.1.

⭐ If this helped, drop a like and subscribe for the rest of the series — and star the repo on GitHub.

⏱️ TIMESTAMPS
0:00 Intro — a day of work, every month
1:30 Assistant vs agent: goal, not instructions
3:30 The five @Tool methods
6:00 Registering them — one line, no sequence
8:00 Reason → Act → Observe (Spring AI runs the loop)
10:30 Running it — the agent picks its own order
13:00 Making the agent observable: the execution trace
15:30 What actually controls an agent
17:30 Recap + what's next

#SpringAI #SpringBoot #Java #Ollama #Llama #LLM #LocalAI #AIAgents #AgenticAI #ToolCalling
```
