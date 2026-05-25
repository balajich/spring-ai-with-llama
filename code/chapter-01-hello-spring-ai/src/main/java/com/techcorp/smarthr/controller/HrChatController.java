package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrRequest;
import com.techcorp.smarthr.model.HrResponse;
import org.springframework.ai.chat.client.ChatClient;
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

    // Chapter 1 — Basic HR Q&A
    // POST /hr/ask  {"question": "How many vacation days do I get?"}
    @PostMapping("/ask")
    public HrResponse ask(@RequestBody HrRequest request) {
        String answer = chatClient
                .prompt()
                .user(request.question())
                .call()
                .content();
        return new HrResponse(request.question(), answer);
    }

    // Convenience GET for quick browser/curl testing
    // GET /hr/ask?question=What+is+the+leave+policy?
    @GetMapping("/ask")
    public HrResponse askGet(@RequestParam String question) {
        String answer = chatClient
                .prompt()
                .user(question)
                .call()
                .content();
        return new HrResponse(question, answer);
    }
}
