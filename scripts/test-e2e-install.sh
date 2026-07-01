#!/usr/bin/env bash
# End-to-end install test.
# Creates an isolated home directory, runs install.sh (which installs
# chezmoi, then runs chezmoi init --apply), and verifies key files/scripts.
#
# Usage:
#   bash scripts/test-e2e-install.sh
#
# Exit codes:
#   0  PASS  — all assertions pass
#   1  FAIL  — one or more assertions failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

ok() {
	printf '[E2E] PASS: %s\n' "$*"
	PASS_COUNT=$((PASS_COUNT + 1))
}
fail() {
	printf '[E2E] FAIL: %s\n' "$*" >&2
	FAIL_COUNT=$((FAIL_COUNT + 1))
}

TEMP_HOME=""
cleanup() {
	if [ -n "$TEMP_HOME" ] && [ -d "$TEMP_HOME" ]; then
		rm -rf "$TEMP_HOME"
	fi
	if [ "$FAIL_COUNT" -gt 0 ]; then
		printf '\n[E2E] SUMMARY: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT" >&2
		exit 1
	fi
	printf '\n[E2E] SUMMARY: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
	exit 0
}
trap cleanup EXIT

# Step 1 — Create isolated home
TEMP_HOME="$(mktemp -d)"
export HOME="$TEMP_HOME"
export USER="${USER:-test}"
ok "created isolated home: $TEMP_HOME"

# Step 2 — Ensure required tools
missing=""
for cmd in curl git; do
	if ! command -v "$cmd" > /dev/null 2>&1; then
		missing="$missing $cmd"
	fi
done
if [ -n "$missing" ]; then
	fail "missing required tools:$missing"
	exit 1
fi
ok "required tools available (curl, git)"

# Step 3 — Run install.sh
printf '\n[E2E] Running install.sh...\n'
bash "$SCRIPT_DIR/install.sh"
ok "install.sh completed without error"

# Step 4 — Verify chezmoi binary
if [ -x "$HOME/.local/bin/chezmoi" ]; then
	ok "chezmoi binary is executable"
else
	fail "chezmoi binary not found or not executable at $HOME/.local/bin/chezmoi"
fi

# Step 5 — Verify key scripts are present and executable
EXPECTED_SCRIPTS=(
	dots-doctor
	dots-skills
	dots-loadenv
	dots-update-check
	dots-bootstrap
	dots-devcompanion
	dots-sync-ai
	dots-workstation-audit
	dots-mcp
	dots-security-audit
)
for script in "${EXPECTED_SCRIPTS[@]}"; do
	script_path="$HOME/.local/bin/$script"
	if [ -x "$script_path" ]; then
		ok "script $script is present and executable"
	else
		fail "script $script missing or not executable at $script_path"
	fi
done

# Step 6 — Verify chezmoi config was created
CHEZMOI_CONFIG="$HOME/.config/chezmoi/agentic-workstation.toml"
if [ -f "$CHEZMOI_CONFIG" ]; then
	ok "chezmoi config file present: $CHEZMOI_CONFIG"
else
	fail "chezmoi config file missing: $CHEZMOI_CONFIG"
fi

# Step 7 — Smoke-test dots-doctor (runs and exits cleanly)
if "$HOME/.local/bin/dots-doctor" > /dev/null 2>&1; then
	ok "dots-doctor ran successfully"
else
	fail "dots-doctor exited with non-zero status"
fi

# Step 8 — Smoke-test dots-loadenv --help
if "$HOME/.local/bin/dots-loadenv" --help > /dev/null 2>&1; then
	ok "dots-loadenv --help ran successfully"
else
	fail "dots-loadenv --help failed"
fi
