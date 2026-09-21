# FastAPI Standard

Version floors: FastAPI ≥ 0.135 (native SSE), ≥ 0.121 (`Depends(scope=...)`), Pydantic v2, pydantic-settings.
Implementation details: fetch the current FastAPI docs via Context7 before coding.

## Contents
1. App factory & lifespan
2. Configuration & secrets (.env)
3. Dependency injection
4. Routers & endpoints
5. API versioning & deprecation
6. Database & migrations
7. Caching with Redis
8. Rate limiting
9. Async vs sync
10. Middleware (HTTP)
11. Errors
12. Background jobs & queues
13. Streaming (SSE / JSON Lines)
14. OpenAPI & docs
15. Testing
16. Load testing (Locust)
17. Running & deployment

---

## 1. App factory & lifespan

**Why:** one place owns every resource's life (open → use → close). Clean startup, clean shutdown, testable.

- Build the app in a `create_app()` factory (Factory pattern): settings in, configured app out. Tests create their own app.
- Use the **`lifespan` async context manager** for all startup/shutdown.
  - `@app.on_event("startup"/"shutdown")` is **deprecated**. If `lifespan` is set, startup/shutdown events are not called at all — it's one or the other.
  - Lifespan runs **only for the main app**, not mounted sub-apps.
- **Startup order** (before `yield`):
  1. Logging setup.
  2. DB client / pools → `validate_connection()` (log ERROR on missing stores, don't crash unless critical).
  3. Vector store client, embedder, reranker (load local models once).
  4. `init_chat_model` instances + agent built once via factories.
  5. Checkpointer setup (Postgres).
  6. **Warm-up**: one cheap embed + one cheap model call so the first user doesn't pay cold start.
  7. Mark readiness = true.
- **Expose resources** by yielding a state dict from lifespan (available as `request.state.<name>`) or via typed getter functions — never module globals scattered across files.
- **Shutdown order** (after `yield`): reverse of startup — stop accepting work, flush tracing/telemetry exporters, close checkpointer, vector store, DB pools, HTTP clients.
- Share **one `httpx.AsyncClient`** created in lifespan (connection pooling) — never create a client per request.
- Graceful shutdown: in-flight streams get a final `error`/`done` event; long jobs belong in a queue, not the web process.

## 2. Configuration & secrets (.env)

- One `Settings(BaseSettings)` singleton; `.env` auto-load; `env` / `is_dev` switch; typed getters for env-dependent values.
- For bigger apps split settings per domain (`AuthSettings`, `AISettings`, `RedisSettings`) and compose them.
- **Secrets live only in `.env`** — never in code, logs, prompts, or git. `.env` is gitignored; **`.env.example` is committed and always current** (every new variable lands there in the same commit).
- Secret fields typed `SecretStr`; `settings.model_dump()` must never be logged wholesale.
- `docker compose` reads `.env` via `env_file:`; never bake secrets into images.
- Production: keep the same variable names but inject from **Azure Key Vault / Doppler / SOPS / platform secret store** — the app code doesn't change.
- Fail fast: the app refuses to start if a required secret is missing (Pydantic validation does this for free).
- Model slugs, temperatures, limits, feature flags (`chatbot_enabled`) are settings, not constants.

## 3. Dependency injection

**Why:** routes stay thin, logic is reusable, tests override dependencies instead of patching.

- Use `Depends` for per-request concerns: current user, pagination, DB session/repo, quota check, tenant resolution.
- Use `Annotated[...]` type aliases for common deps (`CurrentUser`, `DbSession`, `Pagination`) — less repetition.
- **Dependencies can validate**: e.g. `valid_resource_id` loads the object or raises 404 — reuse across routes.
- **Chain dependencies**; FastAPI **caches a dependency within one request**, so chaining is cheap.
- Prefer `async` dependencies (sync ones run in the threadpool).
- **`yield` dependencies** for resources with cleanup (DB session). Since 0.121, `Depends(scope="function")` runs cleanup right after the route returns; the default `scope="request"` runs it after the response is sent — important for streaming responses that still need the session.
- Router-level dependencies (`APIRouter(dependencies=[...])`) for auth on a whole group.

## 4. Routers & endpoints

- One router per resource; versioned prefixes (`/api/v1`). Tags for docs grouping.
- Every endpoint: `response_model`, `status_code`, `summary`, and `responses={...}` for documented errors.
- Separate schemas: `ResourceCreate`, `ResourceUpdate`, `ResourceRead` — never expose DB models directly.
- A shared custom Pydantic base model (serialization config, datetime format) for all schemas.
- Lists → `Paginated[T] {items, total}` with validated `skip/limit` (`ge`, `le`).
- Validate inputs with `Query/Path/Body` constraints and Pydantic validators — invalid input never reaches services.
- Response serialization: FastAPI validates against `response_model` again — keep response models lean; return model objects or dicts consistently.
- REST conventions: nouns, plural, correct verbs and status codes (201 create, 204 delete, 409 conflict, 422 validation).
- Idempotency keys on retry-able POSTs.
- **Health**: `/health/live` (process up, no deps) and `/health/ready` (DB, vector store, model reachable + warm-up done).

## 5. API versioning & deprecation

**Why:** mobile apps can't be force-updated; a contract change without a version breaks installed clients.

- Version in the URL prefix: `/api/v1/...`. One `APIRouter` per version; `app.include_router(v1_router, prefix="/api/v1")`.
- **Additive changes** (new optional field, new endpoint) don't need a new version. **Breaking changes** (removed/renamed field, changed type, changed semantics) do.
- Run v1 and v2 side by side; share services, duplicate only the schema/router layer.
- Deprecation flow: mark the route `deprecated=True` (shows in OpenAPI) → return `Deprecation: true` and `Sunset: <HTTP-date>` headers → announce in the changelog → remove after the sunset date (minimum one mobile release cycle, typically 3–6 months).
- Log usage of deprecated routes with the client version so you know who still calls them.
- Never break the contract silently: the OpenAPI snapshot diff in CI is the gate.

## 6. Database & migrations

**Default: PostgreSQL + SQLAlchemy 2.0 (async) + Alembic.** It's the most robust, best-documented, least surprising option.

- **SQLAlchemy 2.0 async**: `create_async_engine` + `async_sessionmaker`; session per request via a `yield` dependency; `Mapped[...]` typed models.
- **SQLModel** (same author as FastAPI) is a fine choice for simpler CRUD apps — it's SQLAlchemy underneath, models double as Pydantic schemas. Trade-off: less control on complex queries/relationships. Migrations still use Alembic.
- **MongoDB + Motor** (async driver) when the data is genuinely document-shaped; **Beanie** on top if you want Pydantic-style ODM. No migrations — but you still need **explicit schema versioning** (`schema_version` field + a backfill script) and indexes created at startup.
- **Repository layer**: services call repositories; repositories own queries. Routers never touch a session directly.
- **Pooling**: size the pool to worker count (`pool_size`, `max_overflow`, `pool_pre_ping=True`, `pool_recycle`). Pooler (PgBouncer) in transaction mode → disable prepared statement caching.
- **N+1 prevention**: eager loading (`selectinload`/`joinedload`); log slow queries in dev.
- **Alembic**: autogenerate then *read the diff by hand*; one migration per PR; never edit a merged migration.
- **Zero-downtime migrations** (expand → migrate → contract): add nullable column → backfill in batches → start writing both → switch reads → drop the old column in a later release. Never rename/drop in the same deploy as the code change.
- Naming conventions configured once on the metadata (so constraint names are deterministic across migrations).
- Multi-tenancy: shared schema + `tenant_id` + **Row-Level Security** by default; schema-per-tenant only when compliance demands it.

## 7. Caching with Redis

**Why:** the cheapest latency and cost win; also the shared state layer once you run more than one instance.

- One async Redis client created in lifespan, injected via dependency.
- What to cache: expensive + repeated + tolerant of staleness (reference data, aggregate dashboards, embeddings of repeated queries, LLM responses to identical prompts).
- Key design: `app:v1:<entity>:<id>:<variant>`; include a version segment so a deploy can invalidate wholesale.
- Always set a TTL. Prefer short TTLs + explicit invalidation on write over long TTLs.
- **Never cache per-user or tenant-scoped data under a shared key** — include the tenant/user in the key, or don't cache.
- Guard against stampedes (lock or jittered TTL) on hot keys.
- Redis is also used for: rate limiting counters, job queue (ARQ), idempotency keys, SSE resume buffers, session/refresh-token denylist.
- HTTP-level caching: `ETag` + `If-None-Match` and `Cache-Control` on cacheable GETs — free bandwidth savings for web/mobile clients.
- Cache is an optimization, never a correctness requirement: the app must work with Redis empty (and degrade, not crash, if Redis is down).

## 8. Rate limiting

**Why:** protects cost (LLM routes), protects auth from brute force, and keeps one tenant from starving others.

- Token bucket / sliding window in **Redis** (shared across replicas — in-process counters are wrong the moment you scale to 2 instances). SlowAPI or a small custom dependency.
- Key by **user/API key first**, IP as fallback (IP alone punishes shared networks/NAT).
- Different budgets per route class: auth (strict), LLM/agent (strict, also token-budget), read endpoints (loose), webhooks (per-sender).
- Return **429** with `Retry-After`; use the RFC 9457 body with `code: "rate_limited"`.
- Per-user **quotas** (daily tokens/requests) live next to rate limits and are enforced as a dependency before the agent runs.
- Also bound: request body size, upload size, pagination `limit`, retrieval `k`, and concurrency to expensive backends.

## 9. Async vs sync

**Why:** one blocking call in an `async def` freezes every request on that worker.

- `async def` → only non-blocking I/O inside (async DB drivers, `httpx.AsyncClient`, async LLM calls).
- Sync-only SDK? Either make the route `def` (FastAPI runs it in a threadpool) or wrap with `run_in_threadpool` / `anyio.to_thread`.
- CPU-heavy work (parsing big PDFs, local model inference, embeddings on CPU) → worker process / queue, not threads (GIL).
- Timeouts on every outbound call (DB, HTTP, LLM, tools).
- Bound concurrency to expensive backends (semaphore) to protect rate limits.

## 10. Middleware (HTTP)

**Why:** cross-cutting concerns applied once for every request. Per-route concerns → dependencies instead.

- Order rule: with `app.add_middleware(...)`, the **last one added is the outermost** (runs first on the request, last on the response). So add them in *reverse* of the order you want them to run, and write the intended order as a comment in `main.py`.
  (The old template said "add first → runs outermost" — that is backwards.)
  Target order (outer → inner): request-ID/correlation → request logging/timing → CORS → security headers → GZip (not on SSE) → rate limiting (or as dependency).
- CORS: explicit origins from settings; never `*` with credentials in prod.
- `TrustedHostMiddleware` in prod; `--proxy-headers` when behind a reverse proxy/load balancer.
- Request-ID: accept incoming `X-Request-ID` or generate one; put it in logs, traces, and error responses.
- Prefer pure ASGI middleware for anything touching streaming responses (`BaseHTTPMiddleware` can interfere with streaming/background tasks).
- Rate limiting: SlowAPI (Redis backend when multiple replicas) — tighter on auth + LLM routes.
- LangChain agent middleware is a different thing — see `langchain-agents.md`.

## 11. Errors

- Domain exceptions in services (`NotFound`, `Conflict`, `QuotaExceeded`) — services never raise `HTTPException`.
- Global exception handlers map domain errors → HTTP responses in **RFC 9457 Problem Details** format (see `api-contract.md`).
- Catch-all handler: log full error with request ID; return generic 500 — no stack traces to clients.
- Override the validation-error handler to return the same Problem Details shape.
- Graceful parsing when reading DB rows: skip malformed rows with a warning, don't fail the whole list.

## 12. Background jobs & queues

| `BackgroundTasks` | Queue (ARQ / Celery / RQ) |
|---|---|
| < ~1s, in-process | seconds → minutes |
| losing it is acceptable | needs retries, dead-letter, visibility |
| e.g. audit log, cache invalidation | ingestion, embeddings, reports, long agent runs |

Rule of thumb: if you'd page someone when the task is lost, it doesn't belong in `BackgroundTasks`.

**Queue choice**
- **ARQ** — async-native (asyncio, Redis), tiny surface, shares the Redis you already run. Default for an async FastAPI app: ingestion, embeddings, report generation, long agent runs.
- **Celery** — mature, huge ecosystem, beat scheduler, complex routing/retry/dead-letter, Flower UI. Choose when you need scheduling, fan-out, or already run it. Costs a worker process model that is sync-first.
- **Dramatiq** — middle ground; fine, but pick one of the two above unless you have a reason.

**Job standard (whatever the queue)**
- API returns **202 Accepted** + `{job_id, status_url}`; the client polls the status endpoint or subscribes to SSE progress.
- Job records live in the DB (`id, type, status, progress, result_ref, error, created_at, finished_at`) — the queue is transport, not the source of truth.
- Jobs are **idempotent** (safe to re-run) with bounded retries + exponential backoff + a dead-letter path.
- Long AI jobs stream progress via a Redis pub/sub channel the SSE endpoint reads.
- Workers get their own container, their own concurrency setting, and the same settings object as the API.
- Schedule recurring work (re-index, cleanup, eval runs) with ARQ cron or Celery beat — not with `sleep` loops.

## 13. Streaming

- **Use FastAPI native SSE** (`fastapi.sse.EventSourceResponse` + `ServerSentEvent`, FastAPI ≥ 0.135) instead of hand-rolled `StreamingResponse`. It already sends a keep-alive ping every 15s, sets `Cache-Control: no-cache`, and `X-Accel-Buffering: no`.
- Declare the yielded type (e.g. `AsyncIterable[StreamEvent]`) so Pydantic validates, documents, and serializes each event.
- Use `ServerSentEvent(event=..., id=..., data=...)` for named events and IDs; `raw_data` only for sentinels.
- SSE works with **POST** (chat requests carry a body).
- Support resume via the `Last-Event-ID` header when it's worth it.
- Detect client disconnect → stop the agent run (don't burn tokens for nobody).
- Machine-to-machine streams: JSON Lines is a simpler alternative.
- Event schema: see `api-contract.md`.

## 14. OpenAPI & docs

- Hide `/docs` and `openapi.json` in prod unless the API is public (enable per environment).
- Good metadata: title, version, descriptions, tags, examples in schemas.
- OpenAPI is the contract — the frontend generates its typed client from it.
- Stable `operationId`s (custom `generate_unique_id_function`) so generated client method names don't churn.

## 15. Testing

- `pytest` + `pytest-asyncio` + `httpx.AsyncClient(transport=ASGITransport(app))` from day 0.
- Tests build the app via `create_app()` with test settings.
- **Override dependencies** (`app.dependency_overrides`) instead of patching internals.
- Unit tests mock the data layer + LLM (fake chat model / `LLMToolEmulator` for agents).
- Integration tests run real DB/vector store containers in CI.
- Test the lifespan too (startup succeeds with mocked deps; shutdown closes resources).
- Contract test: snapshot `openapi.json` so breaking API changes are visible in PRs; **Schemathesis** property-tests the API against its own schema.

## 16. Load testing (Locust)

**Why:** you cannot set rate limits, pool sizes, worker counts, or an SLO without numbers.

- **Locust** (Python, familiar syntax, distributed mode, web UI) lives in `load/locustfile.py` and is run with `make load`.
- Model real user journeys (`HttpUser` tasks with realistic weights and think time), not a single hot endpoint.
- Always include the expensive paths: search/RAG, the streaming chat endpoint (measure **TTFT**, not just total time), and one write path.
- Measure p50/p95/p99, error rate, and saturation point; record the numbers in `docs/` with the commit they belong to.
- Run against a staging environment with production-like data volume — never against prod, never against an empty DB.
- Use the results to set: pool sizes, worker/replica count, rate limits, timeouts, and the SLO.
- Re-run before launch and after any change to model, retrieval, or DB layer.

## 17. Running & deployment

- Dev: `fastapi dev`. Prod: `fastapi run` (Uvicorn) in exec-form `CMD`.
- In Kubernetes/Container Apps: **one Uvicorn process per container**, scale with replicas (no `--workers` inside the container). Single VM without orchestrator: `--workers N`.
- `--proxy-headers` behind TLS-terminating proxy.
- Graceful shutdown timeout ≥ longest expected stream.
- Liveness/readiness probes wired to `/health/live` and `/health/ready`.
