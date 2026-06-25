# Design

## Problem

When Cursor plans and implements a change in one session, investigation and editing share the same context. That is efficient for small tasks, but on unfamiliar, multi-file, or architecture-sensitive work it can bake in wrong assumptions before any structured evidence gathering happens.

## Solution

`/call-codex` introduces a structured planning harness with explicit role separation:

| Component | Default role |
|---|---|
| Codex | First read-only investigator and implementation planner |
| Cursor / Composer | Launcher before Codex; implementation harness after user approves the plan |
| User | Approves planning depth, Codex execution, and all edits |

## Why Codex plans first

Codex is invoked when the task benefits from a dedicated read-only investigation pass:

- gather evidence from relevant files
- surface assumptions and unknowns
- propose a minimal safe plan
- produce a compact execution packet for Cursor

Cursor must not pre-empt this by reading the repository, inspecting Git, or drafting its own plan first.

## Why Cursor stays the implementation harness

Cursor already has session context, edit tools, and verification workflows. After the user approves a Codex plan, Cursor should:

- implement the approved scope
- run user-approved verification
- manage git workflow (with user approval)

Codex does not edit files by default.

## Why Codex is read-only by default

Planning quality improves when the investigator cannot silently mutate the workspace. Read-only mode:

- reduces accidental edits during investigation
- makes the planning boundary explicit
- keeps the user in control of state changes
- limits blast radius if the planner misjudges context

## Why sequential planning, not autonomous orchestration

This repository intentionally avoids agent-swarm patterns. A predictable sequence is easier to reason about:

1. User describes the task; Cursor prepares the Codex prompt (launcher only).
2. User approves planning depth, command, and execution.
3. Codex investigates read-only and returns a structured plan.
4. User approves, modifies, or rejects the plan.
5. Cursor implements only after explicit approval.

Autonomous loops between agents can be fast, but they are harder to audit, harder to cost-control, and harder to stop mid-flight.

## Why structured planning output matters

Vague plans ("update the module", "add tests") are hard to execute safely. The required output format forces:

- verified evidence vs assumptions
- ordered implementation steps
- explicit target files and non-goals
- focused verification commands
- scoped Cursor-ready execution prompt

That structure makes planning output comparable across sessions and easier to approve.

## Why this repository is opinionated

The skill encodes defaults that reflect practical trade-offs:

- approval before Codex runs
- launcher-only Cursor before Codex
- read-only sandbox by default
- one Codex call unless asked for more
- no default post-implementation review role

Users can adapt the skill, but the defaults optimize for safety and predictability.

## Fit with normal software engineering

This workflow supplements — not replaces — tests, CI, code review, and human judgment. It is most useful when:

- the task spans multiple files or subsystems
- root cause is unclear
- architecture or evaluation methodology is sensitive
- a wrong assumption would be expensive to fix later
