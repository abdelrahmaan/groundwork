---
type: llm
weight: 1
---

Judge whether the response follows THIS standard's kickoff, not merely whether
it is a sensible reply. A capable assistant without the standard will ask good
questions; that alone is not a pass.

Passing requires ALL of:
- It asks about the language profile as THREE separate things — the language of
  the content, the language users ask in, and the language answers come back in
  — not just "the app is in Arabic".
- Every question carries explicit options AND a recommendation, so the user can
  answer "yes" rather than compose an answer.
- It names the kickoff outputs by their actual paths: `docs/stack-guide.md`,
  `CLAUDE.md`, and `docs/constitution-seed.md` — plus `tasks.md`, OR it says that
  a spec workflow's own task list takes its place (the standard skips the root
  `tasks.md` when Spec Kit, OpenSpec, Superpowers or another workflow is in use).
- It states that it will summarize the stack and wait for confirmation before
  writing anything.
- It writes no application code and creates no project files in this response.

Fail if the language question is a single "which language?". Fail if the output
files are not named by path. Fail if questions arrive without recommendations.
