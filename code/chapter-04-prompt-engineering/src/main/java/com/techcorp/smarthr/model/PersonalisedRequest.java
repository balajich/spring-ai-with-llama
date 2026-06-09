package com.techcorp.smarthr.model;

public record PersonalisedRequest(
        String name,
        String department,
        String role,
        String question
) {}
