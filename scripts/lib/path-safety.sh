#!/usr/bin/env bash
# Shared destination validation for install/uninstall scripts.
# Source this file; do not execute directly.

SKILL_BASENAME="call-codex"

# Set by path_safety_validate_dest.
PATH_SAFETY_EXPANDED_DEST=""
PATH_SAFETY_CANONICAL_DEST=""

path_safety_expand_path() {
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

path_safety_expand_tilde() {
  path_safety_expand_path "$1"
}

path_safety_is_symlink() {
  [[ -L "$1" ]]
}

path_safety_physical_pwd() {
  local dir="$1"
  (cd "${dir}" && pwd -P)
}

# Reject symlink components in existing parent directories of a path.
path_safety_refuse_symlink_parents() {
  local path="$1"
  local current="/"
  local remainder="${path#/}"
  local part

  [[ "${path}" == /* ]] || return 0

  while [[ -n "${remainder}" ]]; do
    if [[ "${remainder}" == */* ]]; then
      part="${remainder%%/*}"
      remainder="${remainder#*/}"
    else
      part="${remainder}"
      remainder=""
    fi

    current="${current%/}/${part}"

    if [[ -n "${remainder}" ]]; then
      if [[ -e "${current}" || -L "${current}" ]]; then
        if [[ -L "${current}" ]]; then
          echo "error: refusing path with symlink parent component: ${current}" >&2
          echo "error: remove or replace the symlink manually if this is intentional" >&2
          return 1
        fi
      fi
    fi
  done

  return 0
}

path_safety_refuse_symlink_dest() {
  local dest="$1"
  local operation="${2:-modify}"

  if ! path_safety_is_symlink "${dest}"; then
    return 0
  fi

  case "${operation}" in
    remove)
      echo "error: refusing to remove symlink destination: ${dest}" >&2
      ;;
    *)
      echo "error: refusing to modify symlink destination: ${dest}" >&2
      ;;
  esac
  echo "error: remove or replace the symlink manually if this is intentional" >&2
  return 1
}

path_safety_canonicalize_non_symlink_path() {
  local expanded="$1"
  local resolved parent base

  case "${expanded}" in
    ""|"/"|"."|"..")
      return 1
      ;;
  esac

  if [[ -e "${expanded}" ]]; then
    if command -v realpath >/dev/null 2>&1; then
      resolved="$(realpath "${expanded}" 2>/dev/null || true)"
      if [[ -n "${resolved:-}" ]]; then
        printf '%s\n' "${resolved}"
        return 0
      fi
    fi

    if command -v readlink >/dev/null 2>&1; then
      resolved="$(readlink -f "${expanded}" 2>/dev/null || true)"
      if [[ -n "${resolved:-}" ]]; then
        printf '%s\n' "${resolved}"
        return 0
      fi
    fi

    if command -v python3 >/dev/null 2>&1; then
      resolved="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${expanded}" 2>/dev/null || true)"
      if [[ -n "${resolved:-}" ]]; then
        printf '%s\n' "${resolved}"
        return 0
      fi
    fi

    echo "error: could not canonicalize destination path safely: ${expanded}" >&2
    echo "error: install realpath, readlink, or Python 3 for path normalization" >&2
    return 1
  fi

  parent="$(dirname "${expanded}")"
  base="$(basename "${expanded}")"

  if [[ -d "${parent}" ]]; then
    resolved="$(path_safety_physical_pwd "${parent}")/${base}"
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

  if command -v python3 >/dev/null 2>&1; then
    resolved="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${expanded}" 2>/dev/null || true)"
    if [[ -n "${resolved:-}" ]]; then
      printf '%s\n' "${resolved}"
      return 0
    fi
  fi

  echo "error: could not canonicalize destination path safely: ${expanded}" >&2
  echo "error: install realpath, readlink, or Python 3 for path normalization" >&2
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
  local prefix

  prefix="$(path_safety_physical_pwd "${home}/.cursor/skills" 2>/dev/null || printf '%s' "${home}/.cursor/skills")/"
  [[ "${dest}" == "${prefix}"* ]]
}

path_safety_validate_dest() {
  local raw_dest="$1"
  local allow_outside="${2:-0}"
  local home="${3:-${HOME}}"
  local expanded canonical base

  PATH_SAFETY_EXPANDED_DEST=""
  PATH_SAFETY_CANONICAL_DEST=""

  case "${raw_dest}" in
    "~"|"${home}"|"${home}/.cursor"|"${home}/.cursor/skills"|"/"|"."|"..")
      echo "error: refusing unsafe destination: ${raw_dest}" >&2
      return 1
      ;;
  esac

  expanded="$(path_safety_expand_path "${raw_dest}")"
  PATH_SAFETY_EXPANDED_DEST="${expanded}"

  if path_safety_is_symlink "${expanded}"; then
    echo "error: refusing to use symlink destination: ${expanded}" >&2
    echo "error: remove or replace the symlink manually if this is intentional" >&2
    return 1
  fi

  if ! path_safety_refuse_symlink_parents "${expanded}"; then
    return 1
  fi

  if ! canonical="$(path_safety_canonicalize_non_symlink_path "${expanded}")"; then
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

  PATH_SAFETY_CANONICAL_DEST="${canonical}"
  return 0
}

path_safety_print_uninstall_plan() {
  local raw_dest="$1"
  local expanded_dest="$2"
  local canonical_dest="$3"
  local yes="${4:-0}"

  echo "Uninstall plan"
  echo "--------------"
  echo "Requested destination: ${raw_dest}"
  echo "Expanded destination:  ${expanded_dest}"
  echo "Canonical destination: ${canonical_dest}"

  if [[ -e "${expanded_dest}" ]]; then
    echo "Exists: yes"
  else
    echo "Exists: no"
  fi

  if [[ -L "${expanded_dest}" ]]; then
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