# Running and Comparing Multiple AI Models in Spring Boot — No API Keys Needed

*Part 3 of the "Spring AI with Llama" series*

---

One of the first questions developers ask when building AI features is: **"Which model should I use?"**

The honest answer is — it depends. And the only way to know is to run them side by side and compare.

In Chapter 3 of my Spring AI with Llama series, that's exactly what we build: a single endpoint that sends the same question to two different models and returns both answers so you can see the difference yourself.

No OpenAI account. No cloud bills. Everything runs on your laptop.

---

## The Problem

Sarah, our HR Manager at TechCorp, has been using the SmartHR Assistant we built in chapters 1 and 2. It answers employee questions about leave, benefits, and onboarding policies — all powered by Llama running locally via Ollama.

Then a colleague tells her: *"Mistral is faster. Codellama is better for technical stuff."*

So she asks Dev (that's us):

> "Can we try different models without rewriting everything? And can we actually see how they compare?"

The answer is yes. And it's surprisingly simple.

---

## Switching Models Takes One Line

The default model is set in `application.yml`:

```yaml
spring:
  ai:
    ollama:
      chat:
        options:
          model: mistral
```

Restart the app. Every endpoint now runs on Mistral. Zero Java changes.

But config-level switching means restarting the app every time. What if you want to compare models on the fly?

---

## Switching Models Per-Request with OllamaChatOptions

Spring AI lets you override the model for a single call using `OllamaChatOptions`:

```java
private String askWithModel(String question, String model) {
    return chatClient
            .prompt()
            .system(SYSTEM_PROMPT)
            .user(question)
            .options(OllamaChatOptions.builder().model(model))
            .call()
            .content();
}
```

The key insight: **the model is just another option**. The same ChatClient, the same system prompt, the same code — different model.

---

## The Compare Endpoint

With that helper in place, the comparison endpoint writes itself:

```java
@PostMapping("/ask/compare")
public CompareResponse compare(@RequestBody CompareRequest request) {
    String answerA = askWithModel(request.question(), request.modelA());
    String answerB = askWithModel(request.question(), request.modelB());
    return new CompareResponse(
            request.question(),
            request.modelA(), answerA,
            request.modelB(), answerB
    );
}
```

Try it:

```bash
curl -s -X POST http://localhost:8080/hr/ask/compare \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is a good onboarding plan for a new software engineer?",
    "modelA": "llama3.2",
    "modelB": "mistral"
  }'
```

Response:

```json
{
  "question": "What is a good onboarding plan for a new software engineer?",
  "modelA": "llama3.2",
  "answerA": "A good onboarding plan includes...",
  "modelB": "mistral",
  "answerB": "For a new software engineer joining TechCorp, I recommend..."
}
```

Sarah can now read both answers and decide which model is better for each type of HR question. No guessing.

---

## Which Model Should You Use?

Here's a quick reference based on practical use:

| Model | RAM | Best for | Speed |
|-------|-----|----------|-------|
| llama3.2 (3B) | 4 GB | General Q&A | Fast |
| llama3.2:8b | 8 GB | Better reasoning | Medium |
| mistral | 5 GB | Instruction following | Fast |
| codellama | 4 GB | Code, technical docs | Fast |
| phi3:mini | 2 GB | Constrained environments | Very fast |
| gemma2 | 5 GB | Multi-language | Medium |

For HR policy questions, **llama3.2** and **mistral** are both strong. Mistral tends to be more concise. Llama3.2 gives slightly more context. The right choice depends on your users — which is exactly why the compare endpoint exists.

---

## What I Like About This Approach

Most AI tutorials hardcode a single model and move on. But in production, model choice matters — for latency, accuracy, RAM footprint, and the specific domain you're working in.

Building comparison into the app from chapter 3 means Sarah (and you) can make informed decisions based on actual output, not benchmarks written by the model vendors themselves.

And because everything runs locally via Ollama, you can do this experimentation for free — no tokens consumed, no API rate limits, no cost surprises.

---

## What's Next

Chapter 4 covers **Prompt Engineering** — using `PromptTemplate` to inject dynamic data like employee name, department, and role so the HR assistant gives personalised, TechCorp-branded responses instead of generic ones.

---

## The Series So Far

- **Chapter 1** — Hello, Spring AI: Build your first AI-powered endpoint with ChatClient and Ollama
- **Chapter 2** — Core Concepts: Tokens, messages, and controlling output with temperature and max tokens
- **Chapter 3** — Running and Comparing Multiple Models *(this post)*
- **Chapter 4** — Prompt Engineering *(coming next)*

---

The full code for this chapter is open source. Drop a comment if you have questions or want to see a specific model comparison.

*#SpringAI #Java #SpringBoot #Ollama #Llama #OpenSource #AI #LLM #BackendDevelopment*
