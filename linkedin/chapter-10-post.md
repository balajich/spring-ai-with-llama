# Chapter 10 — Function Calling · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-10-banner.png`** (1200×627).

---

🛠️ **Your AI bot can talk. Now let it take action.**

Until now the assistant could only *describe* things. Chapter 10 of "Spring AI with Llama" gives it hands: annotate a plain Java method with `@Tool`, register it with `defaultTools()`, and the model can call your real code mid-conversation.

Now "check if Tuesday 2pm is free, and book it if so" actually checks the calendar and books the slot — the LLM decides *when* to call, Spring AI handles the invocation, and the result flows back into the conversation.

One lesson worth internalising: the model only knows what your `@Tool` description tells it. Vague description, wrong tool call.

🔗 Read the full article: https://www.linkedin.com/pulse/chapter-10-your-ai-bot-can-talk-now-let-take-action-balaji-chopparapu-f6rgc/?trackingId=Pe9bd8VwA8dBxQHP1T609w%3D%3D

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java #Ollama #FunctionCalling #ToolUse #LLM #LocalAI
