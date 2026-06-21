# Example: Review a Plan Before Implementation

Fictional project: **notify-hub** — webhook dispatch service.

## 1. Plan exists before coding

**User:** I want to add retry with exponential backoff for failed webhook deliveries. Here's my plan:

1. Add `retry_count` column to `deliveries` table.
2. On failure, requeue with delay `2 ** retry_count` seconds.
3. Max 5 retries, then mark dead-letter.
4. Use in-process `sleep()` in the worker loop.

Cursor drafts the plan but has not edited files yet.

## 2. User asks Codex to critique the plan

**User:** `/call-codex review this plan before I implement it`

Cursor gathers minimal context (schema file names, worker module paths) and prepares a read-only Codex prompt. User chooses **B) Standard review** and approves execution.

## 3. Codex identifies risks and gaps

```markdown
# Verdict

Changes requested

# Findings

## High — In-process sleep blocks worker throughput
- **Summary:** `sleep()` in the worker loop stalls concurrent deliveries.
- **Evidence:** Plan step 4; `worker.py` uses a single-threaded poll loop.
- **Why it matters:** Backoff should schedule future attempts, not block the worker.
- **Suggested next step:** Store `next_attempt_at` and skip until due.

## Medium — Migration lacks rollback story
- **Summary:** Adding `retry_count` is forward-only in the plan.
- **Evidence:** Plan step 1 only mentions add column.
- **Why it matters:** Failed deploy rollback may leave schema/code mismatch.
- **Suggested next step:** Document reversible migration or deploy in two phases.

## Medium — No idempotency discussion
- **Summary:** Retries may double-deliver if upstream lacks idempotency keys.
- **Evidence:** Plan does not mention `Idempotency-Key` header or dedupe store.
- **Why it matters:** Webhook consumers may process duplicates incorrectly.
- **Suggested next step:** Define idempotency contract in plan.

# Test and verification gaps

- Missing test strategy for clock skew on `next_attempt_at`.
- Suggested verification: unit tests for scheduler selection + integration test with fake clock.

# Assumptions and uncertainty

- Did not inspect actual `worker.py` concurrency model in depth.
- Assumed PostgreSQL-backed queue from file names only.

# Suggested Cursor follow-up

1. Revise plan to use `next_attempt_at` instead of `sleep()`.
2. Add migration rollback notes.
3. Add idempotency section before implementation.
```

## 4. Cursor updates the plan before coding

Cursor revises the plan:
- replace `sleep()` with `next_attempt_at`
- add two-phase migration note
- add idempotency requirements

**User approves the revised plan.** Only then does Cursor start implementation.