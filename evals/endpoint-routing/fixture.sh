#!/usr/bin/env bash
# An existing Groundwork project in production: the CLAUDE.md and stack guide a
# kickoff would have written, plus a small FastAPI app. Real projects reach the
# skill through this CLAUDE.md, so the case tests that path, not a bare prompt.
set -euo pipefail
mkdir -p app/routers docs tests

cat > CLAUDE.md <<'MD'
# CLAUDE.md — policy-assistant

> Keep this SHORT — it loads every session.
> **Decisions live in `docs/stack-guide.md` (binding) — not here.** This file just points at them.
> The full standard is the **groundwork** skill
> (operating modes, decision register, and reference files for FastAPI, agents, RAG, security,
> API contract, web, Flutter, ops). Follow it for every task.

## What this is
Answers staff questions about HR policy documents, with sources. First user: the HR team.

## Decisions
See **`docs/stack-guide.md`** — it is binding for every plan, task, and generated file.
One-line summary: FastAPI + Postgres/SQLAlchemy async + Qdrant hybrid + Cohere rerank; React+Vite web; no mobile yet.

## Commands
```bash
make install        # uv sync --locked
make dev            # API with reload
make check          # fmt + lint + type + test
```

## Conventions
- Layout: layer-first. Routers thin → services → repositories.
- API: `/api/v1`; errors = RFC 9457 problem+json with stable `code` + `trace_id`.
- Settings: `app/core/config.py`; secrets only in `.env` (never committed).
- Streaming: typed SSE events (`token`, `tool_call`, `sources`, `citation`, `interrupt`, `error`, `done`).

## Rules for Claude here
1. Read `tasks.md` first; mark the item in progress.
2. Fetch current library docs before writing library code.
3. Test-first for endpoints and data.
MD

cat > docs/stack-guide.md <<'MD'
# Stack Guide — policy-assistant

> **This file is binding.** Anything that contradicts it is a bug, not a preference.

## 4. Decisions

| Area | Choice | Why (one line) |
|---|---|---|
| Agent tier | Fixed RAG chain, no agent framework | one fixed sequence: retrieve, rerank, answer |
| Backend | FastAPI 0.141 + Pydantic v2, uv | async, typed, the team's language |
| Database | Postgres + SQLAlchemy 2.0 async + Alembic | relations + reporting |
| Vector store | Qdrant | native hybrid search |
| Retrieval | Hybrid BM25 + dense, RRF, rerank, score threshold | Arabic + English in one document |
| Embeddings | BGE-M3, self-hosted | Arabic + English mixed |
| Reranker | Cohere Rerank | multilingual |
| LLM | Hosted API via init_chat_model | no data-residency constraint |
| Gateway | None | one provider |
| Tracing | Langfuse, self-hosted | HR content stays on our VM |
| Monitoring | Structured logs + /metrics; no Grafana yet | one instance, low traffic |
| Cache | None yet | no measured hot path |
| Rate limiting | Per-user token bucket on the chat route | LLM cost |
| Jobs | BackgroundTasks | ingestion runs are small |
| Secrets | .env + .env.example | one VM |
| Multi-tenancy | Single tenant | one company |
| Auth | Entra ID (company SSO) | staff already have accounts |
| Languages | Arabic + English content, Arabic answers, RTL UI | HR policies are bilingual |
| Hosting | Docker Compose | one VM |

**Open questions / OPEN decisions:** none.
MD

cat > tasks.md <<'MD'
# Tasks
- [x] T1 Health endpoint
- [x] T2 Ingest HR policies
- [ ] T3 Streaming chat endpoint
MD

cat > app/main.py <<'PY'
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.routers import health


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="policy-assistant", lifespan=lifespan)
app.include_router(health.router, prefix="/api/v1")
PY
: > app/__init__.py
: > app/routers/__init__.py
cat > app/routers/health.py <<'PY'
from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
PY

cat > pyproject.toml <<'TOML'
[project]
name = "policy-assistant"
version = "0.4.0"
requires-python = ">=3.12"
dependencies = ["fastapi>=0.141", "pydantic>=2.9", "sqlalchemy[asyncio]>=2.0", "qdrant-client>=1.12"]
TOML

git init -q && git add -A && git -c user.email=eval@example.com -c user.name=eval commit -q -m "policy-assistant v0.4.0 in production"
