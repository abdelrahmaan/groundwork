---
type: llm
weight: 1
---

The response must behave like a kickoff, not like an implementation.

Passing requires ALL of:
- It asks discovery questions before proposing any implementation — at minimum
  about the goal, the first user, and the language/data profile.
- Each question carries options plus a recommendation, so the user can answer
  "yes" rather than compose an answer from scratch.
- It does NOT write application code, and does NOT create project files, in
  this first response.
- It either names the four kickoff outputs (docs/stack-guide.md, CLAUDE.md,
  tasks.md, docs/constitution-seed.md) or makes clear those come after the
  user confirms the stack.

Fail if it jumps to a directory layout, a dependency list, or code before
asking anything. Fail if it asks questions with no recommendation attached.
