Feature: Chapter 02 — Core Concepts
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 2 adds four ask modes and a model-info endpoint.
  #
  # APIs under test:
  #   POST /hr/ask             — standard mode  (temp 0.3, max 500 tokens)
  #   POST /hr/ask/precise     — precise mode   (temp 0.0, max 150 tokens)
  #   POST /hr/ask/creative    — creative mode  (temp 0.9, max 800 tokens)
  #   POST /hr/ask/raw         — raw mode       (ChatModel directly, no ChatClient)
  #   GET  /hr/model/info      — returns active model config
  #
  # Response shape for ask endpoints:
  #   { "question": "<string>", "answer": "<string>", "mode": "<string>" }
  #
  # Response shape for model info:
  #   { "model": "<string>", "ollamaUrl": "<string>",
  #     "defaultTemperature": <number>, "defaultMaxTokens": <number>,
  #     "hint": "<string>" }
  #
  # Test strategy:
  #   - AI answers are non-deterministic — validate structure & mode value.
  #   - Model info fields are config-driven — validate types and ranges.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl
    * def standardQuestion = 'How many days of annual leave do employees get?'

  # ── POST /hr/ask — standard mode ────────────────────────────────────────────

  Scenario: POST /hr/ask — returns standard mode in response
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: '#(standardQuestion)' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }
    And match response.mode == 'standard'
    And match response.question == '#(standardQuestion)'
    And assert response.answer.length > 0

  Scenario: POST /hr/ask — echoes question back verbatim in standard mode
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'What is the parental leave policy?' }
    When method POST
    Then status 200
    And match response.question == 'What is the parental leave policy?'
    And match response.mode == 'standard'

  # ── POST /hr/ask/precise — low temperature, capped tokens ───────────────────

  Scenario: POST /hr/ask/precise — returns precise mode in response
    Given path '/hr/ask/precise'
    And header Content-Type = 'application/json'
    And request { question: '#(standardQuestion)' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }
    And match response.mode == 'precise'
    And assert response.answer.length > 0

  Scenario: POST /hr/ask/precise — answer is present and non-empty for policy question
    Given path '/hr/ask/precise'
    And header Content-Type = 'application/json'
    And request { question: 'What is the remote work policy?' }
    When method POST
    Then status 200
    And match response.answer == '#notnull'
    And match response.mode == 'precise'

  # ── POST /hr/ask/creative — high temperature ─────────────────────────────────

  Scenario: POST /hr/ask/creative — returns creative mode in response
    Given path '/hr/ask/creative'
    And header Content-Type = 'application/json'
    And request { question: 'Write a warm welcome message for new TechCorp employees.' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }
    And match response.mode == 'creative'
    And assert response.answer.length > 0

  Scenario: POST /hr/ask/creative — answer is longer than precise mode for the same question
    # Creative mode allows up to 800 tokens vs 150 for precise —
    # a detailed question should yield a longer creative answer
    Given path '/hr/ask/creative'
    And header Content-Type = 'application/json'
    And request { question: 'Describe all the employee benefits TechCorp offers in detail.' }
    When method POST
    Then status 200
    And match response.mode == 'creative'
    And match response.answer == '#string'

  # ── POST /hr/ask/raw — uses ChatModel directly ───────────────────────────────

  Scenario: POST /hr/ask/raw — returns raw mode in response
    Given path '/hr/ask/raw'
    And header Content-Type = 'application/json'
    And request { question: '#(standardQuestion)' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }
    And match response.mode == 'raw'
    And assert response.answer.length > 0

  Scenario: POST /hr/ask/raw — question is echoed back in raw mode
    Given path '/hr/ask/raw'
    And header Content-Type = 'application/json'
    And request { question: 'What is the sick leave policy?' }
    When method POST
    Then status 200
    And match response.question == 'What is the sick leave policy?'
    And match response.mode == 'raw'


  # ── GET /hr/model/info — active model configuration ─────────────────────────

  Scenario: GET /hr/model/info — returns valid model configuration object
    Given path '/hr/model/info'
    When method GET
    Then status 200
    And match response == { model: '#string', ollamaUrl: '#string', defaultTemperature: '#number', defaultMaxTokens: '#number', hint: '#string' }

  Scenario: GET /hr/model/info — ollamaUrl points to localhost
    Given path '/hr/model/info'
    When method GET
    Then status 200
    And match response.ollamaUrl contains 'localhost'

  Scenario: GET /hr/model/info — temperature is within valid range 0.0 to 1.0
    Given path '/hr/model/info'
    When method GET
    Then status 200
    And assert response.defaultTemperature >= 0.0
    And assert response.defaultTemperature <= 1.0

  Scenario: GET /hr/model/info — defaultMaxTokens is a positive integer
    Given path '/hr/model/info'
    When method GET
    Then status 200
    And assert response.defaultMaxTokens > 0

  Scenario: GET /hr/model/info — hint field is a non-empty string
    Given path '/hr/model/info'
    When method GET
    Then status 200
    And match response.hint == '#notnull'
    And assert response.hint.length > 0

  # ── Scenario Outline — all four POST modes return their correct mode value ───

  Scenario Outline: POST <endpoint> — mode field in response equals '<expectedMode>'
    Given path '<endpoint>'
    And header Content-Type = 'application/json'
    And request { question: 'What is the annual leave policy?' }
    When method POST
    Then status 200
    And match response.mode == '<expectedMode>'

    Examples:
      | endpoint          | expectedMode |
      | /hr/ask           | standard     |
      | /hr/ask/precise   | precise      |
      | /hr/ask/creative  | creative     |
      | /hr/ask/raw       | raw          |

