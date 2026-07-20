package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrSnapshot;
import com.techcorp.smarthr.model.ReportRequest;
import com.techcorp.smarthr.model.ReportResponse;
import com.techcorp.smarthr.service.HrDataService;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/hr")
public class ReportAgentController {

    private static final Pattern MONTH = Pattern.compile("\\d{4}-\\d{2}");

    // The system prompt defines the agent's ROLE and OUTPUT FORMAT — not its steps.
    // Deciding the steps is the agent's job.
    private static final String SYSTEM_PROMPT = """
            You are TechCorp's HR reporting agent. You are given a goal, not instructions.

            You have tools that return HR data for a month. Decide for yourself which
            tools you need, call them, and use ONLY the values they return — never
            invent numbers. When you have gathered enough data, write the report.

            Format the report with these sections, each on its own line:
            Headcount, New Hires, Open Positions, Attrition, Policy Updates, Summary.
            Be concise and factual.
            """;

    private final ChatClient chatClient;
    private final HrDataService hrData;

    public ReportAgentController(ChatClient.Builder builder, HrDataService hrData) {
        this.hrData = hrData;
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultTools(hrData)          // all five @Tool methods become available
                .build();
    }

    // POST /hr/report/generate
    // Give the agent a GOAL. It plans the tool calls itself.
    @PostMapping("/report/generate")
    public ReportResponse generate(@RequestBody ReportRequest request) {
        String month = request.month() == null ? "" : request.month().trim();
        if (month.isBlank() || !MONTH.matcher(month).matches()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "month must be provided in yyyy-MM format, e.g. 2025-05");
        }

        hrData.resetLog();                     // start a clean trace
        long started = System.currentTimeMillis();

        String report = chatClient
                .prompt()
                .options(ChatOptions.builder().temperature(0.0))  // deterministic planning
                .user("""
                      Produce the complete monthly HR report for %s.
                      Gather whatever data you need using your tools first.
                      """.formatted(month))
                .call()
                .content();

        long took = System.currentTimeMillis() - started;

        return new ReportResponse(
                month,
                report == null ? "" : report,
                hrData.invokedTools(),         // ← the agent's actual plan, observed
                hrData.invocationCount(),
                took);
    }

    // GET /hr/agent/tools — what the agent is allowed to do
    @GetMapping("/agent/tools")
    public List<String> tools() {
        return hrData.toolNames();
    }

    // GET /hr/agent/data/{month} — the raw data behind the tools (for comparison)
    @GetMapping("/agent/data/{month}")
    public HrSnapshot data(@PathVariable String month) {
        if (!hrData.hasData(month)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No HR data for " + month);
        }
        return hrData.snapshot(month);
    }
}
