Feature: Chapter 15 — Semantic Search: Finding Meaning, Not Keywords
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 15 searches the candidate database by MEANING, not keywords.
  # Eight candidate resumes are embedded into a SimpleVectorStore at startup
  # with metadata (candidateId, name, role, seniority, location). A query is
  # embedded too, and the store returns the nearest vectors.
  #
  # APIs under test:
  #   POST /hr/candidates/search  — { query, topK, seniority, location }
  #                                 → [ CandidateMatch ]
  #   GET  /hr/candidates         — list all indexed candidates (sanity)
  #
  # CandidateMatch shape:
  #   { candidateId, name, role, seniority, location, score, summary }
  #
  # Test strategy:
  #   - Embeddings are DETERMINISTIC (same model + text = same vector), so
  #     unlike the LLM chapters we can assert real retrieval behaviour, not
  #     just response shape.
  #   - The fixture is deliberately adversarial: no CV contains the phrase
  #     "backend developer with cloud experience". Candidates say "JVM
  #     engineer / AWS Lambda", "server-side developer / Azure Functions",
  #     "SRE / AWS". A keyword search finds nothing; semantic search finds them.
  #   - Frontend / data-science / QA / mobile candidates act as negatives.
  #   - Metadata filters are exact-match, so they are asserted strictly.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Sanity: the index is populated ───────────────────────────────────────────

  Scenario: GET /hr/candidates — all fixture candidates are indexed
    Given path '/hr/candidates'
    When method GET
    Then status 200
    And match response == '#[8]'
    And match each response contains { candidateId: '#string', name: '#string', seniority: '#string' }

  # ── Response shape ───────────────────────────────────────────────────────────

  Scenario: POST /hr/candidates/search — returns correctly shaped matches
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'backend developer with cloud experience', topK: 5 }
    When method POST
    Then status 200
    And match response == '#array'
    And assert response.length > 0
    And match each response contains { candidateId: '#string', name: '#string', role: '#string', seniority: '#string', location: '#string', score: '#number', summary: '#string' }

  # ── The whole point: meaning, not keywords ───────────────────────────────────

  Scenario: POST /hr/candidates/search — finds candidates whose CVs never use the query's words
    # No resume contains "backend developer with cloud experience".
    # Priya says "JVM engineer / AWS Lambda"; Aisha "server-side developer /
    # Azure Functions"; Sofia "SRE / AWS"; Elena "Java / GCP".
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'backend developer with cloud experience', topK: 4 }
    When method POST
    Then status 200
    And assert response.length > 0
    * def ids = $response[*].candidateId
    * def backendish = ['C-1001', 'C-1003', 'C-1005', 'C-1007']
    * def hits = ids.filter(function(x){ return backendish.indexOf(x) >= 0 })
    And assert hits.length > 0

  Scenario: POST /hr/candidates/search — an unrelated domain query does not rank backend engineers first
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'machine learning and statistical modelling', topK: 1 }
    When method POST
    Then status 200
    And assert response.length > 0
    # Tom Baker is the only data scientist in the fixture
    And match response[0].candidateId == 'C-1004'

  # ── topK ─────────────────────────────────────────────────────────────────────

  Scenario: POST /hr/candidates/search — topK caps the number of results
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'software engineer', topK: 2 }
    When method POST
    Then status 200
    And assert response.length <= 2

  # ── Scores ───────────────────────────────────────────────────────────────────

  Scenario: POST /hr/candidates/search — scores are present and ordered best-first
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'java microservices', topK: 4 }
    When method POST
    Then status 200
    And assert response.length > 1
    * def scores = $response[*].score
    * def ordered = karate.sort(scores, function(x){ return -x })
    And match scores == ordered

  # ── Metadata filters (exact match — deterministic) ────────────────────────────

  Scenario: POST /hr/candidates/search — seniority filter returns only SENIOR candidates
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'engineer', topK: 10, seniority: 'SENIOR' }
    When method POST
    Then status 200
    And assert response.length > 0
    And match each response contains { seniority: 'SENIOR' }

  Scenario: POST /hr/candidates/search — location filter returns only London candidates
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'engineer', topK: 10, location: 'London' }
    When method POST
    Then status 200
    And assert response.length > 0
    And match each response contains { location: 'London' }

  Scenario: POST /hr/candidates/search — semantic query plus filter combine
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: 'cloud infrastructure', topK: 10, seniority: 'SENIOR', location: 'London' }
    When method POST
    Then status 200
    And match each response contains { seniority: 'SENIOR', location: 'London' }

  # ── Validation ───────────────────────────────────────────────────────────────

  Scenario: POST /hr/candidates/search — blank query is rejected
    Given path '/hr/candidates/search'
    And header Content-Type = 'application/json'
    And request { query: '  ', topK: 5 }
    When method POST
    Then status 400
