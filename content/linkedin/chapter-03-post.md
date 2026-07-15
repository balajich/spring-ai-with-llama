# Chapter 3 — Comparing Models · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-03-banner.png`** (1200×627).

---

⚖️ **Is mistral really faster than llama3.2? Stop guessing — measure it.**

Chapter 3 of "Spring AI with Llama" shows how to run and compare multiple local models. Swap the model app-wide with one line of `application.yml`, or override it per request with `OllamaChatOptions` — no code rewrite either way.

Then we build a `/hr/ask/compare` endpoint that sends the same question to two models and returns both answers side by side. Same prompt, same system message; the only variable is the model.

That's the payoff of an abstraction layer: your code stops caring which model is behind it.

🔗 Read the full article: https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java #Ollama #Llama #Mistral #LLM #LocalAI
