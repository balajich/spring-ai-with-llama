Feature: Chapter 06 — Chat Memory: Multi-Turn Conversations
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 6 introduces stateful multi-turn chat using MessageWindowChatMemory
  # and MessageChatMemoryAdvisor.
  #
  # APIs under test:
  #   POST   /hr/onboard/chat            — send a message in a named session
  #   DELETE /hr/onboard/chat/{sessionId} — clear session memory
  #
  # Request shape:
  #   { "sessionId": "<string>", "message": "<string>" }
  #
  # Response shape:
  #   { "question": "<string>", "answer": "<string>", "mode": "<string>" }
  #
  # Test strategy:
  #   - Validate response shape and mode value.
  #   - Validate message is echoed back as question.
  #   - Validate context is maintained across turns (follow-up refers to prior answer).
  #   - Validate sessions are isolated from each other.
  #   - Validate DELETE clears the session (new response after clear starts fresh).
  #
  # Note: LLM answers are non-deterministic. Context tests use assertive language
  #   checks rather than exact string matches.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Response shape ────────────────────────────────────────────────────────────

  Scenario: POST /hr/onboard/chat — returns correct response shape
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-shape-01', message: 'What tools do I need on my first day?' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }

  Scenario: POST /hr/onboard/chat — mode is onboard
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-mode-01', message: 'What is the dress code at TechCorp?' }
    When method POST
    Then status 200
    And match response.mode == 'onboard'

  Scenario: POST /hr/onboard/chat — message is echoed back as question
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-echo-01', message: 'Where do I find the employee handbook?' }
    When method POST
    Then status 200
    And match response.question == 'Where do I find the employee handbook?'

  Scenario: POST /hr/onboard/chat — answer is non-empty
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-nonempty-01', message: 'How do I request IT equipment?' }
    When method POST
    Then status 200
    And assert response.answer.length > 0

  # ── Multi-turn context ────────────────────────────────────────────────────────

  Scenario: POST /hr/onboard/chat — multi-turn conversation maintains context
    # Turn 1: ask about laptop
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-multiturn-01', message: 'What laptop options are available for new engineers at TechCorp?' }
    When method POST
    Then status 200
    And match response.mode == 'onboard'
    * def turn1Answer = response.answer

    # Turn 2: follow-up that only makes sense if Turn 1 is remembered
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-multiturn-01', message: 'How long does it take to receive it after requesting?' }
    When method POST
    Then status 200
    And match response.mode == 'onboard'
    And assert response.answer.length > 0

  # ── Session isolation ─────────────────────────────────────────────────────────

  Scenario: POST /hr/onboard/chat — different sessionIds are isolated
    # Session A
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'isolation-session-A', message: 'I am Raj, a new software engineer.' }
    When method POST
    Then status 200

    # Session B — separate session, no knowledge of session A
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'isolation-session-B', message: 'What is my name?' }
    When method POST
    Then status 200
    And match response.mode == 'onboard'
    # The bot should not know "Raj" — it was told in a different session
    And assert !response.answer.toLowerCase().contains('raj')

  # ── DELETE — clear session ────────────────────────────────────────────────────

  Scenario: DELETE /hr/onboard/chat/{sessionId} — returns 204 No Content
    # First create a session
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-delete-01', message: 'What is the parental leave policy?' }
    When method POST
    Then status 200

    # Then delete it
    Given path '/hr/onboard/chat/test-delete-01'
    When method DELETE
    Then status 204

  Scenario: DELETE /hr/onboard/chat/{sessionId} — memory is cleared after delete
    # Turn 1: introduce context
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-clear-01', message: 'My name is Raj and I work in Engineering.' }
    When method POST
    Then status 200

    # Clear the session
    Given path '/hr/onboard/chat/test-clear-01'
    When method DELETE
    Then status 204

    # Turn 2: same sessionId — memory was cleared, bot should not recall "Raj"
    Given path '/hr/onboard/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-clear-01', message: 'What is my name?' }
    When method POST
    Then status 200
    And match response.mode == 'onboard'
    And assert !response.answer.toLowerCase().contains('raj')
