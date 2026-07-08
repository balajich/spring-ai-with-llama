# Chapter 2 — Core Concepts: Tokens, Messages, and the AI Abstraction

> **What you will build:** Three new HR endpoints — `/hr/ask/precise` for short, consistent policy answers, `/hr/ask/creative` for open-ended brainstorming, and `/hr/ask/raw` to call the model directly using Spring AI's lower-level `ChatModel` API.

---

## The Problem We Are Solving

Dev demos the SmartHR bot to Sarah after its first week live. She has two questions:

> "It answered the same question twice and gave me completely different lengths. One was two sentences, the next was six paragraphs. Can we control that?"

> "I asked it the leave policy and it gave me a very confident wrong answer. And when I asked again, the answer was different. Is that a bug?"

These are not bugs. They are features — and misfeatures — of how language models work. Understanding them is what separates developers who fight the AI from those who bend it to their will.

This chapter explains what is actually happening inside the model when you call `.call().content()`, and gives you the tools to control it.

---

## What Is a Token?

A **token** is the basic unit of text that a language model reads and writes. It is not a word. It is not a character. It is something in between — a chunk of commonly occurring text.

| Text | Approximate Tokens |
|------|-------------------|
| `"Hello"` | 1 |
| `"Hello, how are you?"` | 5 |
| `"maternity leave"` | 3 |
| `"How many vacation days do new employees get?"` | 9 |
| A typical HR policy paragraph (~75 words) | ~100 |

A rough rule of thumb: **1 token ≈ 0.75 words** in English.

### Why Do Tokens Matter?

```
Input tokens   → how much of your question the model reads
Output tokens  → how long the response is
Context window → total tokens (input + output) the model can hold in memory
```

For Llama 3.2 (3B), the context window is around **128,000 tokens**. But output token limits control response length. If you do not set a limit, the model decides how long to write — which is why Sarah got six paragraphs sometimes.

### The Token Lifecycle of One Request

```
You send:
  System:  "You are an HR assistant for TechCorp..."    (~40 tokens)
  User:    "How many vacation days do I get?"           (~9 tokens)

Total input: ~49 tokens

Llama generates response tokens one at a time:
  "At" → "TechCorp" → "," → "new" → "employees" → ...

Until it decides to stop (or hits your numPredict limit).
```

The model generates **one token at a time** — which is why streaming responses appear word-by-word (more on this in Chapter 13).

---

## Controlling Response Length with `maxTokens`

`maxTokens` caps how many tokens the model is allowed to generate. Spring AI's `ChatOptions.builder()` is the provider-agnostic way to set it. Pass the **builder itself** (not the built result) to `.options()` — this is what the `ChatClient` API expects:

```java
chatClient.prompt()
        .options(ChatOptions.builder()
                .temperature(0.0)
                .maxTokens(150))    // note: no .build() — pass the builder directly
        .user(question)
        .call()
        .content();
```

This does not make the model dumber — it just forces it to be concise.

---

## Temperature Revisited — Why Sarah Got Different Answers

At each step, the model calculates a probability distribution over all possible next tokens. Temperature scales this distribution:

```
temperature = 0.0 (cold)   → Always picks the most likely token. Deterministic.
temperature = 0.7 (warm)   → Picks randomly from distribution. Different each time.
temperature = 1.5 (hot)    → All tokens nearly equal probability → incoherent.
```

### Choosing Temperature for HR Use Cases

| Use Case | Recommended Temperature |
|----------|------------------------|
| Policy lookup | `0.0` – `0.1` |
| Standard Q&A | `0.3` |
| Writing job descriptions | `0.7` |
| Brainstorming ideas | `0.8` – `0.9` |

---

## The Message Architecture

When you call `chatClient.prompt().user(question).call()`, Spring AI builds a **Prompt** made of **Messages**:

```
┌─────────────────────────────────────────────┐
│                  Prompt                      │
│  SystemMessage   "You are an HR assistant…" │
│  UserMessage     "How many vacation days…"  │
│  AssistantMessage "At TechCorp, you get…"   │  ← used in multi-turn (Ch. 6)
└─────────────────────────────────────────────┘
```

| Message Type | Who writes it | Purpose |
|---|---|---|
| `SystemMessage` | Developer | Instructions, persona, constraints |
| `UserMessage` | End user | The actual question |
| `AssistantMessage` | The model | Previous AI response (for conversation history) |

### Using the Low-Level API Directly

```java
List<Message> messages = List.of(
        new SystemMessage(SYSTEM_PROMPT),
        new UserMessage(request.question())
);

ChatResponse response = chatModel.call(new Prompt(messages));
String answer = response.getResult().getOutput().getText();
```

### The Spring AI Abstraction Layers

```
Your Code
   │
   ├── ChatClient          ← high-level: fluent API, advisors, defaults
   │       │
   │       └── ChatModel   ← low-level: send Prompt, get ChatResponse
   │               │
   │               └── OllamaChatModel  ← Ollama-specific implementation
   │                       │
   │                       └── Ollama HTTP API → Llama 3.2
```

