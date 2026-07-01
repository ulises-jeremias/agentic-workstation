#!/usr/bin/env bash
# test-chezmoi-snapshot.sh — idempotency snapshot test
#
# 1. Install chezmoi if not present
# 2. `chezmoi init --source=. --promptDefaults --apply`
# 3. `chezmoi diff --source=.` — must be empty
#
# Exit 0 on pass, 1 on fail.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CHEZMOI="${CHEZMOI:-}"
if [[ -z "$CHEZMOI" ]]; then
	if command -v chezmoi > /dev/null 2>&1; then
		CHEZMOI="$(command -v chezmoi)"
	elif [[ -x "$HOME/.local/bin/chezmoi" ]]; then
		CHEZMOI="$HOME/.local/bin/chezmoi"
	fi
fi

if [[ -z "$CHEZMOI" ]]; then
	echo "==> Installing chezmoi..."
	BINDIR="$(mktemp -d)"
	sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BINDIR"
	CHEZMOI="$BINDIR/chezmoi"
fi

echo "==> chezmoi init --source=$REPO_ROOT --promptDefaults --apply"
"$CHEZMOI" init --source="$REPO_ROOT" --promptDefaults --apply

echo "==> chezmoi diff --source=$REPO_ROOT"
DIFF_OUTPUT=$("$CHEZMOI" diff --source="$REPO_ROOT" 2>&1 || true)

if [[ -z "$DIFF_OUTPUT" ]]; then
	echo "PASS: chezmoi diff is empty — configuration is idempotent"
	exit 0
else
	echo "FAIL: chezmoi diff is NOT empty — configuration is NOT idempotent"
	echo "$DIFF_OUTPUT"
	exit 1
fi
