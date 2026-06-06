package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 03 — Running and Comparing Multiple Models with Ollama.
 *
 * Runs: src/test/resources/chapter-03/chapter-03-comparing-models.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter03Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-03
 */
class Chapter03Test {

    @Karate.Test
    Karate chapter03() {
        return Karate.run("classpath:chapter-03/chapter-03-comparing-models.feature");
    }
}
