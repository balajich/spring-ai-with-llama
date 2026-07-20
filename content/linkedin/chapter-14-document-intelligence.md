# Chapter 14 — Your AI Can Read a Document and Answer in Exactly the Format You Ask For

Sarah reads every employment contract before it reaches a new hire. Twenty minutes each, looking for the same handful of things: the probation period, the notice period, who owns the IP — and anything unusual that a lawyer should see.

> "Can the AI do a first pass for me?"

Chapter 14 of "Spring AI with Llama" builds it: upload the PDF, get back a summary and the exact fields you asked for. In seconds. All on your own laptop.

---

## Step 1 — Let the AI read the file

For thirteen chapters the bot only ever saw text you typed into a prompt. Real work lives in documents. Spring AI closes that gap with **document readers**:

```java
// PDF — one Document per page
List<Document> pages = new PagePdfDocumentReader(resource).get();

// Word, HTML, almost anything — via Apache Tika
List<Document> docs = new TikaDocumentReader(resource).get();
```

Two lines, and an uploaded file becomes text the model can reason over. No manual parsing. No format-specific libraries.

---

## Step 2 — Ask for the answer in your format

This is the part that matters.

A paragraph of prose is nice to read, but useless to your code. So instead of asking "summarise this contract", you define the shape you want and ask for that:

```java
public record ContractAnalysis(
        String summary,
        String probationPeriod,
        String noticePeriod,
        String ipOwnership,
        List<String> nonStandardClauses,
        Boolean requiresLegalReview
) {}
```

Feed it a real contract and out comes exactly that shape:

```json
{
  "summary": "Employment agreement between TechCorp Ltd and Rahul Menon...",
  "probationPeriod": "six (6) months",
  "noticePeriod": "three (3) months",
  "ipOwnership": "the Company",
  "nonStandardClauses": ["24-month worldwide non-compete", "unpaid on-call"],
  "requiresLegalReview": true
}
```

The AI didn't just summarise — it **read, understood, and reported back in the structure you specified**, including flagging the clauses that need a human.

And because it's structured, your code can act on it:

```java
if (report.requiresLegalReview()) {
    escalateToLegal(report);
}
```

That's the whole point. Prose stops at a human reader. A typed object feeds your systems — route it, store it, alert on it. It turns "read every contract" into "read only the ones the AI escalated."

---

## One design note: don't reach for RAG here

We built RAG back in Chapter 7, so the instinct is to chunk the contract, embed it, and retrieve the relevant bits.

Don't. RAG is for finding a few relevant pieces in a **large library**. Here you have **one document** and you want the model to read **all of it**. So you do the opposite — put the whole contract in the prompt. Same toolbox, different tool.

---

## Two things that make it reliable

Building this on Spring Boot 4.1 / Spring AI 2.0, two habits from Chapter 5 paid off immediately:

- **Use boxed types** (`Boolean`, not `boolean`). Spring AI 2.0 uses Jackson 3, which throws when the model omits a field and `null` lands on a primitive. A contract might not state every term — the type system has to allow that.
- **Name every field in the prompt and set `temperature(0.0)`.** Small local models otherwise improvise. Explicit guidance plus zero temperature makes extraction boringly reliable — exactly what you want for a legal first pass.

---

## What's Next — Chapter 15: Semantic Search

The bot can read documents now. Next it learns to find things by *meaning* — so "how much time off after a baby" finds the parental-leave policy even without the word "leave."

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
- **Chapter 14 — Your AI Can Read a Document and Answer in Exactly the Format You Ask For** ← you are here
- Chapter 15 — When Keyword Search Fails, Try Semantic Search *(link coming soon)*

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #DocumentAI #PDF #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #Llama
