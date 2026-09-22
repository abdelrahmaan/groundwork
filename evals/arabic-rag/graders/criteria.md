---
type: llm
weight: 1
---

Judge whether the response applies THIS standard's retrieval rules. A capable
assistant without the standard will propose chunking, embeddings and a vector
store, and may say "hybrid search"; that alone is not a pass.

Passing requires ALL of:
- It separates content language, question language, and answer language, and
  uses that profile to choose the embedding model — not a single "it's Arabic".
- It names a specific multilingual embedder suited to Arabic (for example
  BAAI/bge-m3) rather than defaulting to an English-first or OpenAI embedder.
- It specifies hybrid retrieval with a NAMED fusion step — lexical (BM25) plus
  dense, fused with RRF — followed by a reranker as a distinct stage.
- It addresses Arabic-specific text normalization during ingestion.

Fail if fusion is vague ("combine the results"). Fail if the reranker is absent
or folded into retrieval. Fail if the embedder is unnamed or English-first.
