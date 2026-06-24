Feature: Chapter 10 — Function Calling: Tool Use and Java Method Binding
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 10 introduces tool calling. The LLM can invoke CalendarService
  # Java methods (checkAvailability, bookInterview) mid-conversation via
  # ChatClient.defaultTools(), using MessageWindowChatMemory for multi-turn
  # state just like Chapter 6.
  #
  # APIs under test:
  #   POST   /hr/schedule/chat            — send a message in a named session
  #   DELETE /hr/schedule/chat/{sessionId} — clear session memory
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
  #   - Validate a scheduling conversation produces a non-empty answer
  #     (tool calls happen transparently inside the LLM's reasoning loop).
  #   - Validate sessions are isolated from each other.
  #   - Validate DELETE clears the session.
  #
  # Note: LLM answers and tool-call decisions are non-deterministic. Tests
  #   check response shape and conversational behaviour rather than exact
  #   wording or asserting a tool was definitely called.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Response shape ────────────────────────────────────────────────────────────

  Scenario: POST /hr/schedule/chat — returns correct response shape
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-shape-01', message: 'Can you check if 2025-06-03 at 14:00 is available for an interview?' }
    When method POST
    Then status 200
    And match response == { question: '#string', answer: '#string', mode: '#string' }

  Scenario: POST /hr/schedule/chat — mode is schedule
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-mode-01', message: 'Is 2025-06-04 at 10:00 free for an interview?' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'

  Scenario: POST /hr/schedule/chat — message is echoed back as question
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-echo-01', message: 'Check availability for 2025-06-05 at 09:00.' }
    When method POST
    Then status 200
    And match response.question == 'Check availability for 2025-06-05 at 09:00.'

  Scenario: POST /hr/schedule/chat — answer is non-empty
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-nonempty-01', message: 'Is there a free slot on 2025-06-06 at 15:00?' }
    When method POST
    Then status 200
    And assert response.answer.length > 0

  # ── Multi-turn scheduling conversation ────────────────────────────────────────

  Scenario: POST /hr/schedule/chat — multi-turn conversation books an interview
    # Turn 1: check availability
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-booking-01', message: 'Please check if Tuesday 2025-06-03 at 14:00 is free for a Java developer interview with Priya Sharma.' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'
    And assert response.answer.length > 0

    # Turn 2: confirm and request booking
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-booking-01', message: 'Yes, please go ahead and book it.' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'
    And assert response.answer.length > 0

  # ── Session isolation ─────────────────────────────────────────────────────────

  Scenario: POST /hr/schedule/chat — different sessionIds are isolated
    # Session A
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'isolation-session-A', message: 'I am scheduling an interview for candidate Amit Verma.' }
    When method POST
    Then status 200

    # Session B — separate session, no knowledge of session A
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'isolation-session-B', message: 'Which candidate am I scheduling for?' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'
    # The bot should not know "Amit" — it was told in a different session
    And assert !response.answer.toLowerCase().contains('amit')

  # ── DELETE — clear session ────────────────────────────────────────────────────

  Scenario: DELETE /hr/schedule/chat/{sessionId} — returns 204 No Content
    # First create a session
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-delete-01', message: 'Check availability for 2025-06-10 at 11:00.' }
    When method POST
    Then status 200

    # Then delete it
    Given path '/hr/schedule/chat/test-delete-01'
    When method DELETE
    Then status 204

  Scenario: DELETE /hr/schedule/chat/{sessionId} — memory is cleared after delete
    # Turn 1: introduce context
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-clear-01', message: 'I am scheduling an interview for candidate Meena Iyer.' }
    When method POST
    Then status 200

    # Clear the session
    Given path '/hr/schedule/chat/test-clear-01'
    When method DELETE
    Then status 204

    # Turn 2: same sessionId — memory was cleared, bot should not recall "Meena"
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-clear-01', message: 'Which candidate am I scheduling for?' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'
    And assert !response.answer.toLowerCase().contains('meena')
