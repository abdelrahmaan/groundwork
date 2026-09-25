---
type: llm
weight: 1
---

The workspace is an existing Groundwork project with a complete stack guide and no open
decisions. Judge the API contract and how the task is handled. (Which SSE response class it
uses is checked by a separate regex grader, not here.)

Passing requires ALL of:
- It treats `docs/stack-guide.md` as binding: it reads or cites it and stays inside its stack.
- It specifies a TYPED SSE event schema — named event types carrying defined fields — rather
  than "stream tokens over SSE".
- It keeps HTTP errors as RFC 9457 problem details (not an ad-hoc JSON shape), and every
  stream ends with exactly one `done` or `error` event — the `error` event carrying a code,
  a detail and a trace id — never a silent close.
- It treats this as one task in an existing project: it asks only what the endpoint cannot be
  built without (if anything). It does NOT run a discovery interview or re-ask decisions the
  stack guide already records (agent tier, tracing, auth, and so on).

Fail if SSE is proposed with no event schema. Fail if it asks about decisions the stack
guide already records, or opens a kickoff interview.
