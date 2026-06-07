package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 04 — Prompt Engineering.
 *
 * Runs: src/test/resources/chapter-04/chapter-04-prompt-engineering.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter04Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-04
 */
class Chapter04Test {

    @Karate.Test
    Karate chapter04() {
        return Karate.run("classpath:chapter-04/chapter-04-prompt-engineering.feature");
    }
}
