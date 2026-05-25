# Chapter 12 — Semantic Search: Finding Meaning, Not Keywords

> **What you will build:** A skills-based candidate search — Lisa types "find me a backend developer with cloud and microservices experience" and gets matching candidates even if their CVs say "AWS Lambda" and "distributed systems" instead of those exact words.

---

## The Problem We Are Solving

TechCorp's candidate database has 800 parsed resumes from Chapter 5. Lisa wants to search them:

> "I need a Java developer with cloud experience for the platform team."

A keyword search for "Java developer cloud experience" misses candidates who wrote "JVM engineer" and "AWS" on their resume. Semantic search finds them because it searches by *meaning*, not exact words.

---

## What You Will Learn

- How semantic search differs from keyword search
- How similarity search works in a vector store
- How to implement metadata filters alongside semantic search
- How to build a candidate search endpoint
- How to tune similarity thresholds

---

## Semantic vs Keyword Search

```
Query: "backend developer with cloud experience"

Keyword search finds:
  ✅ "backend developer" + "cloud experience" (exact match)
  ❌ "server-side engineer" + "AWS Lambda"       (different words, same meaning)
  ❌ "JVM developer" + "distributed systems"     (missed entirely)

Semantic search finds:
  ✅ "backend developer" + "cloud experience"
  ✅ "server-side engineer" + "AWS Lambda"       (similar meaning)
  ✅ "JVM developer" + "distributed systems"     (similar domain)
```

---

## How Similarity Search Works

Every resume was embedded as a vector when it was ingested (Chapter 7). The search query is also embedded. The vector store finds the resumes whose vectors are mathematically closest to the query vector.

```java
// Embed the search query and find similar documents
List<Document> matches = vectorStore.similaritySearch(
        SearchRequest.query("backend developer with cloud experience")
                .withTopK(5)                    // return top 5 matches
                .withSimilarityThreshold(0.75)  // minimum similarity score
);
```

---

## Adding Metadata Filters

Combine semantic search with exact filters:

```java
// "Find senior Java developers in the London office"
List<Document> matches = vectorStore.similaritySearch(
        SearchRequest.query("Java developer")
                .withTopK(10)
                .withFilterExpression("seniority == 'SENIOR' && location == 'London'")
);
```

Metadata is stored alongside documents when ingested:

```java
Document resumeDoc = new Document(resumeText, Map.of(
        "candidateId", candidate.id(),
        "seniority",   candidate.seniority(),
        "location",    candidate.location(),
        "role",        candidate.role()
));
vectorStore.add(List.of(resumeDoc));
```

---

## What You Will Build — Candidate Search Endpoint

```java
public record SearchRequest(String query, int topK, String seniorityFilter) {}
public record CandidateMatch(String candidateId, String name, double score, String summary) {}

@PostMapping("/hr/candidates/search")
public List<CandidateMatch> searchCandidates(@RequestBody SearchRequest request) {

    var filter = request.seniorityFilter() != null
            ? "seniority == '" + request.seniorityFilter() + "'"
            : null;

    List<Document> matches = vectorStore.similaritySearch(
            org.springframework.ai.vectorstore.SearchRequest
                    .query(request.query())
                    .withTopK(request.topK())
                    .withSimilarityThreshold(0.70)
                    .withFilterExpression(filter)
    );

    return matches.stream()
            .map(doc -> new CandidateMatch(
                    doc.getMetadata().get("candidateId").toString(),
                    doc.getMetadata().get("name").toString(),
                    (Double) doc.getMetadata().get("distance"),
                    doc.getText().substring(0, Math.min(200, doc.getText().length()))
            ))
            .toList();
}
```

---

## Tuning Similarity Threshold

| Threshold | Behaviour |
|-----------|-----------|
| `0.9+` | Very strict — only near-identical matches |
| `0.75` | Balanced — recommended starting point |
| `0.6` | Broad — more results, lower precision |
| `0.5` | Very broad — catches distant matches |

Start at `0.75` and adjust based on whether you get too few or too many results.

---

## Summary

In this chapter you will:

- Understand how vector similarity search works vs keyword search
- Use `vectorStore.similaritySearch()` with top-K and threshold controls
- Add metadata filters to combine semantic and exact-match filtering
- Build a candidate search endpoint that finds matches by meaning

---

## What's Next

In **Chapter 13**, we build a fully autonomous AI agent — a monthly HR report generator that plans its own steps, calls multiple tools, gathers data from different sources, and produces a complete report without human prompting.

*Code for this chapter: [`code/chapter-12-semantic-search/`](../code/chapter-12-semantic-search/)*
