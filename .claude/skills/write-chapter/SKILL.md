---
name: write-chapter
description: Author a complete chapter of the "Spring AI with Llama" book — Karate tests first, then implementation, then verify until green, then all collateral (chapter markdown, READMEs, LinkedIn article/post/banner, YouTube text, slide deck, thumbnail, back-patch) and publish to the prompttoapps site (tutorial page + quiz). Use when asked to "write chapter N", "build chapter N", or "start chapter N" in the spring-ai-with-llama repo.
---

# Write a Chapter

Test-first, verify-driven authoring of one chapter of *Spring AI with Llama* (the SmartHR Assistant series for the fictional TechCorp).

**The core principle:** the Karate suite is ground truth. An LLM can bluff a plausible chapter; it cannot bluff a passing test suite against a real Ollama. **Never write collateral before the tests pass.**

---

## Phase 0 — Recon (before writing anything)

1. **Read the existing draft** `content/chapters/chapter-NN-*.md`. Drafts carry a `⚠️ Draft` banner and their snippets are **unvalidated** — treat them as intent, not truth. They routinely contain deprecated APIs.
2. **Verify every artifact/API exists on Maven Central before coding.** Milestone→GA renames are real and silent:
   ```bash
   curl -s "https://repo1.maven.org/maven2/org/springframework/ai/<artifact>/maven-metadata.xml" | grep -oE "<version>2\.0\.0[^<]*</version>" | tail -3
   ```
   Precedent: `spring-ai-advisors-vector-store` → **`spring-ai-vector-store-advisor`** in GA.
3. **Copy the structural pattern** from the previous chapter's module (e.g. `code/chapter-13-streaming-api/`).

---

## Phase 1 — Tests first

**Feature file** → `code/tests/src/test/resources/chapter-NN/chapter-NN-<slug>.feature`

Open with the house-style header comment block: what the chapter introduces, APIs under test, request/response shapes, test strategy, and a note that LLM output is non-deterministic (assert **shape and constraints**, not exact wording).

**Runner** → `code/tests/src/test/java/com/techcorp/smarthr/karate/ChapterNNTest.java`

```java
class ChapterNNTest {
    @Karate.Test
    Karate chapterNN() {
        return Karate.run("classpath:chapter-NN/chapter-NN-<slug>.feature");
    }
}
```

**Fixtures** — generate them; don't hand-wave. Precedent: `hazard-photo.png` (PIL), `employment-contract.pdf` (reportlab). **Bake in deliberate edge cases** — the ch14 contract has a 24-month worldwide non-compete so the analyser has a red flag to catch.

**Register in `code/tests/run-tests.sh` — 3 separate spots:**
1. the usage `echo` list
2. the `case` branch (`APP_MODULE` / `TEST_CLASS`, plus `EXTRA_MODULES`/`EXTRA_PORTS` for multi-process chapters)
3. the "Available:" list in the error branch

---

## Phase 2 — Implement

```
code/chapter-NN-<slug>/
├── pom.xml
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   └── model/
    └── resources/application.yml
```

Stack (keep pinned): **Java 25 · Spring Boot 4.1.0 · Spring AI 2.0.0**.

---

## Phase 3 — Verify loop (this is what makes it agentic)

```bash
export JAVA_HOME="C:/Program Files/Java/jdk-25.0.3"

# compile
cd code/chapter-NN-<slug> && mvn -q clean compile

# ensure Ollama, then run the app on 8123 (NOT 8080)
curl -s -o /dev/null http://localhost:11434/api/tags || (nohup ollama serve >/tmp/ollama.log 2>&1 &)
nohup mvn -q spring-boot:run -Dspring-boot.run.arguments="--server.port=8123" >/tmp/chNN.log 2>&1 &
# wait for "Started .*Application" in the log

# smoke test the real endpoint first — catches what compile can't
curl -s -X POST http://localhost:8123/hr/... -H "Content-Type: application/json" -d '{...}'

# then the suite
cd ../tests && mvn test -Dtest=ChapterNNTest -Dbase.url=http://localhost:8123

# always clean up
powershell -Command "Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force"
```

**Iterate until 100% green.** When a test fails, get the *real* signal — read the raw model output and the actual exception (temporarily instrument the catch block if needed), don't guess. Remove instrumentation before finishing.

---

## Phase 4 — Docs

- **Module `README.md`** — architecture SVG diagram, prerequisites table + the standard version note, endpoints table, curl examples, limitations, common-errors table, project structure. Prereqs are pinned: **Java 25.0.3 · Maven 3.9.16 · Ollama 0.31.1**.
- **Finalize `content/chapters/chapter-NN-*.md`** — strip the `⚠️ Draft` banner; rewrite every snippet to match code that actually ran; add a "Try It" section and the tests command.
- **Root `README.md` — 3 spots:** chapter-table status → ✅ Complete, the `code/` dir listing, and the `run-tests.sh` examples list.

---

## Phase 5 — Collateral (only after green)

