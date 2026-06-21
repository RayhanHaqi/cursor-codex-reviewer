#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

pass() {
  echo "PASS: $*"
  PASS=$((PASS + 1))
}

fail() {
  echo "FAIL: $*" >&2
  FAIL=$((FAIL + 1))
}

require_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    pass "file exists: ${path#${REPO_ROOT}/}"
  else
    fail "missing file: ${path#${REPO_ROOT}/}"
  fi
}

require_executable() {
  local path="$1"
  if [[ -x "${path}" ]]; then
    pass "executable: ${path#${REPO_ROOT}/}"
  else
    fail "not executable: ${path#${REPO_ROOT}/}"
  fi
}

require_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -q "${pattern}" "${file}"; then
    pass "${label}"
  else
    fail "${label} (pattern '${pattern}' not found in ${file#${REPO_ROOT}/})"
  fi
}

echo "cursor-codex-reviewer smoke test"
echo "================================="
echo

cd "${REPO_ROOT}"

# Required files
REQUIRED_FILES=(
  README.md
  LICENSE
  CHANGELOG.md
  CONTRIBUTING.md
  .gitignore
  skills/call-codex/SKILL.md
  scripts/install.sh
  scripts/uninstall.sh
  scripts/doctor.sh
  docs/design.md
  docs/safety-model.md
  docs/limitations.md
  docs/troubleshooting.md
  examples/review-implementation.md
  examples/review-plan.md
  examples/review-diff.md
  examples/sample-output.md
  tests/smoke-test.sh
)

for f in "${REQUIRED_FILES[@]}"; do
  require_file "${REPO_ROOT}/${f}"
done

echo

# Shell script syntax and executability
SHELL_SCRIPTS=(
  scripts/install.sh
  scripts/uninstall.sh
  scripts/doctor.sh
  tests/smoke-test.sh
)

for s in "${SHELL_SCRIPTS[@]}"; do
  if bash -n "${REPO_ROOT}/${s}"; then
    pass "bash -n ${s}"
  else
    fail "bash -n ${s}"
  fi
  require_executable "${REPO_ROOT}/${s}"
done

echo

# SKILL.md required concepts
SKILL_FILE="${REPO_ROOT}/skills/call-codex/SKILL.md"
require_grep "${SKILL_FILE}" "read-only" "SKILL.md mentions read-only"
require_grep "${SKILL_FILE}" "explicit approval" "SKILL.md mentions explicit approval"
require_grep "${SKILL_FILE}" "workspace-write" "SKILL.md mentions workspace-write"
require_grep "${SKILL_FILE}" "structured review" "SKILL.md mentions structured review"
require_grep "${SKILL_FILE}" "commit" "SKILL.md mentions commit"
require_grep "${SKILL_FILE}" "push" "SKILL.md mentions push"

echo

# README required concepts
README_FILE="${REPO_ROOT}/README.md"
require_grep "${README_FILE}" "Experimental / v0.1.0" "README mentions Experimental / v0.1.0"
require_grep "${README_FILE}" "read-only" "README mentions read-only"
require_grep "${README_FILE}" "Cursor" "README mentions Cursor"
require_grep "${README_FILE}" "Codex" "README mentions Codex"

echo
echo "================================="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
  echo "Result: SMOKE TEST FAILED"
  exit 1
fi

echo "Result: SMOKE TEST PASSED"
exit 0