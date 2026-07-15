# Chapter 15 — Semantic Search: Finding Meaning, Not Keywords

Search 800 resumes by *meaning*. Lisa types "backend developer with cloud experience" and finds the candidate whose CV says "JVM engineer" and "AWS Lambda" — words her query never used.

<svg viewBox="0 0 580 300" xmlns="http://www.w3.org/2000/svg" role="img" font-family="'Segoe UI', system-ui, sans-serif">
  <title>Chapter 15 — Semantic search over embedded resumes</title>
  <desc>A query is embedded by nomic-embed-text and compared against embedded resumes in a vector store; metadata filters narrow the result.</desc>
  <rect width="580" height="300" fill="#f8f9fa" rx="12"/>
  <rect x="20" y="105" width="130" height="90" rx="10" fill="white" stroke="#b0568c" stroke-width="2"/>
  <text x="85" y="134" text-anchor="middle" font-size="12" font-weight="700" fill="#7d2a5c">"backend dev</text>
  <text x="85" y="150" text-anchor="middle" font-size="12" font-weight="700" fill="#7d2a5c">with cloud"</text>
  <text x="85" y="172" text-anchor="middle" font-size="10" fill="#999">the query</text>
  <rect x="185" y="80" width="185" height="140" rx="10" fill="white" stroke="#e67e22" stroke-width="2"/>
  <text x="277" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#7a3b00">Spring AI</text>
  <text x="277" y="126" text-anchor="middle" font-size="10" fill="#999">JVM</text>
  <text x="277" y="150" text-anchor="middle" font-size="10" fill="#555">nomic-embed-text</text>
  <text x="277" y="167" text-anchor="middle" font-size="10" fill="#555">SearchRequest.builder()</text>
  <text x="277" y="184" text-anchor="middle" font-size="10" fill="#555">+ metadata filter</text>
  <rect x="405" y="80" width="155" height="140" rx="10" fill="white" stroke="#5b6abf" stroke-width="2"/>
  <text x="482" y="108" text-anchor="middle" font-size="13" font-weight="700" fill="#2d3494">VectorStore</text>
  <text x="482" y="126" text-anchor="middle" font-size="10" fill="#999">8 embedded resumes</text>
  <rect x="420" y="140" width="125" height="24" rx="6" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.2"/>
  <text x="482" y="156" text-anchor="middle" font-size="9" font-weight="700" fill="#2d3494">"JVM engineer, AWS"</text>
  <rect x="420" y="170" width="125" height="24" rx="6" fill="#eef0ff" stroke="#5b6abf" stroke-width="1.2"/>
  <text x="482" y="186" text-anchor="middle" font-size="9" font-weight="700" fill="#2d3494">"server-side, Azure"</text>
  <path d="M 150 150 L 185 150" fill="none" stroke="#b0568c" stroke-width="1.8" marker-end="url(#s15a)"/>
  <path d="M 370 140 L 405 140" fill="none" stroke="#5b6abf" stroke-width="1.8" stroke-dasharray="5,3" marker-end="url(#s15b)"/>
  <text x="388" y="132" text-anchor="middle" font-size="8" fill="#2d3494">vector</text>
  <path d="M 405 175 L 370 175" fill="none" stroke="#5b6abf" stroke-width="1.8" marker-end="url(#s15b)"/>
  <text x="388" y="192" text-anchor="middle" font-size="8" fill="#2d3494">top-K</text>
  <text x="290" y="248" text-anchor="middle" font-size="11" fill="#555">no keyword overlap — matched by meaning</text>
  <text x="290" y="268" text-anchor="middle" font-size="10" fill="#aaa">cosine similarity + exact metadata filters</text>
  <defs>
    <marker id="s15a" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#b0568c"/></marker>
    <marker id="s15b" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#5b6abf"/></marker>
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
ollama pull nomic-embed-text   # the embedding model — required
ollama serve                   # if not already running
```

> No Docker needed. This chapter uses an in-memory `SimpleVectorStore`, so the 8 sample resumes are re-embedded on each start.

---

## Run the Application

```bash
cd code/chapter-15-semantic-search
mvn spring-boot:run
```

Starts on **http://localhost:8080**. On boot it embeds every resume in `candidates.json`.

---

## How It Works

The resume text is what gets embedded — that's what you search *by meaning*. Everything else (id, name, role, seniority, location) is stored as **metadata**, which is what makes exact filtering possible:

```java
new Document(candidate.resume(), Map.of(
        "candidateId", candidate.candidateId(),
        "name",        candidate.name(),
        "seniority",   candidate.seniority(),
        "location",    candidate.location()
));
```

Search embeds the query and finds the nearest vectors:

```java
SearchRequest.Builder builder = SearchRequest.builder()
        .query(request.query())
        .topK(topK)
        .similarityThreshold(0.0);

