# Chapter 14 — Document Intelligence: PDFs, Word Docs, and Web Pages

Give the SmartHR bot the ability to read. Sarah uploads an employment-contract PDF and gets back a structured first-pass legal review — probation period, notice period, IP ownership, and any non-standard clauses that need a lawyer's eyes.

<svg viewBox="0 0 580 300" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 14 — Reading documents with Spring AI and Ollama</title>
  <desc>A contract PDF is read by Spring AI's document readers, injected whole into the prompt, and returned as a structured ContractAnalysis.</desc>
  <rect width="580" height="300" fill="#f8f9fa" rx="12"/>
  <rect x="20" y="105" width="120" height="90" rx="10" fill="white" stroke="#c0392b" stroke-width="2"/>
  <text x="80" y="135" text-anchor="middle" font-size="13" font-weight="700" fill="#7a2018">contract.pdf</text>
  <text x="80" y="153" text-anchor="middle" font-size="10" fill="#999">multipart upload</text>
  <text x="80" y="172" text-anchor="middle" font-size="10" fill="#555">employment terms</text>
  <rect x="180" y="80" width="200" height="140" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="280" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="280" y="126" text-anchor="middle" font-size="10" fill="#999">JVM</text>
  <text x="280" y="150" text-anchor="middle" font-size="10" fill="#555">PagePdfDocumentReader</text>
  <text x="280" y="167" text-anchor="middle" font-size="10" fill="#555">direct injection → prompt</text>
  <text x="280" y="184" text-anchor="middle" font-size="10" fill="#555">BeanOutputConverter</text>
  <rect x="420" y="105" width="140" height="90" rx="10" fill="white" stroke="#5aaa6b" stroke-width="2"/>
  <text x="490" y="135" text-anchor="middle" font-size="13" font-weight="700" fill="#1b6b2f">Ollama</text>
  <text x="490" y="153" text-anchor="middle" font-size="10" fill="#999">llama3.2</text>
  <text x="490" y="172" text-anchor="middle" font-size="10" fill="#555">reads &amp; reasons</text>
  <path d="M 140 150 L 180 150" fill="none" stroke="#c0392b" stroke-width="1.8" marker-end="url(#d14a)"/>
  <path d="M 380 150 L 420 150" fill="none" stroke="#5aaa6b" stroke-width="1.8" marker-end="url(#d14b)"/>
  <rect x="180" y="245" width="200" height="40" rx="8" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.5"/>
  <text x="280" y="269" text-anchor="middle" font-size="11" font-weight="700" fill="#2d3494">ContractAnalysis (JSON)</text>
  <path d="M 280 220 L 280 245" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#d14c)"/>
  <defs>
    <marker id="d14a" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#c0392b"/></marker>
    <marker id="d14b" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5aaa6b"/></marker>
    <marker id="d14c" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
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

```bash
ollama pull llama3.2
ollama serve   # if not already running
```

---

## Run the Application

```bash
cd code/chapter-14-document-intelligence
mvn spring-boot:run
```

The app starts on **http://localhost:8080**.

---

## How It Works

Spring AI ships document readers that turn a file into a list of `Document` objects:

```java
// PDF — one Document per page
List<Document> pages = new PagePdfDocumentReader(resource).get();

// Word / HTML / almost anything — via Apache Tika
List<Document> docs = new TikaDocumentReader(resource).get();

// Combine the extracted text
String text = pages.stream().map(Document::getText).collect(Collectors.joining("\n\n"));
```

For a single contract we use **direct injection** — the whole document goes into the prompt — rather than RAG. Combined with `BeanOutputConverter` (Chapter 5), the result is a typed `ContractAnalysis`:

```java
public record ContractAnalysis(
        String summary,
        String probationPeriod,
        String noticePeriod,
        String ipOwnership,
        List<String> nonStandardClauses,
        Boolean requiresLegalReview
) {}
```

> **Carrying Chapter 5's lessons forward:** all fields are boxed/nullable (Spring AI 2.0 uses Jackson 3, which rejects `null` → primitive), the prompt names each field explicitly, and `temperature` is set to `0.0` — so extraction is reliable even on a small local model.

---

## Direct Injection vs RAG

| Approach | When to use |
|----------|-------------|
| **Direct injection** (this chapter) | A single document that fits the context window (~50 pages) |
| **RAG** (Chapter 7) | A large library of documents queried repeatedly |

If a document exceeds the context window, split it first with `TokenTextSplitter.builder()`.

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/contract/analyse` | Multipart PDF upload (`file`) → structured `ContractAnalysis` |
| `POST` | `/hr/document/summarise` | Multipart upload (`file`, any Tika format) → `{ filename, summary }` |

---

## Example Usage

```bash
# Structured contract review
curl -s -X POST http://localhost:8080/hr/contract/analyse \
  -F "file=@employment-contract.pdf"

# Plain-text summary of any document (PDF, Word, HTML, ...)
curl -s -X POST http://localhost:8080/hr/document/summarise \
  -F "file=@employment-contract.pdf"
```

Example `ContractAnalysis` response:

```json
{
  "summary": "Employment agreement between TechCorp Ltd and Rahul Menon for a Senior Software Engineer role...",
  "probationPeriod": "six (6) months",
  "noticePeriod": "three (3) months",
  "ipOwnership": "the Company",
  "nonStandardClauses": ["24-month worldwide non-compete", "unpaid on-call"],
  "requiresLegalReview": true
}
```

A sample `employment-contract.pdf` (with deliberate red-flag clauses) ships in this directory.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `400 Could not read the PDF` | Not a valid PDF | Upload a real, text-based PDF |
| `422 The PDF has no extractable text` | Scanned/image-only PDF | Use a text PDF, or add OCR |
| `422 Could not analyse the contract` | Model returned non-JSON | Retry — temperature is already 0 |
| `413 Payload Too Large` | File over 10MB | Raise `spring.servlet.multipart.max-file-size` |
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |

---

## Project Structure

```
chapter-14-document-intelligence/
├── pom.xml
├── README.md
├── employment-contract.pdf              ← sample fixture with red-flag clauses
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── DocumentController.java   ← /hr/contract/analyse + /hr/document/summarise
    │   └── model/
    │       └── ContractAnalysis.java
    └── resources/
        └── application.yml
```

---

*Full chapter write-up: [`chapters/chapter-14-document-intelligence.md`](../../chapters/chapter-14-document-intelligence.md)*
