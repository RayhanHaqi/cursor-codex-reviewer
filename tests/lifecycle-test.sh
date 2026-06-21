#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0
TEST_ROOT=""

pass() {
  echo "PASS: $*"
  PASS=$((PASS + 1))
}

fail() {
  echo "FAIL: $*" >&2
  FAIL=$((FAIL + 1))
}

expect_success() {
  local label="$1"
  shift
  if "$@"; then
    pass "${label}"
  else
    fail "${label}"
  fi
}

expect_failure() {
  local label="$1"
  shift
  if "$@"; then
    fail "${label} (expected failure, got success)"
  else
    pass "${label}"
  fi
}

cleanup() {
  if [[ -n "${TEST_ROOT}" && -d "${TEST_ROOT}" ]]; then
    rm -rf "${TEST_ROOT}"
  fi
}
trap cleanup EXIT

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cursor-codex-lifecycle.XXXXXX")"
export HOME="${TEST_ROOT}/home"
mkdir -p "${HOME}/.cursor/skills"

INSTALL="${REPO_ROOT}/scripts/install.sh"
UNINSTALL="${REPO_ROOT}/scripts/uninstall.sh"
DEFAULT_DEST="${HOME}/.cursor/skills/call-codex"
CUSTOM_DEST="${TEST_ROOT}/custom/call-codex"
BAD_DEST="${TEST_ROOT}/custom/not-call-codex"

echo "cursor-codex-reviewer lifecycle test"
echo "===================================="
echo "Isolated HOME: ${HOME}"
echo

# 1. Fresh install succeeds
expect_success "fresh install succeeds" \
  bash "${INSTALL}" --dest "${DEFAULT_DEST}"

# 2. Installed skill file exists
if [[ -f "${DEFAULT_DEST}/SKILL.md" ]]; then
  pass "installed SKILL.md exists"
else
  fail "installed SKILL.md exists"
fi

# 3. Second install without --force fails
expect_failure "second install without --force fails" \
  bash "${INSTALL}" --dest "${DEFAULT_DEST}"

# 4. Reinstall with --force succeeds
expect_success "reinstall with --force succeeds" \
  bash "${INSTALL}" --dest "${DEFAULT_DEST}" --force

# 5. Installer rejects unsafe destinations
for unsafe in "/" "${HOME}" "${HOME}/.cursor" "${HOME}/.cursor/skills"; do
  expect_failure "installer rejects unsafe destination: ${unsafe}" \
    bash "${INSTALL}" --dest "${unsafe}"
done

# 6. Installer rejects wrong basename
mkdir -p "$(dirname "${BAD_DEST}")"
expect_failure "installer rejects custom basename not call-codex" \
  bash "${INSTALL}" --dest "${BAD_DEST}" --allow-custom-outside-cursor-skills

# 7. Custom install outside cursor skills fails without opt-in
expect_failure "custom outside install fails without opt-in flag" \
  bash "${INSTALL}" --dest "${CUSTOM_DEST}"

# 8. Custom install outside succeeds with opt-in and safe basename
expect_success "custom outside install succeeds with opt-in flag" \
  bash "${INSTALL}" --dest "${CUSTOM_DEST}" --allow-custom-outside-cursor-skills

# 9. Uninstall without confirmation does not delete when declined
if printf 'n\n' | bash "${UNINSTALL}" --dest "${CUSTOM_DEST}" --allow-custom-outside-cursor-skills; then
  if [[ -d "${CUSTOM_DEST}" ]]; then
    pass "declined uninstall preserves installation"
  else
    fail "declined uninstall preserves installation"
  fi
else
  fail "declined uninstall command should exit 0 after cancel"
fi

# 10. Uninstall with --yes removes only the skill directory
PARENT="${HOME}/.cursor/skills"
expect_success "uninstall with --yes succeeds" \
  bash "${UNINSTALL}" --dest "${DEFAULT_DEST}" --yes

if [[ ! -e "${DEFAULT_DEST}" ]]; then
  pass "default install removed after --yes uninstall"
else
  fail "default install removed after --yes uninstall"
fi

# 11. Parent directories remain intact
if [[ -d "${PARENT}" ]]; then
  pass "parent directory remains after uninstall"
else
  fail "parent directory remains after uninstall"
fi

if [[ -d "${HOME}/.cursor" ]]; then
  pass ".cursor directory remains after uninstall"
else
  fail ".cursor directory remains after uninstall"
fi

# Custom install still present from test 9
if [[ -d "${CUSTOM_DEST}" ]]; then
  pass "declined custom install still present"
else
  fail "declined custom install still present"
fi

# Cleanup custom install for isolated temp dir hygiene
bash "${UNINSTALL}" --dest "${CUSTOM_DEST}" --allow-custom-outside-cursor-skills --yes >/dev/null

