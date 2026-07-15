package com.techcorp.smarthr.controller;

import com.techcorp.smarthr.model.Candidate;
import com.techcorp.smarthr.model.CandidateMatch;
import com.techcorp.smarthr.model.CandidateSearchRequest;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@RestController
@RequestMapping("/hr")
public class CandidateSearchController {

    private static final int DEFAULT_TOP_K = 5;

    // Accept-all: SimpleVectorStore uses cosine similarity, and a 0.0 floor lets
    // the caller see the scores and tune for themselves. Raise it in production.
    private static final double SIMILARITY_THRESHOLD = 0.0;

    private final VectorStore vectorStore;
    private final List<Candidate> candidates;

    public CandidateSearchController(VectorStore vectorStore, List<Candidate> candidates) {
        this.vectorStore = vectorStore;
        this.candidates = candidates;
    }

    // GET /hr/candidates — everything that is indexed (sanity / UI listing)
    @GetMapping("/candidates")
    public List<Candidate> listCandidates() {
        return candidates;
    }

    // POST /hr/candidates/search
    // Semantic search over resumes, optionally narrowed by exact metadata filters.
    @PostMapping("/candidates/search")
    public List<CandidateMatch> search(@RequestBody CandidateSearchRequest request) {
        if (request.query() == null || request.query().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "query must not be blank");
        }

        int topK = request.topK() != null && request.topK() > 0 ? request.topK() : DEFAULT_TOP_K;

        SearchRequest.Builder builder = SearchRequest.builder()
                .query(request.query())
                .topK(topK)
                .similarityThreshold(SIMILARITY_THRESHOLD);

        String filter = buildFilter(request);
        if (filter != null) {
            builder.filterExpression(filter);   // exact-match, ANDed with the semantic search
        }

        List<Document> matches = vectorStore.similaritySearch(builder.build());
        if (matches == null) {
            return List.of();
        }

        return matches.stream().map(this::toMatch).toList();
    }

    /** Builds a filter expression like: seniority == 'SENIOR' && location == 'London' */
    private String buildFilter(CandidateSearchRequest request) {
        List<String> clauses = new ArrayList<>();
        if (request.seniority() != null && !request.seniority().isBlank()) {
            clauses.add("seniority == '" + request.seniority().trim() + "'");
        }
        if (request.location() != null && !request.location().isBlank()) {
            clauses.add("location == '" + request.location().trim() + "'");
        }
        return clauses.isEmpty() ? null : String.join(" && ", clauses);
    }

    private CandidateMatch toMatch(Document doc) {
        var md = doc.getMetadata();
        String text = Objects.requireNonNullElse(doc.getText(), "");
        return new CandidateMatch(
                str(md.get("candidateId")),
                str(md.get("name")),
                str(md.get("role")),
                str(md.get("seniority")),
                str(md.get("location")),
                doc.getScore(),                                   // GA: score lives on Document
                text.substring(0, Math.min(180, text.length()))
        );
    }

    private String str(Object o) {
        return o == null ? "" : o.toString();
    }
}
