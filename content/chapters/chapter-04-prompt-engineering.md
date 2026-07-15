# Chapter 4 — Prompt Engineering: PromptTemplate and Dynamic Prompts

---

## The Problem We Are Solving

Raj, a new hire in the engineering team, uses the SmartHR bot for the first time. He gets a generic answer that starts with "At a typical company...". He messages Sarah:

> "The bot doesn't even know I work here. Can it give answers that actually apply to TechCorp and mention my name?"

Sarah passes it to Dev. The fix: `PromptTemplate`.

---

## What You Will Learn

- What `PromptTemplate` is and why it matters
- How to inject dynamic variables into prompts
- How to load prompt templates from files (not hardcoded strings)
- How to structure prompts for better, more consistent AI output
- Best practices for prompt design

---

## What Is a PromptTemplate?

A `PromptTemplate` is a reusable prompt with named placeholders, just like a mail-merge template:

```java
PromptTemplate template = new PromptTemplate("""
        You are an HR assistant for TechCorp.
        The employee asking is {name} from the {department} department.
        Their role is {role}.

        Answer their question professionally and mention TechCorp by name where relevant:
        {question}
        """);

Map<String, Object> variables = Map.of(
        "name", "Raj",
        "department", "Engineering",
        "role", "Software Engineer",
        "question", "How do I request my laptop setup?"
);

Prompt prompt = template.create(variables);
```

---

## Loading Templates from Files

Instead of hardcoding templates in Java, store them in `resources/prompts/`:

```
src/main/resources/prompts/
├── hr-assistant.st          ← main HR prompt template
└── onboarding.st            ← onboarding-specific template
```

```java
// Load from classpath
@Value("classpath:prompts/hr-assistant.st")
private Resource hrPromptTemplate;

PromptTemplate template = new PromptTemplate(hrPromptTemplate);
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

---

## What You Will Build — Personalised HR Endpoint

```java
// POST /hr/ask/personalised
public record PersonalisedRequest(String name, String department,
                                   String role, String question) {}

@PostMapping("/ask/personalised")
public HrResponse askPersonalised(@RequestBody PersonalisedRequest request) {
    Prompt prompt = template.create(Map.of(
            "name",       request.name(),
            "department", request.department(),
            "role",       request.role(),
            "question",   request.question()
    ));

    String answer = chatClient.prompt(prompt).call().content();
    return new HrResponse(request.question(), answer, "personalised");
}
```

**Test it:**
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

---

## Prompt Engineering Best Practices

| Practice | Example |
|----------|---------|
| Be specific about the role | "You are an HR assistant" not "You are an assistant" |
| Define output format | "Answer in 3 bullet points" |
| Set boundaries | "Only answer HR-related questions" |
| Give examples | "For example: ..." |
| Control tone | "Be professional but friendly" |

---

## Summary

In this chapter you will:

- Use `PromptTemplate` to inject dynamic variables into prompts
- Load templates from classpath files instead of hardcoded strings
- Build a personalised HR endpoint that addresses employees by name and department
- Apply prompt engineering best practices

---

## What's Next

In **Chapter 5**, we make the AI return structured Java objects instead of raw text — using `BeanOutputConverter` to parse a resume into a `Resume` record with fields like `name`, `skills`, `experience`, and `education`.

*Code for this chapter: [`code/chapter-04-prompt-engineering/`](../code/chapter-04-prompt-engineering/)*
