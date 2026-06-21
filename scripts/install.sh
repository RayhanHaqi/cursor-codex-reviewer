#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_SOURCE="${REPO_ROOT}/skills/call-codex"
DEFAULT_DEST="${HOME}/.cursor/skills/call-codex"
DEST="${DEFAULT_DEST}"
FORCE=0

usage() {
  cat <<'EOF'
Install the call-codex Cursor skill.

Usage:
  ./scripts/install.sh [--dest PATH] [--force]

Options:
  --dest PATH   Custom install destination (default: ~/.cursor/skills/call-codex)
  --force       Overwrite an existing installation
  -h, --help    Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      [[ $# -ge 2 ]] || { echo "error: --dest requires a path" >&2; exit 1; }
      DEST="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
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

if [[ ! -f "${SKILL_SOURCE}/SKILL.md" ]]; then
  echo "error: required source file not found: ${SKILL_SOURCE}/SKILL.md" >&2
  exit 1
fi

if [[ -e "${DEST}" ]]; then
  if [[ "${FORCE}" -eq 0 ]]; then
    echo "error: destination already exists: ${DEST}" >&2
    echo "Use --force to overwrite." >&2
    exit 1
  fi
  echo "Removing existing installation at ${DEST}"
  rm -rf "${DEST}"
fi

mkdir -p "${DEST}"
cp -a "${SKILL_SOURCE}/." "${DEST}/"

echo "Installed call-codex skill to: ${DEST}"
echo
echo "Next steps:"
echo "  1. Restart Cursor or reload skills if needed."
echo "  2. Run ./scripts/doctor.sh to verify setup."
echo "  3. In Cursor, try: /call-codex review this implementation"
echo
echo "Note: Codex CLI must be installed and authenticated separately."