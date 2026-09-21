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
- Key artifacts: the constitution, `spec.md`, `plan.md`, `tasks.md`, checklists.

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

## 4. The combined workflow

**Once per project**
1. Run Discovery (SKILL.md §2) → goal, MVP slice, stack decisions.
2. Groundwork writes the **four kickoff outputs** (SKILL.md §3): `docs/stack-guide.md` (binding), `CLAUDE.md`, `tasks.md`, `docs/constitution-seed.md`.
3. `/speckit.constitution` — paste the seed from `docs/constitution-seed.md`. It states principles and declares the stack guide binding. Example argument:
   > "Principles: MVP-first, no file without a stated need. FastAPI + Pydantic v2 + uv; layered routers → services → repositories; typed contracts with RFC 9457 errors; OpenAPI is the single source of truth; secrets only in .env; test-first for endpoints and data; AI changes gated by evals; OWASP web + LLM controls; readable code over clever code; naming conventions per the groundwork skill."
4. Keep the constitution short — it is the *rules*, not the reference manual. It points at this skill for detail.

**Per feature**
5. `/speckit.specify` — behavior and user stories only, no tech.
6. `/speckit.clarify` — run it whenever the spec has real ambiguity (it's the same spirit as this kit's Validation mode).
7. `/speckit.plan` — don't retype the stack; point at the file: *"Follow docs/stack-guide.md exactly: FastAPI + Postgres/SQLAlchemy async, Qdrant hybrid + Cohere rerank, React+Vite+TanStack web, typed SSE. Do not introduce libraries outside it."*
8. `/speckit.tasks` → `/speckit.analyze` (for anything non-trivial) → `/speckit.implement`.
9. While implementing, this skill governs *how* each file is written (layering, naming, style, security).
10. `/speckit.converge` until Converged, then run this kit's **code review checklist** (`ops-and-review.md` §8) as the human gate.

**Bugs**: use the `bug` extension; this kit still governs the fix's shape (and the bug becomes a test + a golden-set case if it's AI-related).

## 5. Keeping the two in sync

- `tasks.md`: Spec Kit generates and owns it per feature. This kit's "read tasks.md first" rule points at the same file — don't create a second one.
- `CLAUDE.md` / `AGENTS.md`: your durable project context (decisions, commands, conventions). The constitution is the enforceable subset. Some duplication is fine; the constitution wins in `analyze`.
- Don't restate the whole kit inside the constitution — reference it. Long constitutions get ignored by both humans and agents.
- When a decision changes (e.g. you swap the vector store), update `CLAUDE.md` first, then re-run `/speckit.constitution` if it's a principle-level change.

## 6. When NOT to use Spec Kit

- A one-file script, a spike, or a throwaway prototype — the ceremony costs more than it returns.
- A change small enough that the spec would be longer than the diff.
- In those cases use this kit alone: kickoff → minimal implementation → review checklist.

Conversely, use Spec Kit when the work has **multiple user stories, several sessions, or more than one person** — that's where written specs pay for themselves.
