# Chapter 12 — Multimodality: Images and Text Together

Teach the SmartHR bot to see — an employee uploads a photo of a workplace hazard, and a vision model (llava) analyses the image, identifies the risk, and generates a structured safety incident report.

<svg viewBox="0 0 580 300" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 12 — Spring AI, Ollama llava and Multimodal Safety Analysis</title>
  <desc>An employee photo travels through Spring AI's Media API to Ollama's llava vision model, returning a structured SafetyReport.</desc>
  <rect width="580" height="300" fill="#f8f9fa" rx="12"/>
  <rect x="20" y="100" width="130" height="100" rx="10" fill="white" stroke="#b0568c" stroke-width="2"/>
  <text x="85" y="128" text-anchor="middle" font-size="13" font-weight="700" fill="#7d2a5c">Employee</text>
  <text x="85" y="146" text-anchor="middle" font-size="10" fill="#999">multipart upload</text>
  <rect x="38" y="156" width="94" height="30" rx="6" fill="#fbeaf4" stroke="#b0568c" stroke-width="1.5"/>
  <text x="85" y="175" text-anchor="middle" font-size="10" font-weight="700" fill="#7d2a5c">hazard.png</text>
  <rect x="210" y="80" width="180" height="140" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="300" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="300" y="126" text-anchor="middle" font-size="10" fill="#999">JVM</text>
  <text x="300" y="152" text-anchor="middle" font-size="10" fill="#555">ChatClient</text>
  <text x="300" y="168" text-anchor="middle" font-size="10" fill="#555">Media (image bytes)</text>
  <text x="300" y="184" text-anchor="middle" font-size="10" fill="#555">BeanOutputConverter</text>
  <rect x="430" y="80" width="130" height="140" rx="10" fill="white" stroke="#5aaa6b" stroke-width="2"/>
  <text x="495" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#1b6b2f">Ollama</text>
  <text x="495" y="126" text-anchor="middle" font-size="10" fill="#999">localhost:11434</text>
  <rect x="448" y="140" width="94" height="34" rx="7" fill="#e8f5e9" stroke="#5aaa6b" stroke-width="1.5"/>
  <text x="495" y="161" text-anchor="middle" font-size="11" font-weight="700" fill="#1b6b2f">llava</text>
  <text x="495" y="196" text-anchor="middle" font-size="9" fill="#555">vision model</text>
  <path d="M 150 150 L 210 150" fill="none" stroke="#b0568c" stroke-width="1.8" marker-end="url(#m12a)"/>
  <path d="M 390 135 L 430 135" fill="none" stroke="#5aaa6b" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#m12b)"/>
  <text x="410" y="125" text-anchor="middle" font-size="9" fill="#1b6b2f">image + prompt</text>
  <path d="M 430 170 L 390 170" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#m12b)"/>
  <text x="410" y="188" text-anchor="middle" font-size="9" fill="#1b6b2f">analysis</text>
  <rect x="210" y="245" width="180" height="40" rx="8" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.5"/>
  <text x="300" y="269" text-anchor="middle" font-size="11" font-weight="700" fill="#2d3494">SafetyReport (JSON)</text>
  <path d="M 300 220 L 300 245" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#m12c)"/>
  <defs>
    <marker id="m12a" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#b0568c"/></marker>
    <marker id="m12b" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="m12c" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
  </defs>
</svg>

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25.0.3 | `java -version` |
| Maven | 3.9.16 | `mvn -version` |
| Ollama | 0.31.1 | `ollama --version` |

> **Versions:** These tutorials should work on the most recent versions of these tools. They were built and tested on **Java 25.0.3**, **Maven 3.9.16**, and **Ollama 0.31.1**.

---

## Setup

### 1. Pull a vision-capable model

```bash
ollama pull llava
```

> Regular `llama3.2` cannot process images. Vision-capable Ollama models include `llava`, `llava:13b`, `moondream`, and `llama3.2-vision`.

### 2. Start Ollama

```bash
curl -s http://localhost:11434/api/tags
```

If no response, start it:

```bash
ollama serve
```

---

## Run the Application

```bash
cd code/chapter-12-multimodality
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## How It Works

The uploaded photo is wrapped in a Spring AI `Media` object and attached to the user message alongside the text prompt:

```java
Media media = Media.builder()
        .mimeType(MimeType.valueOf(image.getContentType()))
        .data(new ByteArrayResource(image.getBytes()))
        .build();

String analysis = chatClient
        .prompt()
        .user(u -> u
                .text("Analyse this workplace photo for safety hazards. Location: {location} ...")
                .param("location", location)
                .media(media))
        .call()
        .content();
```

The `/hr/safety/report` endpoint goes one step further: it combines the vision analysis with `BeanOutputConverter` (Chapter 5) so the response is a fully typed `SafetyReport` record instead of raw text:

```java
public record SafetyReport(
        String location,
        String hazardDescription,
        String riskLevel,               // LOW / MEDIUM / HIGH
        String recommendedAction,
        boolean requiresIncidentReport
) {}
```

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/safety/analyse` | Multipart upload (`image`, `location`) → free-text hazard analysis |
| `POST` | `/hr/safety/report` | Multipart upload (`image`, `location`) → structured `SafetyReport` JSON |

---

## Example Usage

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

---

## Limitations to Know

| Limitation | Detail |
|-----------|--------|
| Model must be vision-capable | `llava`, `llama3.2-vision` — not all models |
| Image size | Keep under 5MB for reasonable speed (enforced via multipart limits) |
| Accuracy | Vision models are good but not perfect — always have a human review HIGH risk reports |
| Local only | Ollama vision models run locally — image data never leaves your machine |

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | llava not downloaded | Run `ollama pull llava` |
| Model ignores the image | Model is not vision-capable | Use `llava` or `llama3.2-vision`, not `llama3.2` |
| `413 Payload Too Large` | Image over 5MB | Resize the image or raise `spring.servlet.multipart.max-file-size` |
| `422 Unprocessable Entity` on `/report` | Model returned non-JSON text | Retry — or lower temperature further |

---

## Project Structure

```
chapter-12-multimodality/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── SafetyController.java       ← /hr/safety/analyse + /hr/safety/report
    │   └── model/
    │       ├── SafetyAnalysis.java
    │       └── SafetyReport.java
    └── resources/
        └── application.yml                  ← model: llava, multipart limits
```

---

*Full chapter write-up: [`content/chapters/chapter-12-multimodality.md`](../../content/chapters/chapter-12-multimodality.md)*
