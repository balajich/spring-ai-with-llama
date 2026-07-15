# Stop Parsing AI Responses by Hand. Ask for JSON Instead.

*Part 5 of the "Spring AI with Llama" series*

---

Lisa, TechCorp's Hiring Manager, receives 50 resumes a week. Every one of them is formatted differently — some are PDFs converted to plain text, some are copy-pasted from LinkedIn, some are just a wall of unstructured paragraphs.

She asks Dev: **"Can the AI read a resume and give me the key fields in a consistent format? I want to plug it straight into our HR system — not manually parse a paragraph."**

That's exactly what Chapter 5 builds.

---

## The Problem with `.content()`

In the previous chapters, every AI call ended with `.call().content()` — which returns a plain string. For conversational Q&A that's fine. But when you need to store data, pass it downstream, or display it in a UI, you don't want this:

```
"The candidate's name is Priya Sharma. She has 5 years of experience
in Java and Spring Boot. She studied Computer Science at IIT Delhi..."
```

You want this:

```json
{
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "skills": ["Java", "Spring Boot", "Kubernetes"],
  "yearsOfExperience": 5,
  "currentRole": "Senior Engineer at Infosys",
  "education": "B.Tech Computer Science, IIT Delhi"
}
```

Which maps directly to a Java record — no string parsing, no regex, no fragile manual extraction.

---

## How It Works

The key is `BeanOutputConverter`. Here is the full picture:

**Step 1 — Define your output as a Java record**

```java
public record ResumeProfile(
        String name,
        String email,
        List<String> skills,
        int yearsOfExperience,
        String currentRole,
        String education
) {}
```

**Step 2 — `BeanOutputConverter` generates a JSON schema from the record**

Spring AI inspects `ResumeProfile.class` and produces a JSON schema describing every field and its type. This schema is injected into the prompt via a `{format}` placeholder — so the model is explicitly told: *return JSON, not prose*.

**Step 3 — The model returns a JSON string matching the schema**

**Step 4 — `converter.convert()` deserialises it into the Java record**

It is essentially `ObjectMapper.readValue(response, ResumeProfile.class)` under the hood — Jackson doing the final step.

```
Resume text  →  Prompt + JSON schema ({format})
                        ↓
               Ollama returns JSON string
                        ↓
               BeanOutputConverter  →  ResumeProfile record
```

---

## The Code

```java
@PostMapping("/hr/resume/parse")
public ResumeProfile parseResume(@RequestBody ResumeParseRequest request) {
    BeanOutputConverter<ResumeProfile> converter =
            new BeanOutputConverter<>(ResumeProfile.class);

    String response = chatClient
            .prompt()
            .user(u -> u.text("""
                    Extract information from the resume below and return it as a \
                    plain JSON object containing only the field values.

                    Important:
                    - Return a flat JSON object with the actual values, NOT a JSON schema.
                    - Do NOT wrap the result in a "properties" key.
                    - Return ONLY the JSON object, no explanation or extra text.

                    Resume:
                    {resumeText}

                    {format}
                    """)
                    .param("resumeText", request.resumeText())
                    .param("format", converter.getFormat()))
            .call()
            .content();

    try {
        return converter.convert(response);
    } catch (Exception e) {
        throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Could not parse resume. Try providing more structured text.");
    }
}
```

One thing worth calling out — the explicit instructions in the prompt telling the model **not** to return a JSON schema wrapper. Smaller local models like `llama3.2` can confuse the schema format instruction and return the actual data *inside* the `properties` key. A few clear negative instructions fix that reliably.

---

## Try It

```bash
curl -s -X POST http://localhost:8080/hr/resume/parse \
  -H "Content-Type: application/json" \
  -d '{
    "resumeText": "Priya Sharma | priya@example.com\n5 years Java, Spring Boot, AWS\nSenior Engineer at Infosys\nB.Tech CS IIT Delhi 2018"
  }'
```

Response:

```json
{
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "skills": ["Java", "Spring Boot", "AWS"],
  "yearsOfExperience": 5,
  "currentRole": "Senior Engineer at Infosys",
  "education": "B.Tech CS IIT Delhi 2018"
}
```

Lisa now gets a typed Java object she can pass straight to the HR system. No parsing code. No regex. No brittle string splitting.

---

## One Practical Tip — Set Temperature to 0.0

Structured output tasks benefit from a deterministic model. Set temperature to `0.0` in `application.yml`:

```yaml
spring:
  ai:
    ollama:
      chat:
        options:
          temperature: 0.0
```

Higher temperatures introduce randomness which can cause the model to deviate from the schema. For extraction tasks you want consistency, not creativity.

---

## What's Next

Chapter 6 gives the SmartHR bot a **memory** — using `InMemoryChatMemory` so Raj can have a multi-turn onboarding conversation where the AI remembers what was said earlier in the session. No more repeating yourself to the bot.

---

## The Series So Far

- [**Chapter 1** — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [**Chapter 2** — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [**Chapter 3** — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- [**Chapter 4** — Stop Hardcoding Prompts. Use Templates Instead.](https://www.linkedin.com/pulse/chapter-4-stop-hardcoding-prompts-use-templates-balaji-chopparapu-djjmc/?trackingId=rMqGBhWrk30541aP0wIElA%3D%3D)
- **Chapter 5** — Stop Parsing AI Responses by Hand. Ask for JSON Instead. *(this post)*

---

Full source code for all chapters is on GitHub — if you find it useful, please drop a ⭐ it helps others discover the series:
[github.com/balajich/spring-ai-with-llama](https://github.com/balajich/spring-ai-with-llama)

Drop a comment if you have questions or want to see a specific structured output pattern covered.

*#SpringAI #Java #SpringBoot #Ollama #Llama #StructuredOutput #OpenSource #AI #LLM #BackendDevelopment*
