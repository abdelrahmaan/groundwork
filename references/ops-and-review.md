# Ops, Tooling & Code Review Standard

## 1. uv
- `pyproject.toml` + committed `uv.lock`; dev tools in a dependency group (`ruff`, `pytest`, type checker).
- Commands: `uv add`, `uv sync`, `uv run <cmd>`, `uv lock --upgrade-package <pkg>` for controlled upgrades.
- CI and Docker install with a **locked** sync (fails if lock is out of date).

## 2. Makefile — the single entry point

**Why:** every project exposes the same verbs, so neither you nor an AI agent has to remember per-project commands. `make help` is the project's real README.

Required targets (same names in every repo, backend/web/mobile):
`help, install, dev, run, fmt, lint, type, test, eval, load, gen-clients, migrate, upgrade, downgrade, docker-dev, docker-prod, logs, clean, check` (= fmt + lint + type + test).
- Self-documenting help (`##` comments parsed into `make help`).
- `.PHONY` on every target; fail fast (`set -euo pipefail` in multi-line recipes).
- Targets wrap `uv run …` / `docker compose …` — never duplicate logic between Makefile and CI; **CI calls the same make targets**.
- A template lives in `assets/templates/Makefile`.

## 3. Docker (dev + prod)
- Multi-stage build; slim Python base; non-root user.
- uv best practices: copy uv binary from the official image; install **dependencies first** (`--no-install-project`) in a cached layer, then copy code and sync the project; `UV_COMPILE_BYTECODE=1`; `UV_LINK_MODE=copy`; cache mount for `/root/.cache/uv`; `UV_NO_DEV=1` in prod.
- Exec-form `CMD` running `fastapi run` (one process per container under an orchestrator).
- `.dockerignore` (`.venv`, `.env`, data, tests if not needed).
- **Two modes, one file set:**
  - `compose.yaml` — shared services (api, worker, postgres/mongo, redis, qdrant) with healthchecks and named volumes.
  - `compose.override.yaml` — **dev**, auto-loaded: source bind-mount + `--reload`, dev ports exposed, debug logging, `target: dev` build stage.
  - `compose.prod.yaml` — **prod**, explicit merge: baked image, no mount, no reload, restart policy, resource limits, ports closed except the proxy.
- `make docker-dev` → `docker compose up -d`; `make docker-prod` → `docker compose -f compose.yaml -f compose.prod.yaml up -d --build`.
- Multi-stage Dockerfile with a `dev` stage (dev deps + reload) and a `prod` stage (no dev deps, non-root, read-only FS where possible).
- `depends_on: condition: service_healthy` so the API waits for DB/Redis; the app still retries on its own.
- Templates in `assets/templates/` (Dockerfile, compose.yaml, compose.override.yaml, compose.prod.yaml).

## 4. CI (GitHub Actions)
`make check` (format → lint → type → unit tests) → integration tests (service containers) → **OpenAPI snapshot diff** → **evals (`make eval`, when AI code/prompts change)** → `pip-audit` + SBOM → build image → deploy.
Load tests (`make load`) run on demand/pre-release against staging, not on every PR.
Pre-commit hooks mirror the fast parts (format, lint, type check).

## 5. Load testing (Locust)
See `fastapi.md` §16. Keep `load/locustfile.py` in the repo, run with `make load`, record p50/p95/p99 + TTFT + saturation point in `docs/` with the commit they belong to, and use the numbers to set pool sizes, replicas, rate limits and SLOs.

## 6. Observability — Prometheus + Grafana

**Three signals, three tools.** Logs say what happened, metrics say how much and how fast, traces say where the time went. Don't try to get all three from one of them.

**Logs** — structured JSON, request/trace ID on every line, no secrets or PII. stdout only in containers (the platform collects it); ship to **Loki** once you have more than one container to grep.

