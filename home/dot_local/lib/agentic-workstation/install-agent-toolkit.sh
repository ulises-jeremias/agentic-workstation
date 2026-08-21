#!/usr/bin/env bash
# Shared Agent Toolkit CLI bootstrap (agentic-workstation#206).
#
# Prefers a platform-native V binary, then falls back. Every successful path
# must leave `agent-toolkit` on PATH with canonical V behavior (native binary
# or ADR-021 uv launcher that execs the bundled V binary).
# Never `import agent_toolkit` — workstation MUST NOT treat Python as the product.
#
# Channel order (AGENT_TOOLKIT_INSTALL_CHANNEL=auto, default):
#   1. macOS  → Homebrew tap ulises-jeremias/homebrew-tap formula agent-toolkit
#   1. Arch   → AUR agent-toolkit-bin (yay/paru)
#   2. any    → GitHub Release floating binary + SHA256SUMS (ADR-018)
#   3. any    → uv tool install agent-toolkit-cli>=1.11.0 (V launcher, ADR-021)
#
# Env:
#   AGENT_TOOLKIT_MIN_VERSION     default 1.11.0 (refuse older)
#   AGENT_TOOLKIT_CLI_VERSION     rollback pin (semver or full uv spec)
#   AGENT_TOOLKIT_PIN             alias of CLI_VERSION
#   AGENT_TOOLKIT_RELEASE         GitHub tag (v1.11.0) for binary pin
#   AGENT_TOOLKIT_INSTALL_CHANNEL auto|brew|aur|github|uv
#   AGENT_TOOLKIT_CHANNEL         alias of INSTALL_CHANNEL
#   AGENT_TOOLKIT_GITHUB_REPO     default ulises-jeremias/agent-toolkit
#
# Usage (executable):
#   install-agent-toolkit.sh [--force] [--deploy]
# Sourced API:
#   install_agent_toolkit_cli [force]
#   deploy_agent_toolkit_profiles
#   install_and_deploy_agent_toolkit [force]
#   agent_toolkit_meets_min
#   agent_toolkit_current_version

# Do not `set -euo` when sourced — callers (dots-skills) use their own options.
if [[ ${BASH_SOURCE[0]:-} == "$0" ]]; then
  set -euo pipefail
fi

AGENT_TOOLKIT_MIN_VERSION="${AGENT_TOOLKIT_MIN_VERSION:-1.11.0}"
AGENT_TOOLKIT_GITHUB_REPO="${AGENT_TOOLKIT_GITHUB_REPO:-ulises-jeremias/agent-toolkit}"
AGENT_TOOLKIT_BREW_TAP="${AGENT_TOOLKIT_BREW_TAP:-ulises-jeremias/homebrew-tap}"
AGENT_TOOLKIT_BREW_FORMULA="${AGENT_TOOLKIT_BREW_FORMULA:-agent-toolkit}"
AGENT_TOOLKIT_AUR_PKG="${AGENT_TOOLKIT_AUR_PKG:-agent-toolkit-bin}"
AGENT_TOOLKIT_UV_PKG="${AGENT_TOOLKIT_UV_PKG:-agent-toolkit-cli}"

_at_log() { printf '\033[1;34m[agent-toolkit]\033[0m %s\n' "$*"; }
_at_ok() { printf '\033[1;32m[agent-toolkit]\033[0m %s\n' "$*"; }
_at_warn() { printf '\033[1;33m[agent-toolkit]\033[0m %s\n' "$*"; }

_at_uname_s() { printf '%s\n' "${AGENT_TOOLKIT_UNAME_S:-$(uname -s)}"; }
_at_uname_m() { printf '%s\n' "${AGENT_TOOLKIT_UNAME_M:-$(uname -m)}"; }

_at_os_id() {
  if [[ -n ${AGENT_TOOLKIT_OS_RELEASE_ID:-} ]]; then
    printf '%s\n' "$AGENT_TOOLKIT_OS_RELEASE_ID"
    return
  fi
  local osrel="${AGENT_TOOLKIT_OS_RELEASE:-/etc/os-release}"
  if [[ -f $osrel ]]; then
    # Subshell so sourced ID/ID_LIKE do not leak into the caller.
    (
      # shellcheck disable=SC1090,SC1091
      . "$osrel"
      if [[ ${ID:-} == arch || ${ID_LIKE:-} == *arch* ]]; then
        printf 'arch\n'
        exit 0
      fi
      printf '%s\n' "${ID:-linux}"
    )
    return
  fi
  printf 'unknown\n'
}

