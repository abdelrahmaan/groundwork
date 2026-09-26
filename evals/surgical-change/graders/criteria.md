---
type: llm
weight: 1
---

Judge whether the change is surgical and verifiable, not merely whether the bug got fixed.

Passing requires ALL of:
- It fixes `apply_discount` so a 0.1 discount on 100 gives 90.
- It keeps the file's existing style (single-quoted strings, no new type-hint or formatting
  changes outside the fixed line) and does not refactor anything else.
- It mentions that `legacy_export` looks unused (or dead) WITHOUT deleting or editing it.
- It names the check that proves the fix — for example `tests/test_pricing.py::test_ten_percent_off`
  or running `make check` / `pytest` — since it cannot run commands here.

Fail if it edits `add_tax` or `legacy_export`, renames anything, or restyles the file. Fail if it
never mentions how the fix is verified.
