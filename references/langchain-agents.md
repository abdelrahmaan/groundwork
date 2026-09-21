# LangChain Agents Standard

Version floors: `langchain` ≥ 1.3 (event streaming; `ToolErrorMiddleware` needs ≥ 1.3.14), `deepagents` ≥ 0.7 (planning is opt-in).
Implementation: fetch current docs via the LangChain docs MCP or Context7 — these APIs change monthly.

## Contents
1. The agent ladder
2. Models — `init_chat_model`
3. `create_agent` components
4. Tools
5. Runtime context & state
6. Structured output
7. Middleware — built-in
8. Middleware — custom (hooks, decorators, order, jumps)
9. Default production middleware stack
10. Streaming
11. Memory & persistence
12. Deep Agents — when and how
13. Context engineering
14. Evaluation (Ragas + LLM-as-judge)
15. MCP in production
16. Tracing
17. Anti-patterns

---

## 1. The agent ladder

Pick the **lowest rung** that solves the problem (each rung adds latency, cost, unpredictability):
1. No LLM (rules / search / SQL)
2. Single LLM call
3. Structured output (extraction, classification)
4. Fixed chain / RAG pipeline (deterministic steps)
5. `create_agent` + tools — the model must *choose* actions
6. `create_deep_agent` — long multi-step work, planning, subagents, big context
7. Multi-agent / custom LangGraph — only when 5–6 are proven insufficient

## 2. Models — `init_chat_model`

**Why:** Factory pattern for models — change provider/model via config, zero code changes.
- All models created in `factories/llm.py` via `init_chat_model("<provider>:<model>", ...)` from settings.
- Set explicitly: `temperature`, `max_tokens`, `timeout`, `max_retries`.
- Separate roles in config: `main_model`, `fast_model` (summaries, tool selection, guards), `fallback_model`.
- vLLM / LiteLLM Proxy / any OpenAI-compatible server → same factory: provider `openai`, `base_url` + key from settings, model name = the server's `--served-model-name`. Details and the security caveat in `ops-and-review.md` §8.
- Framework choice (LangChain vs LlamaIndex vs Haystack vs no framework) → `frameworks.md`.
- Model profiles (context size) matter for fraction-based summarization triggers — set a custom profile if the provider doesn't expose one.

## 3. `create_agent` components

