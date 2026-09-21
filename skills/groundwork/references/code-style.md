# Code Style & Naming — write it like a senior engineer reads it

The reader is a tired engineer at 2am, not a compiler. Optimize for that.

## 1. Principles

1. **Clarity beats cleverness.** If a line needs a comment to explain *what* it does, rewrite the line.
2. **Boring is a feature.** Use the obvious construct; save the clever one for a proven bottleneck.
3. **Small, honest functions.** One job, a name that says the job, ideally under ~30 lines. If you need "and" to describe it, split it.
4. **Shallow nesting.** Guard clauses and early returns instead of pyramids; max ~3 levels.
5. **Names carry the meaning.** `active_subscribers` not `data2`; `retry_after_seconds` not `t`.
6. **Comments explain *why*, never *what*.** Decisions, trade-offs, links to the issue/RFC. Delete commented-out code.
7. **Explicit over implicit.** No magic globals, no hidden side effects, no truthiness tricks on domain objects.
8. **Types are documentation.** Full type hints in Python, `strict` TypeScript, sound Dart types. No `Any`/`any`/`dynamic` without a comment saying why.
9. **Errors are part of the design.** Typed domain errors, never bare `except:` / `catch {}`; never swallow silently.
10. **Delete before you add.** Dead code, unused flags, and "might need later" abstractions are liabilities.

## 2. Naming conventions

**Universal**
- Booleans read as assertions: `is_active`, `has_access`, `can_retry`, `should_refresh`.
- Functions are verbs: `fetch_`, `build_`, `send_`, `parse_`, `ensure_`. Data is nouns.
- Units in the name: `timeout_seconds`, `max_tokens`, `size_bytes`, `price_cents`.
- Async I/O named for what it gets, not that it's async: `get_user()` not `get_user_async` (Python/TS); Dart is the same.
- One concept, one word, forever: pick `user` or `account` and never mix. Keep a glossary in `CLAUDE.md` when the domain has Arabic/English pairs.
- Abbreviations only when universal (`id`, `url`, `db`, `api`). No `usr`, `cfg`, `mgr`.
- Symmetry: `create/delete`, `start/stop`, `open/close`, `encode/decode`.

**Python (backend + AI)**
- `snake_case` functions/vars, `PascalCase` classes, `UPPER_SNAKE` constants, `_private` prefix.
- Modules: short and singular (`config.py`, `agent.py`, `chat.py`); packages plural when a collection (`routers/`, `services/`, `schemas/`).
- Schemas: `<Entity>Create`, `<Entity>Update`, `<Entity>Read`, `Paginated<Entity>`; ORM models are just `<Entity>`.
- Layers named by job: `ChatService`, `ChatRepository`, `chat_router`. Factories: `build_agent()`, `build_retriever()`.
- Tools for the LLM: `snake_case` verbs describing the action (`search_documents`, `get_invoice`) — the name is part of the prompt.
- Tests: `test_<unit>_<condition>_<expected>()` — e.g. `test_create_order_without_stock_returns_409`.
- Exceptions end in `Error`: `QuotaExceededError`. Error codes are stable `snake_case` strings: `quota_exceeded`.

**TypeScript (web)**
- `camelCase` values, `PascalCase` components/types, `UPPER_SNAKE` constants.
- Files: components `PascalCase.tsx`, hooks `useThing.ts`, everything else `kebab-case.ts`.
- Hooks start with `use`; event handlers `handleX` locally, props `onX`.
- Types describe shape, not implementation: `Invoice`, `InvoiceListParams`; avoid the `I` prefix.
- Query keys mirror the API path: `['invoices', 'list', params]`.

**Dart / Flutter (mobile)**
- `lowerCamelCase` members, `UpperCamelCase` classes, `snake_case.dart` files.
- Widgets say what they are: `InvoiceListTile`, `ChatComposer`. Screens end in `Page` or `Screen` — pick one per project.
- Riverpod providers end in `Provider` (`invoiceListProvider`); notifiers end in `Notifier`/`Controller`.
- Mirror the backend names: an endpoint's entity keeps its name across Python → TS → Dart.

**Database & API**
- Tables plural `snake_case` (`chat_messages`); columns `snake_case`; PK `id`; FK `<entity>_id`; timestamps `created_at` / `updated_at` (UTC).
- Indexes `ix_<table>_<cols>`, constraints `uq_/fk_/ck_<table>_<cols>` (deterministic via metadata naming convention).
- REST paths: plural nouns, kebab-case, no verbs — `/api/v1/chat-sessions/{id}/messages`.
- JSON fields `snake_case` on the wire (alias in Pydantic if the frontend prefers camelCase — decide once, in `CLAUDE.md`).
- Env vars `UPPER_SNAKE`, grouped by prefix (`REDIS_`, `LLM_`, `AUTH_`).
- Branches `feat/<slug>`, commits conventional (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).

## 3. Structure habits that keep code readable

- **Top-down**: the public entry point first, helpers below it.
- **One reason to change per module.** A router that imports a DB driver is a smell.
- **Constructor/DI over hidden imports** — makes testing and reading obvious.
- **Pure core, effectful edges**: business rules are pure functions; I/O lives at the boundary.
- **No premature abstraction**: duplicate twice, abstract on the third (and only if the two really are the same thing).
- **Config over conditionals**: environment differences go through settings, not `if env == "prod"` scattered in code.
- **Docstrings on public functions** (what it returns, what it raises) — not on obvious getters. For LLM tools, the docstring is a contract with the model: precise, no fluff.

## 4. Review smells (fix before merge)

- A function whose name lies about what it does.
- A parameter list longer than ~4 — pass an object/dataclass.
- Nested ternaries, walrus-in-comprehension gymnastics, one-letter names outside a 2-line loop.
- `try/except Exception` without re-raise or a typed translation.
- A service importing `HTTPException`, a router touching a DB session, a widget calling an API client.
- Magic numbers and inline strings that appear more than once.
- Comments that repeat the code, TODOs with no owner or date.
- A new file that no stated requirement asked for.