**Metrics — Prometheus**
- The app exposes `/metrics`; `prometheus-fastapi-instrumentator` gives you RED metrics (Rate, Errors, Duration) per route for free.
- Prometheus **scrapes** (pull), so the app just has to be reachable — no agent, no push.
- Custom metrics worth adding by hand (keep them few, they cost cardinality):
  - `llm_tokens_total{model,route,direction}` — counter, input/output tokens.
  - `llm_cost_usd_total{model}` — counter.
  - `llm_request_duration_seconds{model}` histogram + `llm_ttft_seconds` — time to first token is the streaming UX metric.
  - `retrieval_results_total{lang,hit}` and `rerank_duration_seconds` for RAG.
  - `job_duration_seconds{type,status}` and queue depth for workers.
- **Cardinality rule:** never put a user id, tenant id, request id, prompt, or document id in a label. That's what logs and traces are for. A label set should have tens of values, not millions.
- Histograms over averages; alert on p95/p99, never on the mean.

**Dashboards — Grafana**
- One datasource per signal: Prometheus (metrics), Loki (logs), Tempo/Jaeger (traces). Grafana correlates them by trace ID.
- Keep exactly three dashboards at first, and commit their JSON to the repo (`ops/grafana/`) so they're versioned, not clicked:
  1. **Service health** — request rate, error rate, p95 latency, saturation (CPU/memory/pool usage).
  2. **AI cost & quality** — tokens and cost per model and per day, TTFT, tool-call counts, retrieval hit rate by language.
  3. **Jobs & dependencies** — queue depth, job failures, DB/Redis/vector-store health.
- Provision datasources and dashboards as files, not by hand — a rebuilt Grafana must come back identical.

**Alerts — Alertmanager (or Grafana alerting)**
- Alert on **user-visible symptoms**, not causes: error rate, p95 latency, readiness failing, queue not draining, LLM spend over budget, certificate expiry.
- Every alert names the runbook that fixes it. An alert nobody acts on gets deleted, not muted.
- Solo-engineer reality: 5–7 alerts total, routed to one channel you actually read.

**Traces — OpenTelemetry** for infra spans (HTTP, DB, outbound), plus ONE LLM tracer (LangSmith or Langfuse) for agent spans. Don't conflate the two planes; link them by trace ID.

**When to install the stack:** not on day one. Logs + `/metrics` from the start; run Prometheus + Grafana when you have real traffic, a second instance, or someone asking "is it slow?". In development it's one compose profile:
```bash
docker compose --profile monitoring up -d   # prometheus + grafana
```
Managed alternatives that skip the ops work: Grafana Cloud, Azure Monitor, Datadog. Same metrics, someone else's uptime.

## 7. LiteLLM Proxy (optional gateway)
- Adopt when: multiple providers, per-team/tenant budgets and keys, central rate limiting, or routing to on-prem vLLM.
- App code still uses `init_chat_model` pointing at the proxy's OpenAI-compatible endpoint.
- Don't also use the LiteLLM SDK inside LangChain code (two abstractions for one job).
- Pin the proxy version; it's supply-chain critical (it sees every key and prompt).

## 8. vLLM — self-hosted models behind an OpenAI-shaped API

**Why it matters:** vLLM speaks the OpenAI HTTP API, so your code doesn't know whether it's talking to OpenAI, Azure OpenAI, LiteLLM, or your own GPU box. Switching is a `.env` change, not a code change — that is the whole point of routing every model through the factory.

**Endpoints you'll use** (all under `/v1`):
| Endpoint | Use |
|---|---|
| `/v1/chat/completions` | chat + tool calling + streaming — what `init_chat_model` calls |
| `/v1/completions` | raw completion (rarely needed) |
| `/v1/embeddings` | **embedding models** — serve BGE-M3 here and the embedder is on-prem too |
| `/v1/responses` | OpenAI Responses API shape |
| `/v1/audio/transcriptions`, `/v1/audio/translations` | speech-to-text models (relevant for Arabic ASR) |
| `/v1/models` | lists what's loaded — use it in the readiness check |

