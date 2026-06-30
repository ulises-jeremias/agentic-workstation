#!/usr/bin/env bash
# scripts/check-changelog.sh
# Verify that any PR touching significant source files also includes a
# CHANGELOG entry under [Unreleased].
#
# Usage:
#   bash scripts/check-changelog.sh [--base <ref>]     # check PR diff
#   bash scripts/check-changelog.sh --skip-if-no-diff  # for local pre-commit
#
# Options:
#   --base <ref>          Base git ref to diff against (default: HEAD~1)
#   --skip-if-no-diff     Exit 0 silently if no tracked files changed
#
# Significant source paths (changes to these require a CHANGELOG entry):
#   home/**               chezmoi source state (skills, agents, scripts)
#   scripts/**            maintenance scripts
#   lib/**                library code and schemas

set -euo pipefail

BASE="HEAD~1"
SKIP_IF_NO_DIFF=false
for arg in "$@"; do
  case "${arg}" in
    --base=*) BASE="${arg#*=}" ;;
    --base)
      echo "Use --base=<ref>" >&2
      exit 1
      ;;
    --skip-if-no-diff) SKIP_IF_NO_DIFF=true ;;
    -h | --help)
      echo "Usage: $0 [--base=<ref>] [--skip-if-no-diff]"
      exit 0
      ;;
  esac
done

CHANGELOG="CHANGELOG.md"

if [[ ! -f ${CHANGELOG} ]]; then
  echo "[skip] CHANGELOG.md not found — skipping check." >&2
  exit 0
fi

# Detect changed significant files
CHANGED=$(git diff --name-only "${BASE}" HEAD 2>/dev/null | grep -E '^(home/|scripts/|lib/)' || true)

if [[ -z ${CHANGED} ]]; then
  if [[ ${SKIP_IF_NO_DIFF} == "true" ]]; then
    exit 0
  fi
  echo "  ✓ No significant source changes — CHANGELOG not required."
  exit 0
fi

# Check for Unreleased section with content
# Use awk that skips the start line itself when checking the end pattern
UNRELEASED_CONTENT=$(awk '
  /^## \[Unreleased\]/ { in_section=1; next }
  in_section && /^## \[/  { exit }
  in_section { print }
' "${CHANGELOG}" | grep -E '^- |^\* |^### ' | head -5 || true)

if [[ -z ${UNRELEASED_CONTENT} ]]; then
  echo "  ✗ CHANGELOG.md [Unreleased] section is empty." >&2
  echo "" >&2
  echo "  Files changed that require a CHANGELOG entry:" >&2
  echo "${CHANGED}" | head -10 | sed 's/^/    /' >&2
  echo "" >&2
  echo "  Add an entry under ## [Unreleased] in CHANGELOG.md." >&2
  exit 1
fi

echo "  ✓ CHANGELOG.md [Unreleased] has entries."
exit 0
