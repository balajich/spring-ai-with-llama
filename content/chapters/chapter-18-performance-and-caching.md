# Chapter 18 — Performance and Caching: Handling Scale Efficiently

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** A bulk job description generator — Lisa uploads a spreadsheet of 50 open roles and the system generates polished job descriptions for all of them concurrently, with caching to avoid regenerating identical prompts.

---

## The Problem We Are Solving

The SmartHR bot works great for one user at a time. But TechCorp is growing. Dev sees a new requirement:

> "We need to generate job descriptions for 50 open roles before the recruitment drive next week. Can we do them all at once?"

A naive sequential approach would take 50 × 8 seconds = ~7 minutes. With concurrency and caching, it takes under a minute.

---

## What You Will Learn

- Why AI calls are slow and where the time goes
- Concurrent AI calls with virtual threads (Java 25)
- Response caching for repeated or similar prompts
- Batch processing patterns for bulk AI tasks
- Rate limiting to protect Ollama from overload

---

## Where the Time Goes

```
Total time for one AI call (~8 seconds):
  ├── Network to Ollama:     ~10ms   (negligible — it's localhost)
  ├── Token generation:      ~7500ms ← this is the bottleneck
  └── Response parsing:      ~10ms   (negligible)
```

The model generates tokens one at a time. There is no way to make a single call faster. But you can run many calls **at the same time**.

---

## Concurrent Calls with Virtual Threads

Java 25 virtual threads make concurrent AI calls trivial:

```java
@PostMapping("/hr/jobs/generate-bulk")
public List<JobDescription> generateBulk(@RequestBody List<JobRole> roles) {
    return roles.parallelStream()        // virtual threads handle concurrency
            .map(this::generateJobDescription)
            .toList();
}

private JobDescription generateJobDescription(JobRole role) {
    String content = chatClient.prompt()
            .user("""
                  Write a professional job description for:
                  Role: {title}
                  Department: {department}
                  Level: {level}
                  Key skills: {skills}
                  """)
            // ... params
            .call()
            .content();
    return new JobDescription(role, content);
}
```

Enable virtual threads in `application.yml`:
```yaml
spring:
  threads:
    virtual:
      enabled: true
```

---

## Caching Repeated Prompts

If the same prompt is sent multiple times (e.g., the same system prompt on every call), cache the response:

```java
@Service
public class CachedChatService {

    private final Cache<String, String> cache = Caffeine.newBuilder()
            .maximumSize(500)
            .expireAfterWrite(Duration.ofHours(1))
            .build();

    public String ask(String question) {
        return cache.get(question, q -> chatClient.prompt()
                .user(q)
                .call()
                .content());
    }
}
```

Add Caffeine to `pom.xml`:
```xml
<dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
</dependency>
```

---

## Rate Limiting Ollama

Too many concurrent requests will make Ollama queue or crash. Use a semaphore to limit concurrency:

```java
private final Semaphore semaphore = new Semaphore(3); // max 3 concurrent calls

public String ask(String question) throws InterruptedException {
    semaphore.acquire();
    try {
        return chatClient.prompt().user(question).call().content();
    } finally {
        semaphore.release();
    }
}
```

3 concurrent Llama calls is a reasonable default for a machine with 16GB RAM running `llama3.2`.

---

## Performance Benchmarks

| Strategy | 50 job descriptions | Notes |
|----------|--------------------:|-------|
| Sequential | ~7 minutes | One at a time |
| Parallel (3 threads) | ~2.5 minutes | 3× faster |
| Parallel (5 threads) | ~1.5 minutes | Diminishing returns |
| With caching (repeated) | ~5 seconds | Cache hit, no model call |

---

## Summary

In this chapter you will:

- Use Java 25 virtual threads for concurrent AI calls
- Cache repeated prompt responses with Caffeine
- Rate-limit Ollama to prevent overload
- Build a bulk job description generator that processes 50 roles in parallel

---

## What's Next

In **Chapter 19**, we harden the SmartHR bot for production — handling prompt injection attacks, sanitising user input, protecting PII, and ensuring the bot cannot be misused by malicious employees.

*Code for this chapter: [`code/chapter-18-performance-and-caching/`](../code/chapter-18-performance-and-caching/)*
