# cursor-codex-reviewer

> An opinionated Codex-first planning skill for Cursor.

Use Codex as the first read-only investigator and implementation planner before Cursor edits code.

## Status

**Experimental / v0.2.0** — Codex-first planning with launcher-only Cursor behavior before Codex runs.

This project was extracted from a personal Cursor + Codex workflow and generalized for public use. Some integrations may require adaptation for your own local environment.

## Why this exists

Cursor is strong at implementation, but planning and investigation on unfamiliar or risky work can burn context or bake in wrong assumptions. For multi-file changes, architecture decisions, or unclear bugs, a dedicated first-pass planner can gather evidence and produce a focused execution packet before any edits.

`/call-codex` wraps that workflow as a predictable planning harness — not an autonomous agent framework.

## What it does

- Installs a Cursor skill (`/call-codex`) that invokes Codex CLI as the **first read-only planner**
- Keeps Cursor launcher-only before Codex runs: no repo reads, Git inspection, MCP calls, or Cursor-created plans
- Requires explicit user approval before running Codex
- Returns a **structured plan** with evidence, target files, constraints, and a Cursor-ready execution prompt
- Supports workflow-only mode to preview the prompt and command without running Codex in the same turn
- Provides install, uninstall, and doctor scripts

## What it does not do

- Replace Cursor as the implementation agent after planning
- Automatically plan or review every change
- Run Codex without user approval
- Guarantee correct planning output
- Provide Codex CLI, Cursor, or MCP servers
- Orchestrate autonomous multi-agent loops
- Act as a default post-implementation Codex review pass
- Commit, push, or publish on your behalf

## Core workflow

1. **User** describes the task and invokes `/call-codex`.
2. **Cursor** (launcher only) asks for planning depth, prepares the prompt summary and exact `codex exec` command — without reading the repository.
3. **User** approves (or cancels) execution.
4. **Codex** runs read-only, investigates relevant files, and returns a structured plan plus execution packet.
5. **User** reviews the plan and decides whether to proceed.
6. **Cursor** implements only after explicit user approval.

## Key principles

| Principle | Description |
|---|---|
| Codex-first investigation | Codex performs the first relevant repository read |
| Launcher-only Cursor | Before Codex runs, Cursor does not inspect repo, Git, or MCPs |
| Read-only by default | Codex uses `-s read-only` sandboxing |
| Explicit approval | No execution without user confirmation |
| Structured output | Plans include evidence, target files, and verification steps |
| Cost awareness | One Codex call per planning session unless user requests more |
| Honest uncertainty | Assumptions and unknowns are explicit |

### Default role split

| Component | Default role |
|---|---|
| Codex | First read-only investigator and implementation planner |
| Cursor / Composer | Launcher before Codex; implementation harness after user approves the plan |
| User | Approves planning depth, Codex execution, and all edits |

## Requirements

- **Cursor** with skill support (desktop app or CLI)
- **Codex CLI** installed and authenticated
- **bash** for install/doctor scripts
- Linux or macOS shell environment recommended

Compatibility with all Cursor versions, Codex versions, operating systems, shells, or editors is **not guaranteed**.

## Installation

```bash
git clone https://github.com/RayhanHaqi/cursor-codex-reviewer.git
cd cursor-codex-reviewer
./scripts/install.sh
./scripts/doctor.sh
```

Custom install path (must end with `/call-codex`):

```bash
./scripts/install.sh --dest ~/.cursor/skills/call-codex
```

Overwrite existing install:

```bash
./scripts/install.sh --force
```

Custom path outside `~/.cursor/skills/` (explicit opt-in):

```bash
./scripts/install.sh --dest /custom/path/call-codex --allow-custom-outside-cursor-skills
```

Uninstall:

```bash
./scripts/uninstall.sh
./scripts/uninstall.sh --yes
```

The installer and uninstaller validate destinations and refuse unsafe paths such as `/`, `$HOME`, or `$HOME/.cursor/skills`. Symlink destinations are refused before canonicalization; remove or replace symlinks manually if needed. Path canonicalization may require `realpath`, `readlink`, or Python 3.

## Usage examples

In Cursor, describe a task before implementation:

