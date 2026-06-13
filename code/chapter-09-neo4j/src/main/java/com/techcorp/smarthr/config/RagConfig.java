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
        Neo4jVectorStore store = Neo4jVectorStore.builder(driver, embeddingModel)
                .initializeSchema(true)
                .build();
        ingestPolicy(store, driver);
        return store;
    }

    private void ingestPolicy(Neo4jVectorStore store, Driver driver) {
        TikaDocumentReader reader = new TikaDocumentReader(policyResource);
        List<Document> chunks = new TokenTextSplitter().apply(reader.read());
        store.add(chunks);
        addPolicyRelationships(driver);
    }

    // Connect related policy sections as graph edges so Graph RAG can traverse them.
    private void addPolicyRelationships(Driver driver) {
        try (Session session = driver.session()) {
            session.run("""
                    MATCH (a:Document), (b:Document)
                    WHERE a.text CONTAINS 'parental leave'
                      AND b.text CONTAINS 'sick leave'
                    MERGE (a)-[:RELATED_TO]->(b)
                    """);
            session.run("""
                    MATCH (a:Document), (b:Document)
                    WHERE a.text CONTAINS 'onboarding'
                      AND b.text CONTAINS 'IT'
                    MERGE (a)-[:RELATED_TO]->(b)
                    """);
            session.run("""
                    MATCH (a:Document), (b:Document)
                    WHERE a.text CONTAINS 'performance'
                      AND b.text CONTAINS 'learning'
                    MERGE (a)-[:RELATED_TO]->(b)
                    """);
        }
    }
}
