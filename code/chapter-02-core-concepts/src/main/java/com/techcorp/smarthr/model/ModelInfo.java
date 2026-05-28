package com.techcorp.smarthr.model;

public record ModelInfo(
        String model,
        String ollamaUrl,
        double defaultTemperature,
        int defaultMaxTokens,
        String hint
) {}
