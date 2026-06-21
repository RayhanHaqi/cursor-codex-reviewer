# Example: Review an Implementation

Fictional project: **ledger-lite** — a small Python CLI for expense tracking.

## 1. Cursor implements a focused change

**User:** Add validation so expense amounts must be positive.

Cursor edits `src/ledger/validators.py`:

```python
def validate_amount(amount: float) -> None:
    if amount <= 0:
        raise ValueError("amount must be positive")
```

Cursor updates `tests/test_validators.py` with one new test and reports `pytest tests/test_validators.py -q` passed.

## 2. User requests Codex review

**User:** `/call-codex review this implementation`

Cursor prepares:
- task summary
- auto-context bundle (`git diff`, changed files)
- verification context from the session
- proposed read-only Codex command

Cursor shows review depth options and the exact command. User selects **A) Deep review** and approves **Run Codex now**.

## 3. Codex inspects and returns structured findings

Codex reviews the diff and test file (read-only) and returns:

```markdown
# Verdict

Approve with notes

# Findings

## Medium — Float amounts allow silent precision issues
- **Summary:** `float` comparison may mishandle decimal currency values.
- **Evidence:** `validators.py` accepts `float`; existing `Money` type in `src/ledger/money.py` uses `Decimal`.
- **Why it matters:** Users entering `0.1 + 0.2` style values may pass validation but corrupt totals elsewhere.
- **Suggested next step:** Accept `Decimal` or reuse `parse_money()` from `money.py`.

## Low — Missing test for zero boundary
- **Summary:** No explicit test for `amount == 0`.
- **Evidence:** `tests/test_validators.py` covers negative values only.
- **Why it matters:** Boundary clarity prevents regression if comparison changes.
- **Suggested next step:** Add `test_rejects_zero_amount`.

# Test and verification gaps

- No integration test through CLI entrypoint `ledger add`.
- Suggested verification (not yet run): `pytest tests/ -q`

# Assumptions and uncertainty

- Did not inspect `src/ledger/money.py` implementation details beyond import graph.
- Assumed CLI path still accepts raw floats.

# Suggested Cursor follow-up

1. Switch validator input to `Decimal` via existing money helper.
2. Add zero-boundary unit test.
3. Run full test suite before merge.
```

## 4. Cursor applies only justified changes

Cursor agrees the `Decimal` alignment is a real convention mismatch and adds the zero test. It skips any broader refactor Codex mentioned as optional.

**User approves edits.** Cursor implements two small changes, reruns tests, and stops.