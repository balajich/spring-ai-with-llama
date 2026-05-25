# Chapter 3 — Connecting to Llama: Ollama Config and Model Switching

> **What you will build:** A `/hr/ask/compare` endpoint that sends the same question to two different models and returns both answers side-by-side — so Sarah can see which model performs better for HR queries.

---

## The Problem We Are Solving

Sarah has heard that there are other AI models besides Llama. A colleague told her that `mistral` is faster, and `codellama` is better at technical questions. She asks Dev:

> "Can we try different models without rewriting the whole app? And can we see how they compare?"

The answer is yes — and it only takes one line of config.

---

## What You Will Learn

- How Ollama manages multiple models on your machine
- How to switch models via `application.yml` (zero code changes)
- How to switch models **per-request** using `OllamaOptions`
- How to build a model comparison endpoint
- Which models work best for which HR tasks

---

## Ollama Model Management

```bash
# Pull models
ollama pull llama3.2       # default — good all-rounder
ollama pull mistral        # fast, strong reasoning
ollama pull codellama      # optimised for code
ollama pull phi3:mini      # tiny — runs on 4GB RAM
ollama pull gemma2         # Google's open model

# List what you have
ollama list

# Remove a model
ollama rm mistral
```

---

## Switching Models via Config (No Code Changes)

```yaml
# application.yml — change this one line to switch models
spring:
  ai:
    ollama:
      chat:
        options:
          model: mistral
```

Restart the app. Every endpoint now uses `mistral`. No Java changes.

---

## Switching Models Per-Request

```java
// Override the default model for a single call
OllamaOptions modelOptions = OllamaOptions.builder()
        .model("mistral")
        .temperature(0.3)
        .build();

String answer = chatClient
        .prompt()
        .user(request.question())
        .options(modelOptions)
        .call()
        .content();
```

---

## What You Will Build — Model Comparison Endpoint

```java
// POST /hr/ask/compare
// Sends the same question to two models and returns both answers

public record CompareRequest(String question, String modelA, String modelB) {}
public record CompareResponse(String question, String answerA, String answerB,
                               String modelA, String modelB) {}

@PostMapping("/ask/compare")
public CompareResponse compare(@RequestBody CompareRequest request) {
    String answerA = askWithModel(request.question(), request.modelA());
    String answerB = askWithModel(request.question(), request.modelB());
    return new CompareResponse(request.question(), answerA, answerB,
                               request.modelA(), request.modelB());
}

private String askWithModel(String question, String model) {
    return chatClient.prompt()
            .user(question)
            .options(OllamaOptions.builder().model(model).temperature(0.3).build())
            .call()
            .content();
}
```

**Test it:**
```bash
curl -s -X POST http://localhost:8080/hr/ask/compare \
  -H "Content-Type: application/json" \
  -d '{"question": "What is a good onboarding plan for a new software engineer?",
       "modelA": "llama3.2",
       "modelB": "mistral"}'
```

---

## Model Cheat Sheet

| Model | RAM Required | Best for | Speed |
|-------|-------------|----------|-------|
| `llama3.2` (3B) | 4GB | General Q&A | Fast |
| `llama3.2:8b` | 8GB | Better reasoning | Medium |
| `mistral` | 5GB | Instruction following | Fast |
| `codellama` | 4GB | Code, technical docs | Fast |
| `phi3:mini` | 2GB | Lightweight, constrained env | Very fast |
| `gemma2` | 5GB | Multi-language | Medium |

---

## Summary

In this chapter you will:

- Manage multiple Ollama models from the command line
- Switch models with a single config change
- Override the model per-request using `OllamaOptions`
- Build a side-by-side model comparison endpoint

---

## What's Next

In **Chapter 4**, we tackle prompt engineering — using `PromptTemplate` to inject dynamic data (employee name, department, role) into prompts so the HR assistant gives personalised, TechCorp-branded responses.

*Code for this chapter: [`code/chapter-03-connecting-to-llama/`](../code/chapter-03-connecting-to-llama/)*
