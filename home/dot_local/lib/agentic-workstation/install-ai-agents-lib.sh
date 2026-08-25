#!/usr/bin/env bash
# Shared terminal coding-agent installers (agentic-workstation audit PR 2).
#
# One idempotent installer function per entry in .chezmoidata/ai.yaml
# `agent_catalog`. Same conventions as install-agent-toolkit.sh: graceful
# degradation, has_cmd early-outs, env-driven pins, testable pure helpers,
# and no `set -euo` when sourced.
#
# Channels (per ai.yaml agent_catalog.<name>.channel):
#   native        vendor installer without sudo        → claude_code
#   script        official curl|sh installer           → opencode, muse_code
#   npm           global npm package (node required)   → pi, gemini_cli, codex
#   gh-extension  GitHub CLI extension                 → copilot_cli
#   auto          best-available chain brew→mise→script→ herdr
#
# Env (per agent NAME, e.g. CLAUDE_CODE):
#   <NAME>_PIN              exact version pin (preferred)
#   <NAME>_VERSION          alias of PIN
# Global env:
#   AI_AGENTS_INSTALL_CHANNEL   force one channel for all agents (debug)
#   MUSE_CODE_INSTALL_URL       override Muse installer URL
#   HERDR_INSTALL_URL           override Herdr installer URL
#   AI_AGENTS_CI_BLOCKED        set to 0/1 to override CI detection (tests)
#
# Usage (sourced API):
#   agent_pin <name>
#   agent_npm_spec <npm-package> <name>
#   agent_channel_plan <native|script|npm|gh-extension|auto>
#   install_catalog_agent <name> [force]
#   verify_agent_install <name>
#   install_ai_agents <name>... [force]
#
# Installers never hard-fail the caller: they print a warning and return 1;
# callers decide whether that is fatal.

# Do not `set -euo` when sourced — callers use their own options.
if [[ ${BASH_SOURCE[0]:-} == "$0" ]]; then
  set -euo pipefail
fi

_aa_log() { printf '\033[1;34m[ai-agents]\033[0m %s\n' "$*"; }
_aa_ok() { printf '\033[1;32m[ai-agents]\033[0m %s\n' "$*"; }
_aa_warn() { printf '\033[1;33m[ai-agents]\033[0m %s\n' "$*"; }

_aa_has_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- testable pure helpers ---------------------------------------------------

_aa_uname_s() { printf '%s\n' "${AGENTIC_WS_UNAME_S:-$(uname -s)}"; }

_aa_os_id() {
  if [[ -n ${AGENTIC_WS_OS_RELEASE_ID:-} ]]; then
    printf '%s\n' "$AGENTIC_WS_OS_RELEASE_ID"
    return
  fi
  local osrel="${AGENTIC_WS_OS_RELEASE:-/etc/os-release}"
  if [[ -f $osrel ]]; then
    (
      # shellcheck disable=SC1090,SC1091
      . "$osrel"
      printf '%s\n' "${ID:-linux}"
    )
    return
  fi
  printf 'unknown\n'
}

_aa_env_name() {
  printf '%s\n' "$1" | tr '[:lower:]-' '[:upper:]_'
}

# Resolve the effective pin for an agent: <NAME>_PIN wins, <NAME>_VERSION is
# the alias, empty output means latest.
agent_pin() {
  local base pin_var ver_var
  base="$(_aa_env_name "$1")"
  pin_var="${base}_PIN"
  ver_var="${base}_VERSION"
  if [[ -n ${!pin_var:-} ]]; then
    printf '%s\n' "${!pin_var}"
  elif [[ -n ${!ver_var:-} ]]; then
    printf '%s\n' "${!ver_var}"
  fi
}

# Build an npm package spec honoring pins: pkg@version or pkg@latest.
agent_npm_spec() {
  local pkg="$1" name="$2" ver
  ver="$(agent_pin "$name")"
  if [[ -n $ver ]]; then
    printf '%s@%s\n' "$pkg" "$ver"
  else
    printf '%s@latest\n' "$pkg"
  fi
}

