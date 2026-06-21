# Contributing

Thank you for considering a contribution to `cursor-codex-reviewer`.

## How to help

- Open an issue for defects, unclear behavior, missing documentation, or environment compatibility problems.
- Keep pull requests scoped to a single concern.
- Preserve read-only-by-default behavior unless there is a documented, user-approved exception.
- Avoid autonomous multi-agent orchestration without prior discussion.
- Do not add telemetry, tracking, analytics, or external services.
- Do not embed private assumptions, paths, credentials, or machine-specific configuration.
- Test shell scripts with `bash -n` and run `tests/smoke-test.sh` before opening a pull request.
- Explain any change that affects safety, approval gates, or sandbox behavior.

## Pull request checklist

- [ ] Changes are documented in README or `docs/` when behavior changes
- [ ] No secrets, tokens, or personal paths were added
- [ ] Shell scripts use `set -euo pipefail`
- [ ] `tests/smoke-test.sh` passes locally

## Code of conduct

Be respectful, precise, and safety-conscious. This project optimizes for predictability and trust.