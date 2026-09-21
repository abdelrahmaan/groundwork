# Choosing the AI Framework

Verified 2026-09-20 (PyPI: `langchain` 1.4.x, `llama-index-core` 0.14.x, `haystack-ai` 3.1.x). Re-check before a new project.

## 1. The honest starting point

A framework is a bet on someone else's abstractions and release cadence. It earns its place where
the problem is genuinely hard and generic — **agent runtime** (tool loop, state, checkpointing,
human-in-the-loop, streaming) — and costs you where the problem is specific to you — **retrieval**
(your chunking, your hybrid fusion, your Arabic normalization, your filters).

So the kit's position is split on purpose:
- **Agent layer → a framework** (LangChain `create_agent` on LangGraph).
- **Retrieval layer → your own code** against the vector store client (Qdrant / pgvector / Azure AI Search), behind a repository + factory. ~150 lines you fully understand beat a wrapper you debug through.

## 2. The options, fairly

### LangChain v1 (+ LangGraph underneath) — **kit default for the agent layer**
**Good**
- `create_agent` + middleware is a clean, composable agent runtime: retries, fallbacks, call limits, PII, HITL, summarization — built in.
- LangGraph gives real durability: checkpointers, interrupts, resumable threads, subgraphs. Deep Agents builds on the same pieces.
- Provider-agnostic models via `init_chat_model`; works with any OpenAI-compatible server (vLLM, LiteLLM).
- Largest ecosystem, best AI-assistant coverage, LangSmith integration.

**Bad — don't pretend otherwise**
- **Churn.** APIs move fast: `max_iterations` gave way to call-limit middleware, streaming moved to `stream_events(version="v3")`, error middleware needs a specific minor version. Pin versions and read the docs every time.
- Abstraction depth: when something breaks, the stack trace goes through several layers you didn't write.
- Its retrieval/document-loader layer is broad but shallow; for serious RAG you'll own that part anyway.
- Docs and examples on the internet are full of the pre-v1 API — a trap for both humans and coding agents.

### LlamaIndex
**Good**
- Retrieval-first: ingestion pipelines, node parsers, many index types, advanced retrieval strategies (sentence-window, auto-merging, recursive) out of the box.
- Strong document handling; LlamaParse is genuinely good at hard PDFs and tables.
- Event-driven `Workflows` for agent orchestration.

**Bad**
- **Strategic risk:** the company states its primary focus has shifted to LlamaParse (a commercial platform); the OSS framework remains available but is no longer the main product. Weigh that for anything you must maintain for years.
- LlamaParse is a cloud service — a problem for data-residency / on-prem projects.
- The agent runtime is less mature than LangGraph's for durable, interruptible, human-in-the-loop flows.
- High-level abstractions hide the retrieval details you most need to tune (especially for Arabic).

### Haystack (deepset)
**Good:** explicit pipeline graphs, stable and production-minded, strong for search-heavy RAG teams; readable.
**Bad:** smaller ecosystem, fewer agent features, fewer community examples.

### Pydantic AI
**Good:** small, strictly typed, pleasant; great for a structured-output service or a simple tool-using agent.
**Bad:** no LangGraph-class durability/HITL/checkpointing; you build more yourself.

### DSPy
**Good:** a different paradigm — optimizes prompts/pipelines against a metric instead of hand-writing prompts.
**Bad:** not an app framework; use it *inside* a component when you have a metric and data, not as the backbone.

### No framework (provider SDK + your code)
**Good:** fewest moving parts, zero churn, total control. Right for agent-ladder rungs 1–4 (single call, structured output, fixed RAG chain).
**Bad:** once you need tool loops with state, retries, interrupts, and resumable threads, you'll rebuild half of LangGraph — badly.

## 3. Recommendation

| Situation | Choose |
|---|---|
| Single LLM call / structured output / fixed RAG chain | **No framework** for the flow; `init_chat_model` is fine for provider-switching |
| Tool-using agent, HITL, streaming, resumable conversations | **LangChain `create_agent`** (LangGraph underneath) |
| Long multi-step research / document-heavy analysis | **Deep Agents** (same stack) |
| Hard documents (scans, complex tables) and cloud is allowed | LlamaParse (or Azure Document Intelligence) **as a parsing step only** |
| Search-centric team that values explicit pipelines and stability | Haystack |
| Small typed service with no durability needs | Pydantic AI |

**Rules**
- **One agent runtime per project.** A retrieval or parsing *library* from another ecosystem is allowed if it's contained behind your repository/factory interface — two agent runtimes are not.
- Retrieval is **your code**: hybrid query, RRF, rerank, filters, Arabic normalization. Frameworks call into it as a tool; they don't own it.
- Pin versions, keep the framework behind factories, and never let framework types leak into your API schemas — so switching later is a contained change, not a rewrite.

## 4. Where a framework choice is actually wrong

- Picking LlamaIndex *only* because the project "is RAG" — you'll still need an agent runtime, and you'll own the tricky retrieval parts anyway.
- Picking LangChain for a single summarization call — it's overhead with no payoff.
- Running LangChain and LlamaIndex agents side by side "to use the best of both" — two mental models, two tracing setups, two upgrade treadmills.