# Expand a catalog channel into the ordered plan of concrete channels to try.
agent_channel_plan() {
  local ch="$1"
  ch="${AI_AGENTS_INSTALL_CHANNEL:-$ch}"
  case "$ch" in
    native | script | npm | gh-extension)
      printf '%s\n' "$ch"
      ;;
    auto)
      printf 'brew\nmise\nscript\n'
      ;;
    *)
      _aa_warn "unknown channel '${ch}'"
      return 1
      ;;
  esac
}

# CI/hermetic environments must not hit networks unless explicitly forced.
_aa_ci_blocked() {
  if [[ -n ${AI_AGENTS_CI_BLOCKED:-} ]]; then
    [[ ${AI_AGENTS_CI_BLOCKED} == "1" ]]
    return
  fi
  if [[ ${CI:-} == "true" || -n ${GITHUB_ACTIONS:-} || -n ${HERMETIC_PORT:-} ]]; then
    return 0
  fi
  return 1
}

# --- node dependency (npm-channel agents) ------------------------------------

ensure_node_for_npm() {
  if _aa_has_cmd npm; then
    return 0
  fi
  _aa_warn "npm not found — enable the node group (fnm + Node LTS) first"
  return 1
}

# --- per-agent installers ----------------------------------------------------
# Every installer: idempotent early-out, warns instead of aborting, prints the
# resulting version on success. Returns 0 on installed-or-already-present.

install_claude_code() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping claude_code install"
    return 1
  fi
  if _aa_has_cmd claude && [[ ${1:-} != "force" ]]; then
    _aa_ok "claude already installed: $(claude --version 2>&1 | head -n1)"
    return 0
  fi
  if ! _aa_has_cmd curl; then
    _aa_warn "curl not available — cannot run Claude Code native installer"
    return 1
  fi
  local pin
  pin="$(agent_pin claude_code)"
  _aa_log "Installing Claude Code (native installer${pin:+, pin ${pin}})"
  if [[ -n $pin ]]; then
    curl -fsSL https://claude.ai/install.sh | bash -s -- "$pin"
  else
    curl -fsSL https://claude.ai/install.sh | bash
  fi
  if _aa_has_cmd claude; then
    _aa_ok "claude installed: $(claude --version 2>&1 | head -n1)"
    return 0
  fi
  _aa_warn "Claude Code installer completed but binary not in PATH — ensure ~/.local/bin is on PATH"
  return 1
}

install_opencode() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping opencode install"
    return 1
  fi
  if _aa_has_cmd opencode && [[ ${1:-} != "force" ]]; then
    _aa_ok "opencode already installed: $(opencode --version 2>&1 | head -n1)"
    return 0
  fi
  if ! _aa_has_cmd curl; then
    _aa_warn "curl not available — cannot run OpenCode official installer"
    return 1
  fi
  local pin
  pin="$(agent_pin opencode)"
  _aa_log "Installing OpenCode (official installer${pin:+, pin ${pin}})"
  if [[ -n $pin ]]; then
    curl -fsSL https://opencode.ai/install.sh | bash -s -- "$pin"
  else
    curl -fsSL https://opencode.ai/install.sh | bash
  fi
  if _aa_has_cmd opencode; then
    _aa_ok "opencode installed: $(opencode --version 2>&1 | head -n1)"
    return 0
  fi
  _aa_warn "OpenCode installer completed but binary not in PATH — ensure ~/.opencode/bin is on PATH"
  return 1
}

