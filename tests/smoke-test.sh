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
require_grep "${SKILL_FILE}" "skill-release: 0.2.0" "SKILL.md includes skill-release marker"
require_grep "${SKILL_FILE}" "gpt-5.5" "SKILL.md pins primary model gpt-5.5"
require_grep "${SKILL_FILE}" 'model_reasoning_effort="<selected-effort>"' "SKILL.md documents selected-effort placeholder"
require_grep "${SKILL_FILE}" "Do not silently change models" "SKILL.md forbids silent model downgrade/fallback"
require_grep "${SKILL_FILE}" '\-s read-only' "SKILL.md documents -s read-only flag"
require_grep "${SKILL_FILE}" '\-a untrusted' "SKILL.md documents -a untrusted flag"
require_grep "${SKILL_FILE}" '\-C "\$PWD"' "SKILL.md documents -C \"\$PWD\" flag"
require_grep "${SKILL_FILE}" 'exec - < "\${PROMPT_FILE}"' "SKILL.md documents exec stdin from PROMPT_FILE"
require_grep "${SKILL_FILE}" "read-only" "SKILL.md mentions read-only"
require_grep "${SKILL_FILE}" "Codex planning depth" "SKILL.md defines planning-depth popup"
require_grep "${SKILL_FILE}" "Cancel / Not yet" "SKILL.md defines run-approval default"
require_grep "${SKILL_FILE}" "workspace-write" "SKILL.md mentions workspace-write"
require_grep "${SKILL_FILE}" "codex-plan" "SKILL.md uses codex-plan prompt files"
require_grep "${SKILL_FILE}" "mktemp" "SKILL.md mentions mktemp"
require_grep "${SKILL_FILE}" "chmod 600" "SKILL.md mentions chmod 600"
require_grep "${SKILL_FILE}" "trap" "SKILL.md mentions cleanup trap"
require_no_grep "${SKILL_FILE}" "/tmp/codex-review-prompt.md" "SKILL.md excludes fixed prompt path"
require_no_grep "${SKILL_FILE}" "codex-review" "SKILL.md excludes codex-review prompt prefix"
require_no_grep "${SKILL_FILE}" "CODEX_REVIEW_ENV_FILE" "SKILL.md excludes automatic env file sourcing"
require_no_grep "${SKILL_FILE}" '\.bashrc' "SKILL.md excludes shell-profile references"
require_no_grep "${SKILL_FILE}" 'source.*\.profile' "SKILL.md excludes shell-profile sourcing instructions"
require_no_grep "${SKILL_FILE}" "Auto-context bundle" "SKILL.md excludes Cursor auto-context bundle"
require_no_grep "${SKILL_FILE}" "second-opinion reviewer" "SKILL.md excludes default second-opinion reviewer role"
require_grep "${SKILL_FILE}" "launcher" "SKILL.md documents launcher-only Cursor contract"
require_grep "${SKILL_FILE}" "first interaction must never contain" "SKILL.md defers workflow-only run-approval popup"
require_no_grep "${SKILL_FILE}" "Save prompt only" "SKILL.md excludes Save prompt only run-approval option"
require_grep "${SKILL_FILE}" "Failure handling" "SKILL.md documents failure handling"
require_grep "${SKILL_FILE}" "Do not fall back to Cursor-led" "SKILL.md forbids Cursor-led fallback on Codex failure"
require_grep "${SKILL_FILE}" "no default second-opinion" "SKILL.md disclaims post-implementation review role"

echo

README_FILE="${REPO_ROOT}/README.md"
require_grep "${README_FILE}" "Experimental / v0.2.0" "README mentions Experimental / v0.2.0"
require_grep "${README_FILE}" "Codex-first" "README mentions Codex-first"
require_grep "${README_FILE}" "launcher-only" "README mentions launcher-only Cursor"
require_grep "${README_FILE}" "read-only" "README mentions read-only"
require_grep "${README_FILE}" "Cursor" "README mentions Cursor"
require_grep "${README_FILE}" "Codex" "README mentions Codex"
require_grep "${README_FILE}" "Data boundary" "README contains data boundary section"
require_no_grep "${README_FILE}" "second-opinion reviewer" "README excludes default second-opinion reviewer framing"

SAFETY_FILE="${REPO_ROOT}/docs/safety-model.md"
require_grep "${SAFETY_FILE}" "Degraded containment fallback" "safety docs contain Degraded containment fallback"
require_grep "${SAFETY_FILE}" "codex-plan" "safety docs reference codex-plan prompt files"

CHANGELOG_FILE="${REPO_ROOT}/CHANGELOG.md"
require_grep "${CHANGELOG_FILE}" "## \[0.2.0\]" "CHANGELOG documents v0.2.0 release"

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
require_grep "${DOCTOR_FILE}" "codex-review" "doctor detects legacy codex-review prompt prefix"
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
