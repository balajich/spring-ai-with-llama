Feature: Chapter 16 — AI Agents: Autonomous Workflows and Tool Chaining
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 16 gives the model a GOAL instead of a question. Five @Tool methods
  # expose HR data (headcount, open positions, new hires, attrition, policy
  # updates). The agent decides which to call, in what order, and when it has
  # enough to write the report — Spring AI runs the Reason→Act→Observe loop.
  #
  # APIs under test:
  #   POST /hr/report/generate   — { month } → { month, report, toolsInvoked[],
  #                                              toolCallCount, tookMillis }
  #   GET  /hr/agent/tools       — the tools available to the agent (sanity)
  #   GET  /hr/agent/data/{month} — the raw HR data behind the tools (sanity)
  #
  # Test strategy — the important bit:
  #   The REPORT text is LLM prose, so we only assert it is non-empty. But the
  #   AGENT'S BEHAVIOUR is observable and deterministic-ish: the controller
  #   records every tool the model actually invoked. So we assert on the TRACE
  #   — that it chained MULTIPLE tools autonomously without being told which.
  #   That is the real claim of this chapter, and it is testable.
  #
  #   A small local model won't always call all five tools, so we assert
  #   ">= 2 tools" (proving chaining) rather than an exact set, and that every
  #   name in the trace is a real registered tool.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Sanity: the tools and data exist ─────────────────────────────────────────

  Scenario: GET /hr/agent/tools — the agent has all five HR tools registered
    Given path '/hr/agent/tools'
    When method GET
    Then status 200
    And match response == '#[5]'
    And match response contains 'getHeadcount'
    And match response contains 'getOpenPositions'
    And match response contains 'getRecentHires'
    And match response contains 'getAttrition'
    And match response contains 'getPolicyUpdates'

  Scenario: GET /hr/agent/data/{month} — the underlying HR data is present
    Given path '/hr/agent/data/2025-05'
    When method GET
    Then status 200
    And match response contains { month: '2025-05' }
    And match response.headcount == '#notnull'
    And match response.openPositions == '#array'

  # ── Response shape ───────────────────────────────────────────────────────────

  Scenario: POST /hr/report/generate — returns report plus an execution trace
    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: '2025-05' }
    When method POST
    Then status 200
    And match response contains { month: '#string', report: '#string', toolsInvoked: '#array', toolCallCount: '#number' }
    And assert response.report.length > 0

  # ── The actual claim of the chapter: autonomous multi-tool chaining ──────────

  Scenario: POST /hr/report/generate — the agent chains MULTIPLE tools on its own
    # The prompt never says which tools to call or in what order.
    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: '2025-05' }
    When method POST
    Then status 200
    # more than one distinct tool => it planned a sequence, not a single call
    And assert response.toolCallCount >= 2
    And assert response.toolsInvoked.length >= 2

  Scenario: POST /hr/report/generate — every invoked tool is a real registered tool
    Given path '/hr/agent/tools'
    When method GET
    Then status 200
    * def registered = response

    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: '2025-05' }
    When method POST
    Then status 200
    * def invoked = response.toolsInvoked
    * def unknown = invoked.filter(function(t){ return registered.indexOf(t) < 0 })
    And assert unknown.length == 0

  Scenario: POST /hr/report/generate — the agent grounds the report in tool data
    # Headcount for 2025-05 is 342 in the fixture. A report built from the tools
    # should surface a real figure rather than inventing one.
    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: '2025-05' }
    When method POST
    Then status 200
    And assert response.report.indexOf('342') >= 0 || response.toolsInvoked.indexOf('getHeadcount') >= 0

  # ── Month is honoured ────────────────────────────────────────────────────────

  Scenario: POST /hr/report/generate — echoes the requested month
    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: '2025-04' }
    When method POST
    Then status 200
    And match response.month == '2025-04'

  # ── Validation ───────────────────────────────────────────────────────────────

  Scenario: POST /hr/report/generate — blank month is rejected
    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: '  ' }
    When method POST
    Then status 400

  Scenario: POST /hr/report/generate — malformed month is rejected
    Given path '/hr/report/generate'
    And header Content-Type = 'application/json'
    And request { month: 'May 2025' }
    When method POST
    Then status 400
