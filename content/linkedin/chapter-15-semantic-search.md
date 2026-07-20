# Chapter 15 — When Keyword Search Fails, Try Semantic Search

Lisa needs a backend developer with cloud experience. She types exactly that into TechCorp's candidate search:

> **"backend developer with cloud experience"**

**Zero results.**

Not because nobody matches — four people do. They just wrote it differently: "JVM engineer" and "AWS Lambda", "server-side developer" and "Azure Functions", "Java developer" and "Google Cloud Platform".

Keyword search looks for the exact words. Lisa was asking about the **meaning**.

---

## The Fix: Search by Meaning

Chapter 15 of "Spring AI with Llama" solves it with semantic search. The idea is simple:

1. Turn every resume into a vector (a list of numbers that captures its meaning).
2. Turn the search query into a vector the same way.
3. Return the resumes whose vectors sit closest to the query.

Because it compares *meaning* rather than *spelling*, it finds Priya and Aisha even though their CVs never use the words Lisa typed. In Spring AI it's a few lines:

```java
List<Document> matches = vectorStore.similaritySearch(
        SearchRequest.builder()
                .query("backend developer with cloud experience")
                .topK(4)
                .build());
```

Run it, and the four hidden candidates come back — ranked by how close their meaning is.

A keyword search would have returned **zero** of them.

---

## Two Honest Notes From Building It

**It ranks, it doesn't filter.** Semantic search returns *degrees* of similarity, not yes/no. A mobile developer might show up near the bottom of a "backend developer" search — both are software roles, so they're related. That's normal. It narrows the pile to a few worth reading; a human still decides.

**Don't blindly copy a threshold.** Tutorials often say "start at 0.75". When I ran mine, the genuine matches scored 0.59–0.67 — that recommended threshold would have returned *nothing* and looked like a bug. Measure your own scores first, then pick a cutoff.

---

## What's Next — Chapter 16: AI Agents

The bot can talk, remember, retrieve, act, see, stream, read documents, and now search by meaning. Next it starts working on its own: an autonomous agent that plans its own steps, chains multiple tools, and produces a monthly HR report without being prompted through it.

---

## The Series So Far

- [Chapter 1 — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [Chapter 2 — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [Chapter 3 — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [Chapter 4 — Stop Hardcoding Prompts. Use Templates.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- [Chapter 5 — Stop Parsing AI Responses by Hand. Ask for JSON.](https://www.linkedin.com/pulse/chapter-5-stop-parsing-ai-responses-hand-ask-json-balaji-chopparapu-jrs4c/?trackingId=C0Y5QL8wGeEfj%2FTvrpxmuA%3D%3D)
- [Chapter 6 — Your AI Bot Has Goldfish Memory. Here's How to Fix It.](https://www.linkedin.com/pulse/chapter-6-your-ai-bot-has-goldfish-memory-heres-how-fix-chopparapu-ck0hc/?trackingId=m0DOW59LgPkGihFvJDxZBA%3D%3D)
- [Chapter 7 — Your AI Is Guessing. RAG Makes It Read the Manual.](https://www.linkedin.com/pulse/chapter-7-your-ai-guessing-rag-makes-read-manual-balaji-chopparapu-ararc/?trackingId=4L5yf1FX4CspOTawv4ddmw%3D%3D)
- [Chapter 8 — Your Vector Store Shouldn't Forget Everything When You Restart](https://www.linkedin.com/pulse/chapter-8-your-vector-store-shouldnt-forget-when-you-chopparapu-fbd2c/?trackingId=sJN7GdS8osG3cLtvf7i3Bg%3D%3D)
- [Chapter 9 — Neo4j Graph RAG: When Vector Search Isn't Enough](https://www.linkedin.com/pulse/chapter-9-neo4j-graph-rag-when-vector-search-isnt-balaji-chopparapu-xiutc/?trackingId=ubMaVVYy7Z70TynlVV8IeA%3D%3D)
- [Chapter 10 — Your AI Bot Can Talk. Now Let It Take Action.](https://www.linkedin.com/pulse/chapter-10-your-ai-bot-can-talk-now-let-take-action-balaji-chopparapu-f6rgc/?trackingId=Pe9bd8VwA8dBxQHP1T609w%3D%3D)
- [Chapter 11 — Exposing an Existing REST API as MCP Tools](https://www.linkedin.com/pulse/chapter-11-exposing-existing-rest-api-mcp-tools-balaji-chopparapu-ptegc/?trackingId=XPZnicIu%2BcI9hiU3DrfK1A%3D%3D)
- [Chapter 12 — Your AI Bot Just Learned to See](https://www.linkedin.com/pulse/chapter-12-your-ai-bot-just-learned-see-balaji-chopparapu-ooulc/)
- [Chapter 13 — Your AI Answers in 8 Seconds. Make It Feel Like 200ms.](https://www.linkedin.com/pulse/chapter-13-your-ai-answers-8-seconds-make-feel-like-200ms-chopparapu-0frsc/)
- [Chapter 14 — Your AI Can Read a Document and Answer in Exactly the Format You Ask For](https://www.linkedin.com/pulse/chapter-14-your-ai-can-read-document-answer-exactly-you-chopparapu-k8hac/)
- **Chapter 15 — When Keyword Search Fails, Try Semantic Search** ← you are here
- Chapter 16 — I Gave the AI a Goal Instead of Instructions. It Wrote Its Own Plan. *(link coming soon)*

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #SemanticSearch #VectorSearch #Embeddings #RAG #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #Llama
