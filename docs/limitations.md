# Limitations

This project is **experimental (v0.2.0)**. Understand these limitations before relying on it.

## Planning quality

- Codex may make incorrect inferences.
- Codex may hallucinate files, APIs, or failure causes.
- Plan quality depends on task clarity and what Codex can read in the repository.
- Large repositories may require focused task descriptions.
- Assumptions labeled in the plan may still influence readers incorrectly if not read carefully.

## Not a replacement for engineering practice

Codex-first planning does not replace:

- automated tests
- CI pipelines
- human code review
- security review
- performance benchmarking
- production monitoring

## Launcher contract limits

The skill instructs Cursor not to investigate before Codex runs, but enforcement depends on Cursor following the skill. Users should verify launcher behavior in their environment.

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

Optional integrations (MCP servers, Context7, GitHub tools, web search) may be used by Codex during investigation when configured. Cursor must not call MCPs before Codex runs. Integrations may not work in every setup.

## Output format

The structured planning format may evolve in future releases. Downstream automation should not assume a frozen schema in v0.2.

## Sandboxing

Read-only sandboxing depends on OS-level features. Some environments may require `workspace-write` fallback, which increases risk even when Codex is instructed not to edit files.

## Data boundary

- `/call-codex` transmits the user task to Codex; Codex reads repository files during approved investigation.
- Sensitive-path exclusions reduce risk but do not guarantee sensitive data cannot be read.
- Users must review the generated prompt summary before approval.

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
- guaranteed planning correctness
- a default post-implementation review role
