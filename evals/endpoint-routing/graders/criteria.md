---
type: llm
weight: 1
---

This is an extension of an existing service, not a new project.

Passing requires ALL of:
- It does NOT run a full new-project discovery interview. Asking one or two
  targeted questions about the existing service is fine and expected.
- It answers in terms of streaming specifics: SSE with a typed event schema,
  rather than a vague "use websockets or SSE".
- It reflects the standard's API contract rules — typed SSE events, and errors
  in RFC 9457 problem-details form.
- If a stack guide could exist in the repo, it says those decisions take
  precedence over its own defaults.

Fail if it starts a discovery interview from scratch, or if it proposes a
streaming design with no event schema.
