# Safety Model

## Principles

1. **Read-only by default** — Codex runs with `-s read-only` unless sandbox failure requires an explicit user-approved fallback.
2. **Explicit approval gates** — No Codex execution without user confirmation.
3. **Instructional enforcement** — Even with `workspace-write`, Codex is instructed not to edit files.
4. **User responsibility** — The user decides whether to act on findings.
5. **Second opinion, not truth** — LLM review can be wrong; findings must be verified.

## Default sandbox

Preferred invocation:

```bash
codex -m <model> -c model_reasoning_effort="<effort>" -s read-only -a untrusted -C "$PWD" exec - < <prompt-file>
```

- `-s read-only`: model-generated shell commands run in a read-only sandbox.
- `-a untrusted`: only trusted commands run without prompting.
- `-C "$PWD"`: review is scoped to the working directory.

## Write-enabled fallback

If read-only sandbox fails (e.g. bubblewrap/user-namespace issues on some Linux setups), the skill may propose:

```bash
codex ... -s workspace-write ...
```

This requires explicit user approval. Codex must still be instructed to behave as a read-only reviewer.

`danger-full-access` is never used by default.

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

The skill explicitly forbids Codex from committing or pushing. Cursor must also ask the user before any git write operations prompted by review feedback.

## Dependency and migration restrictions

Review feedback may suggest dependency upgrades or schema migrations. These are suggestions only. Implementation requires:

1. user approval
2. normal project verification (tests, CI, staging)
3. rollback planning for migrations

## User responsibility

The user must:

- approve Codex execution and sandbox mode
- review findings critically
- run meaningful verification
- decide what changes to implement

## Limitations of sandboxing

Sandboxing reduces risk but does not eliminate it:

- read-only review can still read sensitive files if they are in scope
- instructions may be misinterpreted
- `workspace-write` increases blast radius
- sandbox behavior depends on Codex CLI version and OS configuration

## Limitations of LLM review

- findings may be hallucinated
- evidence may reference wrong lines or files
- security issues may be missed
- performance regressions may not be detected without benchmarks
- review does not replace tests, CI, or human code review

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