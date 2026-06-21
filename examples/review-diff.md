# Example: Review the Current Diff

Fictional project: **cachekit** — Redis wrapper library.

## 1. User requests diff review

**User:** `/call-codex review the current diff`

Working tree change (single file):

```diff
diff --git a/src/cachekit/client.py b/src/cachekit/client.py
index abc123..def456 100644
--- a/src/cachekit/client.py
+++ b/src/cachekit/client.py
@@ -40,7 +40,7 @@ class CacheClient:
     def get(self, key: str) -> Optional[bytes]:
-        return self._redis.get(key)
+        value = self._redis.get(key)
+        return value if value is not None else b""
```

Cursor gathers `git diff`, file list, and recent `pytest tests/test_client.py -q` result (passed).

User selects **B) Standard review** and runs Codex read-only.

## 2. Codex distinguishes confirmed vs suggested findings

```markdown
# Verdict

Changes requested

# Findings

## High — Empty byte string changes API contract
- **Summary:** Missing keys now return `b""` instead of `None`.
- **Evidence:** `client.py` diff hunk at `get()` return path.
- **Why it matters:** Callers using `if value is None` will treat misses as empty values.
- **Suggested next step:** Revert to `None` or document breaking change and update all call sites.

## Medium — Test gap for cache miss semantics
- **Summary:** Existing tests may only cover hit cases.
- **Evidence:** Session verification ran `test_client.py` but diff does not update tests.
- **Why it matters:** Regression may ship with green tests.
- **Suggested next step:** Add `test_get_missing_returns_none` (or new contract test).

## Low — Suggestion: consider typed Optional wrapper
- **Summary:** A `CacheResult` type could make miss/hit explicit.
- **Evidence:** N/A — design suggestion only.
- **Why it matters:** May reduce future ambiguity.
- **Suggested next step:** Optional follow-up; not required for this fix.

# Test and verification gaps

- Confirm whether public docs promise `None` on miss (`README.md` not inspected by Codex).
- Suggested verification: `pytest tests/test_client.py -q` after adding miss-case test.

# Assumptions and uncertainty

- Assumed `get()` is part of public API surface.
- Did not inspect downstream internal callers.

# Suggested Cursor follow-up

1. Treat High finding as confirmed — revert or make an explicit breaking-change migration.
2. Add miss-case test before merge.
3. Re-run targeted tests.
```

## 3. Outcome

Cursor reverts the `b""` fallback as a confirmed contract break, adds a miss test, and does not pursue the optional `CacheResult` refactor in this change.