#!/usr/bin/env bash
# Post-install layout assertions used by the install-methods CI matrix.
# Single source of truth so all hermetic jobs agree on what "installed" means.
#
# Usage:
#   scripts/ci/assert-install-layout.sh chezmoi
#   scripts/ci/assert-install-layout.sh skills [tool]
#
# Where <tool> is one of: all|claude|opencode|cursor|windsurf|copilot
# (default: all)

set -euo pipefail

PROFILE="${1:-}"
TOOL="${2:-all}"

if [ -z "$PROFILE" ]; then
  echo "assert-install-layout: usage: $0 <chezmoi|skills> [tool]" >&2
  exit 2
fi

ok() { printf '[assert-install-layout] OK: %s\n' "$*"; }
miss() {
  printf '[assert-install-layout] FAIL: %s\n' "$*" >&2
  exit 1
}

require_dir() {
  [ -d "$1" ] || miss "missing directory: $1"
  ok "dir present: $1"
}

require_dir_nonempty() {
  require_dir "$1"
  if [ -z "$(ls -A "$1" 2>/dev/null || true)" ]; then
    miss "directory exists but is empty: $1"
  fi
  ok "dir non-empty: $1"
}

require_file() {
  [ -f "$1" ] || miss "missing file: $1"
  ok "file present: $1"
}

require_executable() {
  [ -x "$1" ] || miss "missing or non-executable: $1"
  ok "executable present: $1"
}

case "$PROFILE" in
  chezmoi)
    # Full chezmoi apply path — install.sh / manual init+apply.
    require_executable "$HOME/.local/bin/dots-doctor"
    require_dir_nonempty "$HOME/.local/share/agentic-workstation/skills"
    count=$(find "$HOME/.local/share/agentic-workstation/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    if [ "$count" -lt 3 ]; then
      miss "expected at least 3 skill directories, found $count"
    fi
    ok "skills directory has $count top-level entries"
    ;;
  skills)
    # install-skills.* path — only the AI-layer subset.
    require_dir_nonempty "$HOME/.local/share/agentic-workstation/skills"
    case "$TOOL" in
      cursor) require_dir_nonempty "$HOME/.cursor/rules" ;;
      claude) require_dir_nonempty "$HOME/.claude/agents" ;;
      opencode) require_dir_nonempty "$HOME/.config/opencode/agents" ;;
      windsurf) require_dir_nonempty "$HOME/.windsurf/rules" ;;
      copilot) require_file "$HOME/.github/copilot-instructions.md" ;;
      all | "")
        require_dir_nonempty "$HOME/.cursor/rules"
        require_dir_nonempty "$HOME/.claude/agents"
        require_dir_nonempty "$HOME/.config/opencode/agents"
        require_dir_nonempty "$HOME/.windsurf/rules"
        require_file "$HOME/.github/copilot-instructions.md"
        ;;
      *) miss "unknown tool: $TOOL" ;;
    esac
    ;;
  *)
    echo "assert-install-layout: unknown profile: $PROFILE (expected chezmoi|skills)" >&2
    exit 2
    ;;
esac

ok "layout assertions passed (profile=$PROFILE tool=$TOOL)"
