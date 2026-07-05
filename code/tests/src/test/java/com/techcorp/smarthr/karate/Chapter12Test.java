package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 12 — Multimodality: Images and Text Together.
 *
 * Runs: src/test/resources/chapter-12/chapter-12-multimodality.feature
 *
 * Requires the llava vision model:  ollama pull llava
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter12Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-12
 */
class Chapter12Test {

    @Karate.Test
    Karate chapter12() {
        return Karate.run("classpath:chapter-12/chapter-12-multimodality.feature");
    }
}
