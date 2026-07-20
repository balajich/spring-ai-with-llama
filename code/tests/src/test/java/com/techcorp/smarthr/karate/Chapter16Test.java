package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 16 — AI Agents: Autonomous Workflows and Tool Chaining.
 *
 * Runs: src/test/resources/chapter-16/chapter-16-ai-agents.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter16Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-16
 */
class Chapter16Test {

    @Karate.Test
    Karate chapter16() {
        return Karate.run("classpath:chapter-16/chapter-16-ai-agents.feature");
    }
}
