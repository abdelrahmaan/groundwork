# Using Groundwork with GitHub Spec Kit

Verified against github/spec-kit docs on 2026-09-20.

## 1. The one-line answer

**Spec Kit decides *what* to build and in what order. Groundwork decides *how* it is built.**
They don't overlap: Spec Kit owns the process artifacts (spec → plan → tasks → implement → converge);
this kit owns the engineering standard (stack choices, layering, security, contracts, style).

If you use both: **Spec Kit is the workflow, this kit is the constitution + the plan's technical input.**

## 2. What Spec Kit actually is (current, not the old version)

- Install: `uv tool install specify-cli` then `specify init <project> --integration <agent>`.
- The commands are **agent skills invoked in chat**, not terminal commands. Written `/speckit.*` in the docs; Copilot's default skills mode uses `/speckit-*`; some agents use `$speckit-*` or `/skill:speckit-*`.
- Core flow (SDD): `/speckit.constitution` (once per project) → `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement` → `/speckit.converge`, repeating implement → converge until it reports **Converged**.
- Optional quality gates: `/speckit.clarify` (asks up to 5 targeted questions and writes answers back into `spec.md`), `/speckit.checklist` ("unit tests for your requirements"), `/speckit.analyze` (read-only consistency check across spec/plan/tasks).
- Two bundled extensions, installed only when needed: `specify extension add bug` (`/speckit.bug-assess → bug-fix → bug-test`, reports in `.specify/bugs/<slug>/`) and `specify extension add assess` (`intake → research → define → shape → decide`, artifacts in `.specify/assessments/<slug>/`, ending in go / needs-clarification / kill).
- The active feature is tracked in `.specify/feature.json` (or `SPECIFY_FEATURE_DIRECTORY`) — not by the git branch.
- Key artifacts: the constitution, `spec.md`, `plan.md`, `tasks.md`, checklists — **and the four extra outputs `/speckit.plan` produces**: `research.md` (Phase 0), then `data-model.md`, `contracts/`, `quickstart.md` (Phase 1). Three of those overlap with what Groundwork already owns, so §3b below governs them.

## 3. Division of responsibility

| Question | Owner |
|---|---|
| Is this idea worth building? | Spec Kit `assess` extension (or this kit's Discovery interview if you're not using it) |
| What are we building, for whom, with what acceptance criteria? | Spec Kit `specify` (+ `clarify`) |
| Which stack, DB, vector store, model, frontend, mobile? | **Groundwork Discovery** → written once into `docs/stack-guide.md` → referenced by `plan` |
| How is the code layered, named, secured, tested, deployed? | **Groundwork reference files** (via the constitution) |
| What order do we do the work in? | Spec Kit `tasks` |
| Did we actually finish it? | Spec Kit `converge` + **this kit's review checklist** |

Rule: never let `plan` invent a stack. The stack lives in `docs/stack-guide.md`, already agreed with the human. Anything in a spec, plan, task, or generated file that contradicts it is a bug — stop and raise it.

**Who writes what**

