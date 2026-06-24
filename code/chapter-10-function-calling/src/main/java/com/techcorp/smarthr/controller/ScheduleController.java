package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrResponse;
import com.techcorp.smarthr.model.ScheduleRequest;
import com.techcorp.smarthr.service.CalendarService;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.memory.InMemoryChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/hr")
public class ScheduleController {

    private static final String SYSTEM_PROMPT = """
            You are a scheduling assistant for TechCorp's hiring team. You help hiring
            managers schedule candidate interviews.

            You have tools to check calendar availability and book interview slots.
            Always check availability before booking. Only book a slot once the hiring
            manager has explicitly confirmed they want to proceed. Be concise.
            """;

    private final ChatClient chatClient;
    private final ChatMemory chatMemory;

    public ScheduleController(ChatClient.Builder builder, CalendarService calendarService) {
        this.chatMemory = MessageWindowChatMemory.builder()
                .chatMemoryRepository(new InMemoryChatMemoryRepository())
                .maxMessages(20)
                .build();

        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultTools(calendarService)
                .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
                .build();
    }

    // POST /hr/schedule/chat
    // Stateful multi-turn chat — the LLM calls CalendarService tools mid-conversation
    @PostMapping("/schedule/chat")
    public HrResponse chat(@RequestBody ScheduleRequest request) {
        String answer = chatClient
                .prompt()
                .user(request.message())
                .advisors(a -> a.param(ChatMemory.CONVERSATION_ID, request.sessionId()))
                .call()
                .content();
        return new HrResponse(request.message(), answer, "schedule");
    }

    // DELETE /hr/schedule/chat/{sessionId}
    @DeleteMapping("/schedule/chat/{sessionId}")
    public ResponseEntity<Void> clearSession(@PathVariable String sessionId) {
        chatMemory.clear(sessionId);
        return ResponseEntity.noContent().build();
    }
}
