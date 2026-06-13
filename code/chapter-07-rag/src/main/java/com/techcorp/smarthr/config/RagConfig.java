package com.techcorp.smarthr.config;

import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.SimpleVectorStore;
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
    public SimpleVectorStore vectorStore(EmbeddingModel embeddingModel) {
        SimpleVectorStore store = SimpleVectorStore.builder(embeddingModel).build();
        ingestPolicy(store);
        return store;
    }

    private void ingestPolicy(SimpleVectorStore store) {
        TikaDocumentReader reader = new TikaDocumentReader(policyResource);
        List<Document> docs = reader.read();
        List<Document> chunks = new TokenTextSplitter().apply(docs);
        store.add(chunks);
    }
}
