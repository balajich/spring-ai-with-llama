package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 06 — Chat Memory.
 *
 * Runs: src/test/resources/chapter-06/chapter-06-chat-memory.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter06Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-06
 */
class Chapter06Test {

    @Karate.Test
    Karate chapter06() {
        return Karate.run("classpath:chapter-06/chapter-06-chat-memory.feature");
    }
}
