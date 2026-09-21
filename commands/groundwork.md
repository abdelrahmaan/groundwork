---
description: Start, scaffold, review or extend a project using the Groundwork standard
argument-hint: what you want to build or change, e.g. "an Arabic-first booking API with a Flutter app"
---

Invoke the `groundwork` skill and apply it to the request below. Read its `SKILL.md`
in full before doing anything else, and follow its operating modes exactly — in
particular, do not write code before Discovery has produced the four kickoff outputs.

<request>
$ARGUMENTS
</request>

Routing:
- **Empty request** — start Kickoff mode (§1.1) from the first question.
- **A new product or project** — Kickoff mode (§1.1): Discovery, then the Decision
  Register, then the four kickoff outputs, then the MVP slice.
- **An existing repo** — read `docs/stack-guide.md` first if it exists; its decisions
  are binding and override the skill's defaults. If it does not exist, say so and
  offer to run Kickoff before building.
- **A review request** — load `references/ops-and-review.md` and review against the
  stack guide, not against the skill's defaults.
