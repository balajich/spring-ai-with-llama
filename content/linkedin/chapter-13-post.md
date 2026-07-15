# Chapter 13 — Streaming API · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-13-banner.png`** (1200×627).

---

📡 **Your AI answers in 8 seconds. Make it feel like 200ms.**

The SmartHR bot gave good answers — but users stared at a spinner for 8–10 seconds, then the whole reply dropped in at once. It felt frozen.

Chapter 13 of "Spring AI with Llama" fixes it with an almost embarrassingly small change: swap `.call()` for `.stream()`. Your endpoint now returns a `Flux<String>`, and each token streams to the browser the moment Llama generates it — over Server-Sent Events, consumed with the built-in `EventSource` in ~6 lines of JavaScript.

The insight: streaming doesn't make generation faster. It makes the system *honest* about the progress it's already making.

🔗 Read the full article: *(link coming soon)*

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java #Ollama #Streaming #SSE #LLM #LocalAI
