Feature: Chapter 13 — Streaming API: Real-Time Token-by-Token Responses
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 13 introduces streaming. Instead of blocking with .call().content()
  # until the full answer is ready, the controller uses .stream().content() to
  # emit each token as Llama generates it, pushed to the client over
  # Server-Sent Events (text/event-stream).
  #
  # APIs under test:
  #   GET /hr/ask/stream?question=...          — Flux<String>  (SSE, raw tokens)
  #   GET /hr/ask/stream/tokens?question=...    — Flux<StreamChunk> (SSE + metadata)
  #
  # Test strategy:
  #   - Validate the stream endpoints return 200 with a text/event-stream
  #     content type.
  #   - Validate the accumulated stream body is non-empty (tokens were emitted).
  #   - Validate the metadata stream carries the question's answer text.
  #
  # Note: LLM output is non-deterministic and streamed. Karate reads the SSE
  #   connection until the server completes the Flux, then exposes the full
  #   accumulated body — so tests assert shape/content-type/non-empty rather
  #   than exact wording.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Raw token stream ──────────────────────────────────────────────────────────

  Scenario: GET /hr/ask/stream — returns 200 and an event-stream content type
    Given path '/hr/ask/stream'
    And param question = 'What is the leave policy in one sentence?'
    And header Accept = 'text/event-stream'
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/event-stream'

  Scenario: GET /hr/ask/stream — the streamed body is non-empty
    Given path '/hr/ask/stream'
    And param question = 'Name one employee benefit at TechCorp.'
    And header Accept = 'text/event-stream'
    When method GET
    Then status 200
    And match response == '#present'
    And assert response.length > 0

  # ── Token stream with metadata ─────────────────────────────────────────────────

  Scenario: GET /hr/ask/stream/tokens — returns 200 and an event-stream content type
    Given path '/hr/ask/stream/tokens'
    And param question = 'How many vacation days do new employees get?'
    And header Accept = 'text/event-stream'
    When method GET
    Then status 200
    And match responseHeaders['Content-Type'][0] contains 'text/event-stream'

  Scenario: GET /hr/ask/stream/tokens — emits token chunks in the stream
    Given path '/hr/ask/stream/tokens'
    And param question = 'What is the standard notice period?'
    And header Accept = 'text/event-stream'
    When method GET
    Then status 200
    And match response contains 'token'
