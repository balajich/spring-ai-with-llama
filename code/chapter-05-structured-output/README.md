# Chapter 5 — Structured Output: Asking the AI to Serve JSON Instead of Raw Text

Parse unstructured resume text into a typed `ResumeProfile` Java record using Spring AI's `BeanOutputConverter`.

---

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Java | 25+ | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| Ollama | latest | `ollama --version` |

---

## Setup

### 1. Pull the model

```bash
ollama pull llama3.2
```

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
cd code/chapter-05-structured-output
mvn spring-boot:run
```

The app starts on **http://localhost:8080**

---

## Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/hr/resume/parse` | Parse raw resume text into a structured `ResumeProfile` |

**Request shape:**
```json
{
  "resumeText": "<raw resume text>"
}
```

**Response shape:**
```json
{
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "skills": ["Java", "Spring Boot", "Kubernetes"],
  "yearsOfExperience": 5,
  "currentRole": "Senior Software Engineer",
  "education": "B.Tech Computer Science, IIT Delhi"
}
```

---

## Example curl Commands

### Parse a simple resume

```bash
curl -s -X POST http://localhost:8080/hr/resume/parse \
  -H "Content-Type: application/json" \
  -d '{
    "resumeText": "Priya Sharma | priya@example.com\n5 years Java, Spring Boot, AWS\nSenior Engineer at Infosys\nB.Tech CS IIT Delhi 2018"
  }'
```

**Response:**
```json
{
  "name": "Priya Sharma",
  "email": "priya@example.com",
  "skills": ["Java", "Spring Boot", "AWS"],
  "yearsOfExperience": 5,
  "currentRole": "Senior Engineer at Infosys",
  "education": "B.Tech CS IIT Delhi 2018"
}
```

---

### Parse a more detailed resume

```bash
curl -s -X POST http://localhost:8080/hr/resume/parse \
  -H "Content-Type: application/json" \
  -d '{
    "resumeText": "John Smith\njohn.smith@email.com\n\nSummary: 8 years of experience in backend development.\n\nSkills: Java, Kotlin, Spring Boot, PostgreSQL, Docker, Kubernetes\n\nExperience:\n- Lead Engineer, TechStartup Inc. (2020–present)\n- Backend Developer, Accenture (2016–2020)\n\nEducation: M.Sc. Computer Science, University of Manchester, 2016"
  }'
```

---

## How It Works

`BeanOutputConverter` generates a JSON schema from `ResumeProfile` and appends it to the prompt via the `{format}` placeholder. The model is instructed to return JSON that matches the schema. Spring AI then deserialises the response into the Java record automatically.

```
Resume text (input)
        ↓
Prompt + JSON schema injected via {format}
        ↓
Ollama / Llama generates JSON matching the schema
        ↓
BeanOutputConverter.convert() → ResumeProfile record
```

> **Tip:** Temperature is set to `0.0` in `application.yml` for structured output tasks — deterministic output reduces JSON parse failures.

---

## Error Handling

If the model returns malformed JSON, the endpoint returns `422 Unprocessable Entity`:

```json
{
  "status": 422,
  "error": "Unprocessable Entity",
  "message": "Could not parse resume. Try providing more structured text."
}
```

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused localhost:11434` | Ollama not running | Run `ollama serve` |
| `model not found` | Model not downloaded | Run `ollama pull llama3.2` |
| `422 Unprocessable Entity` | Model returned invalid JSON | Provide more structured resume text |
| `Port 8080 already in use` | Another app on 8080 | Set `server.port: 8081` in `application.yml` |

---

## Project Structure

```
chapter-05-structured-output/
├── pom.xml
├── README.md
└── src/main/
    ├── java/com/techcorp/smarthr/
    │   ├── SmartHrAssistantApplication.java
    │   ├── controller/
    │   │   └── ResumeController.java        ← /hr/resume/parse endpoint
    │   └── model/
    │       ├── ResumeParseRequest.java
    │       └── ResumeProfile.java           ← typed output record
    └── resources/
        └── application.yml                 ← temperature 0.0 for consistent JSON
```

---

*Full chapter write-up: [`chapters/chapter-05-structured-output.md`](../../chapters/chapter-05-structured-output.md)*