You write against `ChatClient` or `ChatModel`. If you later switch to OpenAI, only the implementation changes — your code stays identical.

---

## Project Structure (Chapter 2 additions)

```
code/chapter-02-core-concepts/
├── pom.xml
└── src/main/java/com/techcorp/smarthr/
    ├── SmartHrAssistantApplication.java
    ├── controller/
    │   └── HrChatController.java       ← adds /ask/precise, /ask/creative, /ask/raw
    └── model/
        ├── HrRequest.java
        └── HrResponse.java             ← updated: adds "mode" field
```

---

## The Code

### Updated `HrResponse`

```java
public record HrResponse(String question, String answer, String mode) {}
```

### Three new endpoints in `HrChatController`

```java
// PRECISE: policy questions — short, deterministic, capped at ~150 tokens
@PostMapping("/ask/precise")
public HrResponse askPrecise(@RequestBody HrRequest request) {
    String answer = chatClient
            .prompt()
            .options(ChatOptions.builder()
                    .temperature(0.0)
                    .maxTokens(150))    // pass the builder — no .build()
            .user(request.question())
            .call()
            .content();
    return new HrResponse(request.question(), answer, "precise");
}

// CREATIVE: brainstorming — warm temperature, generous token budget
@PostMapping("/ask/creative")
public HrResponse askCreative(@RequestBody HrRequest request) {
    String answer = chatClient
            .prompt()
            .options(ChatOptions.builder()
                    .temperature(0.9)
                    .maxTokens(800))
            .user(request.question())
            .call()
            .content();
    return new HrResponse(request.question(), answer, "creative");
}

// RAW: bypass ChatClient, use ChatModel directly
@PostMapping("/ask/raw")
public HrResponse askRaw(@RequestBody HrRequest request) {
    List<Message> messages = List.of(
            new SystemMessage(SYSTEM_PROMPT),
            new UserMessage(request.question())
    );
    var response = chatModel.call(new Prompt(messages));
    String answer = response.getResult().getOutput().getText();
    return new HrResponse(request.question(), answer, "raw");
}
```

Both `ChatClient.Builder` and `ChatModel` are injected together:

```java
public HrChatController(ChatClient.Builder builder, ChatModel chatModel) {
    this.chatClient = builder.defaultSystem(SYSTEM_PROMPT).build();
    this.chatModel = chatModel;
}
```

---

## Run and Test

```bash
cd code/chapter-02-core-concepts
mvn spring-boot:run
```

```bash
# Precise answer
curl -s -X POST http://localhost:8080/hr/ask/precise \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the maternity leave policy?"}'

# Creative brainstorm
curl -s -X POST http://localhost:8080/hr/ask/creative \
  -H "Content-Type: application/json" \
  -d '{"question": "Give me 5 ideas for remote team-building activities."}'
```

---

## What Is an Embedding? (Preview for Chapter 7)

An **embedding** is a list of numbers (a vector) that represents a piece of text's *meaning*. Similar meanings produce similar vectors.

```
"maternity leave"      → [0.82, 0.14, -0.33, 0.91, ...]
"parental leave"       → [0.80, 0.16, -0.31, 0.89, ...]  ← very close
"office parking spot"  → [0.12, 0.67,  0.44, 0.02, ...]  ← very different
```

This is how RAG (Chapter 7) finds relevant documents — not by keyword matching, but by measuring the distance between meaning vectors.

---

## Concepts Summary

| Concept | What It Means | How to Control It |
|---------|--------------|-------------------|
| Token | Basic unit of text a model reads/writes | ~0.75 tokens per word |
| Temperature | How random the output is | `ChatOptions.builder().temperature(x)` |
| maxTokens | Max tokens in the response | `ChatOptions.builder().maxTokens(x)` |
| SystemMessage | Developer instructions | `chatClient.defaultSystem(...)` |
| UserMessage | The user's question | `chatClient.prompt().user(...)` |
| ChatModel | Low-level Spring AI interface | Inject `ChatModel` directly |
| ChatClient | High-level fluent wrapper | Inject `ChatClient.Builder` |

---

## Summary

In this chapter you:

- Learned what tokens are and how they control response length
- Understood temperature and why the same question gives different answers
- Explored Spring AI's message architecture: `SystemMessage`, `UserMessage`, `AssistantMessage`
- Saw the abstraction layers: `ChatClient` → `ChatModel` → `OllamaChatModel`
- Built precise, creative, and raw HR endpoints using `ChatOptions`

---

## What's Next

In **Chapter 3**, we go deeper into the Ollama connection — switching between models (`llama3.2`, `mistral`, `codellama`) at runtime and benchmarking them on real HR questions.

```java
// Chapter 3 introduces per-request model switching via Ollama-specific options
chatClient.prompt()
        .user(question)
        .options(ChatOptions.builder().temperature(0.3))
        .call().content();
```

*Code for this chapter: [`code/chapter-02-core-concepts/`](../code/chapter-02-core-concepts/)*
