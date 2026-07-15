package com.techcorp.smarthr.model;

// Search request. topK/seniority/location are optional — boxed and nullable so a
// caller can omit them (Spring AI 2.0 uses Jackson 3: null onto a primitive throws).
public record CandidateSearchRequest(
        String query,
        Integer topK,
        String seniority,
        String location
) {}
