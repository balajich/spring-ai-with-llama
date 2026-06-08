package com.techcorp.smarthr.model;

import java.util.List;

public record ResumeProfile(
        String name,
        String email,
        List<String> skills,
        int yearsOfExperience,
        String currentRole,
        String education
) {}
