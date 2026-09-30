# Evals — how Groundwork is measured

Each case is a prompt plus graders, run with and without the plugin on the same model:

```bash
claude plugin eval . --scaffold --trust-plugin                                  # all cases
claude plugin eval . --case surgical-change --scaffold --allow-tools Edit --trust-plugin
```

`--scaffold` runs each case's `fixture.sh` to build a small existing project first (endpoint-routing,
surgical-change). Each case runs 3 times per arm; the Results table below shows the mean.

## Cases

| Case | What it checks | Graders |
|---|---|---|
| `kickoff-discipline` | a new Arabic app: 3-way language profile, options with a recommendation, the kickoff files named, no code | LLM judge + skill-loaded indicator |
| `endpoint-routing` | a streaming endpoint in a scaffolded Groundwork project: stack guide respected, typed events, RFC 9457, task mode | LLM judge + regex (`EventSourceResponse`) + skill-loaded |
| `arabic-rag` | search over Arabic PDFs: cross-lingual retrieval, RRF + reranker, score threshold, per-language evals | LLM judge + skill-loaded |
| `surgical-change` | fix one bug next to a tempting neighbour and unrelated dead code | deterministic: fix landed, neighbour and dead code untouched, test named |

## Results (2026-09-24/26)

Each case runs 3 times with the skill and 3 times without it, on the same model
(`claude plugin eval`). Scores are the mean over 3 runs:

| Case | With | Without |
|---|---|---|
| Kickoff for a new Arabic app: 3-way language profile, options with a recommendation, the kickoff files named | 1.00 | 0.00 |
| Streaming endpoint in an existing Groundwork project: stack guide respected, typed events, native `EventSourceResponse` | 0.67 | 0.00 |
| Search over Arabic PDFs: cross-lingual retrieval, a score threshold, per-language evals | 0.00 | 0.33 |
| Fix one bug next to a tempting neighbour and unrelated dead code: nothing else edited | 1.00 | 1.00 |

## What the numbers mean (2026-09-24/26)

- **Endpoint (0.67 vs 0.00):** all 3 runs with the skill used `EventSourceResponse`, none without; 1 of 3
  passed every criterion — the judge split on the others.
- **Search (0.00 vs 0.33):** the skill did not load on this fresh prompt (0 of 6). Inside a project
  Groundwork set up, its `CLAUDE.md` points at the skill and it loaded 3 of 3.
- **Bug fix (1.00 vs 1.00):** Claude is already surgical on a small fix; the case guards against
  regressions rather than measuring a gain.
- These map to the signals that the change rules are working: fewer unnecessary changes in diffs,
  and clarifying questions before implementation rather than after mistakes.

## The generated CLAUDE.md is measured outside `claude plugin eval`

`claude plugin eval` does not load the project's `CLAUDE.md`: a "start every reply with PINEAPPLE"
`CLAUDE.md` was followed 2 of 2 times by `claude -p` and 0 of 2 inside an eval run (2026-09-26). So the
generated `CLAUDE.md` is A/B-tested through real Claude Code with `claude-md-ab.sh`. With and without
its "How to change code here" block, Claude named the unused function and left it alone 5 of 5 times;
1 of 5 runs without the block edited files beyond the fix, 0 of 5 with it — a small sample, not a
proven gain.
