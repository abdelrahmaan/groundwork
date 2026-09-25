# CLAUDE.md — <project_name>

> Keep this SHORT — it loads every session.
> **Decisions live in `docs/stack-guide.md` (binding) — not here.** This file just points at them.
> The full standard is the **groundwork** skill
> (operating modes, decision register, and reference files for FastAPI, agents, RAG, security,
> API contract, web, Flutter, ops). Follow it for every task.
> (Symlink for other tools: `ln -s CLAUDE.md AGENTS.md`)

## What this is
<one paragraph: purpose, users, core entities, main use cases>

## Decisions

See **`docs/stack-guide.md`** — it is binding for every plan, task, and generated file.
One-line summary: <e.g. "FastAPI + Postgres/SQLAlchemy async + Qdrant hybrid + Cohere rerank; React+Vite web; no mobile yet.">

If a step contradicts the stack guide, stop and raise it instead of changing the stack.

## Commands
Everything goes through the Makefile:
```bash
make install        # uv sync --locked
make dev            # API with reload
make check          # fmt + lint + type + test
make eval           # AI evals (Ragas + judge)
make migrate        # alembic upgrade head
make docker-dev     # dev stack
make docker-prod    # prod stack
make gen-clients    # regenerate TS + Dart clients from openapi.json
```

## Conventions
- Layout: <layer-first | domain-first>. Routers thin → services → repositories.
- API: `/api/v1`; errors = RFC 9457 problem+json with stable `code` + `trace_id`.
- Settings: `app/core/config.py`; secrets only in `.env` (never committed); `.env.example` always current.
- Prompts: `app/ai/prompts.py` (versioned). Tools: `app/ai/tools.py`. Agent built once in lifespan.
- Streaming: typed SSE events (`token`, `tool_call`, `sources`, `citation`, `interrupt`, `error`, `done`).

## Rules for Claude here
1. Read the active task list first — `tasks.md`, or the spec workflow's own (`specs/NNN-*/tasks.md`, `openspec/changes/<change>/tasks.md`, `docs/superpowers/plans/*.md`); mark the item in progress.
2. Fetch current library docs (Context7 / docs MCP) before writing library code.
3. Teaching mode: What → Why → Alternative → minimal code.
4. Validate my answers: agree / partly / disagree, with options + a recommendation.
5. Test-first for endpoints and data; `make eval` when AI behavior changes.
6. Update the active task list (+ README / CLAUDE.md / .env.example) after every task.

## Gotchas
- <add as discovered>