_at_arch_token() {
  case "$(_at_uname_m)" in
    x86_64 | amd64) printf 'x86_64\n' ;;
    arm64 | aarch64) printf 'arm64\n' ;;
    *)
      _at_warn "unsupported architecture: $(_at_uname_m)"
      return 1
      ;;
  esac
}

agent_toolkit_github_asset() {
  local os arch
  os="$(_at_uname_s)"
  arch="$(_at_arch_token)" || return 1
  case "$os" in
    Darwin) printf 'agent-toolkit-macos-%s\n' "$arch" ;;
    Linux) printf 'agent-toolkit-linux-%s\n' "$arch" ;;
    MINGW* | MSYS* | CYGWIN* | Windows_NT) printf 'agent-toolkit-windows-x86_64.exe\n' ;;
    *)
      _at_warn "unsupported OS for GitHub binary: $os"
      return 1
      ;;
  esac
}

agent_toolkit_release_asset() {
  agent_toolkit_github_asset
}

agent_toolkit_uv_package_spec() {
  local ver="${AGENT_TOOLKIT_CLI_VERSION:-${AGENT_TOOLKIT_PIN:-}}"
  if [[ -z $ver ]]; then
    printf '%s>=%s\n' "$AGENT_TOOLKIT_UV_PKG" "$AGENT_TOOLKIT_MIN_VERSION"
    return 0
  fi
  case "$ver" in
    *=*) printf '%s\n' "$ver" ;;
    *) printf '%s==%s\n' "$AGENT_TOOLKIT_UV_PKG" "$ver" ;;
  esac
}

agent_toolkit_channel_plan() {
  local ch="${AGENT_TOOLKIT_INSTALL_CHANNEL:-${AGENT_TOOLKIT_CHANNEL:-auto}}"
  case "$ch" in
    brew | aur | github | uv)
      printf '%s\n' "$ch"
      return 0
      ;;
  esac
  local os id
  os="$(_at_uname_s)"
  id="$(_at_os_id)"
  if [[ $os == Darwin ]]; then
    printf 'brew\ngithub\nuv\n'
  elif [[ $id == arch ]]; then
    printf 'aur\ngithub\nuv\n'
  else
    printf 'github\nuv\n'
  fi
}

# True if $1 >= $2 (semver-ish, via sort -V).
_at_version_ge() {
  local have="$1" need="$2" first
  [[ -n $have && -n $need ]] || return 1
  first="$(printf '%s\n%s\n' "$need" "$have" | sort -V | head -n1)"
  [[ $first == "$need" ]]
}

_at_parse_version() {
  local out
  out="$("$@" 2>/dev/null | head -n1 || true)"
  printf '%s\n' "$out" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1
}

_at_ensure_path() {
  export PATH="${HOME}/.local/bin:${PATH:-}"
  if command -v brew >/dev/null 2>&1; then
    local prefix
    prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n $prefix && -d ${prefix}/bin ]]; then
      export PATH="${prefix}/bin:${PATH}"
    fi
  fi
  hash -r 2>/dev/null || true
}

# Prefer a real binary over pyenv/asdf shims when both exist.
_at_cli_path() {
  local c prefix
  if [[ -x ${HOME}/.local/bin/agent-toolkit ]]; then
    printf '%s\n' "${HOME}/.local/bin/agent-toolkit"
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    prefix="$(brew --prefix 2>/dev/null || true)"
    c="${prefix}/bin/agent-toolkit"
    if [[ -n $prefix && -x $c ]]; then
      printf '%s\n' "$c"
      return 0
    fi
  fi
  command -v agent-toolkit 2>/dev/null || return 1
}

agent_toolkit_current_version() {
  local bin
  bin="$(_at_cli_path)" || return 1
  local ver
  ver="$(_at_parse_version "$bin" --version)"
  if [[ -z $ver ]]; then
    ver="$(_at_parse_version "$bin" version)"
  fi
  [[ -n $ver ]] || return 1
  printf '%s\n' "$ver"
}

