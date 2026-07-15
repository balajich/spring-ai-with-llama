# Chapter 14 — Document Intelligence: PDFs, Word Docs, and Web Pages

> **What you will build:** A contract analyser — Sarah uploads an employment contract PDF and gets back a plain-English summary with key clauses highlighted: probation period, notice period, IP ownership, and any non-standard clauses that need legal review.

---

## The Problem We Are Solving

TechCorp's legal team sends employment contracts as PDFs. Sarah reads every contract manually before it goes to a new hire — looking for unusual clauses, missing standard terms, or anything that might need a lawyer.

> "I spend 20 minutes per contract just reading for red flags. Can the AI do a first pass for me?"

---

## What You Will Learn

- Spring AI's built-in document readers (PDF, Word, web)
- How to analyse a document without a vector store (direct injection)
- When to use direct injection vs RAG (Chapter 7)
- How to combine document reading with structured output (Chapter 5)

---

## Spring AI Document Readers

A **document reader** turns a file into a list of `Document` objects (text plus metadata). Add the dependencies:

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-pdf-document-reader</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-tika-document-reader</artifactId>
</dependency>
```

```java
// PDF — one Document per page
List<Document> pages = new PagePdfDocumentReader(resource).get();

// Word (.docx), HTML, web pages, almost anything — via Apache Tika
List<Document> docs = new TikaDocumentReader(resource).get();

// Pull out the text
String text = pages.stream()
        .map(Document::getText)
        .collect(Collectors.joining("\n\n"));
```

The uploaded `MultipartFile` becomes a `Resource` (a named `ByteArrayResource` so Tika can detect the format from the filename).

---

## Direct Injection vs RAG

| Approach | When to use |
|----------|-------------|
| **Direct injection** | Single document, fits in context window (~50 pages) |
| **RAG (Chapter 7)** | Large document library, many documents, repeated queries |

For contract analysis we use **direct injection** — the full contract goes into the prompt. We are analysing *one* document deeply, not searching *many*. That's the opposite of Chapter 7's RAG, and the distinction matters: RAG retrieves the few relevant chunks from a big corpus; direct injection hands the model the whole document at once.

---

## What You Will Build — Contract Analyser

```java
public record ContractAnalysis(
        String summary,
        String probationPeriod,
        String noticePeriod,
        String ipOwnership,
        List<String> nonStandardClauses,
        Boolean requiresLegalReview      // boxed — see Chapter 5's Jackson 3 lesson
) {}

@PostMapping("/contract/analyse")
public ContractAnalysis analyseContract(@RequestParam("file") MultipartFile file) {
    String contractText = readPdf(file);   // PagePdfDocumentReader + join pages

    BeanOutputConverter<ContractAnalysis> converter =
            new BeanOutputConverter<>(ContractAnalysis.class);

    String response = chatClient
            .prompt()
            .options(ChatOptions.builder().temperature(0.0))   // deterministic
            .user(u -> u.text("""
                    You are an HR contracts assistant. Do a first-pass review of the
                    employment contract below and extract these fields:
                    - summary: a two-sentence plain-English summary
                    - probationPeriod: the probation period stated, or "not specified"
                    - noticePeriod: the notice period for termination, or "not specified"
                    - ipOwnership: who owns intellectual property the employee creates
                    - nonStandardClauses: an array of unusual clauses a lawyer should see
                    - requiresLegalReview: true if anything looks unusual or risky, else false

                    Contract:
                    {contract}

                    {format}
                    """)
                    .param("contract", contractText)
                    .param("format", converter.getFormat()))
            .call()
            .content();

    return converter.convert(response);
}
```

Note the pattern established in Chapter 5, applied again here: **explicit field-by-field guidance**, **`temperature(0.0)`**, and **boxed/nullable fields**. On a small local model like `llama3.2`, this is the difference between reliable extraction and garbage.

---

## Chunking for Large Documents

If a document exceeds the context window, split it before analysis (the same splitter used in Chapter 9's Graph RAG):

```java
TokenTextSplitter splitter = TokenTextSplitter.builder()
        .withChunkSize(800)
        .withMinChunkSizeChars(350)
        .build();

List<Document> chunks = splitter.apply(documents);
```

---

## Try It

```bash
cd code/chapter-14-document-intelligence
mvn spring-boot:run
```

```bash
# Structured contract review
curl -s -X POST http://localhost:8080/hr/contract/analyse \
  -F "file=@employment-contract.pdf"

# Plain-text summary of any document
curl -s -X POST http://localhost:8080/hr/document/summarise \
  -F "file=@employment-contract.pdf"
```

A sample `employment-contract.pdf` (with deliberate red-flag clauses — a 24-month worldwide non-compete and unpaid on-call) ships in the module directory. Run the Karate tests:

```bash
cd code/tests
./run-tests.sh chapter-14
```

---

## Summary

In this chapter you:

- Used `PagePdfDocumentReader` and `TikaDocumentReader` to read PDFs and other formats
- Chose direct injection (single document) over RAG (large libraries)
- Built a contract analyser that returns a structured `ContractAnalysis`
- Reused Chapter 5's structured-output discipline (field guidance, temperature 0, boxed types)

---

## What's Next

In **Chapter 15**, we return to embeddings — building semantic search so employees can find the right policy or document by *meaning*, not just keywords.

*Code for this chapter: [`code/chapter-14-document-intelligence/`](../code/chapter-14-document-intelligence/)*
