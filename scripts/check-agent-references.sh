#!/usr/bin/env bash
# scripts/check-agent-references.sh
# Verify that every agent declared in agent-catalog.yaml exists as an agent
# file under home/dot_claude/agents/.
#
# Usage:
#   bash scripts/check-agent-references.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="${REPO_ROOT}/home/dot_claude/agents"
CATALOG="${AGENTS_DIR}/agent-catalog.yaml"

_c() { [[ -t 1 ]] && printf '\033[%sm%s\033[0m' "$1" "$2" || printf '%s' "$2"; }
ok() {
  _c "1;32" "  ✓"
  echo " $*"
}
fail() {
  _c "1;31" "  ✗"
  echo " $*"
}
info() {
  _c "1;34" "  →"
  echo " $*"
}

echo ""
echo "Agent Reference Conformance Check"
echo "----------------------------------"

if [[ ! -f ${CATALOG} ]]; then
  echo "  [skip] agent-catalog.yaml not found at ${CATALOG}" >&2
  exit 0
fi

ERRORS=0
CHECKED=0

info "Checking catalog entries against agent files..."

# Extract agent names from catalog (name: <name> lines, skipping indented handoff names)
while IFS= read -r name; do
  [[ -z ${name} ]] && continue
  CHECKED=$((CHECKED + 1))
  agent_file="${AGENTS_DIR}/${name}.md"
  if [[ -f ${agent_file} ]]; then
    ok "${name}"
  else
    fail "${name}: in agent-catalog.yaml but agent file not found"
    ERRORS=$((ERRORS + 1))
  fi
done < <(grep -E '^\s*- name:' "${CATALOG}" | sed 's/.*- name: //' | tr -d '"' | sort -u)

echo ""
if [[ $ERRORS -gt 0 ]]; then
  _c "1;31" "  ${ERRORS} missing agent file(s)."
  echo ""
  exit 1
fi
_c "1;32" "  All ${CHECKED} catalog agents have matching files."
echo ""
echo ""
exit 0
