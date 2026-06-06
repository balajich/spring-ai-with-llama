Feature: Chapter 03 — Running and Comparing Multiple Models with Ollama
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 3 adds a model-comparison endpoint on top of the chapter-2 modes.
  #
  # APIs under test:
  #   POST /hr/ask/compare — sends the same question to two models side-by-side
  #
  # CompareResponse shape:
  #   { "question": "<string>",
  #     "modelA":   "<string>", "answerA": "<string>",
  #     "modelB":   "<string>", "answerB": "<string>" }
  #
  # Test strategy:
  #   - AI answers are non-deterministic — validate structure, field presence,
  #     and echoed values rather than exact answer text.
  #   - modelA = llama3.2, modelB = mistral (both must be pulled via ollama pull)
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl
    * def standardQuestion = 'How many days of annual leave do employees get?'
    * def modelA = 'llama3.2'
    * def modelB = 'mistral'

  # ── POST /hr/ask/compare ─────────────────────────────────────────────────────

  Scenario: POST /hr/ask/compare — returns correct response shape
    Given path '/hr/ask/compare'
    And header Content-Type = 'application/json'
    And request { question: '#(standardQuestion)', modelA: '#(modelA)', modelB: '#(modelB)' }
    When method POST
    Then status 200
    And match response == { question: '#string', modelA: '#string', answerA: '#string', modelB: '#string', answerB: '#string' }

  Scenario: POST /hr/ask/compare — question is echoed back verbatim
    Given path '/hr/ask/compare'
    And header Content-Type = 'application/json'
    And request { question: '#(standardQuestion)', modelA: '#(modelA)', modelB: '#(modelB)' }
    When method POST
    Then status 200
    And match response.question == '#(standardQuestion)'

  Scenario: POST /hr/ask/compare — modelA and modelB are echoed back
    Given path '/hr/ask/compare'
    And header Content-Type = 'application/json'
    And request { question: 'What is the sick leave policy?', modelA: '#(modelA)', modelB: '#(modelB)' }
    When method POST
    Then status 200
    And match response.modelA == '#(modelA)'
    And match response.modelB == '#(modelB)'

  Scenario: POST /hr/ask/compare — both answers are non-empty strings
    Given path '/hr/ask/compare'
    And header Content-Type = 'application/json'
    And request { question: 'What is the remote work policy?', modelA: '#(modelA)', modelB: '#(modelB)' }
    When method POST
    Then status 200
    And assert response.answerA.length > 0
    And assert response.answerB.length > 0

  Scenario: POST /hr/ask/compare — works for an HR onboarding question
    Given path '/hr/ask/compare'
    And header Content-Type = 'application/json'
    And request { question: 'What is a good onboarding plan for a new software engineer?', modelA: '#(modelA)', modelB: '#(modelB)' }
    When method POST
    Then status 200
    And match response == { question: '#string', modelA: '#string', answerA: '#string', modelB: '#string', answerB: '#string' }
    And match response.modelA == '#(modelA)'
    And match response.modelB == '#(modelB)'
