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

require_no_grep() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -q "${pattern}" "${file}"; then
    fail "${label} (forbidden pattern '${pattern}' found in ${file#${REPO_ROOT}/})"
  else
    pass "${label}"
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
require_grep "${SKILL_FILE}" "skill-release: 0.1.3" "SKILL.md includes skill-release marker"
require_grep "${SKILL_FILE}" "gpt-5.5" "SKILL.md pins primary model gpt-5.5"
require_grep "${SKILL_FILE}" 'model_reasoning_effort="xhigh"' "SKILL.md documents deep-review xhigh effort"
require_grep "${SKILL_FILE}" "No silent fallback" "SKILL.md forbids silent model downgrade/fallback"
require_no_grep "${SKILL_FILE}" "codex -m gpt-5.3-codex" "SKILL.md excludes gpt-5.3-codex as executable model flag"
require_grep "${SKILL_FILE}" "do not silently retry with \`gpt-5.3-codex\`" "SKILL.md forbids silent gpt-5.3-codex fallback"
require_grep "${SKILL_FILE}" "read-only" "SKILL.md mentions read-only"
require_grep "${SKILL_FILE}" "explicit approval" "SKILL.md mentions explicit approval"
require_grep "${SKILL_FILE}" "workspace-write" "SKILL.md mentions workspace-write"
require_grep "${SKILL_FILE}" "mktemp" "SKILL.md mentions mktemp"
require_grep "${SKILL_FILE}" "chmod 600" "SKILL.md mentions chmod 600"
require_grep "${SKILL_FILE}" "trap" "SKILL.md mentions cleanup trap"
require_no_grep "${SKILL_FILE}" "/tmp/codex-review-prompt.md" "SKILL.md excludes fixed prompt path"
require_no_grep "${SKILL_FILE}" "CODEX_REVIEW_ENV_FILE" "SKILL.md excludes automatic env file sourcing"
require_no_grep "${SKILL_FILE}" '\.bashrc' "SKILL.md excludes shell-profile references"
require_no_grep "${SKILL_FILE}" 'source.*\.profile' "SKILL.md excludes shell-profile sourcing instructions"
require_grep "${SKILL_FILE}" "show the run-approval popup in the same turn" "SKILL.md defers workflow-only run-approval popup"
require_grep "${SKILL_FILE}" "Do not ask the run-approval popup yet" "SKILL.md stops before workflow-only run approval"

echo

README_FILE="${REPO_ROOT}/README.md"
require_grep "${README_FILE}" "Experimental / v0.1.3" "README mentions Experimental / v0.1.3"
require_grep "${README_FILE}" "read-only" "README mentions read-only"
require_grep "${README_FILE}" "Cursor" "README mentions Cursor"
require_grep "${README_FILE}" "Codex" "README mentions Codex"
require_grep "${README_FILE}" "Data boundary" "README contains data boundary section"

SAFETY_FILE="${REPO_ROOT}/docs/safety-model.md"
require_grep "${SAFETY_FILE}" "Degraded containment fallback" "safety docs contain Degraded containment fallback"

INSTALL_FILE="${REPO_ROOT}/scripts/install.sh"
UNINSTALL_FILE="${REPO_ROOT}/scripts/uninstall.sh"
require_grep "${INSTALL_FILE}" 'source "${SCRIPT_DIR}/lib/path-safety.sh"' "installer sources path-safety.sh"
require_grep "${UNINSTALL_FILE}" 'source "${SCRIPT_DIR}/lib/path-safety.sh"' "uninstaller sources path-safety.sh"
require_grep "${INSTALL_FILE}" "path_safety_validate_dest" "installer uses path_safety_validate_dest"
require_grep "${UNINSTALL_FILE}" "path_safety_validate_dest" "uninstaller uses path_safety_validate_dest"
require_grep "${INSTALL_FILE}" "allow-custom-outside-cursor-skills" "installer includes custom outside-root opt-in flag"
require_grep "${UNINSTALL_FILE}" "allow-custom-outside-cursor-skills" "uninstaller includes custom outside-root opt-in flag"
require_grep "${INSTALL_FILE}" 'rm -rf --' "installer uses safe rm delimiter"
require_grep "${UNINSTALL_FILE}" 'rm -rf --' "uninstaller uses safe rm delimiter"
require_grep "${REPO_ROOT}/scripts/lib/path-safety.sh" "path_safety_refuse_symlink_dest" "path safety includes symlink rejection helper"
require_grep "${REPO_ROOT}/scripts/lib/path-safety.sh" "path_safety_refuse_symlink_parents" "path safety includes symlink parent rejection helper"
require_grep "${REPO_ROOT}/scripts/lib/path-safety.sh" "path_safety_physical_pwd" "path safety uses physical pwd for prefix checks"
require_grep "${REPO_ROOT}/tests/lifecycle-test.sh" "Symlink safety tests" "lifecycle test includes symlink coverage"
require_grep "${REPO_ROOT}/tests/lifecycle-test.sh" "Symlink parent safety tests" "lifecycle test includes symlink parent coverage"

DOCTOR_FILE="${REPO_ROOT}/scripts/doctor.sh"
require_grep "${DOCTOR_FILE}" "skill-release" "doctor checks skill-release marker"
require_grep "${DOCTOR_FILE}" "LEGACY_SKILL_PATTERNS" "doctor defines legacy skill patterns"
require_grep "${DOCTOR_FILE}" "/tmp/codex-review-prompt.md" "doctor detects legacy fixed prompt path"
require_grep "${DOCTOR_FILE}" "install.sh --force" "doctor recommends force reinstall for drift"

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