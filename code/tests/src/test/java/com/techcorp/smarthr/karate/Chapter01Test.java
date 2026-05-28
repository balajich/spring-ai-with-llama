package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 01 — Hello Spring AI.
 *
 * Runs: src/test/resources/chapter-01/chapter-01-hr-chat.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter01Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-01
 */
class Chapter01Test {

    @Karate.Test
    Karate chapter01() {
        return Karate.run("classpath:chapter-01/chapter-01-hr-chat.feature");
    }
}
