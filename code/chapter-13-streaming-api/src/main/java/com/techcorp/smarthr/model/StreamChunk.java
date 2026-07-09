package com.techcorp.smarthr.model;

// One chunk of a streamed answer, plus the finish reason (null until the
// final chunk). Emitted by the metadata-carrying stream endpoint.
public record StreamChunk(String token, String finishReason) {}
