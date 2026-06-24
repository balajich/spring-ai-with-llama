package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 10 — Function Calling: Tool Use and Java Method Binding.
 *
 * Runs: src/test/resources/chapter-10/chapter-10-function-calling.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter10Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-10
 */
class Chapter10Test {

    @Karate.Test
    Karate chapter10() {
        return Karate.run("classpath:chapter-10/chapter-10-function-calling.feature");
    }
}
