# Chapter 8 — Persistent Vector Store with PgVector · YouTube Description

> 📋 **Paste everything below the line into the YouTube description box.**
> Attach thumbnail: **`chapter-08-youtube-thumbnail.png`** (1280×720).
>
> ⚠️ YouTube does **not** render markdown — the block below is deliberately plain text
> with emoji only, so it pastes exactly as it looks. Timestamps are placeholders:
> adjust them to your real cut points before publishing (YouTube turns them into chapters).

---

```
🗄️ Spring AI with Llama #8 — Persistent Vector Store with PgVector

Chapter 7's in-memory store was perfect for learning and useless in production - every restart re-embeds every document. We swap it for PostgreSQL + pgvector.

The best part: the controller, the advisor and the endpoints don't change at all. One bean swap behind Spring AI's VectorStore interface.

🎯 WHAT YOU'LL LEARN
• Why in-memory vector stores don't survive production
• PostgreSQL + pgvector with Docker
• HNSW indexing for fast similarity search
• Idempotent ingestion - no duplicates on restart

🔗 RESOURCES
💻 Source code (all chapters): https://github.com/balajich/spring-ai-with-llama
📝 Written notes / tutorial:   https://prompttoapps.com/tutorials/spring-ai-llama/chapter-08-pgvector
🧠 Test yourself — quiz:       https://prompttoapps.com/quiz/#springai/ch08

📺 WATCH THE SERIES IN ORDER
▶ Series Introduction: https://youtu.be/RW9g99Uk_7w
▶ Chapter 1: https://youtu.be/FvLBKbXxrdk
▶ Chapter 2: https://youtu.be/JsAo7xYcaNk

🧰 TECH STACK
Spring Boot 4.1 · Spring AI 2.0 · Java 25 · Ollama · Llama 3.2
Built and tested on Java 25.0.3, Maven 3.9.16, Ollama 0.31.1.

⭐ If this helped, drop a like and subscribe for the rest of the series — and star the repo on GitHub.

⏱️ TIMESTAMPS
0:00 Intro - the restart problem
1:30 Docker + pgvector setup
4:00 The one-bean swap
7:00 HNSW index
10:00 Idempotent ingestion
13:00 Running it
15:30 Recap + what's next

#SpringAI #SpringBoot #Java #Ollama #Llama #LLM #LocalAI #PostgreSQL #pgvector #RAG
```
