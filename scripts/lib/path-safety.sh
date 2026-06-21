#!/usr/bin/env bash
# Shared destination validation for install/uninstall scripts.
# Source this file; do not execute directly.

SKILL_BASENAME="call-codex"

path_safety_expand_tilde() {
  local path="$1"
  case "${path}" in
    "~")
      printf '%s\n' "${HOME}"
      ;;
    "~/"*)
      printf '%s\n' "${HOME}/${path:2}"
      ;;
    *)
      printf '%s\n' "${path}"
      ;;
  esac
}

path_safety_canonical_dest() {
  local raw="$1"
  local expanded resolved parent base

  expanded="$(path_safety_expand_tilde "${raw}")"

  case "${expanded}" in
    ""|"/"|"."|"..")
      return 1
      ;;
  esac

  base="$(basename "${expanded}")"
  parent="$(dirname "${expanded}")"

  if [[ -e "${expanded}" ]]; then
    if command -v readlink >/dev/null 2>&1; then
      resolved="$(readlink -f "${expanded}" 2>/dev/null || true)"
    fi
    if [[ -z "${resolved:-}" ]] && command -v realpath >/dev/null 2>&1; then
      resolved="$(realpath "${expanded}" 2>/dev/null || true)"
    fi
    if [[ -n "${resolved:-}" ]]; then
      printf '%s\n' "${resolved}"
      return 0
    fi
    return 1
  fi

  if [[ -d "${parent}" ]]; then
    resolved="$(cd "${parent}" && pwd)/${base}"
    printf '%s\n' "${resolved}"
    return 0
  fi

  if command -v realpath >/dev/null 2>&1; then
    resolved="$(realpath -m "${expanded}" 2>/dev/null || true)"
    if [[ -n "${resolved:-}" ]]; then
      printf '%s\n' "${resolved}"
      return 0
    fi
  fi

  if [[ "${expanded}" == /* ]]; then
    printf '%s\n' "${expanded}"
    return 0
  fi

  return 1
}

path_safety_is_forbidden_dest() {
  local dest="$1"
  local home="${2:-${HOME}}"
  local cursor_dir="${home}/.cursor"
  local cursor_skills="${cursor_dir}/skills"

  case "${dest}" in
    "/"|"${home}"|"${cursor_dir}"|"${cursor_skills}")
      return 0
      ;;
  esac
  return 1
}

path_safety_under_cursor_skills() {
  local dest="$1"
  local home="${2:-${HOME}}"
  local prefix="${home}/.cursor/skills/"

  [[ "${dest}" == "${prefix}"* ]]
}

# Validate a call-codex skill destination.
# Args: dest allow_outside(0|1) home
# Prints canonical path on success; writes errors to stderr.
path_safety_validate_dest() {
  local raw_dest="$1"
  local allow_outside="${2:-0}"
  local home="${3:-${HOME}}"
  local canonical base

  case "${raw_dest}" in
    "~"|"${home}"|"${home}/.cursor"|"${home}/.cursor/skills"|"/"|"."|"..")
      echo "error: refusing unsafe destination: ${raw_dest}" >&2
      return 1
      ;;
  esac

  if ! canonical="$(path_safety_canonical_dest "${raw_dest}")"; then
    echo "error: could not resolve destination path: ${raw_dest}" >&2
    return 1
  fi

  if path_safety_is_forbidden_dest "${canonical}" "${home}"; then
    echo "error: refusing unsafe destination: ${canonical}" >&2
    return 1
  fi

  base="$(basename "${canonical}")"
  if [[ "${base}" != "${SKILL_BASENAME}" ]]; then
    echo "error: destination basename must be exactly '${SKILL_BASENAME}', got '${base}'" >&2
    return 1
  fi

  if [[ "${allow_outside}" -eq 0 ]] && ! path_safety_under_cursor_skills "${canonical}" "${home}"; then
    echo "error: destination must be under ${home}/.cursor/skills/ unless --allow-custom-outside-cursor-skills is set" >&2
    echo "error: resolved destination: ${canonical}" >&2
    return 1
  fi

  printf '%s\n' "${canonical}"
}

# Refuse symlink destinations for destructive operations.
path_safety_refuse_symlink_dest() {
  local dest="$1"
  if [[ -L "${dest}" ]]; then
    echo "error: refusing to modify symlink destination: ${dest}" >&2
    echo "error: remove or replace the symlink manually if this is intentional" >&2
    return 1
  fi
  return 0
}

path_safety_print_uninstall_plan() {
  local dest="$1"
  local yes="${2:-0}"

  echo "Uninstall plan"
  echo "--------------"
  echo "Target path: ${dest}"

  if [[ -e "${dest}" ]]; then
    echo "Exists: yes"
  else
    echo "Exists: no"
  fi

  if [[ -L "${dest}" ]]; then
    echo "Is symlink: yes"
  else
    echo "Is symlink: no"
  fi

  if [[ "${yes}" -eq 1 ]]; then
    echo "Confirmation: skipped (--yes)"
  else
    echo "Confirmation: required"
  fi
}