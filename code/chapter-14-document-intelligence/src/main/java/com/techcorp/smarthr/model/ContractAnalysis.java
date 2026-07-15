package com.techcorp.smarthr.model;

import java.util.List;

// Structured first-pass review of an employment contract PDF.
// Boxed / nullable fields throughout — a contract may omit any of these, and
// Spring AI 2.0 (Jackson 3) rejects null mapped onto primitive types.
public record ContractAnalysis(
        String summary,
        String probationPeriod,
        String noticePeriod,
        String ipOwnership,
        List<String> nonStandardClauses,
        Boolean requiresLegalReview
) {}