# 12. No writes outside TEST_ROOT (HOME is under TEST_ROOT)
if [[ "${HOME}" == "${TEST_ROOT}"/* ]]; then
  pass "test HOME confined to temporary root"
else
  fail "test HOME confined to temporary root"
fi

echo
echo "Symlink safety tests"
echo "--------------------"

SYMLINK_DEST="${HOME}/.cursor/skills/call-codex"
SYMLINK_TARGET="${TEST_ROOT}/symlink-target"
MARKER_FILE="${SYMLINK_TARGET}/preserve-me.txt"

mkdir -p "${HOME}/.cursor/skills"
rm -rf "${SYMLINK_DEST}"
mkdir -p "${SYMLINK_TARGET}"
printf 'preserve\n' > "${MARKER_FILE}"
ln -s "${SYMLINK_TARGET}" "${SYMLINK_DEST}"

expect_failure "installer rejects symlink destination" \
  bash "${INSTALL}" --dest "${SYMLINK_DEST}"

expect_failure "installer with --force rejects symlink destination" \
  bash "${INSTALL}" --dest "${SYMLINK_DEST}" --force

if [[ -f "${MARKER_FILE}" ]] && [[ -L "${SYMLINK_DEST}" ]]; then
  pass "symlink target remains untouched after rejected install attempts"
else
  fail "symlink target remains untouched after rejected install attempts"
fi

expect_failure "uninstaller rejects symlink destination" \
  bash "${UNINSTALL}" --dest "${SYMLINK_DEST}"

expect_failure "uninstaller with --yes rejects symlink destination" \
  bash "${UNINSTALL}" --dest "${SYMLINK_DEST}" --yes

if [[ -f "${MARKER_FILE}" ]] && [[ -L "${SYMLINK_DEST}" ]]; then
  pass "symlink target remains untouched after rejected uninstall attempts"
else
  fail "symlink target remains untouched after rejected uninstall attempts"
fi

if [[ -d "${HOME}/.cursor/skills" ]]; then
  pass "parent directory remains intact after symlink rejection tests"
else
  fail "parent directory remains intact after symlink rejection tests"
fi

echo
echo "Symlink parent safety tests"
echo "---------------------------"

SKILLS_PARENT="${HOME}/.cursor/skills"
SKILLS_SYMLINK_TARGET="${TEST_ROOT}/skills-parent-target"
SKILLS_PARENT_BACKUP="${TEST_ROOT}/skills-parent-backup"

rm -rf "${SKILLS_SYMLINK_TARGET}" "${SKILLS_PARENT_BACKUP}"
mkdir -p "${SKILLS_SYMLINK_TARGET}"
if [[ -d "${SKILLS_PARENT}" ]]; then
  mv "${SKILLS_PARENT}" "${SKILLS_PARENT_BACKUP}"
fi
ln -s "${SKILLS_SYMLINK_TARGET}" "${SKILLS_PARENT}"

PARENT_SYMLINK_DEST="${SKILLS_PARENT}/call-codex"
rm -rf "${PARENT_SYMLINK_DEST}"

expect_failure "installer rejects destination under symlinked skills parent" \
  bash "${INSTALL}" --dest "${PARENT_SYMLINK_DEST}"

expect_failure "installer with --force rejects destination under symlinked skills parent" \
  bash "${INSTALL}" --dest "${PARENT_SYMLINK_DEST}" --force

if [[ ! -e "${PARENT_SYMLINK_DEST}" && ! -L "${PARENT_SYMLINK_DEST}" ]]; then
  pass "symlinked skills parent remains without call-codex install"
else
  fail "symlinked skills parent remains without call-codex install"
fi

expect_failure "uninstaller rejects destination under symlinked skills parent" \
  bash "${UNINSTALL}" --dest "${PARENT_SYMLINK_DEST}"

expect_failure "uninstaller with --yes rejects destination under symlinked skills parent" \
  bash "${UNINSTALL}" --dest "${PARENT_SYMLINK_DEST}" --yes

rm -f "${SKILLS_PARENT}"
if [[ -d "${SKILLS_PARENT_BACKUP}" ]]; then
  mv "${SKILLS_PARENT_BACKUP}" "${SKILLS_PARENT}"
else
  mkdir -p "${SKILLS_PARENT}"
fi

if [[ -L "${SKILLS_PARENT}" ]]; then
  fail "skills parent restored as a real directory after symlink parent tests"
else
  pass "skills parent restored as a real directory after symlink parent tests"
fi

echo
echo "===================================="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
  echo "Result: LIFECYCLE TEST FAILED"
  exit 1
fi

echo "Result: LIFECYCLE TEST PASSED"
exit 0