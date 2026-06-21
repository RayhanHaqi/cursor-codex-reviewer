# Changelog

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