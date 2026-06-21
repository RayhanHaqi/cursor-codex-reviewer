# Limitations

This project is **experimental (v0.1.1)**. Understand these limitations before relying on it.

## Review quality

- Codex may make incorrect inferences.
- Codex may hallucinate files, APIs, or failure causes.
- Review quality depends on the quality and scope of context provided.
- Large repositories may require narrow review scopes.
- Findings labeled as assumptions may still influence readers incorrectly if not read carefully.

## Not a replacement for engineering practice

Read-only Codex review does not replace:

- automated tests
- CI pipelines
- human code review
- security review
- performance benchmarking
- production monitoring

## Environment compatibility

Compatibility is **not guaranteed** across:

- Cursor versions
- Codex CLI versions
- operating systems
- shells (bash vs zsh vs fish)
- model availability
- subscription tiers and rate limits

This project is designed primarily for Linux and macOS shell environments.

## External dependencies

CLI authentication, billing, model availability, and rate limits are managed outside this repository. The skill cannot fix:

- expired Codex sessions
- quota exhaustion
- model deprecation
- changed `codex exec` flag syntax

## Optional integrations

Optional integrations (MCP servers, Context7, GitHub tools, web search) may not work in every setup. Core review behavior should still work without them, but enriched context will be unavailable.

## Output format

The structured review format may evolve in future releases. Downstream automation should not assume a frozen schema in v0.1.

## Sandboxing

Read-only sandboxing depends on OS-level features. Some environments may require `workspace-write` fallback, which increases risk even when Codex is instructed not to edit files.

## Data boundary

- `/call-codex` may transmit repository context, diffs, plans, and logs to Codex when approved.
- Sensitive-path exclusions reduce risk but do not guarantee sensitive data cannot be sent.
- Users must review the generated prompt before approval.

## Scope of this repository

This repository provides:

- a Cursor skill definition
- install/uninstall/doctor scripts
- documentation and examples

It does not provide:

- Codex CLI itself
- Cursor itself
- MCP server implementations
- autonomous multi-agent orchestration
- guaranteed review correctness