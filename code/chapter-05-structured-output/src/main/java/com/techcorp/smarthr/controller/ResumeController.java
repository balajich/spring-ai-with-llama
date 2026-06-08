package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.ResumeParseRequest;
import com.techcorp.smarthr.model.ResumeProfile;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.converter.BeanOutputConverter;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/hr")
public class ResumeController {

    private final ChatClient chatClient;

    public ResumeController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    // POST /hr/resume/parse
    // Parses raw resume text and returns a structured ResumeProfile Java record
    @PostMapping("/resume/parse")
    public ResumeProfile parseResume(@RequestBody ResumeParseRequest request) {
        BeanOutputConverter<ResumeProfile> converter =
                new BeanOutputConverter<>(ResumeProfile.class);

        String response = chatClient
                .prompt()
                .user(u -> u.text("""
                        Extract information from the resume below and return it as a \
                        plain JSON object containing only the field values.

                        Important:
                        - Return a flat JSON object with the actual values, NOT a JSON schema.
                        - Do NOT wrap the result in a "properties" key.
                        - Do NOT include "$schema", "type", "required", or "additionalProperties".
                        - Return ONLY the JSON object, no explanation or extra text.

                        Resume:
                        {resumeText}

                        {format}
                        """)
                        .param("resumeText", request.resumeText())
                        .param("format", converter.getFormat()))
                .call()
                .content();

        try {
            return converter.convert(response);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Could not parse resume. Try providing more structured text.");
        }
    }
}