```
/call-codex add retry with exponential backoff for webhook deliveries
/call-codex plan the refactor of the session middleware
/call-codex investigate why calibration drifts after camera reconnect
/call-codex design a minimal benchmark for the new tracker module
```

Workflow-only (prepare prompt without running Codex in the same turn):

```
/call-codex workflow only — add OAuth token refresh to the API client
```

See [`examples/`](examples/) for realistic interactions.

## Data boundary and privacy

Data boundary: `/call-codex` sends the user task to Codex; Codex independently reads relevant repository files during its investigation after you approve execution. Review the generated prompt summary before approval. Do not use the skill with confidential code or sensitive data unless your organization's policy and your Codex account configuration permit it.

- Cursor does not pre-gather repository context before Codex runs.
- Planning prompts use private per-invocation temporary files (`codex-plan.*`, `mktemp`, `chmod 600`) with automatic cleanup.
- Codex is instructed to avoid secrets, credentials, datasets, checkpoints, and large artifacts. This does not guarantee sensitive data cannot be read.

## Safety model

Codex operates in **read-only planning mode** by default.

### Default mode: Read-only containment

- Codex runs with `-s read-only` where supported.
- Codex is instructed to plan only; no edits, commits, or long-running commands.
- Workspace mutation is technically restricted by sandbox configuration.

### Fallback mode: Degraded containment fallback

- May technically allow workspace modification (`-s workspace-write`).
- Requires explicit user approval of the exact command and sandbox change.
- Prompt instructions alone do not technically prevent writes in this mode.

The skill does not source shell profiles or environment files automatically. Launch Cursor from an environment where `codex` is already on `PATH` and any required variables are configured.

Full details: [`docs/safety-model.md`](docs/safety-model.md)

## Planning output format

Codex returns structured markdown:

```markdown
## Scope Read
## Evidence
## Assumptions and Unknowns
## Recommended Plan
## Execution Packet for Cursor
## Risks
## MCP Usage
```

Sample: [`examples/sample-output.md`](examples/sample-output.md)

## Optional integrations

Codex may use configured MCP tools when directly relevant during its investigation. Cursor must not call MCPs before Codex runs.

Examples (if configured in your Cursor/Codex environment):

- MCP servers for code intelligence, GitHub, or web search
- Context7 for library documentation
- Paper search for research-heavy tasks

Do not commit API keys or credentials. See [`docs/troubleshooting.md`](docs/troubleshooting.md).

## Repository structure

```text
cursor-codex-reviewer/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── skills/call-codex/SKILL.md    # Cursor skill definition
├── scripts/
│   ├── install.sh
│   ├── uninstall.sh
│   ├── doctor.sh
│   └── lib/path-safety.sh
├── examples/                       # Usage examples
├── docs/                           # Design, safety, limitations
├── .github/workflows/ci.yml
└── tests/
    ├── smoke-test.sh
    └── lifecycle-test.sh
```

## Limitations

Codex planning is **not** a replacement for:

- tests
- CI
- code review
- security review
- human judgment

Other limitations:

- Codex may hallucinate files, APIs, or causes
- Large repos need focused task descriptions
- CLI auth, billing, and rate limits are outside this repo
- Optional integrations may not work in every setup
- Output format may evolve

Full list: [`docs/limitations.md`](docs/limitations.md)

## Compatibility

- Tested primarily on Linux and macOS shell environments.
- Cursor desktop and Cursor CLI may expose different interaction capabilities.
- Popup/approval UI behavior depends on Cursor environment and version.
- Codex CLI command syntax and sandbox features may vary by version.
- Run `./scripts/doctor.sh` after installation.
- This project is experimental and may require local adaptation.

## Troubleshooting

```bash
./scripts/doctor.sh
```

Common issues: [`docs/troubleshooting.md`](docs/troubleshooting.md)

## GitHub metadata (maintainers)

Recommended repository description:

```text
Codex-first read-only planning skill for Cursor, with launcher-only Cursor behavior and explicit approval gates.
```

Suggested topics:

```text
cursor
codex
openai-codex
ai-agents
coding-agents
planning
cursor-skill
developer-tools
llm
agent-workflow
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Please preserve Codex-first launcher behavior, read-only-by-default execution, and explicit approval gates.

## License

MIT License — see [`LICENSE`](LICENSE).

Copyright (c) 2026 Rayhan
