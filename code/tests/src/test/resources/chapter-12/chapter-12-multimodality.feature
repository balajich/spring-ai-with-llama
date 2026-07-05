Feature: Chapter 12 — Multimodality: Images and Text Together
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 12 introduces vision: the SmartHR safety reporter accepts a photo
  # of a workplace hazard, analyses it with a vision model (llava), and either
  # returns a free-text analysis or a structured SafetyReport (vision +
  # BeanOutputConverter from Chapter 5).
  #
  # APIs under test:
  #   POST /hr/safety/analyse  — multipart: image, location → { location, analysis }
  #   POST /hr/safety/report   — multipart: image, location → SafetyReport JSON
  #
  # SafetyReport shape:
  #   { location, hazardDescription, riskLevel, recommendedAction,
  #     requiresIncidentReport }
  #
  # Requires: ollama pull llava
  #
  # Test strategy:
  #   - Validate response shape for both endpoints.
  #   - Validate location is echoed back.
  #   - Validate riskLevel is one of LOW / MEDIUM / HIGH.
  #   - Validate a missing image part is rejected.
  #
  # Note: vision model output is non-deterministic. Tests check shape and
  #   field constraints, not exact wording of the analysis.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── POST /hr/safety/analyse ──────────────────────────────────────────────────

  Scenario: POST /hr/safety/analyse — returns correct response shape
    Given path '/hr/safety/analyse'
    And multipart file image = { read: 'hazard-photo.png', filename: 'hazard-photo.png', contentType: 'image/png' }
    And multipart field location = 'Floor 3, near the printer'
    When method POST
    Then status 200
    And match response == { location: '#string', analysis: '#string' }

  Scenario: POST /hr/safety/analyse — location is echoed back
    Given path '/hr/safety/analyse'
    And multipart file image = { read: 'hazard-photo.png', filename: 'hazard-photo.png', contentType: 'image/png' }
    And multipart field location = 'Building B lobby'
    When method POST
    Then status 200
    And match response.location == 'Building B lobby'

  Scenario: POST /hr/safety/analyse — analysis is non-empty
    Given path '/hr/safety/analyse'
    And multipart file image = { read: 'hazard-photo.png', filename: 'hazard-photo.png', contentType: 'image/png' }
    And multipart field location = 'Floor 2 corridor'
    When method POST
    Then status 200
    And assert response.analysis.length > 0

  # ── POST /hr/safety/report — structured output ──────────────────────────────

  Scenario: POST /hr/safety/report — returns a structured SafetyReport
    Given path '/hr/safety/report'
    And multipart file image = { read: 'hazard-photo.png', filename: 'hazard-photo.png', contentType: 'image/png' }
    And multipart field location = 'Floor 3, near the printer'
    When method POST
    Then status 200
    And match response contains { hazardDescription: '#string', riskLevel: '#string', recommendedAction: '#string', requiresIncidentReport: '#boolean' }

  Scenario: POST /hr/safety/report — riskLevel is LOW, MEDIUM or HIGH
    Given path '/hr/safety/report'
    And multipart file image = { read: 'hazard-photo.png', filename: 'hazard-photo.png', contentType: 'image/png' }
    And multipart field location = 'Server room, rack aisle'
    When method POST
    Then status 200
    And match response.riskLevel == '#regex (?i)(LOW|MEDIUM|HIGH)'

  # ── Validation ───────────────────────────────────────────────────────────────

  Scenario: POST /hr/safety/analyse — missing image part is rejected
    Given path '/hr/safety/analyse'
    And multipart field location = 'Floor 1'
    When method POST
    Then status 400
