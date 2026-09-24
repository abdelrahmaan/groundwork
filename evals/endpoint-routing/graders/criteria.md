---
type: llm
weight: 1
---

The workspace is an existing Groundwork project: its CLAUDE.md already states RFC 9457 errors
and typed SSE event names, so repeating those is expected and is NOT enough to pass. Judge
whether the response also applies the standard's own FastAPI streaming rules, which live in
the groundwork skill and not in CLAUDE.md.

Passing requires ALL of:
- It treats `docs/stack-guide.md` as binding: it reads or cites it and stays inside its stack.
- It specifies a TYPED SSE event schema — named event types carrying defined fields — rather
  than "stream tokens over SSE".
- It keeps HTTP errors as RFC 9457 problem details (not an ad-hoc JSON shape), and every
  stream ends with exactly one `done` or `error` event — the `error` event carrying a code,
  a detail and a trace id — never a silent close.
- It builds the endpoint with FastAPI's native SSE response (`EventSourceResponse` from
  `fastapi.sse`), NOT a hand-rolled `StreamingResponse` with a `text/event-stream` media type.
- It does NOT run a full new-project discovery interview; targeted questions are fine.

Fail if it uses `StreamingResponse` for the SSE stream. Fail if SSE is proposed with no event
schema. Fail if it opens a kickoff interview.
