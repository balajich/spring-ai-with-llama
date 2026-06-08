Feature: Chapter 05 — Structured Output: From Raw Text to Java Objects
  # ──────────────────────────────────────────────────────────────────────────
  # Chapter 5 introduces BeanOutputConverter — the AI returns a typed
  # ResumeProfile JSON object instead of free text.
  #
  # API under test:
  #   POST /hr/resume/parse — parses raw resume text into a ResumeProfile
  #
  # Request shape:
  #   { "resumeText": "<string>" }
  #
  # Response shape:
  #   { "name": "<string>", "email": "<string>",
  #     "skills": ["<string>", ...], "yearsOfExperience": <number>,
  #     "currentRole": "<string>", "education": "<string>" }
  #
  # Test strategy:
  #   - Validate the response is a well-formed JSON object with all fields.
  #   - Validate field types (string, array, number).
  #   - Validate key fields are extracted correctly from clearly written resumes.
  #   - LLM output is non-deterministic — avoid asserting exact string values
  #     except for names/emails that are unambiguous in the input.
  # ──────────────────────────────────────────────────────────────────────────

  Background:
    * url baseUrl
    * def priyaResume = 'Priya Sharma | priya@example.com\n5 years Java, Spring Boot, AWS\nSenior Engineer at Infosys\nB.Tech CS IIT Delhi 2018'

  # ── Response shape ────────────────────────────────────────────────────────────

  Scenario: POST /hr/resume/parse — returns all required fields
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: '#(priyaResume)' }
    When method POST
    Then status 200
    And match response == { name: '#string', email: '#string', skills: '#array', yearsOfExperience: '#number', currentRole: '#string', education: '#string' }

  Scenario: POST /hr/resume/parse — skills field is a non-empty array
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: '#(priyaResume)' }
    When method POST
    Then status 200
    And match response.skills == '#[] #string'
    And assert response.skills.length > 0

  Scenario: POST /hr/resume/parse — yearsOfExperience is a positive number
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: '#(priyaResume)' }
    When method POST
    Then status 200
    And assert response.yearsOfExperience > 0

  # ── Field extraction accuracy ─────────────────────────────────────────────────

  Scenario: POST /hr/resume/parse — extracts name correctly
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: '#(priyaResume)' }
    When method POST
    Then status 200
    And match response.name == '#string'
    And assert response.name.toLowerCase().contains('priya')

  Scenario: POST /hr/resume/parse — extracts email correctly
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: '#(priyaResume)' }
    When method POST
    Then status 200
    And match response.email == 'priya@example.com'

  Scenario: POST /hr/resume/parse — extracts skills containing Java
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: '#(priyaResume)' }
    When method POST
    Then status 200
    # At least one skill should contain 'java' (case-insensitive)
    * def skills = response.skills
    * def javaFound = karate.filter(skills, function(s){ return s.toLowerCase().contains('java') })
    And assert javaFound.length > 0

  Scenario: POST /hr/resume/parse — works for a different candidate
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: 'John Smith\njohn.smith@email.com\n8 years backend development\nLead Engineer at TechStartup\nSkills: Kotlin, Docker, PostgreSQL\nM.Sc. Computer Science, University of Manchester' }
    When method POST
    Then status 200
    And match response == { name: '#string', email: '#string', skills: '#array', yearsOfExperience: '#number', currentRole: '#string', education: '#string' }
    And assert response.name.toLowerCase().contains('john')
    And match response.email == 'john.smith@email.com'

  Scenario: POST /hr/resume/parse — works for a minimal resume
    Given path '/hr/resume/parse'
    And header Content-Type = 'application/json'
    And request { resumeText: 'Alex Lee | alex@techcorp.com\nJunior Developer, 1 year experience\nSkills: Python, Git\nB.Sc. Computer Science' }
    When method POST
    Then status 200
    And match response == { name: '#string', email: '#string', skills: '#array', yearsOfExperience: '#number', currentRole: '#string', education: '#string' }
    And assert response.skills.length > 0
