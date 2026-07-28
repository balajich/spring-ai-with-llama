package com.techcorp.smarthr.service;

import com.techcorp.smarthr.model.HrSnapshot;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * The agent's toolbox. Five independent HR data sources — in a real system these
 * would be five different services or databases.
 *
 * Each @Tool records that it was called. The agent decides WHICH tools to call
 * and in WHAT ORDER; the recorded trace is how we make that decision visible
 * (and testable) instead of just trusting the prose it writes.
 */
@Service
public class HrDataService {

    // Recorded per request, cleared before each agent run. Not thread-safe by
    // design — one agent run at a time keeps the demo readable.
    private final List<String> invocationLog = new ArrayList<>();

    private static final Map<String, HrSnapshot> DATA = Map.of(
            "2026-06", new HrSnapshot("2026-06",
                    new HrSnapshot.Headcount(342, 12),
                    List.of("Staff Engineer (critical)", "Data Scientist (critical)", "HR Business Partner"),
                    List.of("Priya Sharma — Senior Engineer", "Tom Baker — Data Scientist"),
                    new HrSnapshot.Attrition(1.8, 6),
                    List.of("Parental leave extended to 26 weeks", "Hybrid policy: 3 days on-site")),
            "2026-05", new HrSnapshot("2026-05",
                    new HrSnapshot.Headcount(330, 4),
                    List.of("Staff Engineer (critical)", "QA Automation Engineer"),
                    List.of("Marcus Chen — Frontend Engineer"),
                    new HrSnapshot.Attrition(2.4, 8),
                    List.of("Expense policy updated"))
    );

    // ── Tools exposed to the agent ────────────────────────────────────────────

    @Tool(description = "Get total employee headcount and the change from last month for a given month")
    public HrSnapshot.Headcount getHeadcount(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) {
        record("getHeadcount");
        return snapshot(month).headcount();
    }

    @Tool(description = "Get all currently open job positions for a given month")
    public List<String> getOpenPositions(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) {
        record("getOpenPositions");
        return snapshot(month).openPositions();
    }

    @Tool(description = "Get the list of employees who joined in a given month")
    public List<String> getRecentHires(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) {
        record("getRecentHires");
        return snapshot(month).newHires();
    }

    @Tool(description = "Get the attrition rate and number of departures for a given month")
    public HrSnapshot.Attrition getAttrition(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) {
        record("getAttrition");
        return snapshot(month).attrition();
    }

    @Tool(description = "Get HR policy changes announced in a given month")
    public List<String> getPolicyUpdates(
            @ToolParam(description = "Month in yyyy-MM format, e.g. 2026-06") String month) {
        record("getPolicyUpdates");
        return snapshot(month).policyUpdates();
    }

    // ── Trace support (not exposed to the model) ──────────────────────────────

    public void resetLog() {
        invocationLog.clear();
    }

    /** Distinct tool names, in the order the agent first called them. */
    public List<String> invokedTools() {
        return invocationLog.stream().distinct().toList();
    }

    /** Total invocations, including repeats. */
    public int invocationCount() {
        return invocationLog.size();
    }

    public List<String> toolNames() {
        return List.of("getHeadcount", "getOpenPositions", "getRecentHires",
                       "getAttrition", "getPolicyUpdates");
    }

    public HrSnapshot snapshot(String month) {
        return DATA.getOrDefault(month, DATA.get("2026-06"));
    }

    public boolean hasData(String month) {
        return DATA.containsKey(month);
    }

    private void record(String tool) {
        invocationLog.add(tool);
    }
}
