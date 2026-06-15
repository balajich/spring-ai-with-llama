package com.techcorp.smarthr.config;

import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.ai.vectorstore.pgvector.PgVectorStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Objects;

@Configuration
public class RagConfig {

    @Value("classpath:policies/techcorp-hr-policy.txt")
    private Resource policyResource;

    @Bean
    public VectorStore vectorStore(EmbeddingModel embeddingModel, JdbcTemplate jdbcTemplate) {
        return PgVectorStore.builder(jdbcTemplate, embeddingModel)
                .initializeSchema(true)
                .dimensions(768)
                .distanceType(PgVectorStore.PgDistanceType.COSINE_DISTANCE)
                .indexType(PgVectorStore.PgIndexType.HNSW)
                .build();
    }

    // Runs after Spring has fully initialised all beans (including PgVectorStore,
    // which registers the pgvector JDBC type in afterPropertiesSet()).
    // Skips ingestion if chunks are already present so restarts don't duplicate data.
    @Bean
    public ApplicationRunner ingestPolicy(VectorStore vectorStore, JdbcTemplate jdbcTemplate) {
        return args -> {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM vector_store", Integer.class);
            if (Objects.requireNonNullElse(count, 0) > 0) {
                return;
            }
            TikaDocumentReader reader = new TikaDocumentReader(policyResource);
            List<Document> chunks = new TokenTextSplitter().apply(reader.read());
            vectorStore.add(chunks);
        };
    }
}
