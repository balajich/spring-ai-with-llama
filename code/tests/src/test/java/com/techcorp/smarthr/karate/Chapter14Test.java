package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 14 — Document Intelligence: PDFs, Word Docs, and Web Pages.
 *
 * Runs: src/test/resources/chapter-14/chapter-14-document-intelligence.feature
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter14Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-14
 */
class Chapter14Test {

    @Karate.Test
    Karate chapter14() {
        return Karate.run("classpath:chapter-14/chapter-14-document-intelligence.feature");
    }
}