install_muse_code() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping muse_code install"
    return 1
  fi
  if _aa_has_cmd muse && [[ ${1:-} != "force" ]]; then
    _aa_ok "muse already installed: $(muse --version 2>&1 | head -n1)"
    return 0
  fi
  if ! _aa_has_cmd curl; then
    _aa_warn "curl not available — cannot run Muse Code installer"
    return 1
  fi
  local url="${MUSE_CODE_INSTALL_URL:-https://dev.meta.ai/install.sh}"
  _aa_log "Installing Muse Code (${url})"
  if ! curl -fsSL "$url" | bash; then
    _aa_warn "Muse Code installer failed — see output above; install manually from https://dev.meta.ai"
    return 1
  fi
  if _aa_has_cmd muse; then
    _aa_ok "muse installed: $(muse --version 2>&1 | head -n1)"
    return 0
  fi
  _aa_warn "Muse Code installer completed but binary not in PATH"
  return 1
}

install_copilot_cli() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping copilot_cli install"
    return 1
  fi
  if gh extension list 2>/dev/null | grep -qE '(^|[[:space:]])github/gh-copilot([[:space:]]|$)' &&
    [[ ${1:-} != "force" ]]; then
    _aa_ok "gh-copilot extension already installed"
    return 0
  fi
  if ! _aa_has_cmd gh; then
    _aa_warn "gh CLI not found — install the github-cli group first"
    return 1
  fi
  local pin spec
  pin="$(agent_pin copilot_cli)"
  spec="github/gh-copilot"
  [[ -n $pin ]] && spec="${spec}@${pin}"
  _aa_log "Installing Copilot CLI (${spec})"
  if gh extension install "$spec"; then
    _aa_ok "gh-copilot extension installed"
    return 0
  fi
  _aa_warn "gh extension install failed — check 'gh auth status' and retry"
  return 1
}

install_pi() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping pi install"
    return 1
  fi
  if _aa_has_cmd pi && [[ ${1:-} != "force" ]]; then
    _aa_ok "pi already installed: $(pi --version 2>&1 | head -n1)"
    return 0
  fi
  ensure_node_for_npm || return 1
  local spec
  spec="$(agent_npm_spec "${PI_NPM_PACKAGE:-@mariozechner/pi}" pi)"
  _aa_log "Installing pi (npm ${spec})"
  if npm install -g "$spec"; then
    _aa_ok "pi installed: $(pi --version 2>&1 | head -n1)"
    return 0
  fi
  _aa_warn "npm install of pi failed"
  return 1
}

install_gemini_cli() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping gemini_cli install"
    return 1
  fi
  if _aa_has_cmd gemini && [[ ${1:-} != "force" ]]; then
    _aa_ok "gemini already installed: $(gemini --version 2>&1 | head -n1)"
    return 0
  fi
  ensure_node_for_npm || return 1
  local spec
  spec="$(agent_npm_spec "${GEMINI_CLI_NPM_PACKAGE:-@google/gemini-cli}" gemini_cli)"
  _aa_log "Installing Gemini CLI (npm ${spec})"
  if npm install -g "$spec"; then
    _aa_ok "gemini installed: $(gemini --version 2>&1 | head -n1)"
    return 0
  fi
  _aa_warn "npm install of Gemini CLI failed"
  return 1
}

install_codex() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping codex install"
    return 1
  fi
  if _aa_has_cmd codex && [[ ${1:-} != "force" ]]; then
    _aa_ok "codex already installed: $(codex --version 2>&1 | head -n1)"
    return 0
  fi
  ensure_node_for_npm || return 1
  local spec
  spec="$(agent_npm_spec "${CODEX_NPM_PACKAGE:-@openai/codex}" codex)"
  _aa_log "Installing Codex CLI (npm ${spec})"
  if npm install -g "$spec"; then
    _aa_ok "codex installed: $(codex --version 2>&1 | head -n1)"
    return 0
  fi
  _aa_warn "npm install of Codex CLI failed"
  return 1
}

