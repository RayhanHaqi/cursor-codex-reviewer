# Troubleshooting

## Compatibility notes

- This project is tested primarily on Linux and macOS shell environments.
- Cursor desktop and Cursor CLI may expose different interaction capabilities.
- Popup/approval UI behavior depends on Cursor environment and version.
- Codex CLI command syntax and sandbox features may vary by version.
- Run `./scripts/doctor.sh` after installation.
- The project is experimental and may require local adaptation.

## Quick diagnosis

Run:

```bash
./scripts/doctor.sh
```

## `codex: command not found`

**Symptom:** Shell cannot find the Codex CLI.

**Fix:**
1. Install Codex CLI per OpenAI documentation for your environment.
2. Ensure the install directory is on `PATH`.
3. Open a new shell and rerun `./scripts/doctor.sh`.

## `cursor: command not found`

**Symptom:** Doctor reports cursor CLI missing.

**Note:** This is usually not blocking. Many users run Cursor as a desktop app without the CLI on `PATH`.

**Fix (optional):** Install the Cursor CLI or add it to `PATH` if you use terminal workflows.

## Codex authentication problems

**Symptom:** `codex exec` fails with auth errors.

**Fix:**
1. Run `codex` interactively once to complete login.
2. Check `~/.codex/` configuration per Codex CLI docs.
3. Verify subscription or API access is active.
4. Do not commit auth artifacts to this repository.

## Codex session or subscription problems

**Symptom:** Quota errors, rate limits, or model unavailable.

**Fix:**
1. Retry later or choose a lower review depth.
2. Check billing and usage in your OpenAI/Codex account.
3. Try a different model if your CLI supports it.

## Skill not appearing in Cursor

**Symptom:** `/call-codex` is not recognized.

**Fix:**
1. Confirm install path: `~/.cursor/skills/call-codex/SKILL.md`
2. Re-run `./scripts/install.sh`
3. Restart Cursor or reload skills.
4. Check Cursor documentation for skill discovery paths in your version.

## Wrong install location

**Symptom:** Skill installed but Cursor reads a different directory.

**Fix:**
1. Reinstall with explicit destination:
   ```bash
   ./scripts/install.sh --dest ~/.cursor/skills/call-codex
   ```
2. Remove stray copies manually if you experimented with other paths.

## Shell permission issues

**Symptom:** Scripts fail with "Permission denied".

**Fix:**
```bash
chmod +x scripts/*.sh tests/smoke-test.sh
```

## Shell incompatibility

**Symptom:** Scripts fail on zsh/fish.

**Fix:** Run scripts explicitly with bash:

```bash
bash ./scripts/install.sh
```

The skill assumes bash-style command examples for Codex invocation.

## Large repository context issues

**Symptom:** Review is slow, expensive, or misses relevant files.

**Fix:**
1. Use review depth B or C for smaller context.
2. Narrow the task description to specific files or modules.
3. Provide a focused diff summary in the Cursor plan.
4. Avoid pasting large logs into the prompt.

## Slow or expensive review requests

**Symptom:** Deep review consumes significant quota.

**Fix:**
1. Choose C) Quick review for sanity checks.
2. Use `/call-codex workflow only` to inspect the prompt before running.
3. Limit auto-context gathering to changed files.

## Optional integration unavailable

**Symptom:** Context7, MCP, or GitHub tools not working.

**Fix:**
1. Configure MCP servers in `~/.cursor/mcp.json` per Cursor docs.
2. For Context7, define an optional shell helper that exports `CONTEXT7_API_KEY` from your own secure config — never commit keys.
3. Proceed without integrations; core review still works.

## Version mismatch or command syntax mismatch

**Symptom:** Codex flags like `-s read-only` or `-a untrusted` fail.

**Fix:**
1. Run `codex exec --help` and adapt the command shown by the skill.
2. Update Codex CLI to a recent version.
3. File an issue with your CLI version and error message.

## Read-only sandbox failure

**Symptom:** `-s read-only` errors on Linux.

**Fix:**
1. Approve **Degraded containment fallback** (`workspace-write`) only after reading the exact warning that technical write protection is weakened.
2. Check Codex sandbox documentation for your OS (bubblewrap, user namespaces).
3. Do not use `danger-full-access` unless in a disposable environment with explicit approval.

## Symlink destinations refused

**Symptom:** Install or uninstall fails with `refusing to modify symlink destination` or `refusing to remove symlink destination`.

**Note:** Install and uninstall refuse symlink destinations by design. They check the expanded destination path for symlinks before canonicalization and never follow symlink targets.

**Fix:**
1. Remove or replace the symlink manually if you intentionally symlinked the skill directory.
2. Install directly to a real directory named `call-codex`.
3. Use the default path `~/.cursor/skills/call-codex` when possible.

## Path canonicalization unavailable

**Symptom:** `could not canonicalize destination path safely`.

**Note:** Path normalization may depend on standard tools such as `realpath`, `readlink`, or Python 3. Behavior can vary between Linux and macOS.

**Fix:**
1. Ensure `realpath` or Python 3 is available on your system.
2. Use an absolute or `~`-expanded destination path.
3. Create parent directories before custom installs when needed.

## Installer refuses destination path

**Symptom:** `install.sh` or `uninstall.sh` rejects the destination.

**Fix:**
1. Ensure the destination basename is exactly `call-codex`.
2. Use the default path `~/.cursor/skills/call-codex` when possible.
3. For custom paths outside `~/.cursor/skills/`, pass `--allow-custom-outside-cursor-skills`.
4. Do not target `/`, `$HOME`, `$HOME/.cursor`, or `$HOME/.cursor/skills`.

## Shell profile / environment variables

**Symptom:** Codex cannot find credentials or optional integration variables.

**Fix:**
1. Launch Cursor from a shell where `codex` is already on `PATH`.
2. Optionally set `CODEX_REVIEW_ENV_FILE` to a private environment file (see `.env.example`).
3. Do not rely on automatic `.bashrc` / `.zshrc` sourcing — it is intentionally disabled.