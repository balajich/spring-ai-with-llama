# SmartHR Assistant — Karate API Tests

BDD-style API tests for each chapter of *Spring AI with Llama*.  
Written with [Karate](https://github.com/karatelabs/karate) — tests read like plain English, no extra glue code needed.

---

## Prerequisites

| Requirement | Version | Check |
|---|---|---|
| Java | 25+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |
| Llama model | llama3.2 | `ollama list` |
| curl | any | `curl --version` |
| bash | any | Git Bash on Windows works |

### Install Ollama and pull the model (one-time setup)

```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Windows — download installer from https://ollama.ai

# Pull the model (downloads ~2 GB, only needed once)
ollama pull llama3.2

# Start Ollama
ollama serve
```

> Ollama must be running before the tests start. The Spring Boot app connects to it on `http://localhost:11434`.

---

## Project Structure

```
tests/
├── pom.xml                                          # Karate Maven project (Java 25, Karate 1.3.1)
├── run-tests.sh                                     # Shell script — builds, runs, tests, stops
└── src/test/
    ├── java/com/techcorp/smarthr/karate/
    │   ├── Chapter01Test.java                       # JUnit 5 runner for Chapter 01
    │   └── Chapter02Test.java                       # JUnit 5 runner for Chapter 02
    └── resources/
        ├── karate-config.js                         # Global config: baseUrl, timeouts
        ├── chapter-01/
        │   └── chapter-01-hr-chat.feature           # Chapter 01 scenarios
        └── chapter-02/
            └── chapter-02-core-concepts.feature     # Chapter 02 scenarios
```

---

## Running Tests — Shell Script (Recommended)

The shell script handles everything in the right order:  
**build → start app → wait for port 8080 → run tests → stop app**

```bash
# From the tests/ directory
cd C:/code/spring-ai-with-llama/code/tests

# Run Chapter 01 tests
./run-tests.sh chapter-01

# Run Chapter 02 tests
./run-tests.sh chapter-02
```

### What the script does step by step

```
[1/4] Build    — mvn clean package -DskipTests  (in the chapter directory)
[2/4] Start    — mvn spring-boot:run            (background, logs to /tmp/smarthr-<chapter>.log)
[3/4] Wait     — polls http://localhost:8080 every 3s, timeout 90s
[4/4] Test     — mvn test -Dtest=ChapterXXTest  (in the tests/ directory)
      Cleanup  — kills the app automatically on exit, pass or fail
```

### Script output example

```
============================================================
  SmartHR Karate Tests
  Chapter  : chapter-01
  Module   : chapter-01-hello-spring-ai
  Test     : Chapter01Test
============================================================

[1/4] Building chapter-01-hello-spring-ai ...
      Build OK

[2/4] Starting Spring Boot app on port 8080 ...
      Log file: /tmp/smarthr-chapter-01.log

[3/4] Waiting for app to be ready ...
  App is ready (HTTP 404) after 18s

[4/4] Running Karate tests (Chapter01Test) ...

  Tests run: 9, Failures: 0, Errors: 0

============================================================
  RESULT : ALL TESTS PASSED
  Chapter: chapter-01
  Report : .../tests/target/karate-reports/karate-summary.html
============================================================
```

### Windows (Git Bash)

The script runs in Git Bash on Windows without any changes.  
Open **Git Bash** and run the same commands as above.

---

## Running Tests — Maven Directly

Use this if you want to start the app yourself (e.g., from your IDE) and just run the tests.

### Step 1 — Start Ollama

```bash
ollama serve
```

### Step 2 — Start the chapter app manually

```bash
# Chapter 01
cd C:/code/spring-ai-with-llama/code/chapter-01-hello-spring-ai
mvn spring-boot:run

# Chapter 02
cd C:/code/spring-ai-with-llama/code/chapter-02-core-concepts
mvn spring-boot:run
```

Leave this terminal running. The app starts on `http://localhost:8080`.

### Step 3 — Run the Karate tests

Open a **second terminal** in the `tests/` directory:

```bash
cd C:/code/spring-ai-with-llama/code/tests

# Run Chapter 01 feature file
mvn test -Dtest=Chapter01Test

# Run Chapter 02 feature file
mvn test -Dtest=Chapter02Test
```

### Step 4 — Stop the app

Go back to the first terminal and press `Ctrl + C`.

---

## Using a Different Port or Base URL

If the app is running on a port other than 8080, pass `base.url` as a system property:

```bash
# Shell script (edit the APP_PORT variable inside run-tests.sh)

# Maven direct
mvn test -Dtest=Chapter01Test -Dbase.url=http://localhost:9090
```

---

## What Each Feature File Tests

### `chapter-01/chapter-01-hr-chat.feature`

API: `POST /hr/ask` → `{ "question": "...", "answer": "..." }`

| Scenario | What is checked |
|---|---|
| Response JSON shape | Both `question` and `answer` fields are strings |
| Question echo | `response.question` matches what was sent |
| Non-empty answer | `answer.length > 10` for vacation / health / PTO questions |
| Content-Type header | Response header contains `application/json` |
| Outline — 4 questions | Each common HR question gets a valid response |
| Missing question field | Returns HTTP 400 |
| No request body | Returns HTTP 400 |

> AI answers are non-deterministic — tests validate **structure and presence**, not exact wording.

---

### `chapter-02/chapter-02-core-concepts.feature`

| Endpoint | Scenarios |
|---|---|
| `POST /hr/ask` | Correct shape, `mode == "standard"`, echo |
| `POST /hr/ask/precise` | `mode == "precise"`, non-empty answer |
| `POST /hr/ask/creative` | `mode == "creative"`, non-empty answer |
| `POST /hr/ask/raw` | `mode == "raw"`, echo |
| `GET /hr/ask?question=` | `mode == "standard"`, echo |
| `GET /hr/model/info` | Shape, `ollamaUrl` contains `localhost`, `temperature` in `[0, 1]`, `maxTokens > 0` |
| Scenario Outline | All 4 POST modes return their correct `mode` value |
| Error cases | Missing body → HTTP 400 on `/hr/ask` and `/hr/ask/precise` |

---

## Reading the HTML Report

After every test run, Karate generates a detailed HTML report:

```
tests/target/karate-reports/karate-summary.html
```

Open it in any browser. It shows:

- Pass / fail counts per feature and per scenario
- The full request and response for every step
- Exact failure details with diff output

---

## Troubleshooting

### App does not start within 90 seconds

```bash
# Check the app log written by the script
cat /tmp/smarthr-chapter-01.log

# Most common cause: Ollama is not running
ollama serve

# Check Ollama has the model
ollama list
```

---

### Port 8080 already in use

```bash
# Linux / macOS — find and kill the process
lsof -ti :8080 | xargs kill -9

# Windows (Git Bash)
netstat -ano | grep ":8080"
taskkill /F /PID <PID>
```

---

### `Connection refused` when tests run

The app may have crashed before the tests started.  
Check the log:

```bash
cat /tmp/smarthr-chapter-01.log   # chapter 01
cat /tmp/smarthr-chapter-02.log   # chapter 02
```

---

### Tests pass but the AI answer looks wrong

That is expected behaviour in Chapter 1 — the model answers from its  
public training data, not from TechCorp's actual policies.  
Chapter 4 (RAG) fixes this. The tests only validate response **structure**,  
not answer correctness, for this reason.

---

### Maven cannot find `io.karatelabs:karate-junit5`

The Karate artefact is on Maven Central. If your build is behind a corporate proxy:

```bash
# Force Maven to refresh dependencies
mvn test -Dtest=Chapter01Test -U
```

Or add the Maven Central URL to your `settings.xml` mirror configuration.

---

## Chapter Coverage Map

| Chapter | Feature file | Spring Boot module | Runner class |
|---|---|---|---|
| 01 — Hello Spring AI | `chapter-01/chapter-01-hr-chat.feature` | `chapter-01-hello-spring-ai` | `Chapter01Test` |
| 02 — Core Concepts | `chapter-02/chapter-02-core-concepts.feature` | `chapter-02-core-concepts` | `Chapter02Test` |

As new chapters are added to the book, add:
1. A new `chapter-XX/chapter-XX-<name>.feature` in `src/test/resources/`
2. A new `ChapterXXTest.java` runner in `src/test/java/.../karate/`
3. A new `chapter-XX)` case in `run-tests.sh`
