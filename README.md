# Groundwork

An [Agent Skill](https://agentskills.io) that does the work **before** the code: it interviews you
about the goal, picks the stack with you, writes a binding stack guide, then builds an MVP slice to
a production standard.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-d97757.svg)](#claude-code--as-a-plugin)

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

## Use it

The skill fires on its own when a task matches its triggers — a new project, a new endpoint, a
chatbot, a Flutter app, a code review. To call it directly:

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
Writes four files, nothing else:
  docs/stack-guide.md        ← binding decisions + rules + deferred items and their triggers
  CLAUDE.md                  ← short session context, points at the stack guide
  tasks.md                   ← MVP tasks + "Later"
  docs/constitution-seed.md  ← paste-ready text for /speckit.constitution
  ↓
Build the MVP slice — one user story end to end, files created one at a time as needs appear
```

**Ask more, guess less:** every unanswered question becomes a guess baked into the foundation; unknowns go to the stack guide's open-questions list with an owner and a date.
**MVP first:** no file, service, or dependency exists without a stated need, a use this week, and nothing simpler that works.
**Teaching mode:** every step says what, why, the alternative, then the minimal code.
**Readable code:** small functions, meaningful names, consistent conventions across Python, TypeScript, and Dart.

## With GitHub Spec Kit

They compose: **Spec Kit owns the process, Groundwork owns the engineering standard.**

```
Groundwork discovery  →  docs/stack-guide.md
/speckit.constitution →  paste docs/constitution-seed.md
/speckit.specify → clarify → plan → tasks → implement → converge
                      ↑ plan obeys the stack guide; it never invents a stack
```

Details in [`references/spec-kit.md`](./skills/groundwork/references/spec-kit.md).

## Opinions it holds (and why)

- **LangChain `create_agent` for the agent layer, your own code for retrieval.** Frameworks earn their place on the hard generic part (tool loop, state, interrupts, streaming); they cost you on the part that's specific to you (chunking, hybrid fusion, Arabic normalization). Full comparison with LlamaIndex, Haystack, Pydantic AI and DSPy in [`references/frameworks.md`](./skills/groundwork/references/frameworks.md).
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
  references/spec-kit.md          running alongside GitHub Spec Kit
  references/frameworks.md        LangChain vs LlamaIndex vs Haystack vs Pydantic AI vs no framework
  assets/templates/               stack-guide, constitution-seed, Makefile, Dockerfile, compose, .env.example
  assets/CLAUDE.template.md       per-project CLAUDE.md
commands/groundwork.md            the /groundwork slash command
.claude-plugin/                   plugin.json + marketplace.json
```

## Contributing

Issues and pull requests are welcome. CI runs `claude plugin validate --strict` on both manifests
and checks every skill's frontmatter budget, so run those locally before opening a PR:

```bash
claude plugin validate .claude-plugin/marketplace.json --strict
claude plugin validate .claude-plugin/plugin.json --strict
```

## Notes

Verified against official docs on 2026-09-20; per-file version floors noted inside. Fast-moving
areas (LangChain middleware, Spec Kit commands, TanStack Start, MCP spec, embedding leaderboards)
should be re-checked before adoption.

## License

MIT — see [LICENSE](./LICENSE).
