# Chapter 15 — Semantic Search: Finding Meaning, Not Keywords

> **What you will build:** A skills-based candidate search — Lisa types "backend developer with cloud experience" and gets matching candidates even though their CVs say "AWS Lambda" and "JVM engineer" instead of those exact words.

---

## The Problem We Are Solving

TechCorp's candidate database is full of parsed resumes. Lisa wants to search them:

> "I need a backend developer with cloud experience for the platform team."

A keyword search for that phrase returns **nothing**. Not because there are no matching candidates — there are four — but because none of them wrote those exact words. They wrote "JVM engineer" and "AWS Lambda". "Server-side developer" and "Azure Functions". "SRE" and "Terraform".

Keyword search matches *strings*. Lisa is asking about *meaning*.

---

## What You Will Learn

- How semantic search differs from keyword search
- How similarity search works in a vector store
- How to combine semantic search with exact metadata filters
- How to read and tune similarity scores — with real numbers
- How to build a candidate search endpoint

---

## Semantic vs Keyword Search

```
Query: "backend developer with cloud experience"

Keyword search finds:
  ❌ "JVM engineer" + "AWS Lambda"           (different words, same meaning)
  ❌ "server-side developer" + "Azure"       (missed entirely)
  ❌ "Java developer" + "GCP"                (missed entirely)
  → zero results

Semantic search finds:
  ✅ all three — because it compares meaning, not spelling
```

---

## How Similarity Search Works

Every resume is embedded into a vector when it is indexed. The search query is embedded too, using the same model. The vector store then returns the resumes whose vectors sit closest to the query vector — cosine similarity, not string matching.

The text you embed is what you search by. Everything else becomes **metadata**:

```java
new Document(candidate.resume(), Map.of(
        "candidateId", candidate.candidateId(),
        "name",        candidate.name(),
        "role",        candidate.role(),
        "seniority",   candidate.seniority(),
        "location",    candidate.location()
));
```

That split matters: the **resume text** answers *"who is similar to this idea?"*; the **metadata** answers *"who exactly matches this constraint?"*.

---

## The Search Call

```java
SearchRequest.Builder builder = SearchRequest.builder()
        .query(request.query())
        .topK(topK)
        .similarityThreshold(0.0);

// optional exact filter, ANDed with the semantic search
builder.filterExpression("seniority == 'SENIOR' && location == 'London'");

List<Document> matches = vectorStore.similaritySearch(builder.build());

for (Document doc : matches) {
    Double score = doc.getScore();          // similarity lives on the Document
    String name  = doc.getMetadata().get("name").toString();
}
```

> **API note:** in Spring AI 2.0 this is `SearchRequest.builder().query(...).topK(...)`, and the score is read from `Document::getScore()`. Older snippets using `SearchRequest.query(...).withTopK(...)`, or digging a `"distance"` key out of the metadata map, are pre-GA and will not compile.

---

## Adding Metadata Filters

Filters are exact-match and case-sensitive, ANDed onto the vector search:

```java
private String buildFilter(CandidateSearchRequest request) {
    List<String> clauses = new ArrayList<>();
    if (request.seniority() != null && !request.seniority().isBlank()) {
        clauses.add("seniority == '" + request.seniority().trim() + "'");
    }
    if (request.location() != null && !request.location().isBlank()) {
        clauses.add("location == '" + request.location().trim() + "'");
    }
    return clauses.isEmpty() ? null : String.join(" && ", clauses);
}
```

This is the combination that makes the feature genuinely useful: *"someone who sounds like a cloud engineer (**semantic**), who is SENIOR and in London (**exact**)."*

---

## Try It

```bash
ollama pull nomic-embed-text

cd code/chapter-15-semantic-search
mvn spring-boot:run
```

```bash
curl -s -X POST http://localhost:8080/hr/candidates/search \
  -H "Content-Type: application/json" \
  -d '{"query": "backend developer with cloud experience", "topK": 4}'
```

Real output — **no CV in the fixture contains the query's words**:

```
0.6327  C-1005  Elena Rossi     "Java developer ... microservices ... Google Cloud Platform"
0.6270  C-1003  Aisha Khan      "Server-side developer ... Azure Functions"
0.6087  C-1008  Liam O'Brien    "Mobile developer ... Swift"        ← honest noise
0.5924  C-1001  Priya Sharma    "JVM engineer ... AWS Lambda"
```

Three of the four are exactly who Lisa wanted. Keyword search would have returned zero.

Run the tests:

```bash
cd code/tests
./run-tests.sh chapter-15
```

---

## Tuning the Similarity Threshold — With Real Numbers

Most tutorials tell you to start at `0.75`. **Look at the scores above: every genuine match sits between 0.59 and 0.67.** A `0.75` threshold would have returned *nothing at all*.

| Threshold | Behaviour |
|-----------|-----------|
| `0.9+` | Very strict — near-identical text only |
| `0.75` | Often too strict for short queries + `nomic-embed-text` |
| `0.6` | Balanced for this model |
| `0.0` | Accept all — return everything ranked, let the caller decide |

This chapter uses `0.0` and returns the raw scores, so you can *see* the distribution for your own data before choosing. Thresholds are not universal — they depend on your embedding model, your text length, and your query style. **Measure, then pick.**

Note also Liam the mobile developer at rank 3. Semantic search returns *degrees* of similarity, not a boolean — some noise is normal and honest. That is why `topK` and a human reviewer both still matter.

---

## Summary

In this chapter you:

- Understood how vector similarity search differs from keyword search
- Used `SearchRequest.builder()` with `topK` and `similarityThreshold`
- Combined semantic search with exact metadata filters
- Read real scores and learned why a copied-in threshold can silently return nothing
- Built a candidate search endpoint that finds people by meaning

---

## What's Next

In **Chapter 16**, we build a fully autonomous AI agent — a monthly HR report generator that plans its own steps, calls multiple tools, gathers data from different sources, and produces a complete report without human prompting.

*Code for this chapter: [`code/chapter-15-semantic-search/`](../../code/chapter-15-semantic-search/)*
