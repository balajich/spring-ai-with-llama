package com.techcorp.smarthr.model;

// Structured incident report generated from a workplace photo
public record SafetyReport(
        String location,
        String hazardDescription,
        String riskLevel,               // LOW / MEDIUM / HIGH
        String recommendedAction,
        boolean requiresIncidentReport
) {}
