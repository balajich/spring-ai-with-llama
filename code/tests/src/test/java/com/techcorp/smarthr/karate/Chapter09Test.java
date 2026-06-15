package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 09 — Graph RAG with Neo4j.
 *
 * Runs: src/test/resources/chapter-09/chapter-09-neo4j.feature
 *
 * Prerequisites: Neo4j running (docker-compose up -d)
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter09Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-09
 */
class Chapter09Test {

    @Karate.Test
    Karate chapter09() {
        return Karate.run("classpath:chapter-09/chapter-09-neo4j.feature");
    }
}
