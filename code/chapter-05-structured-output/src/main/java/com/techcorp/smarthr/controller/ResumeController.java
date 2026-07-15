package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.ResumeParseRequest;
import com.techcorp.smarthr.model.ResumeProfile;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.ChatOptions;
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
                .options(ChatOptions.builder().temperature(0.0))
                .user(u -> u.text("""
                        You are a resume parser. Read the resume below and extract these fields:
                        - name: the candidate's full name
                        - email: their email address
                        - skills: an array of their technical skills
                        - yearsOfExperience: total years of experience, as a number
                        - currentRole: their current or most recent job title
                        - education: their highest qualification

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
