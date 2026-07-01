#!/usr/bin/env bash
# Verify chezmoi target state after apply (release CI).
# Uses chezmoi dump on a few paths to catch empty / broken target trees.
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-}"
if [[ -z ${ROOT} ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [[ -z ${ROOT} || ! -d "${ROOT}/home" ]]; then
  echo "verify-release-dump: could not resolve repo root (GITHUB_WORKSPACE or git)" >&2
  exit 1
fi

CHEZMOI="${CHEZMOI_BIN:-${HOME}/.local/bin/chezmoi}"
if [[ ! -x ${CHEZMOI} ]]; then
  echo "verify-release-dump: chezmoi not executable: ${CHEZMOI}" >&2
  exit 1
fi

SRC="${ROOT}/home"
DEST="${HOME}"

dump_nonempty() {
  local target="$1"
  local label="$2"
  local out
  # Targets must be absolute paths under the destination directory.
  if ! out="$("${CHEZMOI}" dump -S "${SRC}" -D "${DEST}" --format=yaml "${target}" 2>/dev/null)"; then
    echo "verify-release-dump: dump failed for ${label} (${target})" >&2
    exit 1
  fi
  if [[ -z ${out// /} ]]; then
    echo "verify-release-dump: empty dump for ${label} (${target})" >&2
    exit 1
  fi
}

# Critical paths used by release-artifacts.json
[[ -d "${HOME}/.local/share/agentic-workstation/skills" ]] || {
  echo "verify-release-dump: missing ~/.local/share/agentic-workstation/skills" >&2
  exit 1
}
skill_count="$(find "${HOME}/.local/share/agentic-workstation/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)"
if [[ ${skill_count} -lt 3 ]]; then
  echo "verify-release-dump: expected several skill dirs, found ${skill_count}" >&2
  exit 1
fi

dump_nonempty "${HOME}/.cursor/rules" "Cursor rules"
dump_nonempty "${HOME}/.config/opencode/agents" "OpenCode agents"
dump_nonempty "${HOME}/.claude/agents" "Claude agents"

if [[ ! -f "${HOME}/.github/copilot-instructions.md" ]]; then
  echo "verify-release-dump: missing ~/.github/copilot-instructions.md" >&2
  exit 1
fi

echo "verify-release-dump: OK"
