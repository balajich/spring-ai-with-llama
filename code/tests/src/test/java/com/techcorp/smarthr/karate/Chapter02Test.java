package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 02 — Core Concepts.
 *
 * Runs: src/test/resources/chapter-02/chapter-02-core-concepts.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter02Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-02
 */
class Chapter02Test {

    @Karate.Test
    Karate chapter02() {
        return Karate.run("classpath:chapter-02/chapter-02-core-concepts.feature");
    }
}
