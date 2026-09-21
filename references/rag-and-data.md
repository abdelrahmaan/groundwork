# RAG & Data Standard

## 1. Data layer contract (any DB)
- Singleton client/pool created in lifespan: `connect()`, `disconnect()`, `validate_connection()`.
- Repositories expose semantic methods (`get_order`, `list_orders`) — no raw handles or inline queries in routes/services.
- Parameterized queries only; escape user input before regex/search.
- Least-privilege DB users; migrations for relational DBs (Alembic); explicit naming conventions for tables/indexes/keys.
- Primary DB = **source of truth**. Vector index = derived, always rebuildable.

## 2. Ingestion pipeline
Stages, each independently re-runnable and idempotent:
**Extract → Parse → Clean/Normalize → Chunk → Embed → Index**
- Runs in a worker/queue, never in the request path.
- Content hash per document/chunk → skip unchanged (idempotent re-ingest).
- Parsing: Azure Document Intelligence for scans/tables/complex layout; light parser for clean text.
- Chunking fits the document: structure-aware (headings, tables, pages) over fixed-size; keep overlap modest.
- Metadata on every chunk: `source_id`, `page`, `section`, `tenant_id`, `acl`, `lang`, `doc_version`, `ingested_at`.
- Arabic: normalize consistently in ingest AND query (alef variants, yaa/alef maqsura, taa marbuta, diacritics/tatweel), keep original text for display. Normalization must be one shared function used by both paths — two copies drift and silently kill recall.
- Never embed secrets; redact PII if the index is shared.

## 3. Embedding & reranking models — pick by language

**Embeddings — pick one, record it in `CLAUDE.md`:**
| Model | Why | When |
|---|---|---|
| **BGE-M3** (self-hosted) | best measured Arabic retrieval in the 2026 Arabic-RAG study; one model gives dense + sparse + ColBERT multi-vector (your hybrid stack for free); 100+ languages, 8K context | default for Arabic-first, on-prem, or cost-sensitive |
| **Cohere Embed v4** | managed, strong multilingual, long context, quantization options | managed API, no GPU to run |
| **OpenAI text-embedding-3-large** | managed, strong general quality, easy | already on OpenAI/Azure OpenAI |

**Language routing — decide from the discovery answers, not from habit:**

| Situation | What to do |
|---|---|
| Content and questions both English | any strong English embedder; don't pay the multilingual tax |
| Content and questions both Arabic | BGE-M3 (or a managed multilingual model) + Arabic normalization on **both** sides |
| **Cross-lingual** (Arabic questions over English docs, or the reverse) | a genuinely multilingual embedder is mandatory (BGE-M3, multilingual-e5). Verify with a cross-lingual slice of the golden set *before* building on it — this is the most common silent failure |
| Mixed-language documents (Arabic body, English terms/numbers) | one multilingual embedder; keep raw text for display; don't strip Latin runs during normalization |
| Dialect or code-switched input (Arabizi, Franco-Arabic) | normalize + keep the original; add dialect queries to the golden set; consider query rewriting to MSA only if evals justify it |
| Many languages in one corpus | one multilingual embedder + `lang` metadata filter; never mix embedders in a collection |
| A language none of the above covers well (e.g. low-resource) | benchmark 2–3 candidates on your own data first; assume nothing from leaderboards |

Notes: multilingual models generally beat Arabic-specific encoders for retrieval. Never mix embedders inside one collection; store the model name + version in collection metadata. Re-verify against the current MTEB / ArabicMTEB leaderboard before a new project.

**Answer-language rule:** the language the answer must be in is a *requirement*, not a side effect. State it in the prompt, and make it an eval criterion — a model that answers Arabic questions in English is a failing test, not a quirk.

**Rerankers:** **Cohere Rerank** (multilingual, managed) or **Jina Reranker** (multilingual, self-hostable) — both fine; BGE cross-encoder when everything must stay on-prem. Always benchmark on your own Arabic data before committing; rerank is usually the single biggest quality jump after hybrid search.

## 3b. Choosing the vector store (incl. pgvector / Supabase)

| Option | Choose it when | Cost of choosing it |
|---|---|---|
| **Qdrant** | default for real RAG: native hybrid (dense + sparse), payload filters, quantization, scales past a few million chunks | one more service to run and back up |
| **pgvector** (Postgres extension) | the corpus is small-to-medium (roughly under ~1M chunks), you already run Postgres, and you want **one database, one backup, one transaction** — chunks and business rows join directly | you build hybrid yourself; index tuning is on you |
| **Supabase** | you want managed Postgres + pgvector without ops, and the extras (auth, storage, realtime, edge functions) actually fit the product | vendor coupling; its auth may duplicate your IdP choice — pick one, don't run both |
| **Azure AI Search** | the project is Azure-native and you want managed hybrid + semantic ranking | cost; less control over the ranking internals |

**If you pick pgvector or Supabase, do it properly:**
- Index: **HNSW** for query speed (build is slower, memory heavier) — IVFFlat only when build time dominates and you can re-train the index after big inserts.
- Set the distance operator to match the embedder (cosine for most; store normalized vectors).
- **Hybrid in Postgres is manual**: a `tsvector` full-text index (with the right text search config — Arabic needs care) alongside the vector column, then fuse with RRF in one SQL query. You own that query; test it against the golden set.
- Filters: keep `tenant_id`, `lang`, `doc_type` as real columns with btree indexes and filter *in* the same query — not after retrieval.
- Watch: dimension limits (index support caps out around 2000 dimensions — BGE-M3 at 1024 is fine), table bloat after re-embedding (`VACUUM`/reindex), and connection pool pressure from long vector queries.
- Re-embedding = new table or new column + index, then swap — same versioned-index discipline as §5.
- Supabase specifics: enable **RLS** on the embeddings table from day one (it's exposed through the API by default), keep the service key server-side only, and remember Edge Functions are Deno — your Python backend still does the retrieval.

**Migration path that actually works:** start on pgvector while the corpus is small, keep retrieval behind the repository/factory interface, and move to Qdrant when recall or latency degrades. Because the interface is fixed, the swap is one factory, not a rewrite.

## 4. Retrieval
- **Hybrid always**: sparse (BM25) + dense, fused with **RRF**.
- Then **rerank** (Cohere / BGE cross-encoder) → **score threshold** → top-k to the model.
- Metadata filters for tenant, ACL, doc type, date — applied **in the vector query**, not after.
- Query rewriting / multi-query only if evals show it helps.
- Retrieval `k` capped (cost + context).
- Return citations (source ID, page) with every grounded answer.
- "No relevant results" → say so; never answer from prior knowledge in grounded mode.

## 5. Index lifecycle
- **Versioned collections + alias**: re-embed into `docs_v2`, validate with evals, switch alias; old version kept for rollback.
- Embedding model + version stored in collection metadata; never mix embedders in one collection.
- Deletions propagate from source of truth (tombstones / sync job).

## 6. Evaluation (part of testing)
- Golden set: 20–50 real queries with expected sources (grow it from production failures).
- Retrieval metrics: recall@k, MRR / nDCG — reported **per language** when the corpus is multilingual; a good average can hide a broken Arabic slice.
- Answer metrics: faithfulness/groundedness, answer relevance, citation correctness (LLM-as-judge with a rubric).
- Run on every change to: prompt, model, chunking, embedder, reranker, retrieval params.
- Store eval results with the change (PR comment or tracing tool experiments).

## 7. Caching
- Keyword cache (Redis) for identical requests; semantic cache only if measured (threshold + eviction).
- Provider prompt caching for long static system prompts.
- Never cache per-user/private results under a shared key.
