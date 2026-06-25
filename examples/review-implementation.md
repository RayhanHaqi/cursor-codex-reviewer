# Example: Plan a Focused Code Change

Fictional project: **ledger-lite** — a small Python CLI for expense tracking.

## 1. User invokes planning (no prior implementation)

**User:** `/call-codex add validation so expense amounts must be positive`

Cursor stays launcher-only: no file reads, no Git inspection. User selects **A) Deep — xhigh** and approves **Run Codex now**.

## 2. Codex investigates and returns a plan

Codex reads `src/ledger/validators.py`, `src/ledger/money.py`, and existing tests read-only:

```markdown
## Scope Read
- `src/ledger/validators.py`, `src/ledger/money.py`, `tests/test_validators.py`, `src/ledger/cli.py`

## Evidence
- No `validate_amount` helper exists today.
- `money.py` defines `parse_money()` returning `Decimal`.
- CLI `ledger add` currently accepts raw string amounts parsed as float in one code path.

## Assumptions and Unknowns
- Whether public API should accept floats or only `Decimal`/strings (CLI path needs confirmation).

## Recommended Plan
1. Add `validate_amount` in `validators.py` using `Decimal` via `parse_money()`.
2. Wire validation into CLI add path before persistence.
3. Add unit tests for positive, zero, and negative amounts.

## Execution Packet for Cursor

### Target Files
- `src/ledger/validators.py` (new or extend)
- `src/ledger/cli.py`
- `tests/test_validators.py`

### Constraints
- Reuse `parse_money()`; do not introduce parallel float parsing.

### Non-goals
- Refactoring unrelated CLI commands.

### Acceptance Criteria
- Zero and negative amounts raise clear validation errors.
- Positive decimal amounts pass.

### Focused Verification
- `pytest tests/test_validators.py -q` (not yet run)

### Cursor-Ready Prompt
Implement validation per plan. Minimal diff. Run only focused pytest.

## Risks
- Float literals in tests may need `Decimal` strings for consistency.
```

## 3. Cursor implements after user approval

**User:** Go ahead with the plan.

Cursor implements the scoped change, runs approved verification, and stops. No automatic post-implementation Codex review.
