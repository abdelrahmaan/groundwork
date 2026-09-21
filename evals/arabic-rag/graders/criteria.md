---
type: llm
weight: 1
---

This is a retrieval problem where the language profile drives the decisions.

Passing requires ALL of:
- It treats content language, question language, and answer language as
  separate things, and uses them to choose the embedding model — rather than
  reaching for a default English embedder.
- It proposes hybrid retrieval rather than dense-only: lexical plus dense,
  fused, then reranked.
- It names Arabic-specific handling in ingestion or normalization.
- It does not silently assume an English-first pipeline.

Fail if the answer is a generic "chunk it, embed it with OpenAI, store in a
vector DB" with no Arabic-specific reasoning.
