# cursor-codex-reviewer

> An opinionated read-only Codex reviewer skill for Cursor.

Use Codex as a second-opinion reviewer in Cursor without granting write access by default.

## Status

**Experimental / v0.1.1** — Safety and portability hardening release.

This project was extracted from a personal Cursor + Codex workflow and generalized for public use. Some integrations may require adaptation for your own local environment.

## Why this exists

Cursor is strong at implementation, but the same agent that writes code also verifies it. For risky changes, architecture decisions, or incomplete verification, a structured second opinion can catch regressions, edge cases, and task mismatches before they land.

`/call-codex` wraps that workflow as a predictable review harness — not an autonomous agent framework.

## What it does

- Installs a Cursor skill (`/call-codex`) that invokes Codex CLI as a **read-only reviewer**
- Prepares a focused review prompt with optional git context
- Requires explicit user approval before running Codex
- Returns **structured findings** with verdict, severity, evidence, and follow-up steps
- Supports plan review, diff review, implementation review, and verification critique
- Provides install, uninstall, and doctor scripts

## What it does not do

- Replace Cursor as the primary implementation agent
- Automatically review every change
- Run Codex without user approval
- Guarantee correct review output
- Provide Codex CLI, Cursor, or MCP servers
- Orchestrate autonomous multi-agent loops
- Commit, push, or publish on your behalf

## Core workflow

1. **Cursor** implements or prepares a plan.
2. **User** invokes `/call-codex` with a review request.
3. **Cursor** gathers context, prepares the prompt and exact `codex exec` command.
4. **User** chooses review depth and approves (or cancels) execution.
5. **Codex** runs read-only and returns structured findings.
6. **Cursor** summarizes and recommends next steps.
7. **User** decides what to implement.

## Key principles

| Principle | Description |
|---|---|
| Read-only by default | Codex uses `-s read-only` sandboxing |
| Explicit approval | No execution without user confirmation |
| Role separation | Cursor implements; Codex reviews; user approves risk |
| Structured output | Findings include severity, evidence, and next steps |
| Cost awareness | One Codex call per review unless user requests more |
| Honest uncertainty | Assumptions and gaps are explicit |

### Default role split

| Component | Default role |
|---|---|
| Cursor / Composer | Main executor and implementation agent |
| Codex | Read-only reviewer and second opinion |
| User | Approves risky, expensive, state-changing, or write-enabled actions |

## Requirements

- **Cursor** with skill support (desktop app or CLI)
- **Codex CLI** installed and authenticated
- **bash** for install/doctor scripts
- **git** (optional, for auto-context gathering)
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

The installer and uninstaller validate destinations and refuse unsafe paths such as `/`, `$HOME`, or `$HOME/.cursor/skills`.

## Usage examples

In Cursor, after implementing or planning a change:

```
/call-codex review this implementation
/call-codex review the current diff
/call-codex review this plan before I implement it
/call-codex inspect these failing tests
/call-codex verify whether the implementation matches the task
/call-codex critique this architecture decision
/call-codex identify edge cases and missing tests
```

Workflow-only (prepare prompt without running Codex):

```
/call-codex workflow only
```

See [`examples/`](examples/) for realistic interactions.

## Data boundary and privacy

Data boundary: `/call-codex` may send selected repository context, diffs, plans, task descriptions, and logs to Codex. Review the generated prompt before approval. Do not use the skill with confidential code or sensitive data unless your organization's policy and your Codex account configuration permit it.

- Prompt context is minimized by default.
- Full repository diffs are not included blindly.
- Review prompts use private per-invocation temporary files (`mktemp`, `chmod 600`) with automatic cleanup.
- Sensitive paths (`.env`, keys, credentials, build artifacts) are excluded from gathering where practical. This does not guarantee sensitive data cannot be sent.

## Safety model

Codex operates in **read-only review mode** by default.

### Default mode: Read-only containment

- Codex runs with `-s read-only` where supported.
- Codex is instructed to review only.
- Workspace mutation is technically restricted by sandbox configuration.

### Fallback mode: Degraded containment fallback

- May technically allow workspace modification (`-s workspace-write`).
- Requires explicit user approval of the exact command and sandbox change.
- Prompt instructions alone do not technically prevent writes in this mode.

The skill does not automatically source shell profiles. Launch Cursor with `codex` on `PATH`, or optionally set `CODEX_REVIEW_ENV_FILE` to an explicit environment file (see [`.env.example`](.env.example)).

Full details: [`docs/safety-model.md`](docs/safety-model.md)

## Review output format

Codex returns structured markdown:

```markdown
# Verdict
# Findings        (Critical / High / Medium / Low)
# Test and verification gaps
# Assumptions and uncertainty
# Suggested Cursor follow-up
```

Sample: [`examples/sample-output.md`](examples/sample-output.md)

## Optional integrations

Optional integrations may enrich context or improve documentation lookup, but core review behavior should still work without them.

Examples (if configured in your Cursor environment):

- MCP servers for code intelligence, GitHub, or web search
- Context7 for library documentation (via optional shell helper and `~/.cursor/mcp.json`)
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

Codex review is **not** a replacement for:

- tests
- CI
- code review
- security review
- human judgment

Other limitations:

- Codex may hallucinate files, APIs, or causes
- Large repos need narrow review scopes
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
Read-only Codex second-opinion reviewer skill for Cursor, with approval gates and structured review output.
```

Suggested topics:

```text
cursor
codex
openai-codex
ai-agents
coding-agents
code-review
cursor-skill
developer-tools
llm
agent-workflow
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Please preserve read-only-by-default behavior and explicit approval gates.

## License

MIT License — see [`LICENSE`](LICENSE).

Copyright (c) 2026 Rayhan