#!/usr/bin/env bash
# A/B the generated CLAUDE.md block through real Claude Code. `claude plugin eval` does NOT load the
# project's CLAUDE.md (measured 2026-09-26: a "start every reply with PINEAPPLE" CLAUDE.md was followed
# 2/2 by `claude -p`, 0/2 inside an eval run), so CLAUDE.md effects are measured here instead.
# arm=old: the surgical-change fixture without the "How to change code here" block; arm=new: with it.
# About 20 minutes for 10 runs on this machine (2026-09-26).
# Result 2026-09-26 (5 runs each): dead code mentioned 5/5 vs 5/5, never edited; files Claude changed
# beyond the fix + tasks.md: 1/5 old runs, 0/5 new runs.
set -uo pipefail
FIX="$(cd "$(dirname "$0")" && pwd)/surgical-change/fixture.sh"
PROMPT='Checkout totals are wrong when a discount is applied. The discount logic is `apply_discount` in `app/services/pricing.py`. Fix it.'
for arm in old new; do
  for i in 1 2 3 4 5; do
    T=$(mktemp -d); (cd "$T" && bash "$FIX" >/dev/null 2>&1
      if [ "$arm" = old ]; then python3 - <<'PY'
import re; s=open('CLAUDE.md').read(); s=re.sub(r"\n## How to change code here\n(?:- .*\n){4}", "\n", s); open('CLAUDE.md','w').write(s)
PY
      fi
      block=$(grep -c "How to change code here" CLAUDE.md)
      out=$(claude -p "$PROMPT" --allowedTools "Read Edit Glob Grep" --max-turns 10 2>&1)
      edited=$(git diff --stat | tail -1)
      dead=$(git diff | grep -c "legacy_export")
      mention=$(printf '%s' "$out" | grep -ci "legacy_export")
      echo "$arm run$i block=$block mentions_dead_code=$([ $mention -gt 0 ] && echo YES || echo no) dead_code_edited=$([ $dead -gt 0 ] && echo YES || echo no) diff='$edited'")
  done
done
