package com.techcorp.smarthr.model;

import java.util.List;

// The agent's output plus a TRACE of what it actually did.
// toolsInvoked is what makes autonomous behaviour observable — and testable.
public record ReportResponse(
        String month,
        String report,
        List<String> toolsInvoked,
        Integer toolCallCount,
        Long tookMillis
) {}
