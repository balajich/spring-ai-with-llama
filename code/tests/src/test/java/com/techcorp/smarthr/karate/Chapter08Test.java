package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 08 — Persistent Vector Store with PgVector.
 *
 * Runs: src/test/resources/chapter-08/chapter-08-pgvector.feature
 *
 * Prerequisites: PostgreSQL with pgvector running (docker-compose up -d)
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter08Test
 *
 * Or via the shell script from the tests/ directory:
 *   ./run-tests.sh chapter-08
 */
class Chapter08Test {

    @Karate.Test
    Karate chapter08() {
        return Karate.run("classpath:chapter-08/chapter-08-pgvector.feature");
    }
}
