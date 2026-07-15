# Chapter 5 — Structured Output · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-05-banner.png`** (1200×627).

---

🧩 **Stop parsing AI responses by hand. Ask for JSON.**

Chapter 5 of "Spring AI with Llama" turns free-text answers into typed Java records with `BeanOutputConverter` — paste in a raw résumé, get back a `ResumeProfile` object with name, email, skills, and years of experience.

Two hard-won lessons in here: use **boxed types** (`Integer`, not `int`) because Spring AI 2.0's Jackson 3 throws on `null` → primitive, and **name every field in the prompt** with `temperature(0.0)`. Skip either and a small local model will happily hand you garbage.

Prose terminates at a human. A typed object feeds your database.

🔗 Read the full article: https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java #Ollama #JSON #LLM #LocalAI #StructuredOutput
