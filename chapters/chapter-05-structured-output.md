# Chapter 5 — Structured Output: From Raw Text to Java Objects

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** A resume parser — Lisa the Hiring Manager pastes raw resume text and gets back a structured `ResumeProfile` Java record with `name`, `email`, `skills`, `experience`, and `education` fields ready to store in a database.

---

## The Problem We Are Solving

Lisa, the Hiring Manager, receives 50 resumes a week. Each one is in a different format — some are PDFs converted to text, some are copy-pasted from LinkedIn. She asks Dev:

> "Can the AI read a resume and give me the key info in a consistent format? I want to plug it straight into our HR system — not parse a paragraph of text."

This is structured output. The AI reads unstructured text and returns a typed Java object.

---

## What You Will Learn

- Why `.content()` is not always enough
- How `BeanOutputConverter` works
- How to return typed Java records from AI calls
- How to handle parsing failures gracefully
- How to build a resume parsing endpoint

---

## The Problem with Raw Text Output

Without structured output, you get a paragraph:

```
"The candidate's name is Priya Sharma. She has 5 years of experience in Java
and Spring Boot. She studied Computer Science at IIT Delhi..."
```

You still have to parse that string. Structured output gives you:

```json
{
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "skills": ["Java", "Spring Boot", "Kubernetes"],
  "yearsOfExperience": 5,
  "education": "B.Tech Computer Science, IIT Delhi"
}
```

Which maps directly to a Java record.

---

## How BeanOutputConverter Works

```java
public record ResumeProfile(
        String name,
        String email,
        List<String> skills,
        int yearsOfExperience,
        String currentRole,
        String education
) {}

// Spring AI generates a JSON schema from the record and injects it into the prompt
BeanOutputConverter<ResumeProfile> converter = new BeanOutputConverter<>(ResumeProfile.class);

String prompt = """
        Parse the following resume and extract the key information.

        Resume:
        {resumeText}

        {format}
        """;

// {format} is replaced with the JSON schema instruction automatically
```

---

## What You Will Build — Resume Parser Endpoint

```java
// POST /hr/resume/parse
public record ResumeParseRequest(String resumeText) {}

@PostMapping("/resume/parse")
public ResumeProfile parseResume(@RequestBody ResumeParseRequest request) {
    BeanOutputConverter<ResumeProfile> converter =
            new BeanOutputConverter<>(ResumeProfile.class);

    String response = chatClient
            .prompt()
            .user(u -> u.text("""
                    Parse this resume and extract structured information.

                    Resume:
                    {resumeText}

                    {format}
                    """)
                    .param("resumeText", request.resumeText())
                    .param("format", converter.getFormat()))
            .call()
            .content();

    return converter.convert(response);
}
```

**Test it:**
```bash
curl -s -X POST http://localhost:8080/hr/resume/parse \
  -H "Content-Type: application/json" \
  -d '{
    "resumeText": "Priya Sharma | priya@example.com\n5 years Java, Spring Boot, AWS\nSenior Engineer at Infosys\nB.Tech CS IIT Delhi 2018"
  }'
```

---

## Handling Parse Failures

Sometimes the model does not return valid JSON. Always wrap the conversion:

```java
try {
    return converter.convert(response);
} catch (Exception e) {
    throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
            "Could not parse resume. Try providing more structured text.");
}
```

---

## Summary

In this chapter you will:

- Understand why structured output matters over raw text
- Use `BeanOutputConverter` to map AI responses to Java records
- Build a resume parser that returns a typed `ResumeProfile` object
- Handle parsing failures gracefully

---

## What's Next

In **Chapter 6**, we give the SmartHR bot a memory — using `InMemoryChatMemory` so Raj can have a multi-turn onboarding conversation where the AI remembers what was said earlier in the session.

*Code for this chapter: [`code/chapter-05-structured-output/`](../code/chapter-05-structured-output/)*
