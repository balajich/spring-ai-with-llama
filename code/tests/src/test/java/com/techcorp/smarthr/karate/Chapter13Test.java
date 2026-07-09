package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 13 — Streaming API: Real-Time Token-by-Token Responses.
 *
 * Runs: src/test/resources/chapter-13/chapter-13-streaming-api.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter13Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-13
 */
class Chapter13Test {

    @Karate.Test
    Karate chapter13() {
        return Karate.run("classpath:chapter-13/chapter-13-streaming-api.feature");
    }
}
