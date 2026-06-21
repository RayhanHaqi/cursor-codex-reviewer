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

REQUIRED_FILES=(
  README.md
  LICENSE
  CHANGELOG.md
  CONTRIBUTING.md
  .gitignore
  .env.example
  skills/call-codex/SKILL.md
  scripts/install.sh
  scripts/uninstall.sh
  scripts/doctor.sh
  scripts/lib/path-safety.sh
  docs/design.md
  docs/safety-model.md
  docs/limitations.md
  docs/troubleshooting.md
  examples/review-implementation.md
  examples/review-plan.md
  examples/review-diff.md
  examples/sample-output.md
  tests/smoke-test.sh
  tests/lifecycle-test.sh
  .github/workflows/ci.yml
)

for f in "${REQUIRED_FILES[@]}"; do
  require_file "${REPO_ROOT}/${f}"
done

echo

SHELL_SCRIPTS=(
  scripts/install.sh
  scripts/uninstall.sh
  scripts/doctor.sh
  scripts/lib/path-safety.sh
  tests/smoke-test.sh
  tests/lifecycle-test.sh
)

for s in "${SHELL_SCRIPTS[@]}"; do
  if bash -n "${REPO_ROOT}/${s}"; then
    pass "bash -n ${s}"
  else
    fail "bash -n ${s}"
  fi
done

for s in scripts/install.sh scripts/uninstall.sh scripts/doctor.sh tests/smoke-test.sh tests/lifecycle-test.sh; do
  require_executable "${REPO_ROOT}/${s}"
done

echo

SKILL_FILE="${REPO_ROOT}/skills/call-codex/SKILL.md"
require_grep "${SKILL_FILE}" "read-only" "SKILL.md mentions read-only"
require_grep "${SKILL_FILE}" "explicit approval" "SKILL.md mentions explicit approval"
require_grep "${SKILL_FILE}" "workspace-write" "SKILL.md mentions workspace-write"
require_grep "${SKILL_FILE}" "structured review" "SKILL.md mentions structured review"
require_grep "${SKILL_FILE}" "commit" "SKILL.md mentions commit"
require_grep "${SKILL_FILE}" "push" "SKILL.md mentions push"
require_grep "${SKILL_FILE}" "mktemp" "SKILL.md mentions mktemp"
require_grep "${SKILL_FILE}" "chmod 600" "SKILL.md mentions chmod 600"
require_grep "${SKILL_FILE}" "trap" "SKILL.md mentions cleanup trap"
require_grep "${SKILL_FILE}" "CODEX_REVIEW_ENV_FILE" "SKILL.md mentions CODEX_REVIEW_ENV_FILE"

echo

README_FILE="${REPO_ROOT}/README.md"
require_grep "${README_FILE}" "Experimental / v0.1.1" "README mentions Experimental / v0.1.1"
require_grep "${README_FILE}" "read-only" "README mentions read-only"
require_grep "${README_FILE}" "Cursor" "README mentions Cursor"
require_grep "${README_FILE}" "Codex" "README mentions Codex"
require_grep "${README_FILE}" "Data boundary" "README contains data boundary section"

SAFETY_FILE="${REPO_ROOT}/docs/safety-model.md"
require_grep "${SAFETY_FILE}" "Degraded containment fallback" "safety docs contain Degraded containment fallback"

INSTALL_FILE="${REPO_ROOT}/scripts/install.sh"
UNINSTALL_FILE="${REPO_ROOT}/scripts/uninstall.sh"
require_grep "${INSTALL_FILE}" "path_safety_validate_dest" "installer uses dangerous path checks"
require_grep "${UNINSTALL_FILE}" "path_safety_validate_dest" "uninstaller uses dangerous path checks"
require_grep "${INSTALL_FILE}" "allow-custom-outside-cursor-skills" "installer contains custom outside-root opt-in flag"

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