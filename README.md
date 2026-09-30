# Groundwork

**An AI coding skill that asks before it writes code.**

Groundwork is an [Agent Skill](https://agentskills.io) for Claude Code, Cursor, Codex and other coding
agents. Before the AI writes a line, it asks what you're building, who it's for and what language your
data is in. It writes every decision down in one file, then builds the first working feature on top of
those decisions.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-d97757.svg)](#install)

<p align="center">
  <img src="docs/product-intro.gif" alt="Groundwork in a Claude Code terminal: the request, the interview on the goal and the data's language, BGE-M3 recommended with its reason, the answers written into a binding stack guide, one user story shipped with make check and typed stream events, then the install command" width="960">
  <br>
  <sub>42 seconds, end to end: request → interview → model decision → binding stack guide → shipped user story. Shortened interview, example project.</sub>
</p>

## Why

AI coding tools start writing code the moment you ask. They pick a stack you didn't choose, reach for
libraries you don't use, and forget last week's decisions. Groundwork fixes the order:

1. **It asks first.** A short interview about the goal, the first user and the data. Each question comes
   with a recommendation and its reason, so you can answer "yes", or say no.
2. **It writes the decisions down.** One stack guide holds every choice and why. Later steps follow it
   instead of guessing again.
3. **It builds small.** One feature, end to end, tested. No file, service or library without a reason.

It is built for **API-first, Arabic-first products**: a Python backend with AI, a web app and a Flutter
app, all sharing one API contract.

## Install

Pick **one** route. Both install the same skill, so taking both leaves you with two copies of it.

**Claude Code (plugin):**

```bash
/plugin marketplace add abdelrahmaan/groundwork
/plugin install abdokamar-groundwork
```

If another marketplace on your machine offers a plugin with the same name, install it as
`abdokamar-groundwork@abdokamar`.

**Cursor, Codex and other agents (Skills CLI):**

```bash
npx skills@latest add abdelrahmaan/groundwork
```

Either way you get Markdown instructions and project templates, nothing that runs on its own. The
plugin declares no hooks, MCP servers, LSP servers or agents, sends no telemetry, and makes no network
calls.

<details>
<summary><b>Install details: the two routes</b></summary>

**Claude Code plugin.** A managed, read-only bundle: you subscribe to it, and
`/plugin update abdokamar-groundwork` brings new versions. The first command registers the catalog; the
second enables the plugin from it, and both are needed. This route also installs the `/groundwork`
command, which is what you type day to day; the plugin name is only used at install time.

**Skills CLI.** Copies editable skill files into your project. Works with Claude Code, Codex, Cursor,
OpenCode, and other agents that follow the Agent Skills standard. Two practical differences outside
Claude Code: auto-triggering from the description is less reliable (just say "use groundwork"), and
progressive disclosure varies, so the skill tells the agent explicitly which reference file to open
before each kind of work.

</details>

## Use it

| You type | What happens |
|---|---|
| `/groundwork` | starts the interview for a new project from the first question |
| `/groundwork I want an Arabic-first booking API with a Flutter app` | interview for that product, then the kickoff files |
| `/groundwork add streaming to the chat endpoint` | one task in an existing project: no interview, only the questions the task needs |
| `/groundwork review this branch` | reviews the branch against your project's stack guide |

Inside a project Groundwork set up, it loads on its own. On an existing repo it reads
`docs/stack-guide.md` first, and those decisions override its own defaults. On the Skills CLI route there's no
`/groundwork` command: say "use groundwork" instead.

## What you get

A new project starts with three or four files and nothing else:

| File | What it's for |
|---|---|
| `docs/stack-guide.md` | every decision and its reason, the glossary, open questions, and what was deferred until when. Binding: later steps follow it |
| `CLAUDE.md` | short context for each session; points at the stack guide (`AGENTS.md` links to it for other agents) |
| `docs/constitution-seed.md` | the project's principles, ready for your spec workflow |
| `tasks.md` | the first tasks in order, plus a "Later" list. Skipped when a spec workflow owns the tasks |

Then it builds one user story end to end, creating files only as they're needed.

<details>
<summary><b>The stack it covers</b></summary>

- **Backend + AI — Python**: FastAPI, Pydantic v2, uv, Docker, SQLAlchemy 2.0/Alembic (or SQLModel / MongoDB + Motor), Redis, ARQ/Celery, LangChain `create_agent` / Deep Agents, hybrid RAG (BM25 + dense + RRF + rerank) over Qdrant, pgvector/Supabase, or Azure AI Search, with Prometheus + Grafana when traffic justifies it.
- **Web — React or Next.js**: React + Vite + TanStack by default behind a separate API; Next.js App Router when SEO matters. Tailwind + shadcn/ui, generated client, RTL-first.
- **Mobile — Flutter**: Riverpod, dio, generated Dart client, secure storage, offline, RTL/i18n.
- **One contract**: OpenAPI from FastAPI, RFC 9457 errors, typed SSE streaming events.
- **Any model behind an OpenAI-compatible endpoint**: OpenAI, Azure, LiteLLM or self-hosted vLLM. Switching is a `.env` change, not a code change.
- **Grounded answers that stream with their sources**: `sources` first, the answer as tokens with inline `[n]` markers, then one `citation` per source it actually cited; markers the model invented are dropped.

Every default is a recommendation with a reason, not a requirement. Pick something else and Groundwork
records it in the stack guide and follows that choice's rules.

</details>

<details>
<summary><b>How it works, step by step</b></summary>

```
you: "I want to build X"
  ↓
Discovery interview — goal, first user, success signal, constraints,
                     and a full language/data profile (content language vs question
                     language vs answer language — it decides the embedder)
  ↓  maps the goal to a stack and says the mapping out loud, then waits for your yes
Writes three or four files, nothing else:
  docs/stack-guide.md        ← binding decisions + glossary + rules + deferred items and their triggers
  CLAUDE.md                  ← short session context, points at the stack guide
  tasks.md                   ← MVP tasks + "Later" (skipped when a spec workflow is in use — it owns tasks)
  docs/constitution-seed.md  ← the principles, for your spec workflow's rules slot
  ↓
Build the MVP slice — one user story end to end, files created one at a time as needs appear
```

**Inside an existing project it doesn't interview you.** It reads `docs/stack-guide.md`, `CLAUDE.md` and
the task list, asks only what the task can't be built without, writes anything else it notices into the
stack guide as OPEN, and builds it test-first. With no stack guide, it reads the stack from the code.

**Every project's `CLAUDE.md` carries four change rules**: think first, simplest thing that works,
surgical edits, verifiable results. `AGENTS.md` is a symlink to it, so Cursor, Codex and other agents
follow them too. The same rules are principle 13 of the constitution seed; with Spec Kit that makes them
a gate: `/speckit.plan` runs a Constitution Check that "must pass before Phase 0", and
`/speckit.analyze` marks constitution conflicts CRITICAL (checked in `specify` 1.0.6's own templates).

- **Ask more, guess less:** every unanswered question becomes a guess baked into the foundation; unknowns go to the stack guide's open questions with an owner and a date.
- **MVP first:** no file, service, or dependency without a stated need, a use this week, and nothing simpler that works.
- **Teaching mode:** every step says what, why, the alternative, then the minimal code.
- **Readable code:** small functions, meaningful names, consistent conventions across Python, TypeScript and Dart.

</details>

<details>
<summary><b>With a spec workflow: Spec Kit, OpenSpec, Superpowers, or another</b></summary>

Groundwork doesn't replace your spec workflow. **The workflow owns the process; Groundwork owns the
engineering standard.** It puts a pointer to the stack guide in the workflow's rules slot, so the plan
follows the stack you agreed on instead of inventing one, and it doesn't write a second task list.

| Workflow | Where Groundwork's rules go | Who owns the tasks |
|---|---|---|
| [GitHub Spec Kit](https://github.com/github/spec-kit) | `/speckit.constitution` ← paste `docs/constitution-seed.md` | `specs/NNN-<name>/tasks.md` |
| [OpenSpec](https://github.com/Fission-AI/OpenSpec) | `openspec/config.yaml` → `context:` + per-artifact `rules:` | `openspec/changes/<change>/tasks.md` |
| [Superpowers](https://github.com/obra/superpowers) | `CLAUDE.md` (Superpowers ranks it above its skills) + the plan's Global Constraints | the plan in `docs/superpowers/plans/` |
| anything else | its rules/config slot, or `CLAUDE.md` / `AGENTS.md` if it has none | the workflow's own list |
| none | — | root `tasks.md` |

```
Groundwork discovery  →  docs/stack-guide.md  (+ "which spec workflow?")
       ↓ rules slot points at the stack guide
spec → plan → tasks → implement      ← the workflow's own commands
       ↑ plan obeys the stack guide; it never invents a stack
review gate: the workflow's + Groundwork's review checklist
```

OpenSpec 1.13.2 and Superpowers 6.3.0 were checked against installed copies on 2026-09-24; Spec Kit
against its docs on 2026-09-20. Other workflows get a five-step recipe that is labelled unverified.
Details in [`references/spec-workflows.md`](./skills/groundwork/references/spec-workflows.md) and
[`references/spec-kit.md`](./skills/groundwork/references/spec-kit.md).

</details>

<details>
<summary><b>Updating</b></summary>

New versions don't reach you on their own unless you turn that on.

**Claude Code plugin.** Auto-update is off by default for third-party marketplaces, and a
marketplace can't switch it on for you. Turn it on once, inside a Claude Code session in the
terminal (not the desktop app's Settings → Plugins page, which lists only Anthropic's directory):
run `/plugin`, press Tab to reach **Marketplaces**, select `abdokamar`, then **Enable auto-update**.
There is no shell command for this toggle. After that, each release arrives in the background: the
running session shows `Run /reload-plugins to apply`, and the next session loads it without asking.
To update by hand instead:

```bash
claude plugin update abdokamar-groundwork@abdokamar
```

**Skills CLI.** No automatic updates. Run `npx skills@latest update groundwork` (`-g` for a global install, `-p` for a project one).

**claude.ai.** Re-upload the skill folder for each release.

Installed copies change only when `version` in `.claude-plugin/plugin.json` does. Source: Claude Code
docs, [Keep plugins updated](https://code.claude.com/docs/en/plugins/install.md#keep-plugins-updated),
checked 2026-09-25.

</details>

<details>
<summary><b>What's inside the repo</b></summary>

The skill entry point stays small; the depth loads only when a task needs it.

```
skills/groundwork/
  SKILL.md                        modes, discovery interview, kickoff outputs, MVP gate, decision register
  references/fastapi.md           app factory, lifespan, DI, versioning, DB/migrations, cache, rate limit, jobs, SSE, Locust
  references/langchain-agents.md  models, tools, middleware, context engineering, evals, MCP, Deep Agents
  references/rag-and-data.md      ingestion, Arabic embeddings, hybrid retrieval, reranking, index lifecycle
  references/security.md          auth, OWASP web + LLM, guardrails, secrets
  references/api-contract.md      OpenAPI, RFC 9457, typed SSE event schema
  references/frontend-web.md      React/Vite vs Next.js, state, streaming UI, RTL/i18n, testing, hosting
  references/mobile-flutter.md    architecture, Riverpod, dio, streaming, offline, CI/CD
  references/ops-and-review.md    Makefile, Docker dev/prod, CI, observability, load testing, review checklist
  references/repo-and-kits.md     monorepo vs polyrepo, contract distribution, starter kits
  references/code-style.md        naming conventions and readability rules per language
  references/spec-workflows.md    running alongside any spec workflow (OpenSpec, Superpowers, others)
  references/spec-kit.md          running alongside GitHub Spec Kit
  references/frameworks.md        LangChain vs LlamaIndex vs Haystack vs Pydantic AI vs no framework
  assets/templates/               stack-guide, constitution-seed, Makefile, Dockerfile, compose, .env.example
  assets/CLAUDE.template.md       per-project CLAUDE.md
commands/groundwork.md            the /groundwork slash command
evals/                            eval cases: prompt, graders, and a scaffolded project fixture (results: evals/README.md)
.claude-plugin/                   plugin.json + marketplace.json
```

**Security.** The generated dev Docker stack publishes its ports on `127.0.0.1` only; in prod only the
API port is published. The only scripts in the repo are under `evals/` and run only when a developer
passes `claude plugin eval --scaffold`. Audited 2026-09-26: no hidden Unicode, no secrets in the git
history.

</details>

## Good to know

- **When it loads on its own.** Inside a project Groundwork set up, the `CLAUDE.md` it writes points at
  the skill, and it loads reliably (3 of 3 eval runs, 2026-09-24). On a fresh, single-task request with
  no such `CLAUDE.md` ("build search over our PDFs"), Claude often answers without it (0 of 6): type
  `/groundwork` or say "use groundwork" there.
- **How it's tested.** Eval cases, method and results are in [`evals/README.md`](./evals/README.md).
- **Freshness.** Checked against official docs on 2026-09-20; streaming, structured output and citations
  re-tested against the installed libraries on 2026-09-24. Per-file version floors are noted inside.
  Fast-moving areas (LangChain middleware,
  Spec Kit / OpenSpec / Superpowers commands, TanStack Start, MCP spec, embedding leaderboards) should
  be re-checked before adoption.

## Contributing

Issues are welcome: bug reports, a rule that misfired, a stack you wish it covered. For a pull request,
open an issue first so we agree on the change. Every rule here is measured or sourced, and a rule added
without that tends to contradict another one. CI runs `claude plugin validate --strict` on both
manifests and checks the skill frontmatter; run those locally before a PR:

```bash
claude plugin validate .claude-plugin/marketplace.json --strict
claude plugin validate .claude-plugin/plugin.json --strict
```

## License

MIT — see [LICENSE](./LICENSE).
