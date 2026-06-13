# Chapter 9 — Multimodality: Images and Text Together

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** A workplace safety reporter — an employee uploads a photo of a potential workplace hazard and the AI analyses the image, identifies the risk, and auto-generates a formal safety incident report.

---

## The Problem We Are Solving

TechCorp's office manager reports that employees spot hazards (a broken chair, a trailing cable, a blocked fire exit) but never bother filing the paperwork. Sarah wants a faster way.

> "What if someone could just take a photo and the AI fills in the report for them?"

Multimodal AI — models that understand both text and images — makes this possible.

---

## What You Will Learn

- What multimodal AI models are
- Which Ollama models support vision (image input)
- How to send images to a model using Spring AI
- How to build an image analysis endpoint
- How to generate structured reports from image analysis

---

## Which Models Support Vision?

Not all Ollama models can process images. Vision-capable models:

```bash
ollama pull llava          # LLaVA — the most popular vision model
ollama pull llava:13b      # larger, better quality
ollama pull moondream      # lightweight vision model
ollama pull llama3.2-vision  # Llama 3.2 with vision capability
```

```yaml
# application.yml — switch to a vision model
spring:
  ai:
    ollama:
      chat:
        options:
          model: llava
```

---

## How to Send an Image in Spring AI

```java
@PostMapping("/safety/analyse")
public SafetyReport analyseSafety(
        @RequestParam("image") MultipartFile image,
        @RequestParam("location") String location) throws IOException {

    // Convert uploaded file to Spring AI media object
    var media = new Media(MimeTypeUtils.IMAGE_JPEG,
                          new ByteArrayResource(image.getBytes()));

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
                      4. Whether this requires an official incident report
                      """)
                .param("location", location)
                .media(media))
            .call()
            .content();

    return buildReport(location, analysis);
}
```

---

## Structured Safety Report Output

```java
public record SafetyReport(
        String location,
        String hazardDescription,
        String riskLevel,         // LOW / MEDIUM / HIGH
        String recommendedAction,
        boolean requiresIncidentReport,
        LocalDateTime reportedAt
) {}
```

Combine with `BeanOutputConverter` from Chapter 5 to get a fully typed `SafetyReport` object instead of raw text.

---

## Limitations to Know

| Limitation | Detail |
|-----------|--------|
| Model must be vision-capable | `llava`, `llama3.2-vision` — not all models |
| Image size | Keep under 5MB for reasonable speed |
| Accuracy | Vision models are good but not perfect — always have a human review HIGH risk reports |
| Local only | Ollama vision models run locally — image data never leaves your machine |

---

## Summary

In this chapter you will:

- Understand which Ollama models support image input
- Send images to a vision model using Spring AI's `Media` API
- Build a workplace safety analyser that reads photos and identifies hazards
- Generate structured safety reports combining `BeanOutputConverter` and vision

---

## What's Next

In **Chapter 10**, we tackle streaming — instead of waiting for the full response, we stream tokens as they are generated, giving users the live-typing experience they expect from modern AI interfaces.

*Code for this chapter: [`code/chapter-09-multimodality/`](../code/chapter-09-multimodality/)*
