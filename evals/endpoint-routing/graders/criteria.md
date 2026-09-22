---
type: llm
weight: 1
---

Judge whether the response applies THIS standard's API contract rules to an
existing service. A capable assistant without the standard will suggest SSE;
that alone is not a pass.

Passing requires ALL of:
- It says that `docs/stack-guide.md` in the repo, if present, is binding and
  overrides its own defaults.
- It specifies a TYPED SSE event schema — named event types carrying defined
  fields — rather than "stream tokens over SSE".
- It specifies the error format as RFC 9457 problem details.
- It does NOT run a full new-project discovery interview; targeted questions
  about the existing service are fine.

Fail if SSE is proposed with no event schema. Fail if the error format is
unspecified or is an ad-hoc JSON shape. Fail if it opens a kickoff interview.
