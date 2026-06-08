package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 05 — Structured Output.
 *
 * Runs: src/test/resources/chapter-05/chapter-05-structured-output.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter05Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-05
 */
class Chapter05Test {

    @Karate.Test
    Karate chapter05() {
        return Karate.run("classpath:chapter-05/chapter-05-structured-output.feature");
    }
}
