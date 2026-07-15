# Chapter 14 — Document Intelligence · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-14-banner.png`** (1200×627).

---

📄 **Sarah spends 20 minutes reading every contract for red flags. Now the AI does the first pass.**

Chapter 14 of "Spring AI with Llama" teaches the bot to read: upload an employment contract PDF and get back a structured review — probation period, notice period, IP ownership, and any non-standard clauses a lawyer should see.

The design decision that matters: this is **direct injection, not RAG**. RAG finds the relevant bits in a big library; contract review means reading one document completely. Knowing which tool fits the job is half of building good AI systems.

And the output isn't prose — it's a typed record with `requiresLegalReview: true`. That's what turns "read every contract" into "read only the ones the AI escalated".

🔗 Read the full article: *(link coming soon)*

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java #Ollama #DocumentAI #PDF #LLM #LocalAI
