# Design

## Problem

When Cursor implements a change, the same agent that wrote the code also verifies it. That is efficient, but it can miss regressions, edge cases, or mismatches with the original task — especially on risky or architecture-sensitive work.

## Solution

`/call-codex` introduces a structured review harness with explicit role separation:

| Component | Default role |
|---|---|
| Cursor / Composer | Main executor and implementation agent |
| Codex | Read-only reviewer and second opinion |
| User | Approves risky, expensive, state-changing, or write-enabled actions |

## Why Cursor stays the main executor

Cursor already has session context, repository access, edit tools, and verification workflows. It should remain responsible for:

- preparing the implementation plan
- making edits
- running approved verification
- deciding whether to act on review feedback
- git workflow (with user approval)

Codex is invoked only when a second opinion adds value.

## Why Codex is read-only by default

Review quality improves when the reviewer cannot silently mutate the workspace. Read-only mode:

- reduces accidental edits
- makes the review boundary explicit
- keeps the user in control of state changes
- limits blast radius if the reviewer misjudges context

## Why sequential review, not autonomous orchestration

This repository intentionally avoids agent-swarm patterns. A predictable sequence is easier to reason about:

1. Cursor prepares context and a review prompt.
2. The user approves depth, command, and execution.
3. Codex returns structured findings.
4. Cursor decides what to change.

Autonomous loops between agents can be fast, but they are harder to audit, harder to cost-control, and harder to stop mid-flight.

## Why structured findings matter

Vague opinions ("looks fine", "maybe add tests") are hard to act on. The required output format forces:

- a clear verdict
- severity-ranked findings with evidence
- explicit uncertainty
- scoped follow-up for Cursor

That structure makes review output comparable across sessions and easier to triage.

## Why this repository is opinionated

The skill encodes defaults that reflect practical trade-offs:

- approval before Codex runs
- read-only sandbox by default
- narrow context bundles instead of whole-repo dumps
- cost-awareness (one call unless asked for more)
- correctness over ideology in review criteria

Users can adapt the skill, but the defaults optimize for safety and predictability.

## Fit with normal software engineering

This workflow supplements — not replaces — tests, CI, code review, and human judgment. It is most useful when:

- a plan is risky but not yet implemented
- a diff is small but touches shared infrastructure
- verification is incomplete
- the implementer wants a structured critique before proceeding