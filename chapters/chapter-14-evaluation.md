# Chapter 14 — Evaluation: Testing and Scoring AI Responses

> **What you will build:** An automated QA pipeline — a test suite that sends HR questions to the SmartHR bot, uses a second AI call to score each answer on accuracy, relevance, and tone, and fails the build if quality drops below a threshold.

---

## The Problem We Are Solving

Dev has been adding features for weeks. Sarah suddenly reports:

> "The bot started giving weird answers this week. Did something change?"

Dev has no idea. There are no tests for AI output quality. A change to the system prompt or model version quietly degraded the answers and nobody caught it.

The fix: automated AI evaluation.

---

## What You Will Learn

- Why traditional unit tests do not work for AI output
- The "AI as judge" pattern
- Spring AI's built-in evaluators
- How to write an AI quality test suite
- How to set score thresholds and fail the build

---

## Why Unit Tests Do Not Work for AI

```java
// This test is useless for AI
@Test
void shouldAnswerLeaveQuestion() {
    String answer = chatClient.prompt()
            .user("How many leave days do I get?")
            .call().content();

    assertEquals("You get 15 days", answer);  // ❌ fails every time — output is never identical
}
```

AI output is non-deterministic. You cannot assert exact strings. You need to evaluate the *quality* of the answer, not the exact text.

---

## The AI-as-Judge Pattern

Use a second AI call to evaluate the first:

```
Question: "How many vacation days do new employees get?"
Answer:   "At TechCorp, new employees receive 15 days of paid vacation..."

Judge prompt:
  "Rate this answer on a scale of 1-5 for:
   - Accuracy (does it answer the question?)
   - Relevance (is it on topic?)
   - Tone (is it professional?)
   Return JSON: {accuracy: X, relevance: X, tone: X, feedback: '...'}"
```

---

## Spring AI's Built-In Evaluators

```java
// Relevance evaluator — is the answer relevant to the question?
RelevancyEvaluator evaluator = new RelevancyEvaluator(ChatClient.builder(chatModel));

EvaluationResponse result = evaluator.evaluate(
        new EvaluationRequest(question, List.of(context), answer)
);

boolean isRelevant = result.isPass();
float score = result.getScore();
```

---

## What You Will Build — Evaluation Test Suite

```java
@SpringBootTest
class HrChatQualityTest {

    @Autowired ChatClient chatClient;
    @Autowired ChatModel chatModel;

    RelevancyEvaluator evaluator;

    @BeforeEach
    void setup() {
        evaluator = new RelevancyEvaluator(ChatClient.builder(chatModel));
    }

    @ParameterizedTest
    @MethodSource("hrQuestions")
    void shouldAnswerHrQuestionsRelevantly(String question, String context) {
        String answer = chatClient.prompt().user(question).call().content();

        EvaluationResponse result = evaluator.evaluate(
                new EvaluationRequest(question, List.of(context), answer));

        assertThat(result.getScore())
                .as("Answer quality too low for question: " + question)
                .isGreaterThanOrEqualTo(0.7f);
    }

    static Stream<Arguments> hrQuestions() {
        return Stream.of(
                Arguments.of("How many vacation days do new employees get?",
                             "TechCorp policy: 15 days for first year"),
                Arguments.of("What is the notice period for resignation?",
                             "TechCorp policy: 30 days notice required"),
                Arguments.of("When does health insurance start?",
                             "TechCorp policy: Health insurance from day one")
        );
    }
}
```

---

## Evaluation Metrics to Track

| Metric | What it measures | Acceptable threshold |
|--------|-----------------|---------------------|
| Relevancy | Is the answer on-topic? | ≥ 0.7 |
| Faithfulness | Does it stick to facts (not hallucinate)? | ≥ 0.8 |
| Completeness | Does it address the full question? | ≥ 0.65 |
| Tone | Is it professional? | ≥ 0.75 |

---

## Summary

In this chapter you will:

- Understand why deterministic unit tests fail for AI and what to do instead
- Use the AI-as-judge pattern to evaluate answer quality
- Use Spring AI's `RelevancyEvaluator`
- Build a parameterised test suite that fails the build if quality drops

---

## What's Next

In **Chapter 15**, we focus on performance — prompt caching, batch processing, and how to handle hundreds of AI requests efficiently without overwhelming Ollama.

*Code for this chapter: [`code/chapter-14-evaluation/`](../code/chapter-14-evaluation/)*
