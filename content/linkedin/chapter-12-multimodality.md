# Chapter 12 — Your AI Bot Just Learned to See

For eleven chapters, the SmartHR Assistant has lived in a world made entirely of text. It can chat, remember, retrieve policies, book interviews through tools, and share those tools with other agents over MCP. But show it a photo, and it's blind.

Then TechCorp's office manager came to Sarah with a very analog problem:

> "Employees keep spotting hazards — a trailing cable, a blocked fire exit, a broken chair. Nobody ever files the safety report. The form has eleven fields."

Sarah's answer: skip the form. Take a photo, and let the AI fill it in.

---

## Multimodality: One Prompt, Two Kinds of Input

A multimodal model accepts more than text. You hand it an image *and* a question about that image in the same prompt, and it reasons over both together — "what's in this photo, and is it dangerous?"

The catch: your everyday model can't do this. `llama3.2` is text-only. You need a vision-capable model, and Ollama has several that run entirely on your laptop:

```bash
ollama pull llava            # the most popular local vision model
ollama pull llama3.2-vision  # Llama 3.2 with vision
ollama pull moondream        # lightweight option
```

That last point matters more than it sounds for an HR use case: photos of your office, your equipment, and occasionally your employees **never leave your machine**. No cloud vision API, no data processing agreement, no image retention policy to negotiate.

---

## Sending an Image with Spring AI

Spring AI treats an image as `Media` attached to the user message — the text prompt and the photo travel together:

```java
Media media = Media.builder()
        .mimeType(MimeType.valueOf(image.getContentType()))
        .data(new ByteArrayResource(image.getBytes()))
        .build();

String analysis = chatClient
        .prompt()
        .user(u -> u
                .text("""
                      Analyse this workplace photo for safety hazards.
                      Location: {location}

                      Identify:
                      1. Any visible hazards
                      2. Risk level (LOW / MEDIUM / HIGH)
                      3. Recommended immediate action
                      """)
                .param("location", location)
                .media(media))
        .call()
        .content();
```

That's the entire vision integration. No base64 juggling, no separate image API — `.media(media)` on the user message, and Spring AI handles the encoding for Ollama.

---

## The Real Trick: Vision + Structured Output

A paragraph describing the hazard is nice. A typed object you can store in a database and route to facilities is what actually replaces the eleven-field form.

This is where the chapters compound. Chapter 5 gave us `BeanOutputConverter` — ask the model for JSON matching a Java record. Combine it with vision and the endpoint returns this:

```java
public record SafetyReport(
        String location,
        String hazardDescription,
        String riskLevel,               // LOW / MEDIUM / HIGH
        String recommendedAction,
        boolean requiresIncidentReport
) {}
```

One multipart request in — photo plus location — and out comes:

```json
{
  "location": "Floor 3, near the printer",
  "hazardDescription": "A power cable is trailing across the walkway.",
  "riskLevel": "MEDIUM",
  "recommendedAction": "Tape down or reroute the cable away from the walkway.",
  "requiresIncidentReport": true
}
```

The employee's job went from "fill in eleven fields" to "take a photo." The report is filed before they've put their phone away.

---

## What to Watch Out For

- **Model choice is not optional.** Send an image to a text-only model and it will politely reason about an image it cannot see. Use `llava` or `llama3.2-vision`.
- **Keep images small.** Under 5MB keeps local inference reasonably fast; enforce it with Spring's multipart limits.
- **Trust, but verify.** Vision models are good, not perfect. Anything the model marks HIGH risk should land in front of a human before action is taken — the AI drafts the report, it doesn't own the decision.

---

## What's Next — Chapter 13: Streaming

The bot can talk, remember, retrieve, act, share its tools, and now see. But every response still arrives as one big block after an awkward silence. Next, we stream tokens as they're generated — the live-typing experience users expect from modern AI interfaces.

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
- **Chapter 12 — Your AI Bot Just Learned to See** ← you are here

Full source code for all chapters is on GitHub — drop a star if you find it useful!
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

---

*Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama — runs entirely on your laptop, no paid APIs.*

#SpringAI #SpringBoot #Java25 #Ollama #Multimodal #VisionAI #LLaVA #LLM #GenerativeAI #AIEngineering #LocalAI #JavaDeveloper #SpringFramework #Llama
