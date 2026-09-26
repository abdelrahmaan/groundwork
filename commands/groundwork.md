---
description: Start, scaffold, review or extend a project using the Groundwork standard
argument-hint: what to build, change or review — name the area in plain words (backend, endpoint, agent, RAG, web, Flutter, review); empty starts the interview
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/groundwork/SKILL.md` in full before doing anything
else, then follow its operating modes exactly. Its reference files live alongside it in
`${CLAUDE_PLUGIN_ROOT}/skills/groundwork/references/`, and its templates in
`${CLAUDE_PLUGIN_ROOT}/skills/groundwork/assets/` — load the one the task needs, per the
table in §9.

For a new project, write no code before Discovery has produced the kickoff outputs (§3).

<request>
$ARGUMENTS
</request>

Routing:
- **Empty request** — start Kickoff mode (§1.1) from the first question.
- **A new product or project** — Kickoff mode (§1.1): Discovery, then the Decision
  Register, then the four kickoff outputs, then the MVP slice.
- **One task in an existing repo** — Task mode (§1.5): read `docs/stack-guide.md`,
  `CLAUDE.md` and the task list first; the stack guide is binding. Ask only what the task
  can't proceed without, record other open items as OPEN, and build it surgically. No
  stack guide: state the stack you read from the code, follow it, and offer to write a
  stack guide later — never a kickoff interview for a single task.
- **A review request** — load `references/ops-and-review.md` and review against the
  stack guide, not against the standard's defaults.

If `SKILL.md` cannot be read, say so plainly and stop. Do not improvise a substitute
standard.
