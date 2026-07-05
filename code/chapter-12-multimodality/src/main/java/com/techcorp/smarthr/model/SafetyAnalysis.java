package com.techcorp.smarthr.model;

// Free-text analysis of an uploaded workplace photo
public record SafetyAnalysis(
        String location,
        String analysis
) {}
