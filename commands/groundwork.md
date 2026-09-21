---
description: Start, scaffold, review or extend a project using the Groundwork standard
argument-hint: what to build, change or review — name the area in plain words (backend, endpoint, agent, RAG, web, Flutter, review); empty starts the interview
---

Read `${CLAUDE_PLUGIN_ROOT}/skills/groundwork/SKILL.md` in full before doing anything
else, then follow its operating modes exactly. Its reference files live alongside it in
`${CLAUDE_PLUGIN_ROOT}/skills/groundwork/references/`, and its templates in
`${CLAUDE_PLUGIN_ROOT}/skills/groundwork/assets/` — load the one the task needs, per the
table in §9.

Do not write code before Discovery has produced the four kickoff outputs.

<request>
$ARGUMENTS
</request>

Routing:
- **Empty request** — start Kickoff mode (§1.1) from the first question.
- **A new product or project** — Kickoff mode (§1.1): Discovery, then the Decision
  Register, then the four kickoff outputs, then the MVP slice.
- **An existing repo** — read `docs/stack-guide.md` first if it exists; its decisions
  are binding and override the standard's defaults. If it does not exist, say so and
  offer to run Kickoff before building.
- **A review request** — load `references/ops-and-review.md` and review against the
  stack guide, not against the standard's defaults.

If `SKILL.md` cannot be read, say so plainly and stop. Do not improvise a substitute
standard.
