# Chapter 11 — Document Intelligence: PDFs, Word Docs, and Web Pages

> **What you will build:** A contract analyser — Sarah uploads an employment contract PDF and gets back a plain-English summary with key clauses highlighted: probation period, notice period, IP ownership, and any non-standard clauses that need legal review.

---

## The Problem We Are Solving

TechCorp's legal team sends employment contracts as PDFs. Sarah reads every contract manually before it goes to a new hire — looking for unusual clauses, missing standard terms, or anything that might need a lawyer.

> "I spend 20 minutes per contract just reading for red flags. Can the AI do a first pass for me?"

---

## What You Will Learn

- Spring AI's built-in document readers (PDF, Word, web)
- How to chunk documents for effective analysis
- How to analyse a document without a vector store (direct injection)
- How to combine document reading with structured output
- When to use direct injection vs RAG (Chapter 7)

---

## Spring AI Document Readers

```java
// PDF
var pdfReader = new PagePdfDocumentReader("classpath:contract.pdf");

// Word (.docx)
var wordReader = new TikaDocumentReader(new FileSystemResource("contract.docx"));

// Web page
var webReader = new TikaDocumentReader(new UrlResource("https://example.com/policy"));

// Get documents from any reader
List<Document> documents = reader.get();
```

Add the dependency for Tika (Word/web support):
```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-tika-document-reader</artifactId>
</dependency>
```

---

## Direct Injection vs RAG

| Approach | When to use |
|----------|-------------|
| **Direct injection** | Single document, fits in context window (~50 pages) |
| **RAG (Chapter 7)** | Large document library, many documents, repeated queries |

For contract analysis we use direct injection — the full contract goes into the prompt.

---

## What You Will Build — Contract Analyser

```java
public record ContractAnalysis(
        String summary,
        String probationPeriod,
        String noticePeriod,
        List<String> nonStandardClauses,
        String ipOwnership,
        boolean requiresLegalReview
) {}

@PostMapping("/hr/contract/analyse")
public ContractAnalysis analyseContract(@RequestParam MultipartFile file) throws IOException {

    // Read the PDF
    List<Document> pages = new PagePdfDocumentReader(
            new ByteArrayResource(file.getBytes())).get();

    // Combine all pages into one text block
    String contractText = pages.stream()
            .map(Document::getText)
            .collect(Collectors.joining("\n\n"));

    BeanOutputConverter<ContractAnalysis> converter =
            new BeanOutputConverter<>(ContractAnalysis.class);

    String response = chatClient
            .prompt()
            .user(u -> u.text("""
                    Analyse this employment contract and extract key information.

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

---

## Chunking for Large Documents

If a document exceeds the context window, split it first:

```java
TokenTextSplitter splitter = new TokenTextSplitter(
        512,   // chunk size in tokens
        128,   // overlap between chunks
        5,     // min chunk size
        10000, // max chunk size
        true   // keep separator
);

List<Document> chunks = splitter.apply(documents);
```

---

## Summary

In this chapter you will:

- Use `PagePdfDocumentReader` and `TikaDocumentReader` to read PDFs and Word files
- Choose between direct injection (small docs) and RAG (large libraries)
- Build a contract analyser that returns structured `ContractAnalysis` objects
- Know when to split documents with `TokenTextSplitter`

---

## What's Next

In **Chapter 12**, we build semantic search — finding job candidates by skills and experience using similarity search, not keyword matching. "Find me a Java developer with cloud experience" works even if no CV contains those exact words.

*Code for this chapter: [`code/chapter-11-document-intelligence/`](../code/chapter-11-document-intelligence/)*