- `model` (from factory), `tools`, `system_prompt` (from `ai/prompts.py`, versioned), `middleware`, `response_format`, `checkpointer`, `store`, `context_schema`, `name`.
- Build the agent **once** in lifespan via `factories/agent.py`; reuse per request (it's a compiled graph).
- Per-request data (user ID, tenant, roles, request ID) goes in `context`, not in the prompt text.
- `create_agent` returns a LangGraph graph → it can be a subgraph/node later.

## 4. Tools

- Tools are **narrow, typed, least-privilege** Python helpers; the LLM never writes raw queries.
- Precise docstring = the model-visible description; snake_case names; typed args with descriptions.
- Access state/context/store through the `runtime: ToolRuntime` parameter (injected, hidden from the model). `config` and `runtime` are reserved argument names.
- Enforce authorization **inside the tool** using `runtime.context` (tenant/user) — never trust IDs from the model.
- Return compact, structured results (IDs, titles, snippets) — not huge blobs; large results go to filesystem/offload.
- Tools > ~10? Use `LLMToolSelectorMiddleware` or provider tool search.
- MCP tools are fine — vet the server (supply chain) and scope its permissions.

## 5. Runtime context & state

- **Context** (`context_schema`): read-only, per invocation — user ID, tenant, roles, feature flags, request ID.
- **State**: the conversation (`messages`) + any custom fields declared via middleware `state_schema`.
- **Store**: long-term memory across threads.
- Rule: authz/identity data → context; working data → state; durable user memory → store.

## 6. Structured output

- `response_format=MySchema` → auto-picks `ProviderStrategy` (native) when supported, else `ToolStrategy`.
- JSON-schema dicts must be wrapped explicitly in a strategy.
- Use structured output at every boundary where code (not a human) consumes the result.

## 7. Middleware — built-in (provider-agnostic)

| Goal | Middleware | Note |
|---|---|---|
| Recover from tool exceptions | `ToolErrorMiddleware` | sanitized error to model; pair with retry |
| Retry flaky tools | `ToolRetryMiddleware` | backoff + jitter; `on_failure` |
| Retry flaky model calls | `ModelRetryMiddleware` | exponential backoff |
| Provider outage | `ModelFallbackMiddleware` | ordered fallback models |
| Cost / loop cap | `ModelCallLimitMiddleware` | `run_limit`, `thread_limit` (needs checkpointer) |
| Tool cap | `ToolCallLimitMiddleware` | global or per-tool |
| Long chats | `SummarizationMiddleware` | trigger/keep by tokens, messages, fraction |
| Trim old tool outputs | `ContextEditingMiddleware` + `ClearToolUsesEdit` | cheaper than summarizing |
| Approve writes | `HumanInTheLoopMiddleware` | needs checkpointer; approve/edit/reject |
| PII | `PIIMiddleware` | block/redact/mask/hash; input, output, tool results; custom detectors |
| Planning | `TodoListMiddleware` | `write_todos` tool |
| Many tools | `LLMToolSelectorMiddleware`, `ProviderToolSearchMiddleware` | |
| Subagents / filesystem | `SubAgentMiddleware`, `FilesystemMiddleware` | from `deepagents` |
| Shell / file search | `ShellToolMiddleware`, `FilesystemFileSearchMiddleware` | sandbox policy required |
| Tests | `LLMToolEmulator` | fake tool outputs |
| Provider-specific | Anthropic prompt caching, Bedrock caching, OpenAI moderation | |

## 8. Middleware — custom

**Hooks**
- Node-style (sequential; logging, validation, state updates): `before_agent` (once), `before_model` (each call), `after_model` (each response), `after_agent` (once).
- Wrap-style (control flow; retry, cache, fallback, transform): `wrap_model_call`, `wrap_tool_call` — the handler can be called 0 times (short-circuit), once, or many (retry).

**Two ways to write them**
- Decorators (single hook): `@before_agent`, `@before_model`, `@after_model`, `@after_agent`, `@wrap_model_call`, `@wrap_tool_call`, `@dynamic_prompt`.
- Class (`AgentMiddleware` subclass) for multiple hooks, config, or custom state.
- Extend state with `state_schema`; read per-run data via `runtime.context`.

**Execution order** for `middleware=[m1, m2, m3]`
- `before_*`: m1 → m2 → m3
- `wrap_*`: nested — m1 wraps m2 wraps m3 wraps the call
- `after_*`: m3 → m2 → m1 (reverse)

**Early exit (jumps)**: return `{"jump_to": "end" | "tools" | "model"}`; declare allowed targets with `can_jump_to` (decorator arg or `@hook_config`).

**Official best practices**: one job per middleware; don't let middleware errors crash the agent; node-style for sequential logic, wrap-style for control flow; document custom state; unit-test middleware alone; place critical middleware first; prefer built-ins.

## 9. Default production middleware stack (order matters)

1. Input guard (deterministic: length, banned topics, injection patterns) — `before_agent`
2. `PIIMiddleware` (input; output/tool results if sensitive domain)
3. `ModelCallLimitMiddleware` + `ToolCallLimitMiddleware`
4. `ModelFallbackMiddleware` → `ModelRetryMiddleware`
5. `ToolRetryMiddleware` (inner, `on_failure="error"`) + `ToolErrorMiddleware`
6. `SummarizationMiddleware` / `ContextEditingMiddleware` — only for long conversations
7. `HumanInTheLoopMiddleware` — on any write/destructive tool
8. Output guard (model-based, last) — `after_agent`

Verify the exact composition semantics in the docs when combining retry + fallback + error middleware.

## 10. Streaming

- New apps: **event streaming** — `agent.stream_events(..., version="v3")` / async equivalent — typed projections (messages, tool calls, state, subagents, custom) consumed independently.
- Alternative: `astream(stream_mode=[...], version="v2")` — unified `StreamPart {type, ns, data}`; `"messages"` for tokens, `"updates"` for steps, `"custom"` for progress events from tools.
- Map LangChain events → our own typed SSE events (see `api-contract.md`); never leak raw internal objects to the client.
- Stream reasoning tokens only if the product wants them; filter otherwise.
- Agent used as a subgraph: enable subgraph streaming or you won't see inner tokens.
- Stop the run on client disconnect.

## 11. Memory & persistence

- Short-term (per thread): `checkpointer` + `thread_id` in config. **Prod = Postgres (or Cosmos DB) checkpointer**; `InMemorySaver` only for dev/tests.
- HITL and thread-level limits require a checkpointer.
- Long-term (cross-thread): `store` (and `/memories/` routes in Deep Agents).
- `thread_id` belongs to the user — validate ownership before resuming a thread.

## 12. Deep Agents — when and how

Use `create_deep_agent` when the task is long and multi-step: research, due-diligence-style analysis over many documents, report generation, code/file work.
- It is the same tool-calling loop plus: virtual filesystem (pluggable backends + permissions), subagents via `task` tool (isolated context, single final report), summarization/offloading, skills (progressive disclosure), `AGENTS.md` memory, HITL via `interrupt_on`, provider prompt caching.
- Planning (`TodoListMiddleware`) is opt-in since 0.7.
- Restrict the filesystem (read-only allowlist, deny `.env`/secrets); sandbox any code execution.
- Default stays `create_agent`; escalate only with a reason.

## 13. Context engineering

**The first lever, before more agents.** An agent's quality is mostly a function of what is in its context window at each step.

- Curate, don't dump: retrieve → filter → compress → order. Put stable content (system prompt, schemas) first so provider prompt caching can hit it.
- **Dynamic prompts** (`@dynamic_prompt` middleware): inject only the tenant/user/task facts this run needs; keep the static core cache-friendly.
- **Compression**: `SummarizationMiddleware` (trigger by tokens/messages/fraction) and `ContextEditingMiddleware` + `ClearToolUsesEdit` (drop old tool outputs, keep the last N) — cheaper than summarizing.
- **Offloading**: write large tool results to the filesystem/store and pass a reference + short summary instead of the blob (Deep Agents' filesystem does this).
- **Tool results are context too**: return compact structured results (IDs, titles, snippets), not raw documents.
- **Isolation**: give a subagent its own window only when the subtask is genuinely independent; otherwise share full traces, not summaries — context loss between agents is the main multi-agent failure mode.
- Measure it: track tokens per run and per step; a rising token curve with flat quality means the context is dirty, not the model.

## 14. Evaluation (Ragas + LLM-as-judge)

**Rule: no prompt, model, retrieval, chunking or reranker change ships without an eval run.**

- **Golden set** (20–50 real queries with expected sources) committed to the repo; grow it from production failures — every bug becomes a case.
- **Ragas** is the default RAG eval library: faithfulness, answer relevancy, context precision/recall. Run it in `make eval`, gate CI on thresholds (a drop fails the build).
- Retrieval metrics separately: recall@k, MRR/nDCG — they tell you whether the problem is retrieval or generation.
- **LLM-as-judge** for what metrics can't score (tone, completeness, Arabic fluency): a strong model + an explicit rubric + few-shot anchors.
  - Known biases: **position bias** (order of candidates), **verbosity bias** (longer looks better), **self-preference** (a model prefers its own style). Mitigate: randomize order, cap length in the rubric, use a different model family as judge, and calibrate against ~20 human-labelled examples before trusting scores.
  - Judges drift when the judge model is upgraded — pin the judge model and version the rubric.
- Track results over time in the tracing tool (LangSmith/Langfuse experiments) with the commit SHA.
- Prompts live in a registry/module with a version string; the eval result is attached to that version.

## 15. MCP in production

- Treat every MCP server as an OAuth resource server: PKCE, per-client consent, strict redirect URIs, **audience-bound tokens** (never pass a token through to another service).
- **Tool poisoning** is the top novel risk: malicious instructions hidden in tool descriptions or outputs (structurally the same as indirect prompt injection). Pin and review tool descriptions; alert on changes between sessions; show full tool calls to the user for anything sensitive.
- Watch the "lethal trifecta": untrusted input + sensitive data access + ability to act. Break at least one leg for risky servers (read-only scopes, approval on writes, isolated credentials).
- Vet third-party servers like dependencies: pin versions, review source, least-privilege scopes, TLS/mTLS, and audit every invocation.

## 16. Tracing

- Pick one: **LangSmith** (default) or **Langfuse** (self-host / data residency). Configure via env; tag runs with user, tenant, request ID, prompt version, model.
- Track tokens + cost per request/user/route; alert on spend.
- OTel covers infra spans separately.

## 17. Anti-patterns

- `AgentExecutor` / `initialize_agent`; `max_iterations` as the loop cap.
- Hardcoded model strings; one model client per request.
- Agent for a problem a fixed chain solves.
- Secrets or authz rules in the system prompt.
- `InMemorySaver` in production.
- LLM-generated queries executed directly.
- Mixing LangChain with another agent framework in the same service.
- Jumping to multi-agent before context engineering: only add a supervisor + subagents when a single agent measurably fails on **parallel, read-heavy** work, and the ~15× token cost is acceptable. Tasks needing shared state or tight dependencies stay single-agent.
- Shipping a prompt change with no eval run.