**Wiring it**
- One vLLM server per model. The LLM and the embedder are separate processes (separate GPUs or at least separate memory budgets).
- In the factory: provider = `openai`, `base_url` = the vLLM URL ending in `/v1`, `api_key` from settings, and the **model name must match the name vLLM serves** (set `--served-model-name` so your config uses a stable alias, not a HuggingFace path).
- Embeddings go through the same pattern: an OpenAI-compatible embeddings client pointed at the embedding server's `base_url`. BGE-M3 is supported for dense embeddings; its sparse/ColBERT outputs need model-specific handling — check the vLLM model page before relying on them for hybrid.
- Env: `LLM_BASE_URL`, `LLM_API_KEY`, `EMBEDDING_BASE_URL`, `EMBEDDING_API_KEY` — empty base URL means the provider's default endpoint.

**Security — read this twice**
- `--api-key` only authenticates `/v1`, `/v2`, and `/inference` paths. **Other endpoints on the same server are not authenticated** — notably `/invocations`, which exposes the same inference. The key alone is **not** protection.
- So: never expose vLLM directly. Put it on a private network, and front it with a reverse proxy (or LiteLLM Proxy) that only forwards the `/v1` paths you use and enforces auth, rate limits, and request size.

**Same API shape ≠ same behavior**
- Tool calling needs auto tool choice + the correct tool-call parser for the model family; quality varies a lot between open models. Run the eval set before committing.
- Structured output works via vLLM's structured-output support, but reliability depends on the model; keep the Pydantic validation + retry at your boundary regardless.
- Context length, chat template, and stop tokens are model-specific — a model that works on OpenAI's schema can still fail on formatting.
- Arabic quality is a model property, not a vLLM property — evaluate the specific open model on your Arabic golden set.

**Ops**
- Set max model length, GPU memory utilization, and max concurrent sequences deliberately; load-test with Locust (measure TTFT).
- vLLM exposes Prometheus metrics — add it as a scrape target (queue length, KV-cache usage, tokens/s are the ones to watch).
- Pin the vLLM version and the model revision; both change output.
- Pair with Langfuse (self-hosted) and self-hosted Qdrant/pgvector when data must stay in-house.

## 9. Context7 & docs
- Before writing code against any library: resolve and fetch its current docs via Context7.
- LangChain/LangGraph/Deep Agents: prefer the official LangChain docs MCP.
- If docs contradict this standard → docs win for *API details*; flag the conflict to Abdo and update the standard.

## 10. Code review checklist (Claude reviews every PR against this)
Fix-first: list blocking issues first, then suggestions, then teaching notes.

**Architecture**
- [ ] Layers respected: router thin → service → repository; no DB/LLM calls in routers.
- [ ] New external resources created via factories + lifespan, not per request.
- [ ] Minimal: nothing added that no decision requires.

**API**
- [ ] `response_model`, status codes, documented errors, Problem Details format.
- [ ] Input validated with constraints; pagination bounded.
- [ ] No blocking calls in `async def`; timeouts on outbound calls.

**AI**
- [ ] Model via `init_chat_model` + config; prompt in `prompts.py` (versioned).
- [ ] Tools narrow, typed, authz inside via `runtime.context`.
- [ ] Limits, retry/fallback, HITL on writes; structured output at boundaries.
- [ ] Streaming uses the typed event contract; ends with `done`/`error`.

**Security**
- [ ] Authz deny-by-default; ownership checks; no client-trusted IDs.
- [ ] No secrets in code/logs/prompts; PII handled.
- [ ] OWASP LLM controls relevant to the change.

**Quality**
- [ ] Tests added (red → green); dependency overrides, not patches.
- [ ] Evals run if prompt/model/retrieval changed.
- [ ] `tasks.md`, `README.md`, `CLAUDE.md`, `.env.example` updated as needed.
- [ ] Conventional commit message.
