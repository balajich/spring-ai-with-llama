Feature: Chapter 09 — Graph RAG with Neo4j

  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 9 upgrades from PgVectorStore to Neo4jVectorStore. Policy sections
  # are connected by graph edges, enabling Graph RAG to answer multi-topic
  # questions that flat vector search misses.
  #
  # Prerequisites: Neo4j running via docker-compose.
  #
  # APIs under test:
  #   POST /hr/policy/ask     — ask a question; Graph RAG retrieves connected chunks
  #   POST /hr/policy/ingest  — ingest additional policy text at runtime
  #
  # Test strategy:
  #   - Validate response shape (unchanged from Chapters 7 and 8).
  #   - Validate single-topic grounded answers.
  #   - Validate multi-topic question surfaces connected policy sections.
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

  # ── /ask — Single-topic grounded answers ─────────────────────────────────

  Scenario: POST /hr/policy/ask — annual leave references 20 days
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many days of annual leave do full-time employees get per year?' }
    When method POST
    Then status 200
    And match response.answer contains '20'

  Scenario: POST /hr/policy/ask — parental leave references 16 weeks
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many weeks of parental leave does a primary caregiver receive?' }
    When method POST
    Then status 200
    And match response.answer contains '16'

  # ── /ask — Multi-topic Graph RAG ─────────────────────────────────────────

  Scenario: POST /hr/policy/ask — multi-topic question surfaces connected sections
    # This question spans parental leave AND sick leave — connected by a graph edge.
    # Graph RAG retrieves both; plain vector search would return only one.
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'What happens if my parental leave runs out and I am still unwell?' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string' }
    And assert response.answer.length > 0

  Scenario: POST /hr/policy/ask — onboarding and IT question surfaces connected sections
    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'What laptop do new engineers get and how do they request it during onboarding?' }
    When method POST
    Then status 200
    And assert response.answer.length > 0

  # ── /ingest ───────────────────────────────────────────────────────────────

  Scenario: POST /hr/policy/ingest — returns correct response shape
    Given path '/hr/policy/ingest'
    And header Content-Type = 'application/json'
    And request { text: 'TechCorp Bonus Policy: All employees are eligible for an annual performance bonus of up to 15%.' }
    When method POST
    Then status 200
    And match response == { chunksIngested: '#number', message: '#string' }

  Scenario: POST /hr/policy/ingest — chunksIngested is at least 1
    Given path '/hr/policy/ingest'
    And header Content-Type = 'application/json'
    And request { text: 'TechCorp Sabbatical Policy: Employees with 5 or more years of service are eligible for a 6-week paid sabbatical.' }
    When method POST
    Then status 200
    And assert response.chunksIngested >= 1

  Scenario: POST /hr/policy/ingest then /ask — ingested content is queryable
    Given path '/hr/policy/ingest'
    And header Content-Type = 'application/json'
    And request { text: 'TechCorp Stock Options Policy: All senior engineers receive stock options vesting over 4 years.' }
    When method POST
    Then status 200
    And assert response.chunksIngested >= 1

    Given path '/hr/policy/ask'
    And header Content-Type = 'application/json'
    And request { question: 'Do senior engineers receive stock options?' }
    When method POST
    Then status 200
    And assert response.answer.length > 0
