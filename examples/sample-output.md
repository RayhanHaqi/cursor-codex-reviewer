# Sample Structured Planning Output

Fictional project: **auth-gate** — session middleware for a Go HTTP API.

---

## Scope Read

- `middleware/session.go`, `handlers/refresh.go`, `config/session.go`
- `middleware/session_test.go` (partial — refresh tests missing)
- Did not inspect `deploy/` or mobile clients

## Evidence

- `middleware/session.go` sets `HttpOnly` on session cookies but not `Secure` when `cfg.TLS.Enabled` is true.
- `handlers/refresh.go` calls `store.Renew(id)` without issuing a new session ID.
- `handlers/refresh.go` returns raw `err.Error()` on store failures (500 path).
- `config/session.go` comment says 24h TTL; `DefaultSessionTTL` is 12h.

## Assumptions and Unknowns

- Production TLS termination topology not verified.
- Whether mobile clients depend on non-rotating session IDs.

## Recommended Plan

1. Set `Secure: cfg.TLS.Enabled` on session cookies; add regression test.
2. Rotate session ID on refresh; invalidate previous ID in store.
3. Log store errors internally; return generic 500 message to clients.
4. Align TTL comment with `DefaultSessionTTL` or vice versa per product requirement.

## Execution Packet for Cursor

### Target Files

- `middleware/session.go` — cookie flags + test
- `handlers/refresh.go` — rotation + error sanitization
- `config/session.go` — comment or constant fix
- `middleware/session_test.go`, `handlers/refresh_test.go` — new cases

### Constraints

- Preserve existing session store interface.
- No deploy config changes in this pass.

### Non-goals

- Load balancer or Terraform TLS review.
- Mobile SDK updates.

### Acceptance Criteria

- Cookie has `Secure` when TLS enabled (unit test).
- Refresh issues new session ID (unit test).
- 500 responses do not leak raw store errors.

### Focused Verification

- `go test ./middleware/... ./handlers/... -count=1` (not yet run)

### Cursor-Ready Prompt

Implement P0 items from Recommended Plan only. Touch listed files. Run focused Go tests; do not deploy.

## Risks

- Session rotation may log users out on concurrent refresh unless store handles overlap.
- `Secure` cookie behavior depends on browser-facing URL scheme vs internal HTTP.

## MCP Usage

Skipped:
- GitHub MCP: not needed; evidence from local files sufficient.

---

**User next step:** approve, modify, or reject the plan before Cursor edits files.
