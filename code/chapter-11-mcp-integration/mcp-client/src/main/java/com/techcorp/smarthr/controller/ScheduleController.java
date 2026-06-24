package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrResponse;
import com.techcorp.smarthr.model.ScheduleRequest;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.memory.InMemoryChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.tool.ToolCallbackProvider;
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

    // toolCallbackProvider is auto-configured by spring-ai-starter-mcp-client. It connects
    // to mcp-server (over SSE) which in turn calls calendar-service over REST — three
    // separate processes, discovered and wired together without any @Tool methods here.
    public ScheduleController(ChatClient.Builder builder, ToolCallbackProvider toolCallbackProvider) {
        this.chatMemory = MessageWindowChatMemory.builder()
                .chatMemoryRepository(new InMemoryChatMemoryRepository())
                .maxMessages(20)
                .build();

        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultToolCallbacks(toolCallbackProvider)
                .defaultAdvisors(MessageChatMemoryAdvisor.builder(chatMemory).build())
                .build();
    }

    // POST /hr/schedule/chat
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
