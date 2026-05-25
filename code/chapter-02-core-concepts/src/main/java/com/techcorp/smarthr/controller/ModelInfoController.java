package com.techcorp.smarthr.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/hr/model")
public class ModelInfoController {

    @Value("${spring.ai.ollama.chat.options.model}")
    private String modelName;

    @Value("${spring.ai.ollama.base-url}")
    private String ollamaBaseUrl;

    @Value("${spring.ai.ollama.chat.options.temperature:0.3}")
    private double defaultTemperature;

    @Value("${spring.ai.ollama.chat.options.num-predict:500}")
    private int defaultMaxTokens;

    // GET /hr/model/info — shows what model is active and its default config
    @GetMapping("/info")
    public ModelInfo info() {
        return new ModelInfo(
                modelName,
                ollamaBaseUrl,
                defaultTemperature,
                defaultMaxTokens,
                "llama3.2 is active. Switch model in application.yml."
        );
    }

    public record ModelInfo(
            String model,
            String ollamaUrl,
            double defaultTemperature,
            int defaultMaxTokens,
            String hint
    ) {}
}
