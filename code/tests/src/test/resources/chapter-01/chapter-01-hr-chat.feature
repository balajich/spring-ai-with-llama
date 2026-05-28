Feature: Chapter 01 — Hello Spring AI
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 1 introduces the first Spring AI endpoint: POST /hr/ask
  # The SmartHR Assistant answers HR questions powered by a local Llama model.
  #
  # API under test:
  #   POST /hr/ask   body: { "question": "<string>" }
  #                  response: { "question": "<string>", "answer": "<string>" }
  #
  # Test strategy:
  #   - AI answers are non-deterministic, so we validate structure and
  #     presence of fields, NOT exact answer content.
  #   - We confirm the question is echoed back verbatim.
  #   - We confirm the answer is a non-empty string.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Happy path ──────────────────────────────────────────────────────────────

  Scenario: POST /hr/ask — response JSON has correct shape
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many vacation days do new employees get?' }
    When method POST
    Then status 200
    # Both fields must be present and be strings
    And match response == { question: '#string', answer: '#string' }

  Scenario: POST /hr/ask — original question is echoed back in the response
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'What is the remote work policy at TechCorp?' }
    When method POST
    Then status 200
    And match response.question == 'What is the remote work policy at TechCorp?'

  Scenario: POST /hr/ask — answer is non-empty for a vacation days question
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'How many vacation days do new employees get?' }
    When method POST
    Then status 200
    And match response.answer == '#notnull'
    And assert response.answer.length > 10

  Scenario: POST /hr/ask — answer is non-empty for a health insurance question
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'When does health insurance start for new hires?' }
    When method POST
    Then status 200
    And match response.answer == '#string'
    And assert response.answer.length > 10

  Scenario: POST /hr/ask — answer is non-empty for a PTO carry-over question
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'Can I carry over unused PTO to the next year?' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string' }
    And assert response.answer.length > 0

  Scenario: POST /hr/ask — response Content-Type header is application/json
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: 'What are the steps for onboarding a new hire?' }
    When method POST
    Then status 200
    And match header Content-Type contains 'application/json'

  # ── Multiple questions answered in sequence ─────────────────────────────────

  Scenario Outline: POST /hr/ask — various HR questions all return valid responses
    Given path '/hr/ask'
    And header Content-Type = 'application/json'
    And request { question: '<question>' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string' }
    And match response.question == '<question>'
    And assert response.answer.length > 0

    Examples:
      | question                                            |
      | What is the maternity leave policy?                 |
      | How do I submit a leave request?                    |
      | What benefits does TechCorp offer?                  |
      | Who do I contact for payroll questions?             |