- **LinkedIn article** → `content/linkedin/chapter-NN-<slug>.md` — story-led, with the "Series So Far" list using real URLs from `content/linkedin/links.txt` (unpublished = *(link coming soon)*; current = **bold** + `← you are here`). Footer: *Built with Spring Boot 4.1, Spring AI 2.0, Java 25, and Ollama…*
- **LinkedIn short post** → `content/linkedin/chapter-NN-post.md` — punchy hook + 3 short paragraphs + link + hashtags; names the banner to attach.
- **LinkedIn banner** → `content/linkedin/chapter-NN-banner.png` (1200×627). **Do not hand-roll it**: add a `CHAPTERS` entry in `content/linkedin/build_banners.py` and run `python build_banners.py NN`. (Note: `linkedin-banner.png` is gitignored by exact name — the `chapter-NN-banner.png` naming is what makes it commit.)
- **YouTube text** — title options, description (front-load the differentiator: local, no API keys), timestamps, tags, SEO keywords. Back-link prior videos from `content/slides/youtube-links.txt`.
- **Slide deck** → `content/slides/build-NN-<slug>.js` → `.pptx`. Use `./theme.js` helpers (`applyMaster`, `addKicker`, `addSectionTitle`, `addCodePanel`, `addNodeDivider`, `addCreditsSlide`). End with Like & Subscribe → Credits. QA programmatically with python-pptx for overflow (>7.5" bottom, >13.3" right) and footer collisions (footer sits at 6.95").
- **Thumbnail** → `content/slides/thumbnails/NN-<slug>.png` (1280×720) — append a `THUMBS` entry in `content/slides/thumbnail.py` and rerun it.
- **Back-patch the previous chapter** — update chapter N-1's "What's Next" and its Series-So-Far list to point at the new chapter.

---

## Phase 6 — Publish to the website

Separate repo: **`C:\code\prompttoapps\site`** (plain static HTML — **no build step / no md→html generator**, pages are hand-maintained).

### 6a. Tutorial page
`tutorials/spring-ai-llama/chapter-NN-<slug>.html`

Pages for all 20 chapters already exist, but **unwritten ones hold the stale draft**. When a chapter is finished you must **refresh the page from the finalized `content/chapters/chapter-NN-*.md`**:

- Convert the markdown body to HTML and keep the existing site chrome verbatim — `<head>` (title `Chapter N: <Title> &mdash; PromptToApps`, `../../assets/css/style.css`), `<header class="site-header">` nav, and:
  ```html
  <main class="wrap"><article class="post">
    <div class="meta"><a href="index.html">Spring AI with Llama</a> &middot; Chapter N</div>
    <h1><Chapter Title></h1>
  ```
- ⚠️ **Strip the `⚠️ Draft — …not yet been validated…` blockquote.** This is the #1 thing that gets missed — a finished chapter shipping the draft banner makes the site look unmaintained.
- The series index `tutorials/spring-ai-llama/index.html` already links all 20 chapters — **verify only**, no edit needed.

### 6b. Quiz data
`assets/js/quiz-data.js` — one `QUIZ_DATA` object, keyed `<topic>.<chapterKey>`. Add `springai.chNN` **in chapter order**:

```js
    chNN: {
      title: "Ch N · <Short Title>",
      description: "<one line — what the quiz covers>",
      questions: [
        {
          q: "<question>",
          options: ["<a>", "<b>", "<c>", "<d>"],   // 4 options
          answer: 1,                                // 0-based index of correct option
          explanation: "<why — teach, don't just confirm>"
        },
        // exactly 12 questions — house style, consistent across every chapter
      ]
    },
```
House style: **exactly 12 questions**, 4 plausible options each (no throwaway distractors); `explanation` teaches the concept rather than just confirming the answer, and may use `backticks`. Draw questions from the chapter's real content and the gotchas actually hit while building it.

### 6c. Quiz nav button
`quiz/index.html` — add the leaf button next to the existing ones (they currently stop at ch13):
```html
<button class="tree-leaf tree-leaf--sub" onclick="loadQuiz('springai','chNN')">Ch N · <Short Title></button>
```

### 6d. Verify
Open `quiz/index.html#springai/chNN` and the tutorial page in a browser; confirm the quiz loads, answers/explanations render, and the tutorial has no draft banner.

---

## Conventions & hard-won gotchas

| Rule | Why |
|---|---|
| **Boxed types in records** (`Integer`, `Boolean` — never `int`/`boolean`) | Spring AI 2.0 uses **Jackson 3**; it throws `Cannot map null into type int` when the model omits a field. This broke ch5. |
| Structured output: `temperature(0.0)` **and name every field** in the prompt | Small models otherwise invert keys/values (ch5 returned `{"Priya Sharma":"priya@example.com"}`). Avoid negative "do NOT" instructions — they backfire. |
| `.options(ChatOptions.builder()...)` — **no `.build()`** | `.options()` takes the *builder*, not a built `ChatOptions`. |
| Run apps on **port 8123** | 8080 is held by the harness's uvicorn preview server (unkillable from Windows). |
| `TokenTextSplitter.builder()` | The constructor is deprecated since 2.0.0-M3. |
| Karate **1.5.2** (`io.karatelabs`) | 1.3.1's bundled GraalVM calls `sun.misc.Unsafe.ensureClassInitialized`, removed in JDK 25. Java package is still `com.intuit.karate`. |
| Kill stray `java` between runs | Port conflicts otherwise. |
| `.js` and `.py` are **gitignored** | Only the generated `.pptx` / `.png` are tracked. Don't be surprised the build scripts don't commit. |
| Chapters **compound** | Reuse earlier lessons deliberately (ch14 used ch5's boxed-type fix proactively and avoided the bug). |

---

## Definition of done

- [ ] Karate suite 100% green against a real Ollama
- [ ] Runtime smoke-tested with `curl` (not just tests)
- [ ] `run-tests.sh` registered in all 3 spots
- [ ] Draft banner stripped; chapter snippets match code that ran
- [ ] Root README updated in all 3 spots
- [ ] LinkedIn article + post + banner
- [ ] YouTube text + thumbnail
- [ ] Slide deck built and QA'd
- [ ] Previous chapter back-patched
- [ ] **Website** — tutorial page refreshed from the final markdown **with the draft banner stripped**
- [ ] **Website** — `quiz-data.js` entry added (**12** MCQs) + `quiz/index.html` nav button
- [ ] No stray `java` processes; debug instrumentation removed
