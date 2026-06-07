# Stop Hardcoding Prompts. Use Templates Instead.

*Part 4 of the "Spring AI with Llama" series*

---

Raj, a new software engineer at TechCorp, uses the SmartHR bot for the first time. He asks about getting his laptop set up. The bot replies:

*"At a typical company, new employees are usually assigned a laptop..."*

Raj messages Sarah the HR Manager: **"The bot doesn't even know I work here."**

That's the problem we fix in Chapter 4.

---

## What's Wrong with a Hardcoded Prompt?

In the earlier chapters we used a single system prompt like this:

```java
private static final String SYSTEM_PROMPT = """
        You are an HR assistant for TechCorp...
        """;
```

It works — but it's the same for everyone. Raj gets the same response as Lisa, the same as Sarah, the same as every employee regardless of their name, department, or role. There's nothing personal about it.

The fix is `PromptTemplate`.

---

## What Is a PromptTemplate?

A `PromptTemplate` is a reusable prompt with named placeholders — like a mail-merge template for AI prompts:

```java
PromptTemplate template = new PromptTemplate("""
        You are an HR assistant for TechCorp.
        You are speaking with {name}, a {role} in the {department} department.

        Answer their question professionally and mention TechCorp by name:
        {question}
        """);

Prompt prompt = template.create(Map.of(
        "name",       "Raj",
        "department", "Engineering",
        "role",       "Software Engineer",
        "question",   "How do I get my laptop set up?"
));
```

Spring AI substitutes the placeholders at runtime. The model now knows who it's talking to.

---

## Load Templates from Files, Not Code

Hardcoding prompt strings in Java is fine for prototypes. For a real app, store them in `src/main/resources/prompts/` as `.st` files and load them via `@Value`:

```java
@Value("classpath:prompts/hr-assistant.st")
private Resource hrAssistantTemplate;
```

**`hr-assistant.st`:**

```
You are a professional HR assistant for TechCorp, a technology company.
You are speaking with {name}, a {role} in the {department} department.

Guidelines:
- Address {name} by name in your response
- Reference TechCorp policies specifically
- Be concise and professional
- If you don't know TechCorp's specific policy, say so clearly

Employee question: {question}
```

Now the prompt lives outside your Java code. Edit it, refine it, A/B test it — no recompile needed.

---

## Two Endpoints, Two Templates

Chapter 4 adds two endpoints to the SmartHR Assistant:

```java
// General personalised HR answer
@PostMapping("/hr/ask/personalised")
public HrResponse askPersonalised(@RequestBody PersonalisedRequest request) {
    PromptTemplate template = new PromptTemplate(hrAssistantTemplate);
    Prompt prompt = template.create(Map.of(
            "name",       request.name(),
            "department", request.department(),
            "role",       request.role(),
            "question",   request.question()
    ));
    String answer = chatClient.prompt(prompt).call().content();
    return new HrResponse(request.question(), answer, "personalised");
}

// Onboarding-specific answer (warmer tone, first-day focus)
@PostMapping("/hr/ask/onboarding")
public HrResponse askOnboarding(@RequestBody PersonalisedRequest request) {
    PromptTemplate template = new PromptTemplate(onboardingTemplate);
    Prompt prompt = template.create(Map.of(
            "name",       request.name(),
            "department", request.department(),
            "role",       request.role(),
            "question",   request.question()
    ));
    String answer = chatClient.prompt(prompt).call().content();
    return new HrResponse(request.question(), answer, "onboarding");
}
```

Same pattern, different template file, different tone. The onboarding template uses a friendlier, more encouraging voice suited to someone's first week.

---

## Try It

```bash
curl -s -X POST http://localhost:8080/hr/ask/personalised \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Raj",
    "department": "Engineering",
    "role": "Software Engineer",
    "question": "How do I get my development tools set up on my first day?"
  }'
```

Response:

```json
{
  "question": "How do I get my development tools set up on my first day?",
  "answer": "Hi Raj! Welcome to TechCorp's Engineering team. Here's what you'll need to do to get your development environment ready...",
  "mode": "personalised"
}
```

Raj is addressed by name. TechCorp is mentioned. The answer is relevant to his role. That's what a good template buys you.

---

## Why This Matters Beyond the Demo

Once your prompts are in `.st` files, a few things become possible that weren't before:

**Non-developers can own the prompts.** HR can refine the tone and wording without touching Java. That's a meaningful shift.

**You can version control prompts independently.** A bad prompt change doesn't require a code rollback — just revert the template file.

**You can test prompts in isolation.** Load the template, inject test variables, compare outputs. No Spring context needed.

**Consistency at scale.** Every employee gets a response shaped by the same carefully crafted template — not whatever string a developer typed at 11pm.

---

## What's Next

Chapter 5 tackles **Structured Output** — instead of getting a free-text answer from the model, we use `BeanOutputConverter` to parse the response directly into a typed Java record. Useful when you need the AI to return structured data like a job description, a policy summary, or a list of action items.

---

## The Series So Far

- [**Chapter 1** — Building an AI-Powered HR Assistant with Spring AI and Llama](https://www.linkedin.com/pulse/chapter-1-building-ai-powered-hr-assistant-spring-ai-llama-balaji-0vnbc/?trackingId=KK54qB8UzGAQyZFwB6Gzqw%3D%3D)
- [**Chapter 2** — Why Your AI Gives Different Answers Every Time](https://www.linkedin.com/pulse/chapter-2-why-your-ai-gives-different-answers-every-time-chopparapu-ejyyc/?trackingId=Flj68GZAipZ8RCjxxJ5ApA%3D%3D)
- [**Chapter 3** — Running and Comparing Multiple AI Models with Spring AI](https://www.linkedin.com/pulse/chapter-3-running-comparing-multiple-ai-models-spring-chopparapu-6sqgc/?trackingId=g%2BNtdYCyR5gjh8OzC1LEbw%3D%3D)
- **Chapter 4** — Stop Hardcoding Prompts. Use Templates Instead. *(this post)*

---

All code is open source. Drop a comment if you have questions or want to see a specific prompt pattern covered.

*#SpringAI #Java #SpringBoot #Ollama #Llama #PromptEngineering #OpenSource #AI #LLM #BackendDevelopment*