agent_toolkit_meets_min() {
  local ver
  ver="$(agent_toolkit_current_version)" || return 1
  _at_version_ge "$ver" "$AGENT_TOOLKIT_MIN_VERSION"
}

_at_pin_semver() {
  local ver="${AGENT_TOOLKIT_CLI_VERSION:-${AGENT_TOOLKIT_PIN:-}}"
  case "$ver" in
    '') return 0 ;;
    *=*) ver="${ver##*=}" ;;
  esac
  printf '%s\n' "$ver"
}

_at_pin_or_min_ok() {
  local pin
  pin="$(_at_pin_semver)"
  if [[ -n $pin ]]; then
    _at_version_ge "$pin" "$AGENT_TOOLKIT_MIN_VERSION" || {
      _at_warn "pin ${pin} is below minimum ${AGENT_TOOLKIT_MIN_VERSION}"
      return 1
    }
  fi
  return 0
}

_at_install_brew() {
  command -v brew >/dev/null 2>&1 || return 1
  _at_log "Installing via Homebrew (${AGENT_TOOLKIT_BREW_TAP}/${AGENT_TOOLKIT_BREW_FORMULA})"
  brew tap "$AGENT_TOOLKIT_BREW_TAP" >/dev/null 2>&1 || true
  if brew list --formula "$AGENT_TOOLKIT_BREW_FORMULA" >/dev/null 2>&1; then
    brew upgrade "$AGENT_TOOLKIT_BREW_FORMULA" 2>/dev/null || brew install "$AGENT_TOOLKIT_BREW_FORMULA" || return 1
  else
    brew install "${AGENT_TOOLKIT_BREW_TAP}/${AGENT_TOOLKIT_BREW_FORMULA}" || return 1
  fi
  _at_ensure_path
  return 0
}

_at_install_aur() {
  local helper=""
  if command -v yay >/dev/null 2>&1; then
    helper=yay
  elif command -v paru >/dev/null 2>&1; then
    helper=paru
  else
    return 1
  fi
  if ! sudo -n true >/dev/null 2>&1 && [[ ${EUID:-1} -ne 0 ]]; then
    _at_warn "AUR helper '${helper}' needs sudo; skipping ${AGENT_TOOLKIT_AUR_PKG}"
    return 1
  fi
  _at_log "Installing via AUR (${helper} -S ${AGENT_TOOLKIT_AUR_PKG})"
  "$helper" -S --noconfirm --needed "$AGENT_TOOLKIT_AUR_PKG" || return 1
  _at_ensure_path
  return 0
}

_at_sha256_check() {
  local sums="$1" file="$2"
  if command -v sha256sum >/dev/null 2>&1; then
    grep -E "[[:space:]]${file}$" "$sums" | sha256sum -c -
  elif command -v shasum >/dev/null 2>&1; then
    grep -E "[[:space:]]${file}$" "$sums" | shasum -a 256 -c -
  else
    _at_warn "no sha256sum/shasum — refusing to install an unverified GitHub binary"
    return 1
  fi
}

_at_github_base_url() {
  local rel="${AGENT_TOOLKIT_RELEASE:-}" pin
  pin="$(_at_pin_semver)"
  if [[ -n $rel ]]; then
    [[ $rel == v* ]] || rel="v${rel}"
    printf 'https://github.com/%s/releases/download/%s\n' "$AGENT_TOOLKIT_GITHUB_REPO" "$rel"
  elif [[ -n $pin ]]; then
    printf 'https://github.com/%s/releases/download/v%s\n' "$AGENT_TOOLKIT_GITHUB_REPO" "$pin"
  else
    printf 'https://github.com/%s/releases/latest/download\n' "$AGENT_TOOLKIT_GITHUB_REPO"
  fi
}

_at_install_github() {
  command -v curl >/dev/null 2>&1 || return 1
  local asset base tmp dest
  asset="$(agent_toolkit_github_asset)" || return 1
  base="$(_at_github_base_url)"
  dest="${HOME}/.local/bin/agent-toolkit"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/agent-toolkit.XXXXXX")"
  _at_log "Installing GitHub Release binary (${asset})"
  if ! curl -fsSL "${base}/${asset}" -o "${tmp}/${asset}"; then
    rm -rf "$tmp"
    return 1
  fi
  if ! curl -fsSL "${base}/SHA256SUMS" -o "${tmp}/SHA256SUMS"; then
    _at_warn "SHA256SUMS download failed"
    rm -rf "$tmp"
    return 1
  fi
  if ! (
    cd "$tmp" || exit 1
    _at_sha256_check SHA256SUMS "$asset"
  ); then
    _at_warn "checksum mismatch for ${asset}"
    rm -rf "$tmp"
    return 1
  fi
  mkdir -p "${HOME}/.local/bin"
  chmod +x "${tmp}/${asset}"
  mv -f "${tmp}/${asset}" "$dest"
  rm -rf "$tmp"
  _at_ensure_path
  return 0
}

