package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrRequest;
import com.techcorp.smarthr.model.HrResponse;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/hr")
public class HrChatController {

    private static final String SYSTEM_PROMPT = """
            You are an HR assistant for TechCorp, a mid-sized technology company.
            Your job is to answer employee questions about HR policies, benefits,
            leave, onboarding, and workplace guidelines clearly and professionally.
            Keep answers concise and factual. If you do not know the answer,
            say so honestly and suggest contacting the HR department directly.
            """;

    private final ChatClient chatClient;

    public HrChatController(ChatClient.Builder builder) {
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
    }

    // Chapter 1 endpoint — unchanged
    @PostMapping("/ask")
    public HrResponse ask(@RequestBody HrRequest request) {
        String answer = chatClient
                .prompt()
                .user(request.question())
                .call()
                .content();
        return new HrResponse(request.question(), answer, "standard");
    }

    // Chapter 2 — PRECISE mode: low temperature + token limit
    // Use for policy questions that need short, consistent answers
    @PostMapping("/ask/precise")
    public HrResponse askPrecise(@RequestBody HrRequest request) {
        String answer = chatClient
                .prompt()
                .options(ChatOptions.builder()
                        .temperature(0.0)   // fully deterministic
                        .maxTokens(150))    // hard cap at ~150 tokens (~100 words)
                .user(request.question())
                .call()
                .content();
        return new HrResponse(request.question(), answer, "precise");
    }

    // Chapter 2 — CREATIVE mode: higher temperature
    // Use for brainstorming, generating ideas, writing job descriptions
    @PostMapping("/ask/creative")
    public HrResponse askCreative(@RequestBody HrRequest request) {
        String answer = chatClient
                .prompt()
                .options(ChatOptions.builder()
                        .temperature(0.9)
                        .maxTokens(800))
                .user(request.question())
                .call()
                .content();
        return new HrResponse(request.question(), answer, "creative");
    }

}
