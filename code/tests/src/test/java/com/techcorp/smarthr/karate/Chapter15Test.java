package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 15 — Semantic Search: Finding Meaning, Not Keywords.
 *
 * Runs: src/test/resources/chapter-15/chapter-15-semantic-search.feature
 *
 * Requires the embedding model:  ollama pull nomic-embed-text
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter15Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-15
 */
class Chapter15Test {

    @Karate.Test
    Karate chapter15() {
        return Karate.run("classpath:chapter-15/chapter-15-semantic-search.feature");
    }
}
