#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/path-safety.sh
source "${SCRIPT_DIR}/lib/path-safety.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_SOURCE="${REPO_ROOT}/skills/call-codex"
DEFAULT_DEST="${HOME}/.cursor/skills/call-codex"
DEST="${DEFAULT_DEST}"
FORCE=0
ALLOW_OUTSIDE=0

usage() {
  cat <<'EOF'
Install the call-codex Cursor skill.

Usage:
  ./scripts/install.sh [--dest PATH] [--force] [--allow-custom-outside-cursor-skills]

Options:
  --dest PATH                              Custom install destination (default: ~/.cursor/skills/call-codex)
  --force                                  Overwrite an existing installation
  --allow-custom-outside-cursor-skills     Allow destinations outside ~/.cursor/skills/
  -h, --help                               Show this help message
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
    --allow-custom-outside-cursor-skills)
      ALLOW_OUTSIDE=1
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

EXPANDED_DEST="$(path_safety_expand_path "${DEST}")"
path_safety_refuse_symlink_dest "${EXPANDED_DEST}" "modify"

if ! path_safety_validate_dest "${DEST}" "${ALLOW_OUTSIDE}" "${HOME}"; then
  exit 1
fi

CANONICAL_DEST="${PATH_SAFETY_CANONICAL_DEST}"
OPERATIONAL_DEST="${PATH_SAFETY_EXPANDED_DEST}"

if [[ -e "${OPERATIONAL_DEST}" ]]; then
  if [[ "${FORCE}" -eq 0 ]]; then
    echo "error: destination already exists: ${OPERATIONAL_DEST}" >&2
    echo "Use --force to overwrite." >&2
    exit 1
  fi

  echo "Replacing existing installation at:"
  echo "  expanded:   ${OPERATIONAL_DEST}"
  echo "  canonical:  ${CANONICAL_DEST}"
  rm -rf "${OPERATIONAL_DEST}"
fi

mkdir -p "${OPERATIONAL_DEST}"
cp -a "${SKILL_SOURCE}/." "${OPERATIONAL_DEST}/"

echo "Installed call-codex skill to: ${OPERATIONAL_DEST}"
echo
echo "Next steps:"
echo "  1. Restart Cursor or reload skills if needed."
echo "  2. Run ./scripts/doctor.sh to verify setup."
echo "  3. In Cursor, try: /call-codex review this implementation"
echo
echo "Note: Codex CLI must be installed and authenticated separately."