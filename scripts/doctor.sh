#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_SKILL_FILE="${REPO_ROOT}/skills/call-codex/SKILL.md"

DEFAULT_SKILL_PATH="${HOME}/.cursor/skills/call-codex"
SKILL_PATH="${DEFAULT_SKILL_PATH}"
ERRORS=0
WARNINGS=0
NOTES=0

LEGACY_SKILL_PATTERNS=(
  '/tmp/codex-review-prompt.md'
  'CODEX_REVIEW_ENV_FILE'
  '\.bashrc'
)

usage() {
  cat <<'EOF'
Diagnose call-codex setup.

Usage:
  ./scripts/doctor.sh [--skill-path PATH]

Options:
  --skill-path PATH   Custom installed skill path
  -h, --help          Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill-path)
      [[ $# -ge 2 ]] || { echo "error: --skill-path requires a path" >&2; exit 1; }
      SKILL_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

note() {
  echo "NOTE: $*"
  NOTES=$((NOTES + 1))
}

warn() {
  echo "WARNING: $*" >&2
  WARNINGS=$((WARNINGS + 1))
}

error() {
  echo "ERROR: $*" >&2
  ERRORS=$((ERRORS + 1))
}

version_of() {
  local cmd="$1"
  if command -v "${cmd}" >/dev/null 2>&1; then
    "${cmd}" --version 2>/dev/null || "${cmd}" -V 2>/dev/null || echo "available (version unknown)"
  else
    echo "not found"
  fi
}

echo "cursor-codex-reviewer doctor"
echo "=============================="
echo

# Cursor CLI (optional — many users only use the desktop app)
if command -v cursor >/dev/null 2>&1; then
  echo "cursor: $(version_of cursor)"
else
  note "cursor CLI not found in PATH. The desktop app may still work; this is not blocking."
fi

# Codex CLI (blocking for actual review runs)
if command -v codex >/dev/null 2>&1; then
  echo "codex:  $(version_of codex)"
  if ! codex exec --help >/dev/null 2>&1; then
    warn "codex is installed but 'codex exec --help' failed. Command syntax may differ from this skill."
  fi
else
  error "codex CLI not found in PATH. Install and authenticate Codex before using /call-codex."
fi

echo

# Installed skill
if [[ -d "${SKILL_PATH}" ]]; then
  echo "skill:  installed at ${SKILL_PATH}"
else
  error "call-codex skill not found at ${SKILL_PATH}. Run ./scripts/install.sh"
fi

INSTALLED_SKILL_FILE="${SKILL_PATH}/SKILL.md"

if [[ -f "${INSTALLED_SKILL_FILE}" ]]; then
  if [[ -r "${INSTALLED_SKILL_FILE}" ]]; then
    echo "skill file: readable (${INSTALLED_SKILL_FILE})"
  else
    error "SKILL.md exists but is not readable: ${INSTALLED_SKILL_FILE}"
  fi
else
  error "SKILL.md missing in ${SKILL_PATH}"
fi

if [[ -f "${INSTALLED_SKILL_FILE}" && -f "${REPO_SKILL_FILE}" ]]; then
  installed_release=""
  repo_release=""

  if grep -qE '^skill-release:[[:space:]]*' "${INSTALLED_SKILL_FILE}"; then
    installed_release="$(grep -E '^skill-release:[[:space:]]*' "${INSTALLED_SKILL_FILE}" | head -n1 | sed 's/^skill-release:[[:space:]]*//')"
  fi

  if grep -qE '^skill-release:[[:space:]]*' "${REPO_SKILL_FILE}"; then
    repo_release="$(grep -E '^skill-release:[[:space:]]*' "${REPO_SKILL_FILE}" | head -n1 | sed 's/^skill-release:[[:space:]]*//')"
  fi

  if [[ -n "${installed_release}" && -n "${repo_release}" ]]; then
    if [[ "${installed_release}" == "${repo_release}" ]]; then
      echo "skill release: ${installed_release} (matches repo)"
    else
      warn "installed skill release (${installed_release}) differs from repo (${repo_release}). Run ./scripts/install.sh --force to sync."
    fi
  elif [[ -z "${installed_release}" ]]; then
    warn "installed SKILL.md has no skill-release marker. It may be stale. Run ./scripts/install.sh --force to sync."
  fi

  legacy_found=0
  for pattern in "${LEGACY_SKILL_PATTERNS[@]}"; do
    if grep -qE "${pattern}" "${INSTALLED_SKILL_FILE}"; then
      if [[ "${legacy_found}" -eq 0 ]]; then
        warn "installed SKILL.md contains legacy patterns from an older release:"
        legacy_found=1
      fi
      warn "  - matches: ${pattern}"
    fi
  done

  if [[ "${legacy_found}" -eq 1 ]]; then
    warn "Run ./scripts/install.sh --force from the repo to replace the stale install."
  fi

  if ! cmp -s "${INSTALLED_SKILL_FILE}" "${REPO_SKILL_FILE}"; then
    if [[ "${legacy_found}" -eq 0 && ( -z "${installed_release}" || -z "${repo_release}" || "${installed_release}" != "${repo_release}" ) ]]; then
      note "installed SKILL.md differs from repo copy (content drift detected)."
    elif [[ "${legacy_found}" -eq 0 && -n "${installed_release}" && -n "${repo_release}" && "${installed_release}" == "${repo_release}" ]]; then
      note "installed SKILL.md differs from repo copy despite matching skill-release marker (local edits or packaging drift)."
    fi
  fi
elif [[ ! -f "${REPO_SKILL_FILE}" ]]; then
  note "repo SKILL.md not found at ${REPO_SKILL_FILE}; skipping release/drift checks."
fi

echo

# Optional integrations
if [[ -f "${HOME}/.cursor/mcp.json" ]]; then
  note "Cursor MCP config found at ~/.cursor/mcp.json. Optional integrations may be available."
else
  note "No ~/.cursor/mcp.json found. Core review still works; optional MCP integrations are unavailable."
fi

note "The call-codex skill does not source shell profiles or environment files. Launch Cursor with codex on PATH and required variables already configured."

echo
echo "Summary"
echo "-------"
echo "Blocking errors: ${ERRORS}"
echo "Warnings:        ${WARNINGS}"
echo "Optional notes:  ${NOTES}"

if [[ "${ERRORS}" -gt 0 ]]; then
  echo
  echo "Result: FAIL — fix blocking errors before using /call-codex."
  exit 1
fi

if [[ "${WARNINGS}" -gt 0 ]]; then
  echo
  echo "Result: PASS WITH WARNINGS"
  exit 0
fi

echo
echo "Result: PASS"
exit 0