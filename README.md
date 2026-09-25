# Groundwork

An [Agent Skill](https://agentskills.io) that does the work **before** the code: it interviews you
about the goal, picks the stack with you, writes a binding stack guide, then builds an MVP slice to
a production standard.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-d97757.svg)](#claude-code--as-a-plugin)

<p align="center">
  <img src="docs/technical-demo.gif" alt="Groundwork end to end: the interview asks the goal and the data's language, recommends BGE-M3 with its reason, writes a binding stack guide, ships one user story with make check and typed stream events, then hands off to Spec Kit" width="960">
  <br>
  <sub>60 seconds, end to end: interview → output files → shipped MVP slice → Spec Kit handoff. Shortened interview, example project.</sub>
</p>

Built for **API-first, Arabic-first products**:

- **Backend + AI — Python**: FastAPI, Pydantic v2, uv, Docker, SQLAlchemy 2.0/Alembic (or SQLModel / MongoDB + Motor), Redis, ARQ/Celery, LangChain `create_agent` / Deep Agents, hybrid RAG (BM25 + dense + RRF + rerank) over Qdrant, pgvector/Supabase, or Azure AI Search, with Prometheus + Grafana when traffic justifies it.
- **Web — React or Next.js**: React + Vite + TanStack by default behind a separate API; Next.js App Router when SEO matters. Tailwind + shadcn/ui, generated client, RTL-first.
- **Mobile — Flutter**: Riverpod, dio, generated Dart client, secure storage, offline, RTL/i18n.
- **One contract**: OpenAPI from FastAPI, RFC 9457 errors, typed SSE streaming events.

## Install

Pick **one** of the two routes. They install the same skill, so taking both leaves you with two
copies of it.

### Claude Code — as a plugin

```bash
/plugin marketplace add abdelrahmaan/groundwork
/plugin install abdokamar-groundwork
```

A managed, read-only bundle: you subscribe to it, and `/plugin update abdokamar-groundwork` brings
new versions. This route also installs the `/groundwork` command, which is what you type day to day
— the plugin name is only used at install time.

The first command registers the catalog; the second enables the plugin from it. Both are needed.
If another marketplace on your machine also offers a plugin by this name, disambiguate with
`abdokamar-groundwork@abdokamar`.

### Any other agent — with the Skills CLI

```bash
npx skills@latest add abdelrahmaan/groundwork
```

Copies editable skill files into your project. Works with Claude Code, Codex, Cursor, OpenCode, and
other agents that follow the Agent Skills standard. Update with `npx skills@latest update groundwork`.

Two practical differences outside Claude Code: auto-triggering from the description is less reliable
(just say "use groundwork"), and progressive disclosure varies — so the skill tells the agent
explicitly which reference file to open before each kind of work.

### Updating

New versions don't reach you on their own unless you turn that on.

**Claude Code plugin.** Auto-update is off by default for third-party marketplaces, and a
marketplace can't switch it on for you. Turn it on once, inside a Claude Code session in the
terminal (not the desktop app's Settings → Plugins page, which lists only Anthropic's directory):
run `/plugin`, press Tab to reach **Marketplaces**, select `abdokamar`, then **Enable auto-update**.
There is no shell command for this toggle. After that, each release
arrives in the background: the running session shows `Run /reload-plugins to apply`, and the next
session loads it without asking. To update by hand instead:

```bash
claude plugin update abdokamar-groundwork@abdokamar
```

**Skills CLI.** No automatic updates. Run `npx skills@latest update groundwork` (`-g` for a global
install, `-p` for a project one).

**claude.ai.** Re-upload the skill folder for each release.

Releases bump `version` in `.claude-plugin/plugin.json`; installed copies only change when that
number does. Source: Claude Code docs,
[Keep plugins updated](https://code.claude.com/docs/en/plugins/install.md#keep-plugins-updated),
checked 2026-09-25.

## Use it

Inside a project Groundwork set up, it loads on its own: the `CLAUDE.md` it writes points at it. For
a brand-new project, or a single task in a repo it didn't set up, call it directly:

```
/groundwork I want an Arabic-first booking API with a Flutter app
/groundwork add streaming to the chat endpoint
/groundwork review this branch
```

Called with no argument, it starts the discovery interview from the first question. On an existing
repo it reads `docs/stack-guide.md` first, and those decisions override its own defaults.

The `/groundwork` command ships with the plugin route only. On the Skills CLI route, ask for the
skill by name instead.

## What happens when you call it

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

**Inside an existing project it doesn't interview you.** A request like "add a streaming endpoint"
is one task: it reads `docs/stack-guide.md`, `CLAUDE.md` and the task list, asks only what the task
can't be built without, writes anything else it notices into the stack guide as OPEN, and builds it
test-first.

**Ask more, guess less:** every unanswered question becomes a guess baked into the foundation; unknowns go to the stack guide's open-questions list with an owner and a date.
**MVP first:** no file, service, or dependency exists without a stated need, a use this week, and nothing simpler that works.
**Teaching mode:** every step says what, why, the alternative, then the minimal code.
**Readable code:** small functions, meaningful names, consistent conventions across Python, TypeScript, and Dart.

## With a spec workflow — Spec Kit, OpenSpec, Superpowers, or another

Groundwork doesn't replace your spec workflow. It plugs into it: **the workflow owns the process,
Groundwork owns the engineering standard.** Every spec workflow has a place for standing rules. Groundwork
puts a pointer to the binding stack guide there, so the plan follows the stack you agreed on instead of
inventing one. The workflow keeps its own task list, and Groundwork doesn't write a second one.

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
against its docs on 2026-09-20. Other workflows get a five-step recipe that is labelled unverified. Details
in [`references/spec-workflows.md`](./skills/groundwork/references/spec-workflows.md) and
[`references/spec-kit.md`](./skills/groundwork/references/spec-kit.md).

## Opinions it holds (and why)

- **LangChain `create_agent` for the agent layer, your own code for retrieval.** Frameworks earn their place on the hard generic part (tool loop, state, interrupts, streaming); they cost you on the part that's specific to you (chunking, hybrid fusion, Arabic normalization). Full comparison with LlamaIndex, Haystack, Pydantic AI and DSPy in [`references/frameworks.md`](./skills/groundwork/references/frameworks.md).
- **Grounded answers stream with their sources.** Retrieval sends `sources` first, the answer streams
  as `token`s with inline `[n]` markers, then one `citation` per source actually cited, then `done`.
  Markers the model invented are dropped. Structured output is kept out of the stream on purpose:
  `with_structured_output` with a Pydantic schema returns once, at the end, and through
  `create_agent` it streams as raw JSON (tested on LangChain 1.4.2, 2026-09-24).
- **Every model behind an OpenAI-compatible endpoint** — OpenAI, Azure, LiteLLM, or self-hosted vLLM are a `.env` change, not a code change.

## What's inside

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
evals/                            eval cases: prompt, graders, and a scaffolded project fixture
.claude-plugin/                   plugin.json + marketplace.json
```

## Does it help? Measured

Each case runs 3 times with the skill and 3 times without it, on the same model
(`claude plugin eval`, 2026-09-24/25):

| Case | Score with | Score without |
|---|---|---|
| Kickoff for a new Arabic app: 3-way language profile, options with a recommendation, the kickoff files named | 1.00 | 0.00 |
| Streaming endpoint in an existing Groundwork project: stack guide respected, typed events, native `EventSourceResponse` | 0.67 | 0.00 |
| Search over Arabic PDFs, sharpened to cross-lingual retrieval, a score threshold, per-language evals | 0.00 | 0.33 |

Scores are the mean over 3 runs. On the endpoint case, all 3 runs with the skill used
`EventSourceResponse` (none without it); 1 of 3 passed every criterion.

The last row is the known gap: on a fresh prompt with no Groundwork `CLAUDE.md`, the skill didn't
load (see Notes).

```bash
claude plugin eval . --scaffold --trust-plugin   # --scaffold builds the existing-project fixture
```

## Contributing

Issues and pull requests are welcome. CI runs `claude plugin validate --strict` on both manifests
and checks every skill's frontmatter budget, so run those locally before opening a PR:

```bash
claude plugin validate .claude-plugin/marketplace.json --strict
claude plugin validate .claude-plugin/plugin.json --strict
```

## Notes

**When the skill loads on its own.** Inside a project Groundwork set up, the `CLAUDE.md` it writes
points at the skill, and it loads reliably (3 of 3 eval runs, 2026-09-24). On a fresh, single-task
request with no such `CLAUDE.md` ("build search over our PDFs"), Claude often answers without it (0
of 6) — type `/groundwork` or say "use groundwork" there.

Verified against official docs on 2026-09-20; streaming, structured output and citations were re-tested
against the installed libraries on 2026-09-24, and OpenSpec 1.13.2 / Superpowers 6.3.0 against installed
copies the same day. Per-file version floors are noted inside. Fast-moving
areas (LangChain middleware, Spec Kit / OpenSpec / Superpowers commands, TanStack Start, MCP spec, embedding leaderboards)
should be re-checked before adoption.

## License

MIT — see [LICENSE](./LICENSE).
