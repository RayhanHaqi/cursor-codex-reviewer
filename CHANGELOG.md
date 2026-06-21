# Changelog

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