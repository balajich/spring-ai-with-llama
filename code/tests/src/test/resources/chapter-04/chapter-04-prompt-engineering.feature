Feature: Chapter 04 — Prompt Engineering: PromptTemplate and Dynamic Prompts
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 4 introduces PromptTemplate with dynamic variables loaded from
  # classpath template files (.st).
  #
  # APIs under test:
  #   POST /hr/ask/personalised — personalised HR answer via hr-assistant.st
  #   POST /hr/ask/onboarding   — onboarding-specific answer via onboarding.st
  #
  # Request shape:
  #   { "name": "<string>", "department": "<string>",
  #     "role": "<string>",  "question": "<string>" }
  #
  # Response shape:
  #   { "question": "<string>", "answer": "<string>", "mode": "<string>" }
  #
  # Test strategy:
  #   - AI answers are non-deterministic — validate structure, mode value,
  #     and that the employee name appears in the answer (proves template
  #     variable injection is working).
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl
    * def rajRequest = { name: 'Raj', department: 'Engineering', role: 'Software Engineer', question: 'How do I get my development tools set up on my first day?' }

  # ── POST /hr/ask/personalised ────────────────────────────────────────────────

  Scenario: POST /hr/ask/personalised — returns correct response shape
    Given path '/hr/ask/personalised'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }

  Scenario: POST /hr/ask/personalised — mode is personalised
    Given path '/hr/ask/personalised'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And match response.mode == 'personalised'

  Scenario: POST /hr/ask/personalised — question is echoed back verbatim
    Given path '/hr/ask/personalised'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And match response.question == rajRequest.question

  Scenario: POST /hr/ask/personalised — answer contains the employee name
    # Proves that the {name} variable was injected into the template
    Given path '/hr/ask/personalised'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And match response.answer == '#string'
    And assert response.answer.toLowerCase().contains('raj')

  Scenario: POST /hr/ask/personalised — answer is non-empty for a leave question
    Given path '/hr/ask/personalised'
    And header Content-Type = 'application/json'
    And request { name: 'Lisa', department: 'Product', role: 'Product Manager', question: 'How do I apply for annual leave?' }
    When method POST
    Then status 200
    And match response.mode == 'personalised'
    And assert response.answer.length > 0

  Scenario: POST /hr/ask/personalised — works for different employees and departments
    Given path '/hr/ask/personalised'
    And header Content-Type = 'application/json'
    And request { name: 'Sarah', department: 'HR', role: 'HR Manager', question: 'What is the performance review process?' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }
    And match response.mode == 'personalised'
    And assert response.answer.toLowerCase().contains('sarah')

  # ── POST /hr/ask/onboarding ──────────────────────────────────────────────────

  Scenario: POST /hr/ask/onboarding — returns correct response shape
    Given path '/hr/ask/onboarding'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }

  Scenario: POST /hr/ask/onboarding — mode is onboarding
    Given path '/hr/ask/onboarding'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And match response.mode == 'onboarding'

  Scenario: POST /hr/ask/onboarding — answer contains the employee name
    # Proves that the {name} variable was injected into the onboarding template
    Given path '/hr/ask/onboarding'
    And header Content-Type = 'application/json'
    And request rajRequest
    When method POST
    Then status 200
    And assert response.answer.toLowerCase().contains('raj')

  Scenario: POST /hr/ask/onboarding — answer is non-empty for a first-day question
    Given path '/hr/ask/onboarding'
    And header Content-Type = 'application/json'
    And request { name: 'Raj', department: 'Engineering', role: 'Software Engineer', question: 'What should I do on my first day at TechCorp?' }
    When method POST
    Then status 200
    And match response.mode == 'onboarding'
    And assert response.answer.length > 0

  # ── Scenario Outline — both endpoints return the correct mode ────────────────

  Scenario Outline: POST <endpoint> — mode field equals '<expectedMode>'
    Given path '<endpoint>'
    And header Content-Type = 'application/json'
    And request { name: 'Raj', department: 'Engineering', role: 'Software Engineer', question: 'What is the sick leave policy?' }
    When method POST
    Then status 200
    And match response.mode == '<expectedMode>'

    Examples:
      | endpoint              | expectedMode  |
      | /hr/ask/personalised  | personalised  |
      | /hr/ask/onboarding    | onboarding    |
