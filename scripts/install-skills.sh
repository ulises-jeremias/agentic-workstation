#!/bin/sh
# agentic-workstation Skills Installer
# Downloads and installs agentic-workstation AI skills and agents into the correct directories.
# Compatible with: macOS, Linux, WSL2 (Windows)
#
# Usage:
#   curl -fsSL https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.sh | sh
#   curl -fsSL .../install-skills.sh | sh -s -- --skills jira,github
#   curl -fsSL .../install-skills.sh | sh -s -- --skills list    # show available domains
#   curl -fsSL .../install-skills.sh | sh -s -- --tool claude
#   curl -fsSL .../install-skills.sh | sh -s -- --tool opencode
#   curl -fsSL .../install-skills.sh | sh -s -- --tool cursor
#   curl -fsSL .../install-skills.sh | sh -s -- --tool windsurf
#   curl -fsSL .../install-skills.sh | sh -s -- --tool copilot
#   curl -fsSL .../install-skills.sh | sh -s -- --all
#   curl -fsSL .../install-skills.sh | sh -s -- --guided   # interactive prompts
#   curl -fsSL .../install-skills.sh | sh -s -- --dry-run  # plan only, no changes
#
# The RELEASE_BASE variable is rewritten at release time to pin the version URL.
# When running from source or latest, it falls back to the GitHub latest redirect.
#
# Hermetic CI / private mirrors: set DOTS_WORKSTATION_SKILLS_VERSION (e.g. v0.1.4 or v0.0.0-pr42)
# so zip names resolve without probing GitHub when RELEASE_BASE is not a
# github.com/releases/download URL.

set -eu

GITHUB_REPO="ulises-jeremias/agentic-workstation"
RELEASE_BASE="https://github.com/${GITHUB_REPO}/releases/latest/download"

TARGET_TOOL="all"
GUIDED=0
DRY_RUN=0
SKILLS_FILTER=""

usage() {
  cat <<'USAGE'
install-skills.sh — agentic-workstation AI skills & agents installer

Options:
  --tool <name>   Install for one tool: all|claude|opencode|cursor|windsurf|copilot
  --skills <list> Comma-separated skill domains to install (e.g. jira,github,clickup)
                  Use --skills list to show available domains
  --all           Install for every supported tool (default)
  --guided        Interactive prompts (requires a TTY); falls back to --all if piped
  --dry-run       Print what would be downloaded/installed, but do not change anything
  -h | --help     Show this help and exit

Available skill domains:
  jira     — Jira issues, sprints, epics, JQL, admin (14 skills)
  confluence — Confluence pages, spaces, search, permissions, templates
  clickup  — ClickUp tasks, docs, sprints, goals, comments
  github   — GitHub PRs, CI, releases, comments, code review
  gitlab   — GitLab MRs, issues, CI/CD, pipelines
  slack    — Slack channels, messages, canvases, reactions
  figma    — Figma designs, components, variables, code generation
  linear   — Linear issues, projects, cycles, teams
  dbt      — dbt parse, compile, test, selective run validation
  snowflake — Read-only Snowflake SQL validation
  playwright — E2E tests, browser automation, snapshots, traces
  jupyter  — Jupyter notebook scaffolding and refactoring
  ui-ux    — UI/UX design with 67 styles, 96 palettes, 57 font pairings
  workflow — Planning, epics, user stories, bugs, incidents, ADRs, PRDs, TRDs
  triage   — Workstation health diagnostics
  all      — Every skill domain (default)

See docs/wiki/GUIDED_AI_INSTALL.md for the non-developer walkthrough.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)
      TARGET_TOOL="${2:-all}"
      shift 2
      ;;
    --tool=*) TARGET_TOOL="${1#--tool=}" && shift ;;
    --skills)
      SKILLS_FILTER="${2:-all}"
      if [ "$SKILLS_FILTER" = "list" ]; then
        printf "Available skill domains:\n"
        printf "  jira, confluence, clickup, github, gitlab, slack, figma, linear,\n"
        printf "  dbt, snowflake, playwright, jupyter, ui-ux, workflow, triage, all\n"
        exit 0
      fi
      shift 2
      ;;
    --skills=*) SKILLS_FILTER="${1#--skills=}" && shift ;;
    --all)
      TARGET_TOOL="all"
      shift
      ;;
    --guided)
      GUIDED=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    "") shift ;;
    *)
      printf '[install-skills] ERROR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

