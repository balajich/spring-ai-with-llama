package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.SafetyAnalysis;
import com.techcorp.smarthr.model.SafetyReport;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.content.Media;
import org.springframework.ai.converter.BeanOutputConverter;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpStatus;
import org.springframework.util.MimeType;
import org.springframework.util.MimeTypeUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;

@RestController
@RequestMapping("/hr")
public class SafetyController {

    private static final String SYSTEM_PROMPT = """
            You are a workplace safety officer for TechCorp. Employees send you photos
            of potential workplace hazards. You analyse the photo and describe what you
            see, focusing on anything that could injure someone or violate safety rules.
            Be factual and concise. If the image shows no hazard, say so plainly.
            """;

    private final ChatClient chatClient;

    public SafetyController(ChatClient.Builder builder) {
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
    }

    // POST /hr/safety/analyse  (multipart: image, location)
    // Free-text hazard analysis of an uploaded photo
    @PostMapping("/safety/analyse")
    public SafetyAnalysis analyse(@RequestParam("image") MultipartFile image,
                                  @RequestParam("location") String location) {
        Media media = toMedia(image);

        String analysis = chatClient
                .prompt()
                .user(u -> u
                        .text("""
                              Analyse this workplace photo for safety hazards.
                              Location: {location}

                              Identify:
                              1. Any visible hazards
                              2. Risk level (LOW / MEDIUM / HIGH)
                              3. Recommended immediate action
                              """)
                        .param("location", location)
                        .media(media))
                .call()
                .content();

        return new SafetyAnalysis(location, analysis);
    }

    // POST /hr/safety/report  (multipart: image, location)
    // Structured SafetyReport — vision analysis + BeanOutputConverter (Chapter 5)
    @PostMapping("/safety/report")
    public SafetyReport report(@RequestParam("image") MultipartFile image,
                               @RequestParam("location") String location) {
        Media media = toMedia(image);

        BeanOutputConverter<SafetyReport> converter =
                new BeanOutputConverter<>(SafetyReport.class);

        String response = chatClient
                .prompt()
                .user(u -> u
                        .text("""
                              Analyse this workplace photo taken at "{location}" and fill in
                              a safety incident report.

                              Important:
                              - Return a flat JSON object with the actual values, NOT a JSON schema.
                              - riskLevel must be exactly one of: LOW, MEDIUM, HIGH.
                              - Set requiresIncidentReport to true for MEDIUM or HIGH risk.
                              - Return ONLY the JSON object, no explanation or extra text.

                              {format}
                              """)
                        .param("location", location)
                        .param("format", converter.getFormat())
                        .media(media))
                .call()
                .content();

        try {
            return converter.convert(response);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Could not generate a structured report from this image.");
        }
    }

    private Media toMedia(MultipartFile image) {
        if (image.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Image file is empty.");
        }
        MimeType mimeType = image.getContentType() != null
                ? MimeType.valueOf(image.getContentType())
                : MimeTypeUtils.IMAGE_JPEG;
        try {
            return Media.builder()
                    .mimeType(mimeType)
                    .data(new ByteArrayResource(image.getBytes()))
                    .build();
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Could not read image file.");
        }
    }
}
