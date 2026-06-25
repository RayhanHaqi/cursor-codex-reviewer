# Example: Plan Before Implementation

Fictional project: **notify-hub** — webhook dispatch service.

## 1. User describes the task (no Cursor plan yet)

**User:** `/call-codex add retry with exponential backoff for failed webhook deliveries`

Cursor does **not** read `schema.sql`, `worker.py`, or Git state. It asks for planning depth.

## 2. User selects depth and approves Codex

User chooses **B) Standard — high**. Cursor shows the prompt summary, exact read-only command, and `Codex next step` popup. User selects **Run Codex now**.

Codex investigates relevant files read-only and returns:

```markdown
## Scope Read
- `migrations/`, `src/worker.py`, `src/models/delivery.py`, `tests/test_worker.py`

## Evidence
- Worker uses a single-threaded poll loop in `worker.py`.
- `deliveries` table has no `retry_count` or `next_attempt_at` column today.
- Failed deliveries are logged but not requeued.

## Assumptions and Unknowns
- Upstream webhook consumers may or may not support idempotency keys (not found in repo).
- Production queue backend assumed PostgreSQL from migration style.

## Recommended Plan
1. Add `retry_count` and `next_attempt_at` columns via migration.
2. On failure, schedule next attempt with exponential delay capped at max retries.
3. Use `next_attempt_at` selection in the worker loop instead of blocking `sleep()`.
4. Dead-letter after max retries.

## Execution Packet for Cursor

### Target Files
- `migrations/YYYYMMDD_add_delivery_retry.sql`
- `src/models/delivery.py`
- `src/worker.py`
- `tests/test_worker_retry.py`

### Constraints
- Do not block the worker loop with in-process sleep.
- Preserve existing delivery success path.

### Non-goals
- Idempotency contract with consumers (document as follow-up).
- UI changes for dead-letter inspection.

### Acceptance Criteria
- Failed delivery is requeued with increasing delay until max retries.
- Worker continues processing other deliveries while waiting.

### Focused Verification
- `pytest tests/test_worker_retry.py -q` (not yet run)

### Cursor-Ready Prompt
Implement retry scheduling per Recommended Plan. Touch only listed target files. Do not run full integration suite.

## Risks
- Retries without idempotency may double-deliver.
- Migration rollback story should be documented in the migration file.
```

## 3. User approves implementation

**User:** Implement the Codex plan.

Cursor implements using the execution packet. Codex is not invoked again automatically.
