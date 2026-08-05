#!/usr/bin/env bash
# Verify chezmoi target state after apply (release CI).
# Checks filesystem state produced by chezmoi apply rather than chezmoi dump,
# which can fail on some chezmoi versions when template vars are unavailable.
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-}"
if [[ -z ${ROOT} ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z ${ROOT} || ! -d "${ROOT}/home" ]]; then
  echo "verify-release-dump: could not resolve repo root (GITHUB_WORKSPACE or git)" >&2
  exit 1
fi

DEST="${HOME}"

check_dir_nonempty() {
  local target="$1"
  local label="$2"
  local min_files="${3:-1}"
  if [[ ! -d ${target} ]]; then
    echo "verify-release-dump: missing directory for ${label} (${target})" >&2
    exit 1
  fi
  local count
  count="$(find "${target}" -maxdepth 1 -mindepth 1 | wc -l)"
  if [[ ${count} -lt ${min_files} ]]; then
    echo "verify-release-dump: expected >= ${min_files} item(s) in ${label} (${target}), found ${count}" >&2
    exit 1
  fi
}

check_file_exists() {
  local target="$1"
  local label="$2"
  if [[ ! -f ${target} ]]; then
    echo "verify-release-dump: missing ${label} (${target})" >&2
    exit 1
  fi
}

# Critical paths used by release-artifacts.json
check_dir_nonempty "${DEST}/.local/share/agentic-workstation/skills" "skill store" 3
check_dir_nonempty "${DEST}/.config/opencode/agents" "OpenCode agents" 1
check_dir_nonempty "${DEST}/.claude/agents" "Claude agents" 1
# Cursor rules are deployed by agent-toolkit, not chezmoi.
check_file_exists "${DEST}/.github/copilot-instructions.md" "Copilot instructions"

echo "verify-release-dump: OK"
