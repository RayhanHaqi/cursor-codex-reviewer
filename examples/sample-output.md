# Sample Structured Review Output

Fictional project: **auth-gate** — session middleware for a Go HTTP API.

---

# Verdict

Changes requested

# Findings

## Critical — Session cookie missing Secure flag on HTTPS deployments
- **Severity:** Critical
- **Summary:** Cookie set without `Secure` attribute in production config path.
- **Evidence:** `middleware/session.go` lines 88–94 set `HttpOnly` but not `Secure` when `cfg.TLS.Enabled` is true.
- **Why it matters:** Session tokens may be sent over cleartext if TLS is terminated incorrectly or misconfigured downstream.
- **Suggested next step:** Set `Secure: cfg.TLS.Enabled` and add regression test.

## High — Token refresh does not rotate session ID
- **Severity:** High
- **Summary:** Refresh endpoint reuses the same session identifier.
- **Evidence:** `handlers/refresh.go` line 51 calls `store.Renew(id)` without rotation helper.
- **Why it matters:** Stolen refresh responses remain valid until expiry (session fixation risk).
- **Suggested next step:** Issue new session ID on refresh; invalidate old ID.

## Medium — Error path leaks internal store errors
- **Severity:** Medium
- **Summary:** Raw `store.Err` text returned to clients on 500 responses.
- **Evidence:** `handlers/refresh.go` lines 63–66: `http.Error(w, err.Error(), 500)`.
- **Why it matters:** May expose schema or infrastructure details.
- **Suggested next step:** Log internally; return generic message.

## Low — Comment mismatch on expiry duration
- **Severity:** Low
- **Summary:** Comment says 24h; constant is 12h.
- **Evidence:** `config/session.go` line 12 comment vs `DefaultSessionTTL` value.
- **Why it matters:** Misleads future maintainers.
- **Suggested next step:** Fix comment or constant to match product requirement.

# Test and verification gaps

- Missing tests:
  - cookie `Secure` flag when TLS enabled
  - session ID rotation on refresh
  - sanitized 500 body on store failures
- Unverified assumptions:
  - actual TLS termination topology in production
  - whether mobile clients depend on non-rotating IDs
- Relevant commands worth running (not yet run):
  - `go test ./... -run Session -count=1`
  - `golangci-lint run ./middleware/... ./handlers/...`

Do not run full integration suite or deploy to staging without explicit approval.

# Assumptions and uncertainty

- **Unknowns:** Production reverse proxy configuration; whether `cfg.TLS.Enabled` is set correctly in all environments.
- **Files not inspected:** `deploy/terraform/alb.tf`, mobile client SDK.
- **Assumptions made:** `store.Renew` does not implicitly rotate IDs (based on name and call site only).
- **Possible false positives:** If TLS is enforced exclusively at the load balancer with trusted internal HTTP, `Secure` cookie flag may still be required but severity depends on browser-facing URL scheme.

# Suggested Cursor follow-up

1. **P0:** Add `Secure` flag and unit test in `middleware/session.go`.
2. **P0:** Implement session ID rotation in refresh handler with test coverage.
3. **P1:** Sanitize 500 error responses.
4. **P2:** Fix TTL comment mismatch.
5. Re-run targeted Go tests; ask user before full integration or deploy steps.

---

**Cursor recommendation:** update plan with P0 items before merge; ask user before editing.

**Next:** ask approval before editing files.