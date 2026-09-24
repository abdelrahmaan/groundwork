# Stack Guide — <project_name>

> **This file is binding.** It records the decisions made in the kickoff interview and the rules
> every later step follows — including a spec workflow's plan, tasks and implementation (Spec Kit,
> OpenSpec, Superpowers or another).
> Anything that contradicts this file is a bug, not a preference.
> Detail lives in the **groundwork** skill; this file records *what we chose for this project*.
>
> Created: <date> · Last updated: <date>

---

## 1. Goal (from discovery)

- **Outcome / problem**: <what this creates and for whom>
- **First user**: <name or role>
- **Success signal**: <one measurable thing>
- **Deadline / first demo**: <date, audience>
- **Today's alternative**: <manual process / old system / nothing>

## 2. MVP slice

**One user story, end to end, in production shape:**
> <e.g. "An employee asks a question in Arabic and gets an answer with source citations.">

**MVP task list** (only when no spec workflow is in use — otherwise its task list owns it):
- [ ] <task>

**In scope:** <3–5 bullets>
**Explicitly out of scope:** <the list that keeps us honest>

**Deferred until its trigger fires:**
| Deferred | Trigger that un-defers it |
|---|---|
| Redis cache | a measured slow endpoint |
| Worker / queue | a job over ~1s or that must survive restart |
| Rate limiting | more than one client, or an LLM route in production |
| Multi-tenancy | a second tenant |
| Mobile app | a proven mobile-only need |
| Observability stack | real traffic |

## 3. Language & data profile

| Question | Answer |
|---|---|
| Stored content language(s) | <ar / en / mixed / other> |
| User input language(s) | <same / different — cross-lingual?> |
| Required answer language | <user's / fixed / mirror the source> |
| Arabic specifics | <MSA / dialect(s) / diacritized / OCR noise / code-switching> |
| Other scripts | <none / fr / ur / tr / …> |
| UI localization needed | <yes/no> · RTL required: <yes/no> |
| Data volume & growth | <e.g. 300 PDFs, +20/month> |
| Sensitivity | <public / internal / PII / regulated> |

**Implications taken from this profile:** <embedder, normalization, parsing, eval slices, RTL>

## 3b. Glossary — the names, fixed

One name per concept, used everywhere: spec, data model, API paths, database tables, code, and UI. Fill it
from whatever already exists — the frontend, the product brief, how the client talks — **not** from what
reads best in a sentence. A downstream synonym is a defect.

| Concept | The one name | Do NOT use | Appears as |
|---|---|---|---|
| <a case / engagement> | `Project` | matter, case, engagement | `/api/v1/projects/{id}`, table `projects` |
| <the person served> | `Client` | customer, account | |
| <a generated file> | `Document` | doc, file, artifact | |

Bilingual products: fix the term in both languages (`<english term> = <translated term>`), and always use the English one in code, tables, and API paths.

**Why this section exists.** A spec writer (`/speckit.specify`, `/opsx:propose`, `brainstorming`) writes for business stakeholders, so without this it picks
the word that reads best and calls your `Project` a "Matter". That name flows into `data-model.md`, into
`contracts/`, into the route paths — and the mismatch surfaces when the frontend calls `/projects/123` and
the backend serves `/matters/123`.

## 4. Decisions

| Area | Choice | Why (one line) |
|---|---|---|
| Agent tier | <none / 1 call / structured / RAG chain / create_agent / deep agent> | |
| Backend | Python + FastAPI + Pydantic v2 + uv | |
| DB + migrations | <Postgres + SQLAlchemy 2.0 async + Alembic / SQLModel / Mongo + Motor> | |
| Vector store | <Qdrant / pgvector / Supabase / Azure AI Search / none> | |
| Retrieval | <hybrid BM25 + dense + RRF + rerank / none> | |
| Embeddings | <BGE-M3 / Cohere Embed v4 / text-embedding-3-large> | |
| Reranker | <Cohere Rerank / Jina / BGE cross-encoder / none> | |
| AI framework | agent: <LangChain create_agent / none> · retrieval: own code · parsing: <DI / LlamaParse / light parser> | |
| LLM | main=<> fast=<> fallback=<> · serving=<hosted / vLLM at LLM_BASE_URL> · gateway=<none / LiteLLM> | |
| Jobs | <BackgroundTasks / ARQ / Celery> | |
| Cache / rate limit | <none for now / Redis> | |
| Tracing (LLM) | <LangSmith / Langfuse / none yet> | |
| Monitoring | logs + /metrics now · <Prometheus + Grafana / Grafana Cloud / Azure Monitor> when <trigger> | |
| Auth | <IdP> · web: memory token + HttpOnly refresh cookie · mobile: secure-storage bearer | |
| Web frontend | <React + Vite + TanStack / Next.js App Router / none yet> | |
| Mobile | <Flutter + Riverpod / none> | |
| Repo layout | <single repo / monorepo / hybrid> | |
| Languages & RTL | see §3 | |
| Hosting | <Docker Compose / Container Apps / k8s> | |

**Open questions / OPEN decisions** (decide before they block work):
- [ ] <question> — owner, needed by <date>

When an investigation settles one of these (for example Spec Kit's `research.md` or OpenSpec's `design.md`), close it here in the same commit: move the answer into the table above, delete the open line, add a change-log entry, and link to where the reasoning lives.

## 5. Rules this project follows

**Architecture**
- Layering: routers (thin) → services (business logic) → repositories (data access). A router never touches a DB session or an LLM client.
- External resources (DB, Redis, vector store, models, agent) are created **once in the lifespan** through factories, never per request.
- MVP gate: no file, service or dependency without a stated need, a use this week, and nothing simpler that works.

**Contract**
- OpenAPI generated by FastAPI is the single source of truth; clients are generated, never hand-written.
- Errors: RFC 9457 problem+json with a stable `code` and a `trace_id`.
- Streaming: typed SSE events — `run_started`, `token`, `tool_call`, `tool_result`, `citation`, `interrupt`, `error`, `done`. Every stream ends with exactly one `done` or `error`.
- Pagination: `{items, total}` (or cursor); versioned routes under `/api/v1`.

**AI** (delete this block if the project has no LLM)
- Models via `init_chat_model` from config; agents via `create_agent`; caps via call-limit middleware.
- Tools are typed Python helpers with authorization inside; the model never writes raw queries.
- Answers are grounded with citations; "I don't know" when sources are empty.
- Prompts live in one versioned module; every prompt/model/retrieval change runs the eval set.

**Security**
- Secrets only in `.env` (gitignored); `.env.example` always current.
- Authorization deny-by-default in dependencies; identity derived server-side.
- OWASP web + LLM controls per the skill's `security.md`.

**Code style**
- Readable over clever: small functions, guard clauses, names that carry meaning, comments that explain *why*.
- Naming conventions per the skill's `code-style.md`; an entity keeps the same name across Python, TypeScript and Dart.

**Quality**
- Test-first for endpoints and data tasks. `make check` must pass before every commit.
- Every command goes through the Makefile.

## 6. Commands

```bash
make install     # uv sync --locked
make dev         # API with reload
make check       # fmt + lint + type + test
make docker-dev  # dev stack
```

## 7. Change log

| Date | Change | Reason |
|---|---|---|
| <date> | Initial decisions from kickoff | — |
