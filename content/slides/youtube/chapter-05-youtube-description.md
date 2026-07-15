# Chapter 5 — Structured Output: Ask for JSON, Not Text · YouTube Description

> 📋 **Paste everything below the line into the YouTube description box.**
> Attach thumbnail: **`chapter-05-youtube-thumbnail.png`** (1280×720).
>
> ⚠️ YouTube does **not** render markdown — the block below is deliberately plain text
> with emoji only, so it pastes exactly as it looks. Timestamps are placeholders:
> adjust them to your real cut points before publishing (YouTube turns them into chapters).

---

```
🧩 Spring AI with Llama #5 — Structured Output: Ask for JSON, Not Text

Stop parsing AI responses by hand. We use BeanOutputConverter to turn free-text answers into typed Java records - paste in a raw resume, get back a ResumeProfile object with name, email, skills and years of experience.

Two hard-won lessons: use boxed types (Integer, not int) because Spring AI 2.0's Jackson 3 throws on null-to-primitive, and name every field in the prompt with temperature(0.0).

🎯 WHAT YOU'LL LEARN
• Using BeanOutputConverter to get typed objects
• Why boxed types matter with Jackson 3
• Why temperature(0.0) + explicit field guidance makes extraction reliable
• Building a resume parser endpoint

🔗 RESOURCES
💻 Source code (all chapters): https://github.com/balajich/spring-ai-with-llama
📝 Written notes / tutorial:   https://prompttoapps.com/tutorials/spring-ai-llama/chapter-05-structured-output
🧠 Test yourself — quiz:       https://prompttoapps.com/quiz/#springai/ch05

📺 WATCH THE SERIES IN ORDER
▶ Series Introduction: https://youtu.be/RW9g99Uk_7w
▶ Chapter 1: https://youtu.be/FvLBKbXxrdk
▶ Chapter 2: https://youtu.be/JsAo7xYcaNk

🧰 TECH STACK
Spring Boot 4.1 · Spring AI 2.0 · Java 25 · Ollama · Llama 3.2
Built and tested on Java 25.0.3, Maven 3.9.16, Ollama 0.31.1.

⭐ If this helped, drop a like and subscribe for the rest of the series — and star the repo on GitHub.

⏱️ TIMESTAMPS
0:00 Intro - parsing AI text by hand is painful
1:30 BeanOutputConverter
4:00 The ResumeProfile record
7:00 Making it reliable - temperature & field guidance
10:30 The Jackson 3 gotcha
13:00 Running it
15:30 Recap + what's next

#SpringAI #SpringBoot #Java #Ollama #Llama #LLM #LocalAI #JSON #StructuredOutput
```
