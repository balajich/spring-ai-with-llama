# Chapter 13 — Streaming: Make 8 Seconds Feel Like 200ms · YouTube Description

> 📋 **Paste everything below the line into the YouTube description box.**
> Attach thumbnail: **`chapter-13-youtube-thumbnail.png`** (1280×720).
>
> ⚠️ YouTube does **not** render markdown — the block below is deliberately plain text
> with emoji only, so it pastes exactly as it looks. Timestamps are placeholders:
> adjust them to your real cut points before publishing (YouTube turns them into chapters).

---

```
📡 Spring AI with Llama #13 — Streaming: Make 8 Seconds Feel Like 200ms

Users stared at a spinner for 8-10 seconds, then the whole reply dropped in at once. It felt frozen - even though the model was producing the answer token by token the entire time.

We fix it by swapping .call() for .stream(). Your endpoint returns a Flux<String>, and each token streams to the browser the moment Llama generates it, over Server-Sent Events.

🎯 WHAT YOU'LL LEARN
• How token-by-token streaming works
• Spring AI's streaming API and Flux<String>
• Server-Sent Events and the browser's EventSource
• Handling errors mid-stream - and when NOT to stream

🔗 RESOURCES
💻 Source code (all chapters): https://github.com/balajich/spring-ai-with-llama
📝 Written notes / tutorial:   https://prompttoapps.com/tutorials/spring-ai-llama/chapter-13-streaming-api
🧠 Test yourself — quiz:       https://prompttoapps.com/quiz/#springai/ch13

📺 WATCH THE SERIES IN ORDER
▶ Series Introduction: https://youtu.be/RW9g99Uk_7w
▶ Chapter 1: https://youtu.be/FvLBKbXxrdk
▶ Chapter 2: https://youtu.be/JsAo7xYcaNk

🧰 TECH STACK
Spring Boot 4.1 · Spring AI 2.0 · Java 25 · Ollama · Llama 3.2
Built and tested on Java 25.0.3, Maven 3.9.16, Ollama 0.31.1.

⭐ If this helped, drop a like and subscribe for the rest of the series — and star the repo on GitHub.

⏱️ TIMESTAMPS
0:00 Intro - it feels broken
1:30 Blocking vs streaming
3:30 Flux<String> explained
6:00 Server-Sent Events
9:00 The browser EventSource demo
12:00 Errors mid-stream
14:30 Recap + what's next

#SpringAI #SpringBoot #Java #Ollama #Llama #LLM #LocalAI #Streaming #SSE #ReactiveProgramming
```
