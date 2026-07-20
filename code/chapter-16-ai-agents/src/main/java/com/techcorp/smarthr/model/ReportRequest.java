package com.techcorp.smarthr.model;

// Boxed/nullable so an omitted field arrives as null rather than throwing (Jackson 3).
public record ReportRequest(String month) {}