_at_install_uv() {
  command -v uv >/dev/null 2>&1 || return 1
  local spec
  spec="$(agent_toolkit_uv_package_spec)"
  _at_log "Installing via uv tool (${spec}) — ADR-021 V launcher, not Python as product"
  uv tool install --force "$spec" || return 1
  _at_ensure_path
  return 0
}

_at_run_channel() {
  case "$1" in
    brew) _at_install_brew ;;
    aur) _at_install_aur ;;
    github) _at_install_github ;;
    uv) _at_install_uv ;;
    *) return 1 ;;
  esac
}

_at_try_forced_channel() {
  local ch
  while IFS= read -r ch; do
    [[ -n $ch ]] || continue
    if _at_run_channel "$ch" && agent_toolkit_meets_min; then
      return 0
    fi
    _at_warn "channel ${ch} did not yield ${AGENT_TOOLKIT_MIN_VERSION}+; trying next"
  done < <(agent_toolkit_channel_plan)
  return 1
}

install_agent_toolkit_cli() {
  local force="${1:-}"
  _at_pin_or_min_ok || return 1
  _at_ensure_path
  if [[ $force != force && $force != --force ]]; then
    if agent_toolkit_meets_min; then
      _at_ok "agent-toolkit $(agent_toolkit_current_version) already meets minimum ${AGENT_TOOLKIT_MIN_VERSION}"
      return 0
    fi
  fi
  if _at_try_forced_channel; then
    _at_ok "CLI ready: $(agent_toolkit_current_version) ($(_at_cli_path))"
    return 0
  fi
  _at_warn "failed to install agent-toolkit ${AGENT_TOOLKIT_MIN_VERSION}+ via brew/AUR/GitHub/uv"
  _at_warn "Rollback: export AGENT_TOOLKIT_CLI_VERSION=${AGENT_TOOLKIT_MIN_VERSION} and re-run"
  return 1
}

# Resolve XDG data dir for toolkit capability data (ADR-015 tier 2).
_at_data_dir() {
  local base="${XDG_DATA_HOME:-}"
  if [[ -z $base ]]; then
    base="${HOME}/.local/share"
  fi
  printf '%s\n' "${base}/agent-toolkit/data"
}

# Valid data root requires profiles/ plus skills/ or loops/ (sync.v:is_valid_data_root).
# NOTE: must match paths.v:is_valid_toolkit_root (any of skills/loops/profiles suffices).
_at_is_valid_data_root() {
  local p="$1"
  [[ -n $p && -d $p ]] || return 1
  [[ -d "${p}/skills" || -d "${p}/loops" || -d "${p}/profiles" ]] || return 1
  return 0
}

