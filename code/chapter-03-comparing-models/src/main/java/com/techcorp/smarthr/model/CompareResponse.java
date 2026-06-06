package com.techcorp.smarthr.model;

public record CompareResponse(
        String question,
        String modelA,
        String answerA,
        String modelB,
        String answerB
) {}
