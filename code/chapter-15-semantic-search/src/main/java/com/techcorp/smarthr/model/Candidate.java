package com.techcorp.smarthr.model;

// One candidate as loaded from candidates.json and embedded into the vector store.
public record Candidate(
        String candidateId,
        String name,
        String role,
        String seniority,   // JUNIOR / MID / SENIOR
        String location,
        String resume
) {}
