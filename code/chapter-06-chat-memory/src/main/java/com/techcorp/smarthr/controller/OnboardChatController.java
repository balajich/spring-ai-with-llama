package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrResponse;
import com.techcorp.smarthr.model.OnboardRequest;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.memory.InMemoryChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/hr")
public class OnboardChatController {

    private static final String SYSTEM_PROMPT = """
            You are a friendly onboarding assistant for TechCorp, a technology company.
            Your job is to help new employees through their first days — answering questions
            about tools, processes, policies, and who to contact.
            Keep answers concise and practical. Remember what the employee has already asked
            in this conversation and build on it where relevant.
            """;

    private final ChatClient chatClient;
    private final ChatMemory chatMemory;

    public OnboardChatController(ChatClient.Builder builder) {
        // InMemoryChatMemoryRepository is the backing store.
        // MessageWindowChatMemory keeps the last 20 messages per session (default).
        this.chatMemory = MessageWindowChatMemory.builder()
                .chatMemoryRepository(new InMemoryChatMemoryRepository())
                .maxMessages(20)
                .build();

        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
                .build();
    }

    // POST /hr/onboard/chat
    // Stateful multi-turn chat — each message is linked to a session via sessionId
    @PostMapping("/onboard/chat")
    public HrResponse chat(@RequestBody OnboardRequest request) {
        String answer = chatClient
                .prompt()
                .user(request.message())
                .advisors(a -> a.param(ChatMemory.CONVERSATION_ID, request.sessionId()))
                .call()
                .content();
        return new HrResponse(request.message(), answer, "onboard");
    }

    // DELETE /hr/onboard/chat/{sessionId}
    // Clears conversation history for a given session
    @DeleteMapping("/onboard/chat/{sessionId}")
    public ResponseEntity<Void> clearSession(@PathVariable String sessionId) {
        chatMemory.clear(sessionId);
        return ResponseEntity.noContent().build();
    }
}
