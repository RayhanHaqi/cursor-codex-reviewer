# Safety Model

## Principles

1. **Codex-first investigation** — Codex performs the first relevant repository read after user-approved execution.
2. **Launcher-only Cursor** — Before Codex runs, Cursor must not inspect repository files, Git state, or MCPs.
3. **Read-only by default** — Codex runs with `-s read-only` unless sandbox failure requires an explicit user-approved fallback.
4. **Explicit approval gates** — No Codex execution without user confirmation.
5. **Technical containment first** — Read-only sandbox restricts workspace mutation where supported.
6. **User responsibility** — The user decides whether to act on the plan and what data to send.
7. **Evidence-based recommendation, not truth** — LLM planning can be wrong; plans must be verified.

## Data boundary and privacy

Data boundary: `/call-codex` sends the user task to Codex; Codex independently reads relevant repository files during its investigation when you approve execution. Review the generated prompt summary before approval. Do not use the skill with confidential code or sensitive data unless your organization's policy and your Codex account configuration permit it.

- Cursor does not pre-gather repository context before Codex runs.
- Users should approve the generated prompt summary before Codex executes.
- Codex is instructed to avoid sensitive files, credentials, datasets, checkpoints, and large artifacts.

Default sensitive-path exclusions during Codex investigation:

```text
.env
.env.*
*.pem
*.key
id_rsa
id_ed25519
credentials*
secrets*
node_modules/
vendor/
dist/
build/
datasets/
checkpoints/
model weights
large binaries
generated artifacts
report PDFs
```

This exclusion list does not guarantee sensitive data cannot be read.

Planning prompts are written to unique private temporary files (`codex-plan.*`, `mktemp` + `chmod 600`) and cleaned up automatically unless the user explicitly opts to keep them for debugging.

## Sandbox modes

### Default mode: Read-only containment

Meaning:

- Codex runs with a read-only sandbox where supported.
- Codex is instructed to plan only; no edits, commits, or long-running commands.
- Workspace mutation is technically restricted by sandbox configuration.

Preferred invocation:

```bash
PROMPT_FILE="$(mktemp "${TMPDIR:-/tmp}/codex-plan.XXXXXX.md")"
chmod 600 "${PROMPT_FILE}"
trap 'rm -f "${PROMPT_FILE}"' EXIT

codex -m gpt-5.5 -c 'model_reasoning_effort="xhigh"' -s read-only -a untrusted -C "$PWD" exec - < "${PROMPT_FILE}"
```

- `-s read-only`: model-generated shell commands run in a read-only sandbox.
- `-a untrusted`: only trusted commands run without prompting.
- `-C "$PWD"`: planning is scoped to the working directory.

### Fallback mode: Degraded containment fallback

Meaning:

- This mode may technically allow workspace modification.
- Codex must still be instructed not to edit files.
- The user must explicitly approve the exact command and sandbox change.
- The user must see a warning that write prevention is no longer technically enforced.

If read-only sandbox fails (e.g. bubblewrap/user-namespace issues on some Linux setups), the skill may propose:

```bash
codex ... -s workspace-write ...
```

This requires explicit user approval. Do not silently switch sandbox modes.

The approval request for fallback must include:

1. Why read-only mode could not be used.
2. The exact command to be executed.
3. The exact sandbox mode change.
4. This exact warning:

```text
This fallback weakens technical write protection. Codex is instructed not to edit files, but the environment may permit workspace changes.
```

5. A clear cancel option.

Prompt instructions alone do **not** technically prevent writes in `workspace-write` mode.

`danger-full-access` is never used by default.

## Environment configuration

The skill does **not** source shell profiles or environment files automatically.

Launch Cursor from an environment where `codex` is already on `PATH` and any required variables are already configured.

## Categories of risky actions

Actions that require explicit user approval before Codex or Cursor runs them:

### State-changing
- editing source files
- deleting files
- database migrations
- modifying CI configuration
- changing infrastructure configuration
- installing or upgrading dependencies
- publishing packages

### Destructive
- `rm -rf` or bulk deletion
- dropping database tables
- force-pushing branches
- rewriting git history

### Remote / publish
- `git commit`
- `git push`
- creating releases
- publishing to registries
- opening network tunnels

### Expensive / long-running
- full test suite on large repos
- long benchmark runs
- training jobs
- broad repo scans
- repeated Codex retries

## Commit and push restrictions

The skill explicitly forbids Codex from committing or pushing. Cursor must also ask the user before any git write operations.

## Dependency and migration restrictions

Plans may suggest dependency upgrades or schema migrations. These are suggestions only. Implementation requires:

1. user approval
2. normal project verification (tests, CI, staging)
3. rollback planning for migrations

## User responsibility

The user must:

- approve Codex execution and sandbox mode
- review the generated prompt summary before sending data to Codex
- review the plan critically
- run meaningful verification after implementation
- decide what changes to implement

## Limitations of sandboxing

Sandboxing reduces risk but does not eliminate it:

- read-only planning can still read sensitive files if they are in scope
- instructions may be misinterpreted
- `workspace-write` weakens technical write protection even when Codex is instructed not to edit
- sandbox behavior depends on Codex CLI version and OS configuration

## Limitations of LLM planning

- plans may be based on hallucinated files or APIs
- evidence may reference wrong lines or files
- security issues may be missed
- performance regressions may not be detected without benchmarks
- planning does not replace tests, CI, or human code review

## Examples requiring approval

| Action | Why |
|---|---|
| Running `pytest` on entire monorepo | Expensive, long-running |
| `alembic upgrade head` | State-changing migration |
| `npm update` major version | Dependency upgrade risk |
| Deleting legacy module | Destructive |
| Editing `.github/workflows/ci.yml` | CI change affects all PRs |
| Changing Terraform modules | Infrastructure risk |
| `git commit -m "fix"` | Remote/publish pipeline |
| `git push` | Remote/publish |
| Publishing to PyPI | Remote/publish |
| Network curl to external API | Network operation |
| 30-minute benchmark suite | Expensive |
