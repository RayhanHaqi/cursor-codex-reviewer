#!/usr/bin/env bash
set -euo pipefail

DEFAULT_DEST="${HOME}/.cursor/skills/call-codex"
DEST="${DEFAULT_DEST}"
YES=0

usage() {
  cat <<'EOF'
Uninstall the call-codex Cursor skill.

Usage:
  ./scripts/uninstall.sh [--dest PATH] [--yes]

Options:
  --dest PATH   Custom skill destination (default: ~/.cursor/skills/call-codex)
  --yes         Skip confirmation prompt
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
    --yes)
      YES=1
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

# Safety: refuse to delete paths that are too broad.
case "${DEST}" in
  ""|"/"|"${HOME}"|"${HOME}/.cursor"|"${HOME}/.cursor/skills")
    echo "error: refusing to delete unsafe path: ${DEST}" >&2
    exit 1
    ;;
esac

if [[ ! -e "${DEST}" ]]; then
  echo "Nothing to uninstall. Path does not exist: ${DEST}"
  exit 0
fi

if [[ ! -f "${DEST}/SKILL.md" ]]; then
  echo "error: ${DEST} does not look like a call-codex skill directory (missing SKILL.md)" >&2
  exit 1
fi

echo "The following directory will be deleted:"
echo "  ${DEST}"
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

rm -rf "${DEST}"
echo "Removed: ${DEST}"