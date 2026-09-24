# Using Groundwork with any spec workflow

Verified on 2026-09-24 against installed copies: Superpowers 6.3.0 (Claude Code plugin) and
OpenSpec 1.13.2 (`@fission-ai/openspec`). Spec Kit is covered in `spec-kit.md` (docs, 2026-09-20).
Anything else below is a recipe, not a verified adapter — say so when you use it.

## 1. The one-line answer

**The spec workflow decides *what* to build and in what order. Groundwork decides *how* it is built.**
Every spec workflow — Spec Kit, OpenSpec, Superpowers, or the next one — has the same five slots.
Groundwork fills one of them (the rules slot) and is the technical input to another (the plan).
It never runs a second copy of the process.

| Slot | What it holds | Groundwork's part |
|---|---|---|
| **Rules** | standing constraints every step reads | points at `docs/stack-guide.md` as binding + the principles from `docs/constitution-seed.md` |
| **Spec** | behavior, user stories, acceptance criteria | uses the glossary's names; stack guide §2 is its input |
| **Plan / design** | how it will be built | implements the stack guide, never re-decides it |
| **Tasks** | ordered work items | owned by the workflow — Groundwork writes no second list |
| **Review gate** | "is it done?" | adds `ops-and-review.md` §10 as the human gate |

The invariants are the same whichever workflow fills the slots, and live in one place each:
stack guide outranks everything (SKILL.md §3), one scope authority (`spec-kit.md` §3c),
investigation vs decision (§3d), one task list (§3e). Read those as "the spec", "the plan",
"the task list" — not as Spec Kit files.

## 2. Detect which workflow is in use

Check before kickoff writes anything, and before any task in an existing repo:

| Found in the repo | Workflow | Its task list |
|---|---|---|
| `.specify/` | Spec Kit | `specs/NNN-<name>/tasks.md` |
| `openspec/` (with `config.yaml`) | OpenSpec | `openspec/changes/<change>/tasks.md` |
| `docs/superpowers/`, or the `superpowers:*` skills are loaded | Superpowers | the plan in `docs/superpowers/plans/` |
| none of these | none — Groundwork alone | root `tasks.md` |

On a new repo the folders don't exist yet — Discovery question 24 asks. More than one present
(Superpowers is often installed next to Spec Kit or OpenSpec): ask the human which one owns the
task list. The other may still run its discipline skills (TDD, debugging, review), but only one
list is live.

## 3. Superpowers (obra/superpowers, verified 6.3.0)

What it is: skills, not a CLI. `brainstorming` → `writing-plans` → `subagent-driven-development`
or `executing-plans`, with `test-driven-development`, `systematic-debugging`,
`requesting-code-review` and `finishing-a-development-branch` along the way.

