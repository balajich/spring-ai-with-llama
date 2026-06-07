package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.HrResponse;
import com.techcorp.smarthr.model.PersonalisedRequest;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.chat.prompt.PromptTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/hr")
public class HrChatController {

    private final ChatClient chatClient;

    // Loaded from src/main/resources/prompts/hr-assistant.st
    @Value("classpath:prompts/hr-assistant.st")
    private Resource hrAssistantTemplate;

    // Loaded from src/main/resources/prompts/onboarding.st
    @Value("classpath:prompts/onboarding.st")
    private Resource onboardingTemplate;

    public HrChatController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    // Chapter 4 — personalised HR response using hr-assistant.st template
    @PostMapping("/ask/personalised")
    public HrResponse askPersonalised(@RequestBody PersonalisedRequest request) {
        PromptTemplate template = new PromptTemplate(hrAssistantTemplate);

        Prompt prompt = template.create(Map.of(
                "name",       request.name(),
                "department", request.department(),
                "role",       request.role(),
                "question",   request.question()
        ));

        String answer = chatClient.prompt(prompt).call().content();
        return new HrResponse(request.question(), answer, "personalised");
    }

    // Chapter 4 — onboarding-specific response using onboarding.st template
    @PostMapping("/ask/onboarding")
    public HrResponse askOnboarding(@RequestBody PersonalisedRequest request) {
        PromptTemplate template = new PromptTemplate(onboardingTemplate);

        Prompt prompt = template.create(Map.of(
                "name",       request.name(),
                "department", request.department(),
                "role",       request.role(),
                "question",   request.question()
        ));

        String answer = chatClient.prompt(prompt).call().content();
        return new HrResponse(request.question(), answer, "onboarding");
    }
}
