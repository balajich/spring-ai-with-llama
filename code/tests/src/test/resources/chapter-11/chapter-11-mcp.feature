Feature: Chapter 11 — MCP: Exposing an Existing REST API as MCP Tools
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 11 is a multi-module Maven project (code/chapter-11-mcp-integration/)
  # with three independent Spring Boot apps:
  #   - calendar-service (port 8082): the pre-existing REST API
  #     (CalendarRestController -> CalendarService). No MCP/LLM awareness.
  #   - mcp-server (port 8081): wraps calendar-service as MCP tools
  #     (checkAvailability, bookInterview) via spring-ai-starter-mcp-server-webmvc.
  #     Calls calendar-service over REST.
  #   - mcp-client (port 8080): the SmartHR scheduling chatbot. Has no @Tool
  #     methods of its own — discovers tools from mcp-server at runtime over SSE
  #     (spring-ai-starter-mcp-client).
  #
  # All three processes must be running for these tests:
  #   cd code/chapter-11-mcp-integration/calendar-service && mvn spring-boot:run  (8082)
  #   cd code/chapter-11-mcp-integration/mcp-server        && mvn spring-boot:run  (8081)
  #   cd code/chapter-11-mcp-integration/mcp-client        && mvn spring-boot:run  (8080)
  #
  # APIs under test (against mcp-client, port 8080, unless noted):
  #   POST   /hr/schedule/chat            — send a message in a named session
  #   DELETE /hr/schedule/chat/{sessionId} — clear session memory
  #
  # Request shape:
  #   { "sessionId": "<string>", "message": "<string>" }
  #
  # Response shape:
  #   { "question": "<string>", "answer": "<string>", "mode": "<string>" }
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

  # ── Multi-turn scheduling conversation across all three processes ─────────────

  Scenario: POST /hr/schedule/chat — multi-turn conversation books an interview via MCP
    # Turn 1: check availability — mcp-client calls mcp-server (SSE),
    # which calls calendar-service (REST) on :8082
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
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'isolation-session-A', message: 'I am scheduling an interview for candidate Amit Verma.' }
    When method POST
    Then status 200

    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'isolation-session-B', message: 'Which candidate am I scheduling for?' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'
    And assert !response.answer.toLowerCase().contains('amit')

  # ── DELETE — clear session ────────────────────────────────────────────────────

  Scenario: DELETE /hr/schedule/chat/{sessionId} — returns 204 No Content
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-delete-01', message: 'Check availability for 2025-06-10 at 11:00.' }
    When method POST
    Then status 200

    Given path '/hr/schedule/chat/test-delete-01'
    When method DELETE
    Then status 204

  Scenario: DELETE /hr/schedule/chat/{sessionId} — memory is cleared after delete
    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-clear-01', message: 'I am scheduling an interview for candidate Meena Iyer.' }
    When method POST
    Then status 200

    Given path '/hr/schedule/chat/test-clear-01'
    When method DELETE
    Then status 204

    Given path '/hr/schedule/chat'
    And header Content-Type = 'application/json'
    And request { sessionId: 'test-clear-01', message: 'Which candidate am I scheduling for?' }
    When method POST
    Then status 200
    And match response.mode == 'schedule'
    And assert !response.answer.toLowerCase().contains('meena')

  # ── Underlying calendar-service REST API sanity checks ────────────────────────

  Scenario: calendar-service REST API is reachable directly on :8082
    Given url 'http://localhost:8082'
    And path '/api/calendar/availability'
    And param date = '2099-01-01'
    And param time = '09:00'
    When method GET
    Then status 200
    And match response == { date: '2099-01-01', time: '09:00', available: '#boolean' }
