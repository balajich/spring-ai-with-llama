package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.CompareRequest;
import com.techcorp.smarthr.model.CompareResponse;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.ollama.api.OllamaChatOptions;
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
        this.chatClient = builder.build();
    }

    @PostMapping("/ask/compare")
    public CompareResponse compare(@RequestBody CompareRequest request) {
        String answerA = askWithModel(request.question(), request.modelA());
        String answerB = askWithModel(request.question(), request.modelB());
        return new CompareResponse(
                request.question(),
                request.modelA(), answerA,
                request.modelB(), answerB
        );
    }

    private String askWithModel(String question, String model) {
        return chatClient
                .prompt()
                .system(SYSTEM_PROMPT)
                .user(question)
                .options(OllamaChatOptions.builder().model(model))
                .call()
                .content();
    }
}
