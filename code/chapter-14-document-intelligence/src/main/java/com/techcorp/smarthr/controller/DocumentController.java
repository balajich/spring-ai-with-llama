package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.ContractAnalysis;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.converter.BeanOutputConverter;
import org.springframework.ai.document.Document;
import org.springframework.ai.reader.pdf.PagePdfDocumentReader;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/hr")
public class DocumentController {

    private final ChatClient chatClient;

    public DocumentController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }

    // POST /hr/contract/analyse  (multipart: file = an employment contract PDF)
    // Reads the whole PDF, injects it into the prompt (direct injection, not RAG),
    // and returns a structured first-pass legal review.
    @PostMapping("/contract/analyse")
    public ContractAnalysis analyseContract(@RequestParam("file") MultipartFile file) {
        String contractText = readPdf(file);

        BeanOutputConverter<ContractAnalysis> converter =
                new BeanOutputConverter<>(ContractAnalysis.class);

        String response = chatClient
                .prompt()
                .options(ChatOptions.builder().temperature(0.0))   // deterministic extraction
                .user(u -> u.text("""
                        You are an HR contracts assistant. Do a first-pass review of the
                        employment contract below and extract these fields:
                        - summary: a two-sentence plain-English summary of the contract
                        - probationPeriod: the probation period stated, or "not specified"
                        - noticePeriod: the notice period for termination, or "not specified"
                        - ipOwnership: who owns intellectual property created by the employee
                        - nonStandardClauses: an array of any unusual or non-standard clauses
                          a lawyer should look at (empty array if none)
                        - requiresLegalReview: true if anything looks unusual or risky, else false

                        Contract:
                        {contract}

                        {format}
                        """)
                        .param("contract", contractText)
                        .param("format", converter.getFormat()))
                .call()
                .content();

        try {
            return converter.convert(response);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Could not analyse the contract. Ensure the PDF contains readable text.");
        }
    }

    // POST /hr/document/summarise  (multipart: file = PDF, Word, HTML, txt, ...)
    // Tika reads almost any document format; we return a plain-text summary.
    @PostMapping("/document/summarise")
    public SummaryResponse summarise(@RequestParam("file") MultipartFile file) {
        Resource resource = toResource(file);
        List<Document> docs = new TikaDocumentReader(resource).get();
        String text = docs.stream().map(Document::getText).collect(Collectors.joining("\n\n"));

        if (text.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "No readable text found in the uploaded document.");
        }

        String summary = chatClient
                .prompt()
                .options(ChatOptions.builder().temperature(0.2))
                .user(u -> u.text("""
                        Summarise the document below for an HR manager in 3-4 sentences.

                        Document:
                        {doc}
                        """).param("doc", text))
                .call()
                .content();

        return new SummaryResponse(file.getOriginalFilename(), summary);
    }

    public record SummaryResponse(String filename, String summary) {}

    // ── helpers ───────────────────────────────────────────────────────────────

    private String readPdf(MultipartFile file) {
        Resource resource = toResource(file);
        List<Document> pages;
        try {
            pages = new PagePdfDocumentReader(resource).get();
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Could not read the PDF. Is it a valid, text-based PDF?");
        }
        String text = pages.stream().map(Document::getText).collect(Collectors.joining("\n\n"));
        if (text.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "The PDF has no extractable text (it may be a scanned image).");
        }
        return text;
    }

    private Resource toResource(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No file uploaded.");
        }
        try {
            // named resource so Tika can use the filename to detect the content type
            return new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename();
                }
            };
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Could not read the uploaded file.");
        }
    }
}
