---
type: llm
weight: 1
---

Judge whether the response applies THIS standard's retrieval rules. A capable assistant
without the standard already proposes BGE-M3, hybrid BM25 + dense with RRF, a reranker and
Arabic normalization (measured 2026-09-24: 3 of 3 baseline runs did) — those are required
here but no longer sufficient.

Passing requires ALL of:
- It separates content language, question language, and answer language, and names the
  English-question-over-Arabic-documents case as CROSS-LINGUAL retrieval that the embedder
  choice must handle — not "it's Arabic, use a multilingual model".
- It names a specific multilingual embedder suited to Arabic (for example BAAI/bge-m3).
- It specifies hybrid retrieval with a NAMED fusion step (BM25 + dense, fused with RRF),
  followed by a reranker as a distinct stage.
- After the reranker it applies a SCORE THRESHOLD, and when nothing passes it the system says
  it doesn't know instead of answering from the model's own knowledge.
- It addresses Arabic-specific text normalization during ingestion.
- It evaluates retrieval/answers SEPARATELY per question language (Arabic questions and
  English questions as distinct slices of the eval set).

Fail if fusion is vague. Fail if there is no threshold or no "I don't know" path. Fail if the
evaluation is not split by language.
