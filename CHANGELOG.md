# Changelog

## [0.2.0] - 2026-06-26

### Changed

- **Codex-first planning:** Codex is now the first read-only repository investigator and implementation planner
- **Launcher-only Cursor:** Before Codex runs, Cursor must not read the repository, inspect Git, call MCPs, build auto-context bundles, or create its own implementation plan
- Renamed planning workflow from review depth to **planning depth** (`Codex planning depth` popup)
- Prompt files now use `codex-plan.*` temporary paths instead of `codex-review.*`
- Workflow-only mode stops after prompt/command preview; run-approval popup is deferred to a later turn
- Normal mode: planning-depth popup, prompt preview, then run-approval popup with `Cancel / Not yet` as default
- Removed default post-implementation second-opinion reviewer role from the skill contract
- Updated README, docs, examples, smoke tests, and doctor drift detection for v0.2.0

### Security

- No change to read-only containment defaults; workspace-write remains explicit opt-in only
- Cursor no longer pre-gathers git diffs or file contents before user-approved Codex execution

## [0.1.3] - 2026-06-24

### Changed

- Pinned primary Codex model to `gpt-5.5` for `/call-codex` reviews
- Deep review uses `model_reasoning_effort="xhigh"`; Standard uses `high`; Quick uses `medium`
- Documented explicit primary deep-review command with `-s read-only` and `-a untrusted`
- Failure handling now stops on `gpt-5.5` unavailability instead of silently falling back to another model or downgrading effort

### Security

- No change to read-only containment defaults; workspace-write remains explicit opt-in only

## [0.1.2] - 2026-06-21

### Security

- Rejected symlink destinations before path canonicalization during install and uninstall
- Prevented install and uninstall operations from following symlink targets
- Added lifecycle coverage for symlink safety behavior

### Changed

- Improved cross-platform path canonicalization fallback handling
- Extended CI and smoke tests to validate path-safety helpers

### Fixed

- Integrated shared path-safety validation into the actual installer and uninstaller execution paths
- Removed legacy fixed prompt-file and shell-profile sourcing instructions from the Cursor skill
- Aligned smoke tests, lifecycle tests, CI, README, and runtime behavior with v0.1.2 safety claims
- Rejected symlink parent directories during destination validation to prevent logical/physical path bypass
- Fixed symlink-parent rejection not aborting validation when called from `if ! path_safety_validate_dest`
- Removed unsafe absolute-path fallback when path canonicalization tools are unavailable
- Resolved workflow-only contradiction: run-approval popup is deferred to a later turn, not shown in the same turn
- Added `skill-release` marker and doctor drift detection for stale local installs

## [0.1.1] - 2026-06-21

### Changed

- Hardened install and uninstall destination validation
- Added explicit opt-in for custom installation paths outside Cursor skills directories
- Replaced fixed temporary prompt paths with private per-invocation temporary files
- Removed automatic shell-profile sourcing
- Clarified degraded containment semantics for workspace-write fallback
- Added privacy and data-boundary documentation
- Added install/uninstall lifecycle tests
- Added GitHub Actions CI

### Security

- Reduced risk of unsafe recursive deletion during install and uninstall
- Reduced accidental persistence of review prompt context in shared temporary directories

## [0.1.0] - 2026-06-21

### Added

- Initial public experimental release
- Read-only Codex review skill for Cursor
- Installation, uninstall, and diagnostic scripts
- Documentation, examples, and smoke tests
- Explicit approval gates for risky and state-changing actions
- Optional integration guidance