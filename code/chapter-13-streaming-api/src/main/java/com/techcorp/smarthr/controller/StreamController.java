package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.StreamChunk;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

@RestController
@RequestMapping("/hr")
public class StreamController {

    private static final String SYSTEM_PROMPT = """
            You are an HR assistant for TechCorp, a mid-sized technology company.
            Answer employee questions about HR policies, benefits, leave, onboarding,
            and workplace guidelines clearly and professionally. Keep answers factual.
            If you do not know the answer, say so and suggest contacting HR directly.
            """;

    private final ChatClient chatClient;

    public StreamController(ChatClient.Builder builder) {
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
    }

    // GET /hr/ask/stream?question=...
    // Streams the answer token-by-token as Server-Sent Events. Each token is
    // pushed to the browser the instant Llama generates it.
    @GetMapping(value = "/ask/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> streamAnswer(@RequestParam String question) {
        return chatClient
                .prompt()
                .user(question)
                .stream()
                .content()
                .onErrorResume(e -> Flux.just("[stream error: " + e.getMessage() + "]"));
    }

    // GET /hr/ask/stream/tokens?question=...
    // Same stream, but each event carries metadata (the finish reason arrives
    // on the final chunk) instead of just raw text.
    @GetMapping(value = "/ask/stream/tokens", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<StreamChunk> streamTokens(@RequestParam String question) {
        return chatClient
                .prompt()
                .user(question)
                .stream()
                .chatResponse()
                .map(response -> {
                    var result = response.getResult();
                    String token = result != null && result.getOutput() != null
                            ? result.getOutput().getText()
                            : "";
                    String finishReason = result != null && result.getMetadata() != null
                            ? result.getMetadata().getFinishReason()
                            : null;
                    return new StreamChunk(token == null ? "" : token, finishReason);
                })
                .onErrorResume(e -> Flux.just(new StreamChunk("[stream error: " + e.getMessage() + "]", "ERROR")));
    }
}
