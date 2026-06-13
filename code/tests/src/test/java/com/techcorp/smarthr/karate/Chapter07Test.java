package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 07 — RAG (Retrieval-Augmented Generation).
 *
 * Runs: src/test/resources/chapter-07/chapter-07-rag.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter07Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-07
 */
class Chapter07Test {

    @Karate.Test
    Karate chapter07() {
        return Karate.run("classpath:chapter-07/chapter-07-rag.feature");
    }
}
