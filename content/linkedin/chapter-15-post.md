# Chapter 15 — Semantic Search · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-15-banner.png`** (1200×627).

---

🔍 **Your search box returned zero results. Four people actually matched.**

Lisa searched TechCorp's candidates for "backend developer with cloud experience". Nothing came back — not because nobody fits, but because nobody used her words. Priya wrote "JVM engineer" and "AWS Lambda". Aisha wrote "server-side developer" and "Azure Functions". All perfect fits, all invisible to keyword search.

Chapter 15 of "Spring AI with Llama" fixes it with semantic search: embed the resumes, embed the query, and rank by *meaning* instead of spelling. The design trick that makes it usable — embed the **resume text** (fuzzy: "who sounds like a cloud engineer?"), keep everything else as **metadata** (exact: "who is SENIOR and in London?"), and ask both in one call.

One warning from actually running it: every tutorial says start your similarity threshold at 0.75. My real matches scored **0.59–0.67**. That recommended threshold would have returned *nothing* — and looked like a bug. Measure your own distribution before you pick a number.

🔗 Read the full article: *(link coming soon)*

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java25 #Ollama #SemanticSearch #VectorSearch #Embeddings #LLM #LocalAI #JavaDeveloper