builder.filterExpression("seniority == 'SENIOR' && location == 'London'");  // optional

List<Document> matches = vectorStore.similaritySearch(builder.build());
double score = matches.get(0).getScore();   // similarity lives on the Document
```

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `GET` | `/hr/candidates` | List all indexed candidates |
| `POST` | `/hr/candidates/search` | Semantic search — `{ query, topK, seniority, location }` → `[CandidateMatch]` |

---

## Example Usage

```bash
# Meaning, not keywords — no CV contains this phrase
curl -s -X POST http://localhost:8080/hr/candidates/search \
  -H "Content-Type: application/json" \
  -d '{"query": "backend developer with cloud experience", "topK": 4}'

# Semantic query + exact filters
curl -s -X POST http://localhost:8080/hr/candidates/search \
  -H "Content-Type: application/json" \
  -d '{"query": "cloud infrastructure", "topK": 10, "seniority": "SENIOR", "location": "London"}'
```

Real output for the first query — note **none** of these resumes contain the words "backend", "developer with cloud", yet all are correct hits:

```
0.6327  C-1005  Elena Rossi     "Java developer ... microservices ... Google Cloud Platform"
0.6270  C-1003  Aisha Khan      "Server-side developer ... Azure Functions"
0.6087  C-1008  Liam O'Brien    "Mobile developer ... Swift"        ← honest noise
0.5924  C-1001  Priya Sharma    "JVM engineer ... AWS Lambda"
```

A keyword search would have returned **zero** of them.

---

## Tuning the Similarity Threshold

| Threshold | Behaviour |
|-----------|-----------|
| `0.9+` | Very strict — near-identical text only |
| `0.75` | Strict — often too strict for short queries |
| `0.6` | Balanced for `nomic-embed-text` |
| `0.0` | Accept all — return everything ranked, let the caller decide |

This chapter uses `0.0` and returns the scores so you can see the real distribution and tune for *your* data. Note the scores above cluster in the **0.59–0.67** band — a `0.75` threshold (as often suggested) would have returned **nothing**. Always measure before you pick a threshold.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | `ollama serve` |
| `model not found` | Embedding model missing | `ollama pull nomic-embed-text` |
| Empty results for every query | Threshold too high for your model | Lower `similarityThreshold` — see the table above |
| Filter returns nothing | Metadata key/value mismatch (case-sensitive) | `seniority == 'SENIOR'`, not `'senior'` |
| `400 query must not be blank` | Empty query | Send a real query string |

---

## Project Structure

```
chapter-15-semantic-search/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── config/
    │   │   └── CandidateIndexConfig.java    ← embeds resumes + metadata at startup
    │   ├── controller/
    │   │   └── CandidateSearchController.java
    │   └── model/
    │       ├── Candidate.java
    │       ├── CandidateSearchRequest.java
    │       └── CandidateMatch.java
    └── resources/
        ├── application.yml
        └── candidates/candidates.json       ← 8 candidates with deliberately varied vocabulary
```

---

*Full chapter write-up: [`content/chapters/chapter-15-semantic-search.md`](../../content/chapters/chapter-15-semantic-search.md)*
