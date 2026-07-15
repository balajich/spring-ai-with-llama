package com.techcorp.smarthr.model;

// One search hit. `score` is the vector store's similarity score (higher = closer).
public record CandidateMatch(
        String candidateId,
        String name,
        String role,
        String seniority,
        String location,
        Double score,
        String summary
) {}
