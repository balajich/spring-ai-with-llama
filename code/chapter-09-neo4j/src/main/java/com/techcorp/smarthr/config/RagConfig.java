package com.techcorp.smarthr.config;

import org.neo4j.driver.Driver;
import org.neo4j.driver.Session;
import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.ai.vectorstore.neo4j.Neo4jVectorStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.util.List;

@Configuration
public class RagConfig {

    @Value("classpath:policies/techcorp-hr-policy.txt")
    private Resource policyResource;

    @Bean
    public VectorStore vectorStore(EmbeddingModel embeddingModel, Driver driver) {
        return Neo4jVectorStore.builder(driver, embeddingModel)
                .initializeSchema(true)
                .build();
    }

    // Runs after Spring has fully initialised all beans (including Neo4jVectorStore
    // afterPropertiesSet()) so the schema and type registration are complete.
    @Bean
    public ApplicationRunner ingestPolicy(VectorStore vectorStore, Driver driver) {
        return args -> {
            // Skip ingestion if nodes already exist (idempotent on restart)
            try (Session session = driver.session()) {
                long count = session.run("MATCH (n:Document) RETURN count(n) AS count")
                        .single().get("count").asLong();
                if (count > 0) {
                    return;
                }
            }

            TikaDocumentReader reader = new TikaDocumentReader(policyResource);
            // 150-token chunks so each policy section (Annual Leave, Sick Leave, etc.)
            // lands in its own node — required for cross-section graph edges to exist.
            List<Document> chunks = TokenTextSplitter.builder()
                    .withChunkSize(150)
                    .withMinChunkSizeChars(50)
                    .build()
                    .apply(reader.read());
            vectorStore.add(chunks);
            addPolicyRelationships(driver);
        };
    }

    // Connect related policy sections as graph edges so Graph RAG can traverse them.
    private void addPolicyRelationships(Driver driver) {
        try (Session session = driver.session()) {
            // Bidirectional — neither policy section is the "parent" of the other
            session.run("""
                    MATCH (a:Document), (b:Document)
                    WHERE a.text CONTAINS 'parental leave'
                      AND b.text CONTAINS 'sick leave'
                      AND a <> b
                    MERGE (a)-[:RELATED_TO]->(b)
                    MERGE (b)-[:RELATED_TO]->(a)
                    """);
            session.run("""
                    MATCH (a:Document), (b:Document)
                    WHERE a.text CONTAINS 'onboarding'
                      AND b.text CONTAINS 'IT'
                      AND a <> b
                    MERGE (a)-[:RELATED_TO]->(b)
                    MERGE (b)-[:RELATED_TO]->(a)
                    """);
            session.run("""
                    MATCH (a:Document), (b:Document)
                    WHERE a.text CONTAINS 'performance'
                      AND b.text CONTAINS 'learning'
                      AND a <> b
                    MERGE (a)-[:RELATED_TO]->(b)
                    MERGE (b)-[:RELATED_TO]->(a)
                    """);
        }
    }
}
