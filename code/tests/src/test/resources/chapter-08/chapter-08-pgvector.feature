Feature: Chapter 08 — Persistent Vector Store with PgVector

  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 8 upgrades from SimpleVectorStore (in-memory) to PgVectorStore
  # (PostgreSQL with pgvector extension). The API is identical to Chapter 7.
  #
  # Prerequisites: PostgreSQL with pgvector running via docker-compose.
  #
  # APIs under test:
  #   POST /hr/policy/ask     — ask a question grounded in policy documents
  #   POST /hr/policy/ingest  — ingest additional policy text at runtime
  #
  # Test strategy:
  #   - Validate response shape (unchanged from Chapter 7).
  #   - Validate grounded answers reference known policy facts.
  #   - Validate persistence: ingest then query in same session.
  #   - Validate /ingest shape and chunksIngested.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── /ask — Response shape ─────────────────────────────────────────────────

  Scenario: POST /hr/policy/ask — returns correct response shape
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many days of annual leave do employees get?' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string' }

  Scenario: POST /hr/policy/ask — question is echoed back
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'What is the remote work policy?' }
    When method POST
    Then status 200
    And match response.question == 'What is the remote work policy?'

  Scenario: POST /hr/policy/ask — answer is non-empty
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many sick days are employees entitled to?' }
    When method POST
    Then status 200
    And assert response.answer.length > 0

  # ── /ask — Grounded answers ───────────────────────────────────────────────

  Scenario: POST /hr/policy/ask — annual leave answer references 20 days
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many days of annual leave do full-time employees get per year?' }
    When method POST
    Then status 200
    And match response.answer contains '20'

  Scenario: POST /hr/policy/ask — sick leave answer references 10 days
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many days of paid sick leave are employees entitled to?' }
    When method POST
    Then status 200
    And match response.answer contains '10'

  Scenario: POST /hr/policy/ask — parental leave answer references 16 weeks
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many weeks of parental leave does a primary caregiver receive?' }
    When method POST
    Then status 200
    And match response.answer contains '16'

  Scenario: POST /hr/policy/ask — remote work answer references 3 days
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many days per week can employees work remotely?' }
    When method POST
    Then status 200
    And match response.answer contains '3'

  # ── /ingest ───────────────────────────────────────────────────────────────

  Scenario: POST /hr/policy/ingest — returns correct response shape
    Given path '/hr/policy/ingest'
    And header Content-Type = 'application/json'
    And request { text: 'TechCorp Bonus Policy: All employees are eligible for an annual performance bonus of up to 15% of their base salary.' }
    When method POST
    Then status 200
    And match response == { chunksIngested: '#number', message: '#string' }

  Scenario: POST /hr/policy/ingest — chunksIngested is at least 1
    Given path '/hr/policy/ingest'
    And header Content-Type = 'application/json'
    And request { text: 'TechCorp Relocation Policy: Employees relocating for work receive a one-time allowance of $3,000.' }
    When method POST
    Then status 200
    And assert response.chunksIngested >= 1

  Scenario: POST /hr/policy/ingest then /ask — ingested content is queryable
    Given path '/hr/policy/ingest'
    And header Content-Type = 'application/json'
    And request { text: 'TechCorp Sabbatical Policy: Employees with 5 or more years of service are eligible for a 6-week paid sabbatical.' }
    When method POST
    Then status 200
    And assert response.chunksIngested >= 1

    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How long is the paid sabbatical for eligible employees?' }
    When method POST
    Then status 200
    And assert response.answer.length > 0