# Ensure XDG data exists for AUR/bin installs that ship only the binary (no embedded
# baseline). The V binary's `agent-toolkit install` is offline-only (paths.v ADR-015,
# #557 owns downloads), so a fresh AUR install with empty XDG data would always
# fail with "toolkit root not found". Bootstrap via curl + tarball promote (mirrors
# sync.v:DataSync.download_data / promote_staging) when feasible.
_at_ensure_toolkit_data() {
  local bin="${1:-}"
  # Already valid — nothing to do (xdg_data tier will win over AI_WORKSPACE/CWD).
  local dest
  dest="$(_at_data_dir)"
  if _at_is_valid_data_root "$dest"; then
    return 0
  fi
  # Honor offline flag — never hit network.
  local offline="${AGENT_TOOLKIT_OFFLINE:-}"
  offline="$(printf '%s' "$offline" | tr '[:upper:]' '[:lower:]')"
  if [[ $offline == 1 || $offline == true || $offline == yes ]]; then
    _at_warn "offline mode — skipping toolkit data bootstrap (${dest} missing)"
    return 1
  fi
  command -v curl >/dev/null 2>&1 || return 1
  command -v tar >/dev/null 2>&1 || return 1
  local ver=""
  if [[ -n $bin && -x $bin ]]; then
    ver="$(_at_parse_version "$bin" --version)"
  fi
  if [[ -z $ver ]]; then
    ver="${AGENT_TOOLKIT_MIN_VERSION}"
  fi
  # Strip leading v if any (caller may pass vX.Y.Z).
  ver="${ver#v}"
  local tag="v${ver}"
  # Allow pin via AGENT_TOOLKIT_RELEASE.
  if [[ -n ${AGENT_TOOLKIT_RELEASE:-} ]]; then
    tag="${AGENT_TOOLKIT_RELEASE}"
    [[ $tag == v* ]] || tag="v${tag}"
    ver="${tag#v}"
  fi
  local url="https://github.com/${AGENT_TOOLKIT_GITHUB_REPO}/archive/refs/tags/${tag}.tar.gz"
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/agent-toolkit-data.XXXXXX")"
  _at_log "Bootstrapping toolkit data ${tag} → ${dest} (AUR thin install, no embedded baseline)"
  if ! curl --proto =https -fsSL "$url" -o "${tmp}/source.tar.gz"; then
    _at_warn "toolkit data download failed: ${url}"
    rm -rf "$tmp"
    return 1
  fi
  local extract_dir="${tmp}/extract"
  mkdir -p "$extract_dir"
  if ! tar -xzf "${tmp}/source.tar.gz" -C "$extract_dir"; then
    _at_warn "toolkit data extract failed"
    rm -rf "$tmp"
    return 1
  fi
  local src
  src="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  if [[ -z $src || ! -d $src ]]; then
    _at_warn "toolkit data: no top-level dir in tarball"
    rm -rf "$tmp"
    return 1
  fi
  if ! _at_is_valid_data_root "$src"; then
    _at_warn "release tarball does not contain capability data (profiles + skills/loops missing)"
    rm -rf "$tmp"
    return 1
  fi
  local staging
  staging="$(mktemp -d "${TMPDIR:-/tmp}/agent-toolkit-data.XXXXXX")"
  rm -rf "$staging"
  mkdir -p "$staging"
  local ok=1
  for name in skills loops profiles mcp catalogs agents capabilities distributions; do
    if [[ -d "${src}/${name}" ]]; then
      if ! cp -a "${src}/${name}" "${staging}/"; then
        _at_warn "copy ${name} failed"
        ok=0
        break
      fi
    fi
  done
  if [[ $ok -ne 1 ]] || ! _at_is_valid_data_root "$staging"; then
    rm -rf "$staging" "$tmp"
    return 1
  fi
  printf '%s\n' "$ver" >"${staging}/.version"
  if [[ -e $dest ]]; then
    rm -rf "$dest" || {
      rm -rf "$staging" "$tmp"
      return 1
    }
  fi
  mkdir -p "$(dirname "$dest")"
  if ! mv "$staging" "$dest"; then
    rm -rf "$staging" "$tmp"
    return 1
  fi
  rm -rf "$tmp"
  _at_ok "toolkit data bootstrapped: ${dest} (${tag})"
  return 0
}

