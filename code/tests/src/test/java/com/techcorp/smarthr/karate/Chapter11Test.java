package com.techcorp.smarthr.karate;

import com.intuit.karate.junit5.Karate;

/**
 * JUnit 5 runner for Chapter 11 — MCP: Exposing an Existing REST API as MCP Tools.
 *
 * Runs: src/test/resources/chapter-11/chapter-11-mcp.feature
 *
 * Prerequisites: all three apps in code/chapter-11-mcp-integration/ must be running —
 *   calendar-service on port 8082 (the pre-existing REST API)
 *   mcp-server        on port 8081 (wraps calendar-service as MCP tools)
 *   mcp-client         on port 8080 (chat app, the baseUrl under test)
 *
 * Run via Maven:
 *   mvn test -Dtest=Chapter11Test
 */
class Chapter11Test {

    @Karate.Test
    Karate chapter11() {
        return Karate.run("classpath:chapter-11/chapter-11-mcp.feature");
    }
}
