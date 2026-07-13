Feature: Chapter 14 — Document Intelligence: PDFs, Word Docs, and Web Pages
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 14 reads real documents. A PDF employment contract is uploaded,
  # its text extracted with PagePdfDocumentReader, injected whole into the
  # prompt (direct injection, not RAG), and returned as a structured
  # ContractAnalysis. A second endpoint uses TikaDocumentReader to summarise
  # any document format.
  #
  # APIs under test:
  #   POST /hr/contract/analyse    — multipart file (PDF) → ContractAnalysis JSON
  #   POST /hr/document/summarise  — multipart file (any) → { filename, summary }
  #
  # ContractAnalysis shape:
  #   { summary, probationPeriod, noticePeriod, ipOwnership,
  #     nonStandardClauses[], requiresLegalReview }
  #
  # Test strategy:
  #   - Validate response shape and field types for both endpoints.
  #   - Validate the analyser extracts probation/notice periods from the fixture.
  #   - Validate a missing file is rejected with 400.
  #
  # Note: LLM output is non-deterministic. Tests assert shape and that key
  #   facts from the fixture contract appear, not exact wording.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl

  # ── Contract analysis (PDF → structured) ──────────────────────────────────────

  Scenario: POST /hr/contract/analyse — returns a structured ContractAnalysis
    Given path '/hr/contract/analyse'
    And multipart file file = { read: 'employment-contract.pdf', filename: 'employment-contract.pdf', contentType: 'application/pdf' }
    When method POST
    Then status 200
    And match response contains { summary: '#string', probationPeriod: '#string', noticePeriod: '#string', ipOwnership: '#string', nonStandardClauses: '#array', requiresLegalReview: '#boolean' }

  Scenario: POST /hr/contract/analyse — extracts the six-month probation period
    Given path '/hr/contract/analyse'
    And multipart file file = { read: 'employment-contract.pdf', filename: 'employment-contract.pdf', contentType: 'application/pdf' }
    When method POST
    Then status 200
    And match response.probationPeriod contains 'six'

  Scenario: POST /hr/contract/analyse — summary is non-empty
    Given path '/hr/contract/analyse'
    And multipart file file = { read: 'employment-contract.pdf', filename: 'employment-contract.pdf', contentType: 'application/pdf' }
    When method POST
    Then status 200
    And assert response.summary.length > 0

  # ── Document summary (Tika) ────────────────────────────────────────────────────

  Scenario: POST /hr/document/summarise — returns filename and a summary
    Given path '/hr/document/summarise'
    And multipart file file = { read: 'employment-contract.pdf', filename: 'employment-contract.pdf', contentType: 'application/pdf' }
    When method POST
    Then status 200
    And match response == { filename: '#string', summary: '#string' }
    And assert response.summary.length > 0

  # ── Validation ─────────────────────────────────────────────────────────────────

  Scenario: POST /hr/contract/analyse — missing file is rejected
    Given path '/hr/contract/analyse'
    And multipart field note = 'no file here'
    When method POST
    Then status 400