install_herdr() {
  if _aa_ci_blocked; then
    _aa_warn "CI environment detected — skipping herdr install"
    return 1
  fi
  if _aa_has_cmd herdr && [[ ${1:-} != "force" ]]; then
    _aa_ok "herdr already installed: $(herdr --version 2>&1 | head -n1)"
    return 0
  fi
  local channel
  while read -r channel; do
    case "$channel" in
      brew)
        if _aa_has_cmd brew; then
          if brew install herdr 2>/dev/null && _aa_has_cmd herdr; then
            _aa_ok "herdr installed via brew: $(herdr --version 2>&1 | head -n1)"
            return 0
          fi
          _aa_warn "brew install herdr failed, trying next channel"
        fi
        ;;
      mise)
        if _aa_has_cmd mise; then
          if mise use -g herdr 2>/dev/null && _aa_has_cmd herdr; then
            _aa_ok "herdr installed via mise: $(herdr --version 2>&1 | head -n1)"
            return 0
          fi
          _aa_warn "mise use -g herdr failed, trying next channel"
        fi
        ;;
      script)
        if ! _aa_has_cmd curl; then
          _aa_warn "curl not available — cannot run Herdr official installer"
          continue
        fi
        local url="${HERDR_INSTALL_URL:-https://herdr.dev/install.sh}"
        _aa_log "Installing Herdr (${url})"
        if curl -fsSL "$url" | sh 2>/dev/null && _aa_has_cmd herdr; then
          _aa_ok "herdr installed via official script: $(herdr --version 2>&1 | head -n1)"
          return 0
        fi
        _aa_warn "herdr official installer failed — see https://herdr.dev/docs/install/"
        ;;
    esac
  done < <(agent_channel_plan auto)
  _aa_warn "herdr not installed — swarms will fall back to tmux"
  return 1
}

# --- dispatcher + verification ----------------------------------------------

# Post-install gate per catalog entry (mirrors ai.yaml `check` fields).
verify_agent_install() {
  case "$1" in
    claude_code) _aa_has_cmd claude ;;
    opencode) _aa_has_cmd opencode ;;
    muse_code) _aa_has_cmd muse ;;
    copilot_cli) gh extension list 2>/dev/null | grep -q github/gh-copilot ;;
    pi) _aa_has_cmd pi ;;
    gemini_cli) _aa_has_cmd gemini ;;
    codex) _aa_has_cmd codex ;;
    herdr) _aa_has_cmd herdr ;;
    *)
      _aa_warn "unknown agent '${1}' — no verification available"
      return 1
      ;;
  esac
}

install_catalog_agent() {
  local name="$1" force="${2:-}"
  case "$name" in
    claude_code) install_claude_code "$force" ;;
    opencode) install_opencode "$force" ;;
    muse_code) install_muse_code "$force" ;;
    copilot_cli) install_copilot_cli "$force" ;;
    pi) install_pi "$force" ;;
    gemini_cli) install_gemini_cli "$force" ;;
    codex) install_codex "$force" ;;
    herdr) install_herdr "$force" ;;
    *)
      _aa_warn "unknown agent '${name}' in catalog dispatcher"
      return 1
      ;;
  esac
}

# Convenience loop: install several agents, reporting a summary line each.
install_ai_agents() {
  local overall=0 name
  for name in "$@"; do
    if ! install_catalog_agent "$name"; then
      overall=1
    fi
  done
  return "$overall"
}

# --- executable entry point --------------------------------------------------
#   install-ai-agents-lib.sh [--force] <agent-name>...
if [[ ${BASH_SOURCE[0]:-} == "$0" ]]; then
  force=""
  agents=()
  for arg in "$@"; do
    case "$arg" in
      --force) force="force" ;;
      -h | --help)
        sed -n '2,40p' "${BASH_SOURCE[0]}" | grep -E '^#' | sed 's/^# \{0,1\}//'
        exit 0
        ;;
      *) agents+=("$arg") ;;
    esac
  done
  if [[ ${#agents[@]} -eq 0 ]]; then
    _aa_warn "usage: $0 [--force] <agent-name>...  (see header for catalog names)"
    exit 2
  fi
  install_ai_agents "${agents[@]}"
fi
