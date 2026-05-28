package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrRequest;
import com.techcorp.smarthr.model.HrResponse;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
    private final ChatModel chatModel;

    public HrChatController(ChatClient.Builder builder, ChatModel chatModel) {
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
        this.chatModel = chatModel;
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

    // Chapter 2 — LOW-LEVEL: using ChatModel directly with Message objects
    // This exposes the underlying Message architecture Spring AI uses internally
    @PostMapping("/ask/raw")
    public HrResponse askRaw(@RequestBody HrRequest request) {
        List<Message> messages = List.of(
                new SystemMessage(SYSTEM_PROMPT),
                new UserMessage(request.question())
        );

        var response = chatModel.call(new Prompt(messages));
        String answer = response.getResult().getOutput().getText();
        return new HrResponse(request.question(), answer, "raw");
    }
   
}