deploy_agent_toolkit_profiles() {
  _at_ensure_path
  if ! command -v agent-toolkit >/dev/null 2>&1 && [[ ! -x ${HOME}/.local/bin/agent-toolkit ]]; then
    _at_warn "agent-toolkit not on PATH — cannot deploy profiles"
    return 1
  fi
  local bin
  bin="$(_at_cli_path)"
  # Sanitize harness workspace env that would hijack toolkit root resolution.
  # ADR-015: AGENT_TOOLKIT_ROOT / AI_WORKSPACE override must be a valid data
  # root. Fresh thin workstations have ~/.ai-workspace/profiles (single file
  # oss-contrib.yaml) which falsely qualifies as is_valid_toolkit_root (only
  # checks dir existence). Unset it for the install invoke so XDG/embedded
  # tiers win. Preserve user's env after.
  local _at_save_ai="${AI_WORKSPACE:-__unset__}"
  local _at_save_root="${AGENT_TOOLKIT_ROOT:-__unset__}"
  local _at_sanitized=0
  if [[ -n ${AI_WORKSPACE:-} ]]; then
    if [[ -f ${AI_WORKSPACE}/AGENTS.md || -d ${AI_WORKSPACE}/knowledge ]]; then
      if ! _at_is_valid_data_root "$AI_WORKSPACE"; then
        _at_warn "sanitizing AI_WORKSPACE for toolkit install (harness workspace, not data root): ${AI_WORKSPACE}"
        unset AI_WORKSPACE
        _at_sanitized=1
      elif [[ ! -d ${AI_WORKSPACE}/profiles/claude-code && ! -d ${AI_WORKSPACE}/profiles/cursor ]]; then
        # Workspace with only profiles/oss-contrib.yaml but no real tool profiles.
        _at_warn "sanitizing AI_WORKSPACE (contains profiles/ but no tool data): ${AI_WORKSPACE}"
        unset AI_WORKSPACE
        _at_sanitized=1
      fi
    fi
  fi
  if [[ -n ${AGENT_TOOLKIT_ROOT:-} ]]; then
    if [[ -f ${AGENT_TOOLKIT_ROOT}/AGENTS.md || -d ${AGENT_TOOLKIT_ROOT}/knowledge ]]; then
      if ! _at_is_valid_data_root "$AGENT_TOOLKIT_ROOT"; then
        _at_warn "sanitizing AGENT_TOOLKIT_ROOT for toolkit install (harness workspace): ${AGENT_TOOLKIT_ROOT}"
        unset AGENT_TOOLKIT_ROOT
        _at_sanitized=1
      fi
    fi
  fi
  # Bootstrap XDG data for AUR/GitHub binary installs without embedded baseline.
  _at_ensure_toolkit_data "$bin" || _at_warn "toolkit data bootstrap skipped/failed — install may report 'toolkit root not found'"
  _at_log "Deploying profiles via: ${bin} install"
  local rc=0
  # Run from neutral CWD to avoid CWD fallback picking ~/.ai-workspace (which
  # has a spurious profiles/ dir). Keep env sanitized for this invoke only.
  local neutral_cwd
  neutral_cwd="$(mktemp -d "${TMPDIR:-/tmp}/agent-toolkit-neutral.XXXXXX")"
  if ! (cd "$neutral_cwd" && "$bin" install); then
    rc=$?
  fi
  rm -rf "$neutral_cwd"
  # Restore caller's env.
  if [[ $_at_save_ai == __unset__ ]]; then
    unset AI_WORKSPACE 2>/dev/null || true
  else
    export AI_WORKSPACE="$_at_save_ai"
  fi
  if [[ $_at_save_root == __unset__ ]]; then
    unset AGENT_TOOLKIT_ROOT 2>/dev/null || true
  else
    export AGENT_TOOLKIT_ROOT="$_at_save_root"
  fi
  # If we sanitized, also warn how to get the old behavior back if needed.
  if [[ $_at_sanitized -eq 1 ]]; then
    _at_log "env restored after sanitized install"
  fi
  return $rc
}

install_and_deploy_agent_toolkit() {
  install_agent_toolkit_cli "${1:-}" || return 1
  deploy_agent_toolkit_profiles
}

_at_main() {
  local force="" deploy=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force | force) force=force ;;
      --deploy | deploy) deploy=1 ;;
      -h | --help)
        cat <<'EOF'
install-agent-toolkit.sh — bootstrap canonical Agent Toolkit CLI (V binary)

  --force   reinstall/upgrade even if minimum version is already met
  --deploy  run `agent-toolkit install` after the CLI is on PATH

Env: AGENT_TOOLKIT_CLI_VERSION, AGENT_TOOLKIT_INSTALL_CHANNEL, AGENT_TOOLKIT_MIN_VERSION
Rollback: AGENT_TOOLKIT_CLI_VERSION=1.11.0 install-agent-toolkit.sh --force --deploy
EOF
        return 0
        ;;
      *)
        _at_warn "unknown argument: $1"
        return 2
        ;;
    esac
    shift
  done
  if [[ -n $deploy ]]; then
    install_and_deploy_agent_toolkit "$force"
  else
    install_agent_toolkit_cli "$force"
  fi
}

if [[ ${BASH_SOURCE[0]:-} == "$0" ]]; then
  _at_main "$@"
fi
