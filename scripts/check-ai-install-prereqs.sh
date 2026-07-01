#!/bin/sh
# agentic-workstation AI install — prerequisite checker (POSIX / macOS / Linux / WSL2)
#
# Read-only script: verifies that a machine is ready to run
# `install-skills.sh` and reports whether the AI layer is already installed.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/scripts/check-ai-install-prereqs.sh)
#   ./scripts/check-ai-install-prereqs.sh
#
# Exit codes:
#   0  READY   — all requirements satisfied
#   1  NOT READY — one or more required tools missing
#   2  ERROR  — unexpected failure while probing

set -u

SCRIPT_NAME="check-ai-install-prereqs"
STATUS=0
WARN_COUNT=0

note() { printf '[%s] %s\n' "$SCRIPT_NAME" "$*"; }
ok() { printf '[%s] OK: %s\n' "$SCRIPT_NAME" "$*"; }
warn() {
  printf '[%s] WARN: %s\n' "$SCRIPT_NAME" "$*" >&2
  WARN_COUNT=$((WARN_COUNT + 1))
}
miss() {
  printf '[%s] MISSING: %s\n' "$SCRIPT_NAME" "$*" >&2
  STATUS=1
}

note "starting AI install prerequisite check"

# ---- OS detection (informational only) -----------------------------------
UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
case "$UNAME_S" in
  Linux*) OS="linux" ;;
  Darwin*) OS="macos" ;;
  MINGW* | MSYS* | CYGWIN*) OS="windows-posix" ;;
  *) OS="unknown" ;;
esac
note "detected OS: ${OS} (uname=${UNAME_S})"

if [ "$OS" = "linux" ] && [ -n "${WSL_DISTRO_NAME:-}" ]; then
  note "running inside WSL2 (distro: ${WSL_DISTRO_NAME})"
fi

# ---- Required tools ------------------------------------------------------
need_any() {
  # need_any "human label" cmd1 cmd2 ...
  label="$1"
  shift
  for c in "$@"; do
    if command -v "$c" >/dev/null 2>&1; then
      ok "${label}: found ${c}"
      return 0
    fi
  done
  miss "${label}: none of [$*] available in PATH"
  return 1
}

need_one() {
  # need_one "human label" cmd
  label="$1"
  cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "${label}: found ${cmd}"
    return 0
  fi
  miss "${label}: missing ${cmd} in PATH"
  return 1
}

need_any "HTTPS downloader" curl wget
need_one "ZIP extractor" unzip
need_one "Temp dir creator" mktemp

# POSIX shell is implicit — we're executing under /bin/sh. Still surface it.
if [ -n "${BASH_VERSION:-}" ]; then
  ok "shell: bash ${BASH_VERSION}"
else
  ok "shell: POSIX sh (ok)"
fi

# ---- Network reachability (soft check; skipped if curl/wget missing) ----
probe_url() {
  url="$1"
  label="$2"
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSI --max-time 8 "$url" >/dev/null 2>&1; then
      ok "${label}: reachable (${url})"
      return 0
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q --spider --timeout=8 "$url" >/dev/null 2>&1; then
      ok "${label}: reachable (${url})"
      return 0
    fi
  else
    warn "${label}: cannot probe — no curl/wget"
    return 1
  fi
  warn "${label}: not reachable from this shell (proxy/VPN/offline?) — ${url}"
  return 1
}

probe_url "https://github.com" "GitHub"
probe_url "https://api.github.com" "GitHub API"

# ---- Home directory writability ----------------------------------------
if [ -z "${HOME:-}" ]; then
  miss "HOME env var is not set"
else
  if [ ! -d "$HOME" ]; then
    miss "HOME directory does not exist: $HOME"
  elif [ ! -w "$HOME" ]; then
    miss "HOME directory is not writable: $HOME"
  else
    ok "HOME writable: $HOME"
  fi
fi

# ---- Existing AI install footprint (informational) ----------------------
SKILLS_DIR="${HOME:-}/.local/share/agentic-workstation/skills"
if [ -d "$SKILLS_DIR" ]; then
  count=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  ok "existing skills install detected: ${SKILLS_DIR} (${count} top-level entries)"
else
  note "no existing skills install at ${SKILLS_DIR} (will be created by install-skills)"
fi

for d in "${HOME:-}/.claude/agents" \
  "${HOME:-}/.config/opencode/agents" \
  "${HOME:-}/.cursor/rules" \
  "${HOME:-}/.windsurf/rules"; do
  if [ -d "$d" ]; then
    ok "existing tool dir: $d"
  fi
done
if [ -f "${HOME:-}/.github/copilot-instructions.md" ]; then
  ok "existing Copilot instructions: ${HOME}/.github/copilot-instructions.md"
fi

# ---- Summary ------------------------------------------------------------
note ""
case "$STATUS" in
  0) note "AI install prereq check: READY (warnings: ${WARN_COUNT})" ;;
  *) note "AI install prereq check: NOT READY — fix MISSING items above" ;;
esac

exit "$STATUS"
