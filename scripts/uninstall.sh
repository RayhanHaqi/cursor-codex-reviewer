#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/path-safety.sh
source "${SCRIPT_DIR}/lib/path-safety.sh"

DEFAULT_DEST="${HOME}/.cursor/skills/call-codex"
DEST="${DEFAULT_DEST}"
YES=0
ALLOW_OUTSIDE=0

usage() {
  cat <<'EOF'
Uninstall the call-codex Cursor skill.

Usage:
  ./scripts/uninstall.sh [--dest PATH] [--yes] [--allow-custom-outside-cursor-skills]

Options:
  --dest PATH                              Custom skill destination (default: ~/.cursor/skills/call-codex)
  --yes                                    Skip confirmation prompt
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
    --yes)
      YES=1
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

EXPANDED_DEST="$(path_safety_expand_path "${DEST}")"
path_safety_refuse_symlink_dest "${EXPANDED_DEST}" "remove"

if ! path_safety_validate_dest "${DEST}" "${ALLOW_OUTSIDE}" "${HOME}"; then
  exit 1
fi

CANONICAL_DEST="${PATH_SAFETY_CANONICAL_DEST}"
OPERATIONAL_DEST="${PATH_SAFETY_EXPANDED_DEST}"

if [[ ! -e "${OPERATIONAL_DEST}" ]]; then
  echo "Nothing to uninstall. Path does not exist: ${OPERATIONAL_DEST}"
  exit 0
fi

if [[ ! -f "${OPERATIONAL_DEST}/SKILL.md" ]]; then
  echo "error: ${OPERATIONAL_DEST} does not look like a call-codex skill directory (missing SKILL.md)" >&2
  exit 1
fi

path_safety_print_uninstall_plan "${OPERATIONAL_DEST}" "${YES}"
echo

if [[ "${YES}" -eq 0 ]]; then
  read -r -p "Proceed with uninstall? [y/N] " reply
  case "${reply}" in
    y|Y|yes|YES) ;;
    *)
      echo "Uninstall cancelled."
      exit 0
      ;;
  esac
fi

PARENT_DIR="$(dirname "${OPERATIONAL_DEST}")"
rm -rf "${OPERATIONAL_DEST}"

if [[ -d "${PARENT_DIR}" ]]; then
  echo "Parent directory preserved: ${PARENT_DIR}"
fi

echo "Removed: ${OPERATIONAL_DEST}"