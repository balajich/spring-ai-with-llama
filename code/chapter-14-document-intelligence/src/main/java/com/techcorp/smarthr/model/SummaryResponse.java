package com.techcorp.smarthr.model;

// Plain-text summary of any uploaded document (PDF, Word, HTML, ...) read via Tika.
public record SummaryResponse(String filename, String summary) {}
