# Repo Strategy, Contract Distribution & Starter Kits

## 1. One contract across backend, web and mobile

**OpenAPI is the single source of truth.** FastAPI generates it from Pydantic models; every client is generated from it.

- Backend exports `openapi.json` in CI as a build artifact (and optionally publishes it to a `contracts/` package or a URL).
- **Web**: Hey API (`@hey-api/openapi-ts`) → typed client + TanStack Query hooks + Zod schemas.
- **Mobile**: `openapi-generator` (dart-dio) or `swagger_dart_code_generator` → typed Dart client used behind repositories.
- **Versioning**: semver the spec; a breaking change means a new URL version (`/api/v2`) and a deprecation window for v1 (see `fastapi.md` §5).
- **Contract testing**: **Schemathesis** (property-based, FastAPI-native — the strongest pick here); Dredd or Pact if you need consumer-driven contracts across teams.
- CI gate: diff the committed `openapi.json` snapshot on every PR. A silent contract change should fail the build, not surprise a shipped mobile app.
- Regeneration is a make target (`make gen-clients`) that runs in CI, so no one hand-edits generated code.

## 2. Shared conventions (identical across web and mobile)

| Concern | Standard |
|---|---|
| Errors | RFC 9457 problem+json with stable `code` + `trace_id` |
| Auth | web: memory access token + HttpOnly refresh cookie · mobile: bearer in secure storage |
| Pagination | cursor by default (`{items, next_cursor}`); offset only for small admin lists |
| Dates | UTC + ISO-8601 on the wire; localize only at display |
| i18n keys | shared namespace per feature; ARB (Flutter) and JSON (web) generated from the same source where possible |
| Analytics | one event schema (name, props) shared by both clients |
| Streaming | the typed SSE event contract in `api-contract.md` |
| Idempotency | `Idempotency-Key` header on retryable POSTs |

## 3. Monorepo vs polyrepo (solo engineer)

For a solo dev with backend + web + mobile that share types/contracts, a **monorepo with pnpm workspaces + Turborepo** is pragmatic: atomic cross-cutting changes, one source of truth, shared conventions. **Turborepo beats Nx** for a solo/small setup (simpler, works with existing scripts).

But polyrepo has faster PR cycles and full isolation. If the three stacks (Python / TS / Dart) rarely change together, polyrepo is also defensible — and note Turborepo/Nx are TS-centric and won't manage the Python/Dart builds anyway.

**Pragmatic middle (the kit default): monorepo for web + shared TS contract, separate repos for FastAPI and Flutter, linked by the published OpenAPI spec.**

```
web-monorepo/          apps/web, packages/api-client (generated), packages/ui, packages/config
backend-repo/          FastAPI + uv + Makefile + Docker (publishes openapi.json)
mobile-repo/           Flutter + generated Dart client
```
Whatever the layout: one `CLAUDE.md`/`AGENTS.md` per repo, one Makefile per repo, one CI pipeline per repo.

## 4. Starter kits worth borrowing from

- **fastapi/full-stack-fastapi-template** (official, MIT) — FastAPI + SQLModel + PostgreSQL + Alembic + React/TS/Vite + Tailwind/shadcn/ui + uv + Docker Compose + Playwright + JWT.
  *Good:* authoritative, modern, batteries-included; the best convention reference for decoupled React ↔ FastAPI. *Bad:* opinionated toward SQLModel/React/Postgres.
  https://github.com/fastapi/full-stack-fastapi-template
- **T3 stack (create-t3-app)** — Next.js + TS + Tailwind + optional tRPC/Prisma/NextAuth. Deliberately co-locates FE+BE in one Next app; tRPC type-safety depends on shared TS, so it is **not a fit for a separate FastAPI backend** (you'd lose tRPC's benefit and run two backends). Borrow its modular-CLI philosophy only. https://create.t3.gg
- **Flutter — Very Good CLI (VGV)** — v1.0.0, Bloc layered architecture, Very Good Analysis lints, flavors, 100%-coverage CI, multi-platform. *Good:* production conventions; *Bad:* Bloc-opinionated (swap for Riverpod), minimal template. Also see `guilherme-v/flutter-clean-architecture-example` (cross-state-management reference) and `ntminhdn/Flutter-Bloc-CleanArchitecture` (full production stack: auto_route, get_it/injectable, dio, objectbox, freezed). https://verygood.ventures
- **Next.js SaaS starters** — `ixartz/SaaS-Boilerplate` (Next.js + React + Tailwind + shadcn + Clerk + Drizzle + Stripe + multi-tenancy/RBAC/i18n) is the most complete free option; Vercel's minimal `nextjs/saas-starter` (Postgres + Drizzle + Stripe) is the cleaner "no magic" reference. https://github.com/ixartz/SaaS-Boilerplate

**How to use them:** read them for conventions (folder layout, CI, Docker, auth wiring) — don't fork them wholesale. This kit's decisions win where they differ.

## 5. AI-assisted development conventions

- Ship standards as **SKILL.md** files following the Agent Skills standard (agentskills.io) — portable across Claude Code, Codex, Cursor, Copilot, Gemini CLI. Required frontmatter: `name` + `description` (a wrong/missing description means the skill silently never triggers).
- **AGENTS.md** is the cross-tool project-context file; Claude Code reads **CLAUDE.md**. Keep one file and symlink the other (`ln -s AGENTS.md CLAUDE.md`).
- Per repo: short `CLAUDE.md` (decisions + commands + conventions) that points at this skill; the long-form standard stays in the skill.
- Keep `tasks.md` as the work log the agent reads first.
