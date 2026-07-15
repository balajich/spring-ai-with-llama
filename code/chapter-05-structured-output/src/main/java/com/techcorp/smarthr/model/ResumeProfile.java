package com.techcorp.smarthr.model;

import java.util.List;

public record ResumeProfile(
        String name,
        String email,
        List<String> skills,
        Integer yearsOfExperience,   // boxed: a resume may omit this; null must not crash parsing
        String currentRole,
        String education
) {}
