package com.techcorp.smarthr.model;

import java.util.List;

// All HR data for one month — the raw material behind the agent's tools.
public record HrSnapshot(
        String month,
        Headcount headcount,
        List<String> openPositions,
        List<String> newHires,
        Attrition attrition,
        List<String> policyUpdates
) {
    public record Headcount(Integer total, Integer changeFromLastMonth) {}
    public record Attrition(Double ratePercent, Integer departures) {}
}
