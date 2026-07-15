# Chapter 20 — Production Deployment: Docker, Observability, and Going Live

> ⚠️ **Draft** — This chapter is a work in progress. Code snippets have not yet been validated against the running codebase and may need fixes before use.

> **What you will build:** A production-ready SmartHR Assistant — Dockerised, health-checked, observable with Micrometer metrics, running Ollama in a container, and deployed behind a reverse proxy. The complete system Sarah can hand to TechCorp's IT team to run.

---

## The Problem We Are Solving

The SmartHR Assistant works perfectly on Dev's laptop. Now TechCorp's IT team needs to run it on a server. They ask:

> "How do we deploy this? How do we monitor it? What happens if Ollama crashes? How do we update the Llama model without downtime?"

This chapter answers all of it.

---

## What You Will Learn

- Dockerising a Spring Boot app with Ollama
- Docker Compose for the full stack
- Health checks for the app and Ollama
- Micrometer metrics for AI call monitoring
- Structured logging for AI interactions
- Zero-downtime model updates
- Production configuration checklist

---

## Dockerfile

```dockerfile
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY target/smarthr-assistant-*.jar app.jar

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## Docker Compose — Full Stack

```yaml
# docker-compose.yml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-models:/root/.ollama    # persist downloaded models
    healthcheck:
      test: ["CMD", "ollama", "list"]
      interval: 30s
      timeout: 10s
      retries: 5

  smarthr:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_AI_OLLAMA_BASE_URL: http://ollama:11434
      SPRING_AI_OLLAMA_CHAT_OPTIONS_MODEL: llama3.2
    depends_on:
      ollama:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: smarthr
      POSTGRES_USER: smarthr
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  ollama-models:
  postgres-data:
```

**Start the full stack:**
```bash
docker compose up -d

# Pull the model into the Ollama container (one time)
docker compose exec ollama ollama pull llama3.2
```

---

## Micrometer Metrics for AI Calls

```java
@Service
public class MeteredChatService {

    private final MeterRegistry registry;
    private final ChatClient chatClient;

    public String ask(String question) {
        return Timer.builder("smarthr.ai.call")
                .tag("endpoint", "hr-ask")
                .register(registry)
                .record(() -> chatClient.prompt().user(question).call().content());
    }
}
```

Add Actuator and Prometheus:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

```properties
management.endpoints.web.exposure.include=health,metrics,prometheus
management.endpoint.health.show-details=always
```

Metrics to monitor:
- `smarthr.ai.call` — response time per endpoint
- `smarthr.ai.call.count` — request volume
- `jvm.memory.used` — heap (grows with chat memory)

---

## Production Configuration

```properties
# application-prod.properties

# Ollama — point to container
spring.ai.ollama.base-url=http://ollama:11434

# Conservative defaults for production
spring.ai.ollama.chat.options.temperature=0.3
spring.ai.ollama.chat.options.num-predict=500

# Connection timeouts
spring.ai.ollama.chat.options.timeout=30s

# Database
spring.datasource.url=jdbc:postgresql://postgres:5432/smarthr
spring.datasource.username=smarthr
spring.datasource.password=${DB_PASSWORD}

# Actuator
management.endpoints.web.exposure.include=health,metrics,prometheus
```

---

## Zero-Downtime Model Updates

```bash
# 1. Pull new model while old one is still running
docker compose exec ollama ollama pull llama3.2:8b

# 2. Update application.yml
# spring.ai.ollama.chat.options.model: llama3.2:8b

# 3. Rolling restart
docker compose up -d --no-deps smarthr
```

Ollama serves the old model until the app restarts — no gap in service.

---

## Production Checklist

| Item | Chapter | Status |
|------|---------|--------|
| Prompt injection guard | 16 | |
| PII scrubbing from logs | 16 | |
| Rate limiting | 15 | |
| HTTPS (TLS termination at proxy) | 17 | |
| Authentication on endpoints | 17 | |
| Health checks | 17 | |
| Metrics and alerts | 17 | |
| Model pinned to specific version | 17 | |
| Database backups | 17 | |
| Log aggregation | 17 | |

---

## Summary

In this final chapter you:

- Dockerised the SmartHR Assistant and Ollama together
- Used Docker Compose for the full production stack
- Added Micrometer metrics for AI call monitoring
- Configured production `application.yml`
- Implemented a zero-downtime model update strategy
- Completed the production readiness checklist

---

## The End — What You Built

Starting from a blank Spring Boot project, you built a production-ready AI-powered HR platform:

```
Chapter 1   → Basic HR Q&A endpoint
Chapter 2   → Controlled, mode-based responses
Chapter 3   → Multi-model support
Chapter 4   → Personalised, template-driven responses
Chapter 5   → Resume parsing to typed Java objects
Chapter 6   → Stateful onboarding chatbot
Chapter 7   → Policy document Q&A with RAG
Chapter 8   → Interview scheduling with function calling
Chapter 9   → Workplace safety analysis with vision
Chapter 10  → Real-time streaming responses
Chapter 11  → Contract intelligence from PDFs
Chapter 12  → Semantic candidate search
Chapter 13  → Autonomous monthly report agent
Chapter 14  → Automated AI quality evaluation
Chapter 15  → Bulk processing and caching
Chapter 16  → Security hardening
Chapter 17  → Production deployment ← You are here
```

Sarah's Monday mornings are no longer about answering the same questions. They are about reviewing what the SmartHR Assistant accomplished overnight.

*Code for this chapter: [`code/chapter-20-production-deployment/`](../../code/chapter-20-production-deployment/)*
