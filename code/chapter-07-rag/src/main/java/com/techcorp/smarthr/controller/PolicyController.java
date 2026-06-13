package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.IngestResponse;
import com.techcorp.smarthr.model.PolicyAskRequest;
import com.techcorp.smarthr.model.PolicyIngestRequest;
import com.techcorp.smarthr.model.PolicyResponse;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.vectorstore.QuestionAnswerAdvisor;
import org.springframework.ai.document.Document;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.SimpleVectorStore;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/hr/policy")
public class PolicyController {

    private static final String SYSTEM_PROMPT = """
            You are an HR assistant for TechCorp. Answer employee questions about HR policies
            based only on the information provided to you. If the information is not in the
            provided context, say you don't have that information in the current policy documents.
            Be concise and precise.
            """;

    private final ChatClient chatClient;
    private final SimpleVectorStore vectorStore;
    private final TokenTextSplitter splitter;

    public PolicyController(ChatClient.Builder builder, SimpleVectorStore vectorStore) {
        this.vectorStore = vectorStore;
        this.splitter = new TokenTextSplitter();
        this.chatClient = builder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultAdvisors(QuestionAnswerAdvisor.builder(vectorStore).build())
                .build();
    }

    @PostMapping("/ask")
    public PolicyResponse ask(@RequestBody PolicyAskRequest request) {
        String answer = chatClient.prompt()
                .user(request.question())
                .call()
                .content();
        return new PolicyResponse(request.question(), answer);
    }

    @PostMapping("/ingest")
    public IngestResponse ingest(@RequestBody PolicyIngestRequest request) {
        List<Document> docs = List.of(new Document(request.text()));
        List<Document> chunks = splitter.apply(docs);
        vectorStore.add(chunks);
        return new IngestResponse(chunks.size(), "Ingested " + chunks.size() + " chunk(s) into the policy store.");
    }
}