log() { printf '[install-skills] %s\n' "$*"; }
ok() { printf '[install-skills] OK: %s\n' "$*"; }
warn() { printf '[install-skills] WARNING: %s\n' "$*" >&2; }
fail() {
  printf '[install-skills] ERROR: %s\n' "$*" >&2
  exit 1
}

# Detect download tool
if command -v curl >/dev/null 2>&1; then
  download() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  download() { wget -qO "$2" "$1"; }
else
  fail "curl or wget is required but neither was found"
fi

# Detect version: explicit env (CI / mirrors), else from URL, else GitHub redirect.
VERSION=""
if [ -n "${DOTS_WORKSTATION_SKILLS_VERSION:-}" ]; then
  VERSION="$DOTS_WORKSTATION_SKILLS_VERSION"
  log "using DOTS_WORKSTATION_SKILLS_VERSION from environment: $VERSION"
else
  case "$RELEASE_BASE" in
    */releases/download/*)
      VERSION=$(printf '%s' "$RELEASE_BASE" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9_.-]+)?' | head -1)
      ;;
  esac
  if [ -z "$VERSION" ]; then
    log "detecting latest release version..."
    LATEST_URL=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
      "https://github.com/${GITHUB_REPO}/releases/latest" 2>/dev/null || echo "")
    VERSION=$(printf '%s' "$LATEST_URL" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9_.-]+)?' | head -1 || echo "")
    if [ -n "$VERSION" ]; then
      RELEASE_BASE="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}"
    fi
  fi
fi
log "version: ${VERSION:-latest (redirect)}"

TMPDIR_SKILLS=$(mktemp -d)
# shellcheck disable=SC2064
trap "rm -rf '$TMPDIR_SKILLS'" EXIT

# ---- Guided (interactive) mode -----------------------------------------
# Only prompt when both stdin and stdout are real TTYs; otherwise silently
# fall back to --all so piped installs (curl | sh) remain non-interactive.
if [ "$GUIDED" = "1" ]; then
  if [ -t 0 ] && [ -t 1 ]; then
    printf '\n[install-skills] Guided mode\n'
    printf '  Which AI tool do you use? [1] all (default) [2] claude [3] cursor [4] opencode [5] windsurf [6] copilot\n'
    printf '  Your choice: '
    read -r _choice || _choice=""
    case "${_choice:-1}" in
      1 | "") TARGET_TOOL="all" ;;
      2 | claude) TARGET_TOOL="claude" ;;
      3 | cursor) TARGET_TOOL="cursor" ;;
      4 | opencode) TARGET_TOOL="opencode" ;;
      5 | windsurf) TARGET_TOOL="windsurf" ;;
      6 | copilot) TARGET_TOOL="copilot" ;;
      *)
        warn "unknown choice '${_choice}', defaulting to 'all'"
        TARGET_TOOL="all"
        ;;
    esac
    printf '  Proceed with tool="%s" and version="%s"? [Y/n]: ' "$TARGET_TOOL" "${VERSION:-latest}"
    read -r _confirm || _confirm=""
    case "$_confirm" in
      n | N | no | NO) fail "aborted by user" ;;
    esac
  else
    warn "--guided requested but no TTY available (piped install); continuing with --tool=${TARGET_TOOL}"
  fi
fi

if [ "$DRY_RUN" = "1" ]; then
  log "DRY RUN — no files will be modified"
  log "  tool: ${TARGET_TOOL}"
  log "  skills filter: ${SKILLS_FILTER:-all}"
  log "  release base: ${RELEASE_BASE}"
  log "  version: ${VERSION:-latest}"
  log "  skills dir (target): ${HOME}/.local/share/agentic-workstation/skills"
  exit 0
fi

# Try dots-workstation- prefix first, then fall back to dots-ai- (pre-v1.2.0 releases).
_download_asset() {
  _name="$1"
  _out="$2"
  if download "${RELEASE_BASE}/dots-workstation-${_name}-${VERSION}.zip" "$_out" 2>/dev/null; then
    return 0
  fi
  log "dots-workstation-${_name}-${VERSION}.zip not found, trying dots-ai- prefix..."
  download "${RELEASE_BASE}/dots-ai-${_name}-${VERSION}.zip" "$_out" 2>/dev/null
}

install_skills() {
  log "downloading skills package..."
  if [ -n "$SKILLS_FILTER" ] && [ "$SKILLS_FILTER" != "all" ]; then
    log "  skills filter requested: ${SKILLS_FILTER}"
    log "  note: per-domain filtering requires 'dots-skills sync' after install"
    log "  all skills will be downloaded; use dots-skills to manage which are active"
  fi
  _download_asset "skills" "${TMPDIR_SKILLS}/skills.zip" ||
    fail "could not download skills package from ${RELEASE_BASE}"

  SKILLS_DIR="${HOME}/.local/share/agentic-workstation/skills"
  mkdir -p "$SKILLS_DIR"
  if command -v unzip >/dev/null 2>&1; then
    unzip -o "${TMPDIR_SKILLS}/skills.zip" -d "${TMPDIR_SKILLS}/extracted" >/dev/null
    _ext="${TMPDIR_SKILLS}/extracted"
    if [ -d "${_ext}/.local/share/agentic-workstation/skills" ]; then
      _skills_src="${_ext}/.local/share/agentic-workstation/skills"
    elif [ -d "${_ext}/skills" ]; then
      _skills_src="${_ext}/skills"
    else
      fail "skills zip had unexpected layout (expected .local/share/agentic-workstation/skills/ or skills/)"
    fi
    cp -r "${_skills_src}/." "$SKILLS_DIR/"
  else
    fail "unzip is required — install it and retry"
  fi
  ok "skills installed to ${SKILLS_DIR}"
}

install_for_claude() {
  log "installing agents for Claude Code / Claude Desktop..."
  if ! _download_asset "agents-claude" "${TMPDIR_SKILLS}/claude.zip"; then
    warn "could not download claude agents package — skipping"
    return 0
  fi
  mkdir -p "${HOME}/.claude/agents"
  unzip -o "${TMPDIR_SKILLS}/claude.zip" -d "${TMPDIR_SKILLS}/claude-extracted" >/dev/null
  # ZIPs are built from chezmoi-deployed paths (e.g. .claude/agents/ not dot_claude/agents/)
  cp -r "${TMPDIR_SKILLS}/claude-extracted/.claude/agents/." "${HOME}/.claude/agents/"
  if [ -f "${TMPDIR_SKILLS}/claude-extracted/.claude/settings.json" ]; then
    if [ ! -f "${HOME}/.claude/settings.json" ]; then
      cp "${TMPDIR_SKILLS}/claude-extracted/.claude/settings.json" \
        "${HOME}/.claude/settings.json"
      ok "claude settings.json installed"
    else
      ok "skipped settings.json (already exists — not overwriting)"
    fi
  fi
  ok "Claude agents installed to ${HOME}/.claude/agents/"
}

install_for_opencode() {
  log "installing agents for OpenCode..."
  if ! _download_asset "agents-opencode" "${TMPDIR_SKILLS}/opencode.zip"; then
    warn "could not download opencode agents package — skipping"
    return 0
  fi
  mkdir -p "${HOME}/.config/opencode/agents"
  unzip -o "${TMPDIR_SKILLS}/opencode.zip" -d "${TMPDIR_SKILLS}/opencode-extracted" >/dev/null
  cp -r "${TMPDIR_SKILLS}/opencode-extracted/.config/opencode/agents/." \
    "${HOME}/.config/opencode/agents/"
  # Note: skills are symlinked by dots-skills sync; for standalone install use dots-workstation-skills ZIP
  ok "OpenCode agents installed to ${HOME}/.config/opencode/agents/"
}

install_for_cursor() {
  log "installing agents for Cursor..."
  if ! _download_asset "agents-cursor" "${TMPDIR_SKILLS}/cursor.zip"; then
    warn "could not download cursor agents package — skipping"
    return 0
  fi
  mkdir -p "${HOME}/.cursor/rules"
  unzip -o "${TMPDIR_SKILLS}/cursor.zip" -d "${TMPDIR_SKILLS}/cursor-extracted" >/dev/null
  cp -r "${TMPDIR_SKILLS}/cursor-extracted/.cursor/rules/." "${HOME}/.cursor/rules/"
  ok "Cursor rules installed to ${HOME}/.cursor/rules/"
}

install_for_windsurf() {
  log "installing agents for Windsurf..."
  if ! _download_asset "agents-windsurf" "${TMPDIR_SKILLS}/windsurf.zip"; then
    warn "could not download windsurf agents package — skipping"
    return 0
  fi
  mkdir -p "${HOME}/.windsurf/rules" "${HOME}/.config/windsurf/rules"
  unzip -o "${TMPDIR_SKILLS}/windsurf.zip" -d "${TMPDIR_SKILLS}/windsurf-extracted" >/dev/null
  cp -r "${TMPDIR_SKILLS}/windsurf-extracted/.windsurf/rules/." "${HOME}/.windsurf/rules/"
  if [ -d "${TMPDIR_SKILLS}/windsurf-extracted/.config/windsurf/rules" ]; then
    cp -r "${TMPDIR_SKILLS}/windsurf-extracted/.config/windsurf/rules/." \
      "${HOME}/.config/windsurf/rules/"
  fi
  ok "Windsurf agents installed to ${HOME}/.windsurf/ and ${HOME}/.config/windsurf/"
}

install_for_copilot() {
  log "installing GitHub Copilot custom instructions..."
  if ! _download_asset "agents-copilot" "${TMPDIR_SKILLS}/copilot.zip"; then
    warn "could not download copilot agents package — skipping"
    return 0
  fi
  mkdir -p "${HOME}/.github"
  unzip -o "${TMPDIR_SKILLS}/copilot.zip" -d "${TMPDIR_SKILLS}/copilot-extracted" >/dev/null
  if [ -f "${TMPDIR_SKILLS}/copilot-extracted/.github/copilot-instructions.md" ]; then
    cp "${TMPDIR_SKILLS}/copilot-extracted/.github/copilot-instructions.md" \
      "${HOME}/.github/copilot-instructions.md"
    ok "GitHub Copilot instructions installed to ${HOME}/.github/copilot-instructions.md"
  else
    warn "copilot zip missing .github/copilot-instructions.md — skipping"
  fi
}

# Always install the skills library
install_skills

case "$TARGET_TOOL" in
  all)
    install_for_claude
    install_for_opencode
    install_for_cursor
    install_for_windsurf
    install_for_copilot
    ;;
  claude) install_for_claude ;;
  opencode) install_for_opencode ;;
  cursor) install_for_cursor ;;
  windsurf) install_for_windsurf ;;
  copilot) install_for_copilot ;;
  *)
    warn "unknown tool: ${TARGET_TOOL}. Valid: all, claude, opencode, cursor, windsurf, copilot"
    ;;
esac

log ""
log "Installation complete."
log "  Skills:  ${HOME}/.local/share/agentic-workstation/skills/"
log "  Restart your AI tool for changes to take effect."
