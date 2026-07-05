# Chapter 12 — Multimodality: Images and Text Together

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
- How to send images to a model using Spring AI's `Media` API
- How to build an image analysis endpoint
- How to combine vision with `BeanOutputConverter` for structured reports

---

## Which Models Support Vision?

Not all Ollama models can process images. Vision-capable models:

```bash
ollama pull llava          # LLaVA — the most popular vision model
ollama pull llava:13b      # larger, better quality
ollama pull moondream      # lightweight vision model
ollama pull llama3.2-vision  # Llama 3.2 with vision capability
```

This chapter uses `llava`:

```yaml
# application.yml — switch to a vision model
spring:
  ai:
    ollama:
      chat:
        options:
          model: llava
          temperature: 0.2

  servlet:
    multipart:
      max-file-size: 5MB
      max-request-size: 6MB
```

---

## Sending an Image in Spring AI

The uploaded file is wrapped in a `Media` object (`org.springframework.ai.content.Media`) and attached to the user message next to the text prompt:

```java
@PostMapping("/safety/analyse")
public SafetyAnalysis analyse(@RequestParam("image") MultipartFile image,
                              @RequestParam("location") String location) {
    Media media = toMedia(image);

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

    return new SafetyAnalysis(location, analysis);
}
```

Building the `Media` object from a multipart upload:

```java
private Media toMedia(MultipartFile image) {
    MimeType mimeType = image.getContentType() != null
            ? MimeType.valueOf(image.getContentType())
            : MimeTypeUtils.IMAGE_JPEG;
    return Media.builder()
            .mimeType(mimeType)
            .data(new ByteArrayResource(image.getBytes()))
            .build();
}
```

Under the hood, Spring AI base64-encodes the image bytes and sends them to Ollama alongside the text — llava sees both in a single prompt.

---

## Structured Safety Report Output

Free text is nice; a typed report you can store in a database is better. The `/hr/safety/report` endpoint combines vision with `BeanOutputConverter` from Chapter 5:

```java
public record SafetyReport(
        String location,
        String hazardDescription,
        String riskLevel,               // LOW / MEDIUM / HIGH
        String recommendedAction,
        boolean requiresIncidentReport
) {}
```

```java
BeanOutputConverter<SafetyReport> converter =
        new BeanOutputConverter<>(SafetyReport.class);

String response = chatClient
        .prompt()
        .user(u -> u
                .text("""
                      Analyse this workplace photo taken at "{location}" and fill in
                      a safety incident report.

                      Important:
                      - Return a flat JSON object with the actual values, NOT a JSON schema.
                      - riskLevel must be exactly one of: LOW, MEDIUM, HIGH.
                      - Set requiresIncidentReport to true for MEDIUM or HIGH risk.
                      - Return ONLY the JSON object, no explanation or extra text.

                      {format}
                      """)
                .param("location", location)
                .param("format", converter.getFormat())
                .media(media))
        .call()
        .content();

return converter.convert(response);
```

One request in, one typed `SafetyReport` record out — ready to persist, route to facilities, or escalate.

---

## Try It

```bash
cd code/chapter-12-multimodality
mvn spring-boot:run
```

```bash
# Free-text analysis
curl -s -X POST http://localhost:8080/hr/safety/analyse \
  -F "image=@hazard.jpg" \
  -F "location=Floor 3, near the printer"

# Structured incident report
curl -s -X POST http://localhost:8080/hr/safety/report \
  -F "image=@hazard.jpg" \
  -F "location=Floor 3, near the printer"
```

Example structured response:

```json
{
  "location": "Floor 3, near the printer",
  "hazardDescription": "A power cable is trailing across the walkway.",
  "riskLevel": "MEDIUM",
  "recommendedAction": "Tape down or reroute the cable away from the walkway.",
  "requiresIncidentReport": true
}
```

Run the Karate tests (requires `ollama pull llava`):

```bash
cd code/tests
./run-tests.sh chapter-12
```

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

In this chapter you:

- Learned which Ollama models support image input
- Sent images to a vision model using Spring AI's `Media` API
- Built a workplace safety analyser that reads photos and identifies hazards
- Generated structured safety reports combining `BeanOutputConverter` and vision

---

## What's Next

In **Chapter 13**, we tackle streaming — instead of waiting for the full response, we stream tokens as they are generated, giving users the live-typing experience they expect from modern AI interfaces.

*Code for this chapter: [`code/chapter-12-multimodality/`](../code/chapter-12-multimodality/)*
