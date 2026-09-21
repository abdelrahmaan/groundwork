# API Contract Standard

The contract every client obeys — web, mobile, and any third party. FastAPI generates it; nobody hand-writes it.

## 1. OpenAPI is the contract
- FastAPI generates OpenAPI from Pydantic schemas → single source of truth.
- Frontend generates a **typed client** from it (openapi-typescript / Orval / Hey API) — no hand-written API types.
- Stable `operationId`s; version prefix (`/api/v1`); breaking changes → new version.
- CI snapshots `openapi.json`; diffs are reviewed in PRs.

## 2. Response shapes
- Single resource → the resource schema.
- Lists → `{ "items": [...], "total": n }` (cursor pagination for large/unstable sets: `{ items, next_cursor }`).
- Create → 201 + resource (+ `Location` header). Delete → 204. Async job → 202 + `{ job_id, status_url }`.
- Timestamps ISO-8601 UTC; IDs as strings; consistent field casing (pick snake_case or camelCase once — alias in Pydantic if frontend wants camelCase).

## 3. Errors — RFC 9457 Problem Details
Content-Type `application/problem+json`, one shape for every error (validation, domain, 500):
```json
{
  "type": "https://errors.example.com/quota-exceeded",
  "title": "Quota exceeded",
  "status": 429,
  "detail": "Daily chat quota reached.",
  "instance": "/api/v1/chat",
  "code": "quota_exceeded",
  "trace_id": "01J...",
  "errors": [{"field": "message", "msg": "too long"}]
}
```
- `code` = stable machine-readable string the frontend switches on.
- `trace_id` = request ID, also in logs and tracing → any bug report is traceable.
- Never leak stack traces or internal messages.

## 4. Streaming contract (chat / agent)
- `POST /api/v1/chat/stream` → `text/event-stream` via FastAPI native SSE.
- Browser `EventSource` is GET-only → frontend uses `fetch` streaming (e.g. `@microsoft/fetch-event-source`) for POST.
- **Named, typed events** (each a Pydantic model, documented in OpenAPI):

```
event: run_started   data: {"run_id": "...", "thread_id": "..."}
event: token         data: {"delta": "Once"}
event: tool_call     data: {"id": "...", "name": "search_docs", "status": "started"}
event: tool_result   data: {"id": "...", "status": "ok", "summary": "5 docs"}
event: citation      data: {"source_id": "...", "title": "...", "page": 3}
event: interrupt     data: {"type": "approval_required", "tool": "send_email", "args": {...}}
event: error         data: {"code": "rate_limited", "detail": "...", "trace_id": "..."}
event: done          data: {"finish_reason": "stop", "usage": {...}, "trace_id": "..."}
```
Rules:
- Every stream ends with exactly one `done` or `error` — never a silent close.
- Event IDs increase monotonically (enables `Last-Event-ID` resume).
- Keep-alive pings every ~15s (built into FastAPI SSE); no GZip on SSE routes.
- `interrupt` events drive human-in-the-loop UI; the approval is a separate POST that resumes the thread.
- Tool args/results sent to the UI are summarized + PII-filtered.
- Why not the OpenAI `choices[].delta` + `[DONE]` format? It only carries text — no tool calls, citations, interrupts, or structured errors. Use it only if a third-party client requires OpenAI compatibility.
- Alternatives: Vercel AI SDK stream protocol (Next.js + AI SDK frontend), LangGraph SDK `useStream` (when deployed on LangGraph Agent Server).

## 5. Other client concerns
- CORS origins per environment from settings.
- Auth: bearer token from the IdP; refresh handled by the frontend.
- Cancel: frontend aborts the fetch → backend detects disconnect and stops the run.
- Threads: `GET /threads`, `GET /threads/{id}/messages` for history; server validates ownership.
- File uploads: size/type limits; direct-to-blob signed URLs for large files.
