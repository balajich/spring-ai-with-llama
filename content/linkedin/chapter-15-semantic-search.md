# Chapter 15 — Your Search Box Is Lying: It Found Nothing, But Four People Matched

Lisa needs a backend developer with cloud experience. She types exactly that into TechCorp's candidate search:

> **"backend developer with cloud experience"**

**Zero results.**

Not because nobody matches. Four people match. They just didn't use her words:

- Priya wrote *"JVM engineer"* and *"AWS Lambda"*
- Aisha wrote *"server-side developer"* and *"Azure Functions"*
- Elena wrote *"Java developer"* and *"Google Cloud Platform"*
- Sofia wrote *"SRE"* and *"Terraform"*

Every one of them is exactly who Lisa wanted. Keyword search matched *strings*. Lisa was asking about *meaning*.

---

## Two Kinds of Question, One Endpoint

Chapter 15 of "Spring AI with Llama" fixes this — and the design insight is the part worth stealing.

When you index a resume, you make a deliberate split:

```java
new Document(candidate.resume(), Map.of(   // ← embedded: searched by MEANING
        "candidateId", candidate.candidateId(),
        "seniority",   candidate.seniority(),   // ← metadata: matched EXACTLY
        "location",    candidate.location()
));
```

The **resume text** gets embedded into a vector. It answers the fuzzy question: *"who sounds like a cloud engineer?"*

The **metadata** stays literal. It answers the precise question: *"who is SENIOR and in London?"*

Then you ask both at once:

```java
SearchRequest.builder()
        .query("cloud infrastructure")                              // semantic
        .topK(10)
        .filterExpression("seniority == 'SENIOR' && location == 'London'")  // exact
        .build();
```

Fuzzy where you want recall, exact where you want control. That combination is what makes it usable rather than a demo.

---

## The Part Most Tutorials Get Wrong

Nearly every semantic search tutorial tells you to start with a similarity threshold of **0.75**.

Here are the real scores from the running app, for Lisa's query:

```
0.6327  Elena Rossi     "Java developer ... Google Cloud Platform"
0.6270  Aisha Khan      "Server-side developer ... Azure Functions"
0.6087  Liam O'Brien    "Mobile developer ... Swift"        ← honest noise
0.5924  Priya Sharma    "JVM engineer ... AWS Lambda"
```

Every genuine match lands between **0.59 and 0.67**. Set that recommended `0.75` threshold and your search returns **absolutely nothing** — and it looks like a bug, not a config choice.

Thresholds aren't universal. They depend on your embedding model, your text length, and how people phrase queries. So this chapter ships with the threshold at `0.0` and returns the raw scores, so you can *see* your distribution before you pick a number.

**Measure first. Then threshold.**

---

## Semantic Search Returns Degrees, Not Booleans

Notice Liam — the mobile developer — sitting at rank 3, above Priya.

That's not a defect I hid. It's what semantic search *is*: a ranking by proximity of meaning, not a yes/no filter. "Mobile developer" genuinely shares vocabulary-space with "backend developer" — both are software engineering roles.

Which is why `topK` and a human reviewer both still matter. The AI narrows 800 resumes to 4 worth reading. It doesn't decide who gets hired.

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
- Chapter 13 — Your AI Answers in 8 Seconds. Make It Feel Like 200ms. *(link coming soon)*
- Chapter 14 — Your AI Can Now Read the Contract So You Don't Have To *(link coming soon)*
- **Chapter 15 — Your Search Box Is Lying: It Found Nothing, But Four People Matched** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #SemanticSearch #VectorSearch #Embeddings #RAG #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #Llama
