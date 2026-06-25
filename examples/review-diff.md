# Example: Plan a Bugfix From Symptoms

Fictional project: **cachekit** — Redis wrapper library.

## 1. User describes incorrect behavior

**User:** `/call-codex cache misses return empty bytes instead of None — find the smallest safe fix`

Cursor does not run `git diff` or open files. User selects **B) Standard — high** and runs Codex read-only.

## 2. Codex investigates and distinguishes evidence from proposal

```markdown
## Scope Read
- `src/cachekit/client.py`, `tests/test_client.py`, package `__init__.py` exports

## Evidence
- `CacheClient.get()` recently changed to return `b""` when Redis returns `None`.
- Public docstring still documents `Optional[bytes]` with `None` on miss.
- Tests cover hit cases only; no explicit miss assertion.

## Assumptions and Unknowns
- Downstream callers may rely on `is None` checks (not fully traced).

## Recommended Plan
1. Revert miss path to return `None` to match documented contract.
2. Add `test_get_missing_returns_none`.
3. Grep internal callers for `b""` assumptions before merge.

## Execution Packet for Cursor

### Target Files
- `src/cachekit/client.py`
- `tests/test_client.py`

### Constraints
- Preserve hit-path behavior unchanged.

### Non-goals
- Introducing a new `CacheResult` wrapper type.

### Acceptance Criteria
- Miss returns `None`; test proves it.

### Focused Verification
- `pytest tests/test_client.py -q` (not yet run)

### Cursor-Ready Prompt
Apply minimal contract fix. Add miss test. Do not refactor API surface.

## Risks
- If any caller intentionally depended on `b""`, revert may break them — internal grep required.
```

## 3. Outcome

Cursor applies the minimal revert and test from the execution packet. Optional API redesign stays out of scope.
