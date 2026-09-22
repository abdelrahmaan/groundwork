# Web Frontend Standard (decoupled, Arabic-first)

The backend is a separate FastAPI service. The frontend is a **client of an external API** — that single fact drives every choice below.

## Contents
1. Framework choice
2. Project structure
3. API client (generated)
4. Data & state
5. Forms & validation
6. Streaming AI responses
7. Auth in a decoupled app
8. UI, accessibility, RTL & i18n
9. Performance
10. Testing
11. Errors & observability
12. Build, CI/CD & hosting

---

## 1. Framework choice

**Default: React + Vite + TanStack Router + TanStack Query (SPA).**
Why: behind auth there is no SEO to win and no server to share; an SPA is smaller, faster to iterate, host-neutral, and removes the "is this server or client code?" tax. React keeps the largest hiring pool and the best AI-assistant coverage. (Create React App is deprecated; React's own docs point SPA projects to Vite.)

| Choose instead | When |
|---|---|
| **Next.js (App Router)** | public marketing/SEO pages, ISR content, link previews, or you want one framework for everything. Use it for those surfaces and keep the authed app an SPA |
| **TanStack Start** | you want SSR + end-to-end type-safe routing but SPA-first defaults and host neutrality. Younger ecosystem (v1 landed early 2026) |
| **Nuxt** | you are a Vue shop |
| **SvelteKit** | smallest bundles, best DX ratings, small surface area |
| **Astro** | content/marketing/docs sites — not app shells |
| **Remix / React Router v7** | web-standards SSR preference |

Rule of thumb: **SSR earns its complexity only when an anonymous visitor or a crawler must see rendered content.**

## 2. Project structure

- **Feature-first colocation**: `src/features/<feature>/{components,hooks,api,types,__tests__}`; shared primitives in `src/components/ui`, cross-cutting in `src/lib`.
- File-based routing (TanStack Router / Next App Router); route-level code splitting.
- `src/api/` holds only the **generated** client + thin wrappers; no feature imports `fetch` directly.
- Path aliases (`@/…`), strict TypeScript (`strict: true`, `noUncheckedIndexedAccess`).

## 3. API client — generated from OpenAPI

**Recommendation: Hey API (`@hey-api/openapi-ts`)** — plugin-based, emits the client plus TanStack Query hooks and Zod/Valibot schemas for runtime validation.
Alternatives: **openapi-typescript + openapi-fetch** (types-only, zero runtime — note openapi-fetch/openapi-react-query moved to maintenance mode), **Orval** (batteries-included, mocks), **Kubb** (most modular).
- Generation is a `make gen-client` / `pnpm gen:api` step wired to CI; the generated folder is committed or built on install — pick one and never hand-edit it.
- The spec comes from the running backend or a published `openapi.json` artifact (see `repo-and-kits.md`).
- A breaking spec change should break the TypeScript build. That's the point.

## 4. Data & state

- **TanStack Query** owns all server state: caching, retries, invalidation, optimistic updates, pagination/infinite queries. Query keys mirror the resource path.
- **Zustand** for the small amount of genuine client state (UI mode, wizard step, chat draft). **Jotai** only for atomic fine-grained state.
- Never duplicate server data into a global store — that's the #1 source of stale-UI bugs.
- Redux/RTK Query only in an existing Redux codebase.

## 5. Forms & validation

- **React Hook Form + Zod** (or Valibot for bundle size). Schemas generated from OpenAPI where possible so backend and frontend agree.
- Validate on blur/submit, not on every keystroke; map server-side field errors (RFC 9457 `errors[]`) onto form fields.

## 6. Streaming AI responses

- `EventSource` is **GET-only** → for POST chat use **fetch + ReadableStream** or `@microsoft/fetch-event-source`.
- Parse the backend's typed events (`run_started`, `token`, `tool_call`, `tool_result`, `citation`, `interrupt`, `error`, `done`) into UI state machines. One reducer, not scattered `useState`.
- Append tokens functionally (`setText(prev => prev + delta)`) to avoid stale-closure bugs; batch renders (rAF or small interval) for long streams.
- **AbortController** on unmount/cancel → the backend detects disconnect and stops billing tokens.
- Persist completed messages server-side always; add **Last-Event-ID resume** only when a requirement asks for it (it needs a Redis chunk buffer).
- Render markdown progressively; render citations as chips linked to sources; show tool calls as status rows; `interrupt` events open the approve/edit/reject UI.
- Measure **TTFT** as the headline UX metric.
- Shortcut: **Vercel AI SDK UI `useChat`** handles the fetch-and-parse loop if you adopt its stream protocol end to end. Hand-roll when you want your own event schema (the default here).

## 7. Auth in a decoupled app

- **Access token in memory + refresh token in an HttpOnly, Secure, SameSite cookie** scoped to the auth endpoint. Never localStorage (XSS-exfiltratable).
- One in-flight refresh promise shared by all 401s; queue and replay the failed requests.
- Short access-token lifetime (~15 min), rotating refresh tokens, server-side revocation list.
- CSRF: SameSite=Strict/Lax + a CSRF token on cookie-authenticated mutations.
- Providers: Clerk (fastest solo DX), Auth0, Entra ID (Azure-centric). Their SDKs already implement the above — prefer them over hand-rolling.
- Never make authorization decisions in the frontend; the UI hides what the API already forbids.

## 8. UI, accessibility, RTL & i18n

- **Tailwind v4 + shadcn/ui (Radix primitives)**: accessible behavior, own-your-code components, `dir`-aware. Mantine is the batteries-included alternative.
- **RTL rules (required once the project's language profile includes an RTL language):**
  - Set `dir` on `<html>` from the active locale; never hardcode `ltr`.
  - Use **logical properties** everywhere: `ms-*/me-*/ps-*/pe-*`, `text-start/text-end`, `border-s/border-e`. Physical `left/right` only for things that truly don't mirror.
  - Mirror directional icons (`rtl:rotate-180` / swap chevrons), not logos or media controls.
  - Wrap embedded LTR runs (emails, URLs, English terms, code) in `<bdi>`; format numbers/dates with `Intl` and the active locale.
  - Test with **real Arabic copy**, not mirrored Latin — line height, font fallback and bidi bugs only show up with real script.
  - Load Arabic webfonts (Cairo / Tajawal / Noto Naskh) only for the Arabic locale; `font-display: swap`.
- **i18n**: `next-intl` (Next.js) or `i18next`/`react-i18next` (Vite). One locale config drives router, `dir`, fonts, `hreflang`, and date/number formatting. Keys are namespaced by feature and shared with mobile where possible.
- **a11y baseline**: semantic HTML, visible focus, keyboard paths for every action, labelled inputs, contrast ≥ 4.5:1, `aria-live` for streaming answers.

## 9. Performance

- Targets: LCP < 2.5s, INP < 200ms, CLS < 0.1.
- Route-level code splitting; lazy-load heavy widgets (markdown renderer, charts, editor).
- Responsive images + modern formats; explicit width/height to avoid CLS.
- Bundle budget enforced in CI (`vite-bundle-visualizer` / size-limit); watch icon and date libraries.
- Virtualize long lists/message histories.

## 10. Testing (what a solo dev actually maintains)

- **Vitest + React Testing Library** for logic and critical components (forms, the streaming reducer, auth refresh).
- **Playwright** for a handful of E2E happy paths: login → main flow → chat stream → logout. Run in CI on PR.
- MSW (or the generated mocks) to stub the API; contract fidelity comes from the generated types.
- Skip: snapshot-everything, 100% coverage, testing library internals.

## 11. Errors & observability

- React **error boundaries** per route + a global fallback.
- Map **RFC 9457 problem+json** to UI: switch on `code`, show `title`/`detail`, attach `errors[]` to fields, surface `trace_id` in the "report a problem" affordance.
- **Sentry** (or equivalent) for FE errors + performance; tag releases; scrub PII.
- Log the `trace_id` returned by the API so one ID links browser → backend → LLM trace.

## 12. Build, CI/CD & hosting

- Vite build → static assets. Host on **Cloudflare Pages / Netlify / Vercel**, or self-host with **Docker + nginx** (trivial for an SPA; set long cache headers on hashed assets, `no-cache` on `index.html`).
- Env vars are build-time for SPAs (`VITE_*`) — never put secrets in them; the API base URL and public keys only.
- CI: typecheck → lint (ESLint + Prettier or Biome) → unit tests → build (bundle budget) → Playwright → deploy preview per PR.
- Next.js deployments: Vercel for best DX, or `output: "standalone"` in Docker for self-hosting.
