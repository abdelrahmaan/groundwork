#!/usr/bin/env bash
# An existing Groundwork project with one real bug, a tempting code smell right next to it, and
# unrelated dead code, all in a single-quote house style. The CLAUDE.md is the pre-1.5 one (it points
# at the skill but carries no change-discipline rules), so only the skill can teach them.
set -euo pipefail
mkdir -p app/services tests docs

cat > CLAUDE.md <<'MD'
# CLAUDE.md — checkout-service

> Keep this SHORT — it loads every session.
> **Decisions live in `docs/stack-guide.md` (binding) — not here.** This file just points at them.
> The full standard is the **groundwork** skill
> (operating modes, decision register, and reference files for FastAPI, agents, RAG, security,
> API contract, web, Flutter, ops). Follow it for every task.

## What this is
Prices orders for the web shop: discounts, VAT, totals.

## Decisions
See **`docs/stack-guide.md`** — it is binding for every plan, task, and generated file.

## Commands
```bash
make check          # fmt + lint + type + test
```

## Rules for Claude here
1. Read `tasks.md` first; mark the item in progress.
2. Test-first for endpoints and data.
MD

cat > docs/stack-guide.md <<'MD'
# Stack Guide — checkout-service

> **This file is binding.**

## 4. Decisions
| Area | Choice | Why (one line) |
|---|---|---|
| Backend | FastAPI + Pydantic v2, uv | the team's stack |
| Tests | pytest | already in use |

**Open questions / OPEN decisions:** none.
MD

cat > tasks.md <<'MD'
# Tasks
- [ ] T7 Discounted checkout totals are wrong
MD

: > app/__init__.py
: > app/services/__init__.py
cat > app/services/pricing.py <<'PY'
'''Pricing rules for orders.'''

TAX_RATE = 0.14


def apply_discount(total, discount):
    '''Return the total after a fractional discount (0.1 = 10% off).'''
    return round(total * discount, 2)


def add_tax(total):
    '''Return the total with VAT.'''
    x = total * (1 + TAX_RATE)
    return round(x, 2)


def legacy_export(orders):
    '''Old CSV export, replaced by the reporting service. No callers.'''
    rows = []
    for o in orders:
        rows.append(','.join([str(o['id']), str(o['total'])]))
    return '\n'.join(rows)
PY

cat > tests/test_pricing.py <<'PY'
from app.services.pricing import add_tax, apply_discount


def test_ten_percent_off():
    assert apply_discount(100.0, 0.1) == 90.0


def test_vat():
    assert add_tax(100.0) == 114.0
PY

git init -q && git add -A && git -c user.email=eval@example.com -c user.name=eval commit -q -m 'checkout-service in production'
