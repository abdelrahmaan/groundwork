# Constitution seed — <project_name>

Paste the block below as the argument to `/speckit.constitution` (Copilot skills mode: `/speckit-constitution`).
Keep it short: a constitution is the enforceable rules, not the manual. The detail stays in
`docs/stack-guide.md` and the **groundwork** skill.

---

```text
/speckit.constitution Principles for <project_name>:

1. MVP first — build the smallest slice that proves the goal. No file, service, or dependency
   without a stated need, a use this week, and nothing simpler that works. Deferred items and their
   triggers are listed in docs/stack-guide.md; do not pull them forward.
2. The stack is already decided — docs/stack-guide.md is binding. Plans and tasks implement those
   decisions; they never introduce a different database, framework, model, or library. If a decision
   looks wrong, stop and raise it instead of silently changing it.
3. Layered architecture — routers stay thin, business logic lives in services, data access lives in
   repositories. External clients are created once in the application lifespan through factories.
4. Typed contracts — every endpoint declares a response model; OpenAPI is the single source of truth;
   clients are generated from it; errors use RFC 9457 problem+json with a stable code and a trace id.
5. Secrets only in .env, never in code, logs, or prompts. .env.example stays current in the same commit.
6. Test-first for endpoints and data tasks. AI behavior changes require an eval run against the golden
   set before they are considered done.
7. Security by default — deny-by-default authorization derived server-side; OWASP web and LLM controls
   as described in the groundwork skill.
8. Readable over clever — small honest functions, guard clauses, meaningful names, comments that explain
   why. Naming conventions follow the groundwork skill's code-style rules, consistently across Python,
   TypeScript, and Dart.
9. Every command goes through the Makefile; make check must pass before a task is complete.
10. Documentation is part of done — update tasks.md every task, and README/CLAUDE.md/.env.example when
    they are affected.
```

---

## After running it

- Check that the generated constitution actually mentions the stack-guide as binding. If it paraphrased it away, re-run with that line emphasized.
- When a decision changes: update `docs/stack-guide.md` first, then re-run `/speckit.constitution` only if a *principle* changed (not for a stack swap — that lives in the stack guide).
- `/speckit.plan` argument should reference the file rather than repeat it:
  > "Follow docs/stack-guide.md exactly: <one-line summary of the stack>. Do not introduce libraries outside it."