| Artifact | Written by | Binding on |
|---|---|---|
| `docs/stack-guide.md` | Groundwork (kickoff) | every later step, including Spec Kit |
| constitution | `/speckit.constitution`, seeded by Groundwork | spec, plan, tasks, analyze |
| `spec.md` | `/speckit.specify` | plan + tasks |
| `plan.md` | `/speckit.plan` (obeying the stack guide) | tasks + implementation |
| `tasks.md` | `/speckit.tasks` (Groundwork writes the MVP list if Spec Kit isn't used) | implementation |
| `CLAUDE.md` | Groundwork | every session |

### 3b. Artifact map — who owns what, and the overlap rule

Commands are not the interface; **artifacts are**. Every file Spec Kit produces gets one owner and one rule.

| Spec Kit artifact | Overlaps with | Rule |
|---|---|---|
| constitution | Groundwork non-negotiables + defaults | seeded from `docs/constitution-seed.md`; principles only |
| `spec.md` | stack guide §2 (MVP slice) | behavior and user stories only; **after it exists it is the authority for scope** (see §3c) |
| `plan.md` | stack guide §4 (decisions) | implements the stack guide, never re-decides it; its Technical Context is copied from the stack guide, not derived afresh |
| `research.md` | stack guide §4 (decisions) | may resolve **only** items the stack guide marks OPEN; closes them there in the same commit (see §3d) |
| `data-model.md` | stack guide §4 (DB) + glossary | uses the glossary's names; never invents synonyms |
| `contracts/` | `references/api-contract.md` | follows Groundwork's error shape (RFC 9457 + stable `code` + `trace_id`), pagination, and SSE event contract — never a second error format |
| `quickstart.md` | `README.md` / `CLAUDE.md` | no conflict — keep it, link it from the README |
| `tasks.md` | ⚠️ collision | **Spec Kit owns it.** Groundwork does not write a second one (see §3e) |
| checklists | — | Spec Kit's own quality gates |

### 3c. Scope has one authority at a time

Stack guide §2 (MVP slice) is the **input** to `/speckit.specify`. Once `spec.md` exists, its user stories are the authority for scope, and stack guide §2 is updated to match **in the same commit**. If the spec's stories exceed the agreed MVP slice, that's a scope change: raise it and get a yes — don't absorb it silently.

### 3d. Investigation vs decision

`research.md` records the **investigation**; the stack guide records the **decision**.
- Research may settle only what the stack guide lists as OPEN. It must not reopen or quietly override a settled decision — if it finds a settled decision is wrong, stop and raise it.
- When research settles an open item: write the outcome into stack guide §4, remove it from the open-questions list, add a change-log line, and link back to `research.md` for the detail — all in the same commit.
- Result: the binding file is never stale, and the reasoning isn't duplicated.

### 3e. One task list

If `.specify/` exists in the repo, Spec Kit owns `tasks.md` per feature. Groundwork then does **not** create a root `tasks.md`; the MVP task list lives as a section inside `docs/stack-guide.md` §2 until `/speckit.tasks` generates the real one. (These are different paths — a root `tasks.md` and `specs/<feature>/tasks.md` can never be "the same file".)

## 4. The combined workflow

**Pre-flight (30 seconds, saves an hour)**
0. If `.specify/memory/constitution.md` already exists, read it. A constitution left over from another product will silently fail the `/speckit.plan` gate, and the failure appears late. If it names a different product or contradicts the new stack guide, re-ratify it before `/speckit.specify`. Treat a principle removed or redefined as a MAJOR version bump.

**Once per project**
1. Run Discovery (SKILL.md §2) → goal, MVP slice, stack decisions, **and the glossary** (stack guide §3b).
2. Groundwork writes the **kickoff outputs** (SKILL.md §3): `docs/stack-guide.md` (binding), `CLAUDE.md`, `docs/constitution-seed.md` — and no root `tasks.md` when `.specify/` exists (§3e).
3. `/speckit.constitution` — paste the seed from `docs/constitution-seed.md`. It states principles and declares the stack guide binding. Example argument:
   > "Principles: MVP-first, no file without a stated need. FastAPI + Pydantic v2 + uv; layered routers → services → repositories; typed contracts with RFC 9457 errors; OpenAPI is the single source of truth; secrets only in .env; test-first for endpoints and data; AI changes gated by evals; OWASP web + LLM controls; readable code over clever code; naming conventions per the groundwork skill."
4. Keep the constitution short — it is the *rules*, not the reference manual. It points at this skill for detail.

**Per feature**
5. `/speckit.specify` — behavior and user stories only, no tech. **It must use the glossary's names.** Inventing a friendlier synonym ("Matter" for `Project`) is a defect: it propagates into `data-model.md`, then `contracts/`, and finally into endpoints the frontend doesn't call.
6. `/speckit.clarify` — run it whenever the spec has real ambiguity (it's the same spirit as this kit's Validation mode).
7. `/speckit.plan` — don't retype the stack; point at the file: *"Follow docs/stack-guide.md exactly: FastAPI + Postgres/SQLAlchemy async, Qdrant hybrid + Cohere rerank, React+Vite+TanStack web, typed SSE. Do not introduce libraries outside it."*
8. `/speckit.tasks` → `/speckit.analyze` (for anything non-trivial) → `/speckit.implement`.
9. While implementing, this skill governs *how* each file is written (layering, naming, style, security).
10. `/speckit.converge` until Converged, then run this kit's **code review checklist** (`ops-and-review.md` §8) as the human gate.

**Bugs**: use the `bug` extension; this kit still governs the fix's shape (and the bug becomes a test + a golden-set case if it's AI-related).

## 5. Keeping the two in sync

- `tasks.md`: Spec Kit generates and owns it per feature, at `specs/NNN-<name>/tasks.md`. With Spec Kit, this kit's "read tasks.md first" rule means that file — never a root `tasks.md` alongside it (§3e).
- `CLAUDE.md` / `AGENTS.md`: a short pointer to the stack guide plus commands and conventions — not a second copy of the decisions.
- Don't restate the whole kit inside the constitution — reference it. Long constitutions get ignored by both humans and agents.
- **When a decision changes, the order is fixed:** `docs/stack-guide.md` first (with a change-log line) → then anything that quotes it (`CLAUDE.md`, `plan.md`) → then re-run `/speckit.constitution` only if a *principle* changed, not for a stack swap. The stack guide always wins; everything else points at it.

## 6. When NOT to use Spec Kit

- A one-file script, a spike, or a throwaway prototype — the ceremony costs more than it returns.
- A change small enough that the spec would be longer than the diff.
- In those cases use this kit alone: kickoff → minimal implementation → review checklist.

Conversely, use Spec Kit when the work has **multiple user stories, several sessions, or more than one person** — that's where written specs pay for themselves.
