package com.techcorp.smarthr.config;

import com.techcorp.smarthr.model.Candidate;
import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.vectorstore.SimpleVectorStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import tools.jackson.databind.ObjectMapper;   // Jackson 3 — Spring Boot 4.1 moved off com.fasterxml

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Map;

/**
 * Loads candidates.json and embeds every resume into an in-memory vector store.
 *
 * The resume text becomes the embedded content (that is what we search by
 * meaning). Everything else — id, name, role, seniority, location — is stored as
 * METADATA, which is what makes exact-match filtering possible alongside the
 * semantic search.
 */
@Configuration
public class CandidateIndexConfig {

    @Value("classpath:candidates/candidates.json")
    private Resource candidatesResource;

    @Bean
    public List<Candidate> candidates(ObjectMapper mapper) throws IOException {
        try (InputStream in = candidatesResource.getInputStream()) {
            return List.of(mapper.readValue(in, Candidate[].class));
        }
    }

    @Bean
    public SimpleVectorStore vectorStore(EmbeddingModel embeddingModel, List<Candidate> candidates) {
        SimpleVectorStore store = SimpleVectorStore.builder(embeddingModel).build();

        List<Document> docs = candidates.stream()
                .map(c -> new Document(c.resume(), Map.of(
                        "candidateId", c.candidateId(),
                        "name", c.name(),
                        "role", c.role(),
                        "seniority", c.seniority(),
                        "location", c.location()
                )))
                .toList();

        store.add(docs);   // embeds each resume via nomic-embed-text
        return store;
    }
}
