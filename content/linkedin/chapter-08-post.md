# Chapter 8 — PgVector Store · LinkedIn Post

> Short promo post to accompany the article. Paste into LinkedIn and attach **`chapter-08-banner.png`** (1200×627).

---

🗄️ **Your vector store shouldn't forget everything when you restart.**

Chapter 7's in-memory store was perfect for learning and useless in production — every restart re-embeds every document. Chapter 8 of "Spring AI with Llama" swaps it for **PostgreSQL + pgvector**.

The best part: the controller, the advisor, and the endpoints don't change at all. One bean swap behind Spring AI's `VectorStore` interface and you get durable embeddings, an HNSW index for O(log N) search, and idempotent ingestion that doesn't duplicate on restart.

That's the whole point of an abstraction: swap the backend, keep the code.

🔗 Read the full article: https://www.linkedin.com/pulse/chapter-8-your-vector-store-shouldnt-forget-when-you-chopparapu-fbd2c/?trackingId=sJN7GdS8osG3cLtvf7i3Bg%3D%3D

💻 Code: https://github.com/balajich/spring-ai-with-llama

#SpringAI #SpringBoot #Java #PostgreSQL #pgvector #RAG #LLM #LocalAI