Artifacts:
- Spec: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` — written only on the
  *architectural* path. The *bounded* path is a short design in chat, and a *spike* writes nothing.
- Plan: `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`, with checkbox tasks and a header
  holding **Tech Stack**, **Spec** (path), and **Global Constraints** "copied verbatim from the spec".

Where Groundwork plugs in:
- **Rules slot = `CLAUDE.md` / `AGENTS.md`.** `using-superpowers` ranks user instructions
  (CLAUDE.md, AGENTS.md, GEMINI.md) above skills. The Groundwork `CLAUDE.md` already declares the
  stack guide binding — that is the hook. Keep it.
- **Discovery vs `brainstorming`.** For a new project, Groundwork Discovery *is* the architectural
  brainstorm for the stack; don't run both interviews. Per feature afterwards, `brainstorming` runs
  as normal, but its "propose 2–3 approaches" step chooses **inside** the stack guide. An approach
  that needs a library outside it is a stack change: raise it (SKILL.md §3), don't offer it as an
  option.
- **The design doc** names the stack guide as binding and uses the glossary's names.
- **The plan header**: `Tech Stack` is copied from the stack guide's one-line summary, and the
  first line of `Global Constraints` is
  `docs/stack-guide.md is binding — no library, service or name outside it.`
  This line matters most: `subagent-driven-development` gives each implementer a fresh context
  built by the controller rather than the session history, and reviews every task against the plan's
  Global Constraints. On a harness where subagents don't load `CLAUDE.md`, this line is the only way
  the stack guide reaches them.
- **Tasks**: the plan owns them. No root `tasks.md`.
- **Review**: `requesting-code-review` per task, then `ops-and-review.md` §10 before
  `finishing-a-development-branch`.
- TDD already matches Groundwork's test-first rule; nothing to reconcile.

## 4. OpenSpec (Fission-AI/OpenSpec, verified 1.13.2)

What it is: a CLI (`openspec`) plus agent skills and `/opsx:*` commands. Default flow
`/opsx:propose` → `/opsx:apply` → `/opsx:archive`; schema `spec-driven`, artifacts
`proposal → specs → design → tasks` per change in `openspec/changes/<change>/`. Archiving merges the
change's spec deltas into `openspec/specs/`.

Where Groundwork plugs in:
- **Rules slot = `openspec/config.yaml`.** `context:` is sent with the instructions for *every*
  artifact; `rules:` are per artifact (keys `proposal`, `specs`, `design`, `tasks`). Checked on
  1.13.2 with `openspec instructions <artifact> --change <name> --json`. OpenSpec treats both as
  constraints and does not copy them into the files, and ignores a `context` over 51,200 bytes — so
  point at the stack guide, don't paste it:

  ```yaml
  schema: spec-driven
  context: |
    docs/stack-guide.md is binding: its stack, glossary and rules override any default.
    Principles: <the numbered headlines from docs/constitution-seed.md, one line each>
  rules:
    specs:
      - Use the glossary names in docs/stack-guide.md §3b; never invent a synonym.
    design:
      - Implement docs/stack-guide.md; never introduce a library, service or model outside it.
      - Close any OPEN item from the stack guide there, in the same commit.
    tasks:
      - Endpoint and data tasks start with a failing test.
  operations:
    archive:
      guidance:
        - Before archiving, run the groundwork review checklist (ops-and-review.md §10); archive only when it passes.
  ```

- **`proposal.md`** = the spec slot's *why*; stack guide §2 is its input, and it becomes the scope
  authority once written (`spec-kit.md` §3c).
- **`design.md`** = the plan slot.
- **`tasks.md`** (per change) owns the task list. No root `tasks.md`.
- **Review**: `ops-and-review.md` §10 before `/opsx:archive` — archiving is OpenSpec's "done". Put it in
  `operations.archive.guidance` (above): OpenSpec delivers that guidance at the archive step only, not to
  the artifacts or to apply — checked on 1.13.2 with `openspec instructions archive --change <name> --json`.

## 5. Spec Kit

Fully covered in `spec-kit.md`. Rules slot = the constitution, seeded by pasting
`docs/constitution-seed.md` into `/speckit.constitution`.

## 6. Any other workflow

Not verified here — apply the recipe and tell the human it's unverified:
1. Find the **rules slot**: a constitution, a project config the tool injects, or steering/rules
   files. If there is none, `CLAUDE.md` / `AGENTS.md` is the rules slot.
2. Put a pointer to `docs/stack-guide.md` there, plus the seed's principles in one line each. Don't
   paste the stack guide — it goes stale in two places.
3. Find where it writes the plan and the task list. The plan obeys the stack guide; the task list
   is the workflow's, so Groundwork writes no root `tasks.md`.
4. Add `ops-and-review.md` §10 before the workflow's "done" step.
5. Test it once: ask it to plan a small feature and check that the plan names the stack guide and
   uses only what it lists. If it doesn't, the rules slot is wrong — fix it before building.

## 7. When to use none

Same as `spec-kit.md` §6: a spike, a one-file script, or a change smaller than its spec — use
Groundwork alone. A workflow earns its ceremony with several user stories, several sessions, or
more than one person.
