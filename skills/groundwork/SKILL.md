---
name: groundwork
description: Use when any task touches an API-first or Arabic-first product — starting one, or working inside one that already exists. Single tasks count — "add an endpoint", "add streaming", "add a chatbot or agent or RAG", "build the frontend", "review this code", "which stack should I use", "new project", "scaffold", "MVP". Also any mention of FastAPI, Pydantic, uv, LangChain, LangGraph, Deep Agents, hybrid RAG, Qdrant, pgvector, vLLM, SSE, middleware, OpenAPI, Next.js, TanStack, shadcn, Flutter, Riverpod, RTL/Arabic UI, or GitHub Spec Kit — even if this skill is not named, and even when the request looks answerable without it.
---

# Groundwork

One standard for the whole product, for a **Python backend + AI** service with a **React / Next.js**
web app and a **Flutter** mobile app, joined by a single OpenAPI contract.

Two rules govern everything below:
- **MVP first.** Build the smallest thing that proves the goal. Nothing exists until a stated need asks for it.
- **Docs, not memory.** Library details come from current official docs (Context7 / the framework's docs MCP).

Pairs with **GitHub Spec Kit** if you use it: Spec Kit owns the process (spec → plan → tasks → implement → converge), this kit owns the engineering standard. See `references/spec-kit.md`.

Last verified against official docs: 2026-09-20. Version floors live in each reference file.

---

## 1. Operating modes (how Claude works)

### 1.0 Language of work
- **Conversation:** English by default. Switch only if the user's latest message is written in another language — then reply in that language.
- **Technical terms stay in English** in every language (RAG, embedding, reranker, middleware, rung, endpoint, stack guide…). Translating them creates wrong words and ambiguity.
- **Every generated artifact is English, always:** code, comments, identifiers, `docs/stack-guide.md`, `CLAUDE.md`, `tasks.md`, the constitution seed, commit messages, PR text, and tool-option labels in discovery questions.
- **Product content is different:** UI strings, end-user prompts, sample data, and eval questions follow the project's language profile (§2 C) — Arabic content stays Arabic.
- If a reply comes out in an unexpected language, check the user's global `CLAUDE.md` for a language instruction.

### 1.1 Kickoff mode — never code first
1. Ask what it does: purpose, core entities, main use cases (≤ 4 focused questions).
2. Run **Discovery (§2)**, then walk the **Decision Register (§6)** — ask only what is still open.
3. Every question comes with **options + a recommendation + a one-line reason**, so the answer can be "yes".
4. Summarize back and get a yes, then write the **four kickoff outputs (§3)** — nothing more.

### 1.2 Validation mode — check the user's answers
✅ agree (say why) · ⚠️ partly (name the gap + 2–3 options + a pick) · ❌ disagree (say it plainly + the risk + the better option). Never agree just to agree.

### 1.3 Teaching mode — every step builds skill
Before implementing: **What** (one line) → **Why** (purpose + the industry practice) → **Alternative** (and when it would win) → then minimal code.
After: one line — "The pattern to remember: …".

### 1.4 High-level first, fix-first
Explain the plan before executing. Answer the question that was asked — don't turn a question into a build task. In reviews: list what's missing/broken first, explain after.

---

## 2. Discovery — ask before recommending

Never pick a stack from the technology. Pick it from the **goal**. Run this before the Decision Register; keep it conversational, ask in small batches (2–3 questions), and summarize back what you heard.

**A. The goal (always ask)**
1. What outcome does this create, for whom? Who is the first user, by name or role?
2. How do we know it worked — one measurable signal?
3. What exists today (manual process, spreadsheet, old system)? What breaks if we do nothing?
4. What is the deadline and who is the audience for the first demo?

**B. Shape of the thing**
5. Who uses it: internal team / logged-in customers / anonymous public visitors?
6. Where do they use it: browser, phone, both, or another system calling an API?
7. What data does it hold: documents, records, conversations, files, money? Roughly how much, and in which languages?
8. Does anything need to be real time (streaming answers, live updates)?
9. Any hard constraints: data residency, on-prem, existing cloud, compliance, budget?

**C. Language — ask this properly, it changes the models**
The stored data and the user's questions can be in different languages, and model quality varies hugely per language. Never assume.
10. **What language is the stored content in?** (documents, records, transcripts) — one language, or mixed inside the same document?
11. **What language will users type in?** Same as the content, or different? (Arabic question over an English contract is a *cross-lingual* problem, not a translation one.)
12. **What language must the answer be in?** Always the user's, always one fixed language, or mirror the source?
13. If Arabic: **MSA, dialect, or both?** Which dialect(s)? Is the text diacritized, scanned, or noisy OCR?
14. Any other scripts in play (French, Urdu, Turkish, Chinese…)? Any domain jargon, transliterated names, or code-switching (Arabizi, English terms inside Arabic sentences)?
15. Do the UI and the notifications need localization too, or just the answers?

Route from the answers (details in `references/rag-and-data.md` §3):

| What you heard | Retrieval / model implication |
|---|---|
| English only | any strong English embedder; simplest case |
| Arabic only, or Arabic + English mixed | **BGE-M3** (or Cohere Embed v4 / text-embedding-3-large if managed) + Arabic normalization on ingest *and* query + RTL UI |
| Questions in one language, documents in another | cross-lingual embedder is mandatory (BGE-M3, multilingual-e5); test it before committing — this is where naive stacks fail |
| Dialect or code-switched input | normalize + keep the raw text; add dialect examples to the golden set; expect lower recall, plan the eval accordingly |
| Scanned / OCR'd Arabic | document parsing (Azure Document Intelligence) becomes a first-class step, not an afterthought |
| Many languages, one index | one multilingual embedder + a `lang` metadata filter; never mix embedders in one collection |
| Answer language ≠ question language | state it in the prompt and test it; it is an eval criterion, not a hope |

**D. Where the AI actually is (only if AI is involved)**
16. What decision or task is the model doing that plain code can't?
17. What does "correct" look like, and who can judge it? Do example questions with approved answers exist?
18. What is the cost of a wrong answer — embarrassing, expensive, or dangerous? (This sets guardrails and whether a human approves actions.)
19. Does it need to *do* things (write, send, book) or only answer?

**E. Reality check**
20. Who maintains it in six months?
21. What's explicitly *out* of the MVP?
22. What would make you kill this project in three months?

**Ask more, not less.** Every unanswered question here becomes a guess baked into the foundation. If an answer is "I don't know", write it in the stack guide's open-questions list with an owner and a date — don't silently pick for them. Ask in batches of 2–3 and reflect the answers back before moving on.

**Then map goal → stack, and say the mapping out loud:**

| What you heard | What it implies |
|---|---|
| "internal tool, ten users, no SEO" | React + Vite SPA; skip Next.js, skip CDN concerns |
| "public product, people must find it on Google" | Next.js App Router for the public surface |
| "people use it on the go / notifications / camera / offline" | Flutter app; otherwise a responsive web app is cheaper |
| "answers must come from our documents, with sources" | RAG (hybrid + rerank), not a fine-tune, not a bare LLM call |
| "it has to decide which tool to use / multi-step" | `create_agent`; if it's one fixed sequence, a chain is enough |
| "documents in Arabic" | BGE-M3 + Arabic normalization + RTL from day one |
| "data can't leave the country / the building" | vLLM + self-hosted Qdrant + Langfuse |
| "records with relations, reporting, money" | Postgres + SQLAlchemy 2.0 + Alembic |
| "one big demo in three weeks" | MVP slice: one user story end to end, everything else deferred |

**F. The names (ask this even when it feels obvious)**
23. What do *they* call a case or engagement — matter, project, file, case? What do they call the
    people using it? Write the answers into the stack guide's glossary §3b, and use those words
    everywhere afterwards. If a frontend, brief or existing system already exists, take the names
    from it rather than inventing better ones — a synonym introduced later is a rename across every
    artifact, and with Spec Kit it is found the day the frontend fails to connect.

Close discovery with a written summary: **goal, first user, success signal, MVP slice, the names,
what's out of scope, stack answers, open questions.** Get a yes before writing code.

---

## 3. Kickoff outputs — what discovery produces

Discovery ends with **three or four files and nothing else** — see the `tasks.md` condition below.
No `app/` skeleton yet; no dependencies installed yet.

| File | Purpose | Template |
|---|---|---|
| `docs/stack-guide.md` | **Binding**: goal, MVP slice, glossary, every decision + why, the rules this project follows, deferred items and their triggers | `assets/templates/stack-guide.template.md` |
| `CLAUDE.md` | Short session context: points at the stack guide and this skill; commands; gotchas (symlink `AGENTS.md` → it) | `assets/CLAUDE.template.md` |
| `tasks.md` | MVP tasks in order + a "Later" list — **only when Spec Kit is not in use** | — |
| `docs/constitution-seed.md` | The text to paste into `/speckit.constitution` if using Spec Kit | `assets/templates/constitution-seed.template.md` |

> ⚠️ **`tasks.md` is conditional.** Check for `.specify/` **before** writing it.
> If it exists, Spec Kit owns the task list and writes it to `specs/NNN-<name>/tasks.md`.
> Writing a second one at the repo root creates two live lists with colliding ids (`T1` vs `T001`),
> and nobody can tell which "T1" a commit means. In that case put the MVP task order in the stack
> guide's §2 MVP slice instead, and let `/speckit.tasks` own execution order.
> Details: `references/spec-kit.md` §3.

Rules for these outputs:
- Write them **only after the human confirms** the discovery summary.
- `docs/stack-guide.md` outranks anything a later plan, task, or agent proposes. A step that contradicts it is a bug — stop and raise it instead of silently changing the stack.
- One decision, one place: decisions live in the stack guide; `CLAUDE.md` links to it; the constitution states the *principles*, not the stack.
- When a decision changes: update the stack guide (and its change log) **first** — it is the binding
  record, and `CLAUDE.md` only links to it. Then re-run `/speckit.constitution` if a *principle*
  changed. With Spec Kit, a decision reached in `research.md` is not decided until the stack guide
  says so, in the same commit (`references/spec-kit.md` §3).
- Project files (`app/`, `Makefile`, `Dockerfile`, …) get created later, one at a time, as §4's gate allows — copy them from `assets/templates/` when the need appears.

**Handoff after kickoff**
- With Spec Kit: `/speckit.constitution` (paste the seed) → `/speckit.specify` → `/speckit.clarify` → `/speckit.plan` (argument: "follow docs/stack-guide.md exactly") → `/speckit.tasks` → `/speckit.implement` → `/speckit.converge`. See `references/spec-kit.md`.
- Without Spec Kit: work straight from `tasks.md`, this skill governing how each file is written.

---

## 4. MVP first — the file-creation gate

Before creating **any** file, directory, service, or dependency, it must pass all three:
1. **A stated need**: a user story, a decision in the register, or an explicit request points at it.
2. **Used this week**: the MVP path actually runs through it.
3. **Nothing simpler works**: no existing file or a few lines elsewhere would do.

If any answer is no → don't create it; note it in `tasks.md` under "Later".

**The MVP slice**: one user story, end to end, in production shape (typed, tested, logged) — not a prototype, not a half of every feature.

Default MVP inventory (a backend + AI service): `app/main.py`, `core/config.py`, one router, one service, one repository, one schema module, one factory module if AI is involved, `tests/`, `Makefile`, `Dockerfile` + `compose.yaml` + override, `.env.example`, `CLAUDE.md`, `tasks.md`, `README.md`. That's it.

Deferred until the trigger fires: Redis (no measured hot path yet), queue/worker (no job over a second), multi-tenancy (one tenant), rate limiting (one client), the Prometheus/Grafana stack (no traffic yet — but expose `/metrics` and log structurally from day one so it's a config change later, not a refactor), the mobile app (no mobile need proven), CI matrices, k8s manifests, feature flags, caching layers, subagents.

Say what you're skipping and why — a one-line "deferred: Redis until we see a slow endpoint" beats silent omission.

---

## 5. Staged adoption — don't build it all on day one

| Stage | Trigger | Add |
|---|---|---|
| **0. Foundation** | new project | FastAPI + uv + Docker + Makefile + `.env` + typed contract + tests + one agent tier |
| **1. Public surface** | you need SEO / link previews / marketing pages | Next.js App Router for those pages only; keep the app shell an SPA |
| **2. Scale-out** | > 1 backend instance, or first paying tenants | Redis rate limiting + cache, idempotency keys, RLS multi-tenancy, **Prometheus + Grafana + 5–7 alerts**, SLOs, zero-downtime migrations |
| **3. Long-horizon agents** | runs must survive restarts / take minutes | LangGraph durable execution + Postgres checkpointer; Mem0/Zep for long-term memory |
| **4. Multi-agent** | a single agent measurably fails on *parallel, read-heavy* work that context engineering can't fix, and ~15× token cost is acceptable | supervisor + subagents |

Anything not triggered yet is **over-engineering**. Skip it (§4).

---

## 6. Decision Register (confirmed after Discovery)

This is the **checklist of what must be decided**; the answers are recorded once in `docs/stack-guide.md` (§3) and nowhere else.

### 6.1 Product & backend
| # | Decision | Default recommendation |
|---|---|---|
| 1 | Agent tier (ladder) | lowest rung that works: none → 1 LLM call → structured output → fixed RAG chain → `create_agent` → deep agent → multi-agent |
| 2 | Primary DB | Postgres + **SQLAlchemy 2.0 async + Alembic** (robust default) · **SQLModel** for simple CRUD apps · **MongoDB + Motor/Beanie** for document data · Neo4j for graph traversal |
| 3 | Vector store | **Qdrant** (native hybrid) · **pgvector** if already on Postgres and the corpus is small/medium (one DB, one backup) · **Supabase** for managed Postgres + pgvector with batteries · Azure AI Search if Azure-native |
| 4 | Retrieval | always hybrid (BM25 + dense, RRF) + reranker + score threshold |
| 5 | Embeddings (ar/en) | **BGE-M3** self-hosted (best measured for Arabic, gives dense+sparse+ColBERT) · **Cohere Embed v4** or **OpenAI text-embedding-3-large** managed |
| 6 | Reranker | **Cohere Rerank** (multilingual) or **Jina Reranker** · BGE cross-encoder self-hosted |
| 6b | AI framework | agent layer: **LangChain `create_agent`** (LangGraph) · rungs 1–4: no framework · retrieval: **your own code** behind a factory · LlamaIndex/LlamaParse only as a contained parsing step · see `references/frameworks.md` |
| 7 | LLM + serving | hosted API · **vLLM** (OpenAI-compatible `/v1` API, same factory via `base_url`) when on-prem/data residency — never exposed publicly |
| 8 | Gateway | none → **LiteLLM Proxy** when multi-provider/budgets/on-prem routing |
| 9 | Tracing (LLM) | pick ONE: LangSmith (default) or Langfuse (self-host) |
| 9b | Monitoring | logs + `/metrics` from day one; **Prometheus + Grafana** (compose profile) once there's real traffic or a second instance; Grafana Cloud / Azure Monitor if you'd rather not run it |
| 10 | Cache | **Redis** (keyword) → semantic cache only if measured → provider prompt caching |
| 11 | Rate limiting | Redis-backed token bucket on auth + LLM + expensive routes |
| 12 | Jobs | `BackgroundTasks` (<1s, losable) → **ARQ** (async-native, Redis) or **Celery** (mature, scheduling/retries) |
| 13 | Secrets | `.env` (never committed) + `.env.example` → Key Vault / Doppler / SOPS in prod |
| 14 | Multi-tenancy | single → shared schema + tenant_id + **RLS**; schema-per-tenant only for compliance |
| 15 | Auth | managed IdP (Entra ID / Auth0 / Clerk) unless internal tool |
| 16 | Languages | Arabic → normalization in ingest+query, multilingual embedder, RTL everywhere |

### 6.2 Web frontend
| # | Decision | Default recommendation |
|---|---|---|
| 17 | Framework | **React + Vite + TanStack Router + TanStack Query (SPA)** — the backend is separate, so SSR buys little behind auth. Next.js App Router when SEO/marketing/RSC is needed; Nuxt only if Vue; TanStack Start if you want SSR + host neutrality; Astro for content sites |
| 18 | UI | Tailwind v4 + shadcn/ui (Radix) — RTL-aware, accessible |
| 19 | API client | generated from OpenAPI with **Hey API** (`@hey-api/openapi-ts`) |
| 20 | Auth storage | access token in memory + refresh token in HttpOnly/Secure/SameSite cookie |

### 6.3 Mobile
| # | Decision | Default recommendation |
|---|---|---|
| 21 | Framework | **Flutter** (one codebase, best solo fit) · React Native + Expo if the team is React-first · KMP for incremental native modernization |
| 22 | State | **Riverpod** (codegen) · Bloc for strict event-driven/audit domains |
| 23 | Client | generated Dart client from the same OpenAPI spec + `dio` interceptors |
| 24 | Token storage | `flutter_secure_storage` (Keychain/Keystore), bearer tokens |

### 6.4 Repo & contract
| # | Decision | Default recommendation |
|---|---|---|
| 25 | Contract | **OpenAPI is the single source of truth** (FastAPI generates it); versioned; contract-tested with Schemathesis |
| 26 | Repo layout | pragmatic middle: **monorepo (pnpm + Turborepo) for web + shared TS contract**, separate repos for FastAPI and Flutter, linked by the published spec. Full monorepo if the three change together; polyrepo if they rarely do |

Record every answer in the project `CLAUDE.md` → "Decisions".

---

## 7. Non-negotiables

**Engineering**
- **MVP first**: no file, service, or dependency without a stated need (§4).
- **Readable over clever**: small honest functions, guard clauses, names that carry meaning, comments that explain *why*. Naming conventions per stack in `references/code-style.md` — follow them consistently across Python, TypeScript, and Dart.
- **uv** only (`pyproject.toml` + committed `uv.lock`); **Makefile** as the one entry point for every command; **Docker** dev + prod side by side.
- Minimal code: add a module only when a decision requires it.
- Docs-first: fetch current docs before writing library code.
- **MVC + Factory**: routers (view) → services (controller) → repositories + schemas (model); factories build DB, vector store, embedder, reranker, LLM, retriever, agent from config.
- Pydantic v2 at every boundary; one typed `Settings` singleton from `.env`; no scattered `os.environ`.
- Typed API: `response_model`, status codes, documented errors, **RFC 9457** problem+json.
- Never block the event loop in `async def`. Timeouts on every outbound call.
- **Lifespan** for startup/shutdown — never `@app.on_event`.
- Pin everything, including model/embedding/SDK versions.

**AI**
- `init_chat_model` for models; `create_agent` / `create_deep_agent` only (never `AgentExecutor`).
- Caps via `ModelCallLimitMiddleware` + `ToolCallLimitMiddleware` (not `max_iterations`).
- Reliability via built-in retry / fallback / tool-error middleware.
- **Context engineering before more agents**: curate what enters the window (dynamic prompts, summarization, context editing, offloading).
- The LLM never writes raw SQL/Cypher/Mongo; tools are typed helpers with authz inside.
- Grounded answers with citations; **Ragas + LLM-as-judge evals** gate every prompt/model/retrieval change.
- One agent runtime per project; retrieval is your own code; other-ecosystem libraries only as contained parsing/utility steps (`references/frameworks.md`).

**Frontend & mobile**
- One generated client per platform from the same spec — no hand-written API types.
- RTL from day one: `dir` on the root + CSS logical properties (`ms-/me-/ps-/pe-`), real Arabic test content.
- Streaming UI consumes the typed SSE event contract (`token`, `tool_call`, `citation`, `interrupt`, `error`, `done`).
- Access tokens never in localStorage (web) / SharedPreferences (mobile).

**Quality & Ops**
- Test-first for endpoints and data tasks; evals for AI changes; **Locust** for load tests before launch.
- Structured JSON logs + RED metrics + one LLM tracer + OTel.
- OWASP Top 10 (web/API) + OWASP Top 10 for LLM Apps by default.
- `tasks.md` updated every task; `README.md` / `CLAUDE.md` / `.env.example` when affected.

---

## 8. Workflow rules (every task)

0. Using Spec Kit? Follow its flow and let this kit govern *how* the code is written (`references/spec-kit.md`).
1. Read `tasks.md`; mark the item `in_progress` (create it if missing).
2. Teaching mode: What → Why → Alternative.
3. Test-first for API/data tasks (red → green).
4. Implement the minimal version following the relevant reference file and `code-style.md`. Create only files that pass the §4 gate.
5. `make fmt lint type test` (→ `make eval` when AI behavior changed).
6. Update docs. Conventional commit (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).

---

## 9. Reference files — read the one the task needs

| Task touches… | Read |
|---|---|
| FastAPI app, lifespan, DI, middleware, errors, SSE, DB/migrations, versioning, jobs, cache, rate limit, testing | `references/fastapi.md` |
| Models, agents, tools, middleware, context engineering, streaming, memory, Deep Agents, MCP | `references/langchain-agents.md` |
| RAG, ingestion, embeddings, reranking, Arabic retrieval, evals (Ragas, LLM-as-judge) | `references/rag-and-data.md` |
| Auth, OWASP, LLM security, guardrails, secrets | `references/security.md` |
| API contract, error format, streaming event schema, generated clients | `references/api-contract.md` |
| Web app: framework choice, structure, state, forms, streaming UI, RTL/i18n, testing, hosting | `references/frontend-web.md` |
| Flutter app: architecture, Riverpod, dio, streaming, secure storage, offline, RTL, CI/CD | `references/mobile-flutter.md` |
| uv, Makefile, Docker dev/prod, CI, observability, Locust, LiteLLM, vLLM, code review | `references/ops-and-review.md` |
| Monorepo vs polyrepo, starter kits to borrow from, shared conventions | `references/repo-and-kits.md` |
| Naming conventions, readability rules, review smells | `references/code-style.md` |
| LangChain vs LlamaIndex vs Haystack vs Pydantic AI vs no framework | `references/frameworks.md` |
| Working alongside GitHub Spec Kit (constitution, spec, plan, tasks, converge) | `references/spec-kit.md` |
| New project files | `assets/templates/stack-guide.template.md`, `assets/templates/constitution-seed.template.md`, `assets/CLAUDE.template.md`, `assets/templates/` (Makefile, Dockerfile, compose, .env.example) |

---

## 10. Default project layout (backend) — grow into it, don't scaffold it all

Start with the MVP inventory in §4. This is the **target** shape once the needs appear — create each folder the day something goes in it.

```
app/
  main.py            # create_app() + lifespan + router/middleware registration
  core/              # config.py logging.py errors.py security.py cache.py ratelimit.py observability.py
  api/v1/            # routers (VIEW) — thin
  services/          # business logic (CONTROLLER)
  repositories/      # data access only (MODEL - persistence)
  schemas/           # Pydantic request/response (MODEL - contract)
  models/            # ORM / ODM models
  factories/         # llm.py embeddings.py vectorstore.py db.py agent.py
  ai/                # prompts.py tools.py middleware.py agent.py retriever.py
  jobs/              # worker tasks (ARQ/Celery)
  deps.py
migrations/ tests/ scripts/ load/ docs/specs/ docs/plans/
pyproject.toml uv.lock Makefile Dockerfile compose.yaml compose.override.yaml compose.prod.yaml
.env.example CLAUDE.md tasks.md README.md
```
Many domains → switch to **domain-first** folders (each holding router/service/repository/schemas); the layering stays identical. Decide at kickoff.
