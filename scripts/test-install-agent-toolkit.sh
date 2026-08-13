#!/usr/bin/env bash
# Unit tests for install-agent-toolkit.sh (no network).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="${ROOT}/home/dot_local/lib/agentic-workstation/install-agent-toolkit.sh"

if [[ ! -f $HELPER ]]; then
  echo "FAIL: missing ${HELPER}" >&2
  exit 1
fi

# shellcheck source=home/dot_local/lib/agentic-workstation/install-agent-toolkit.sh
source "$HELPER"

pass=0
fail=0
ok() {
  printf 'PASS: %s\n' "$*"
  pass=$((pass + 1))
}
bad() {
  printf 'FAIL: %s\n' "$*" >&2
  fail=$((fail + 1))
}

expect_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ $got == "$want" ]]; then
    ok "$msg"
  else
    bad "$msg (got '${got}', want '${want}')"
  fi
}

# --- asset mapping ---
AGENT_TOOLKIT_UNAME_S=Linux AGENT_TOOLKIT_UNAME_M=x86_64
expect_eq "$(agent_toolkit_release_asset)" "agent-toolkit-linux-x86_64" "linux x86_64 asset"

AGENT_TOOLKIT_UNAME_S=Linux AGENT_TOOLKIT_UNAME_M=aarch64
expect_eq "$(agent_toolkit_release_asset)" "agent-toolkit-linux-arm64" "linux aarch64 asset"

AGENT_TOOLKIT_UNAME_S=Linux AGENT_TOOLKIT_UNAME_M=arm64
expect_eq "$(agent_toolkit_release_asset)" "agent-toolkit-linux-arm64" "linux arm64 asset"

AGENT_TOOLKIT_UNAME_S=Darwin AGENT_TOOLKIT_UNAME_M=arm64
expect_eq "$(agent_toolkit_release_asset)" "agent-toolkit-macos-arm64" "darwin arm64 asset"

AGENT_TOOLKIT_UNAME_S=Darwin AGENT_TOOLKIT_UNAME_M=x86_64
expect_eq "$(agent_toolkit_release_asset)" "agent-toolkit-macos-x86_64" "darwin x86_64 asset"

# --- uv spec / pin ---
unset AGENT_TOOLKIT_CLI_VERSION || true
expect_eq "$(agent_toolkit_uv_package_spec)" "agent-toolkit-cli>=1.11.0" "default uv spec >=1.11.0"

AGENT_TOOLKIT_CLI_VERSION=1.11.0
expect_eq "$(agent_toolkit_uv_package_spec)" "agent-toolkit-cli==1.11.0" "rollback pin AGENT_TOOLKIT_CLI_VERSION"

AGENT_TOOLKIT_CLI_VERSION='agent-toolkit-cli==1.11.0'
expect_eq "$(agent_toolkit_uv_package_spec)" "agent-toolkit-cli==1.11.0" "full spec passthrough"
unset AGENT_TOOLKIT_CLI_VERSION || true

# --- channel plan ---
osrel="$(mktemp)"
printf 'ID=arch\n' >"$osrel"
AGENT_TOOLKIT_UNAME_S=Linux AGENT_TOOLKIT_OS_RELEASE="$osrel"
plan="$(agent_toolkit_channel_plan | tr '\n' ' ')"
expect_eq "$plan" "aur github uv " "arch plan: aur then github then uv"
rm -f "$osrel"

AGENT_TOOLKIT_UNAME_S=Darwin
plan="$(agent_toolkit_channel_plan | tr '\n' ' ')"
expect_eq "$plan" "brew github uv " "darwin plan: brew then github then uv"

osrel="$(mktemp)"
printf 'ID=ubuntu\n' >"$osrel"
AGENT_TOOLKIT_UNAME_S=Linux AGENT_TOOLKIT_OS_RELEASE="$osrel"
plan="$(agent_toolkit_channel_plan | tr '\n' ' ')"
expect_eq "$plan" "github uv " "generic linux plan: github then uv"
rm -f "$osrel"

AGENT_TOOLKIT_INSTALL_CHANNEL=uv
expect_eq "$(agent_toolkit_channel_plan)" "uv" "forced channel uv"
unset AGENT_TOOLKIT_INSTALL_CHANNEL || true

# --- never import agent_toolkit as the product ---
if rg -n --glob '*.py' 'import agent_toolkit|from agent_toolkit' "$ROOT" >/dev/null 2>&1; then
  bad "found Python import of agent_toolkit"
  rg -n --glob '*.py' 'import agent_toolkit|from agent_toolkit' "$ROOT" || true
else
  ok "no import agent_toolkit in Python sources"
fi

if rg -n --glob '*.py' --glob '!.git/**' 'python[0-9.]* -m agent_toolkit|-m agent_toolkit' "$ROOT" >/dev/null 2>&1; then
  bad "found python -m agent_toolkit invocation"
  rg -n --glob '*.py' --glob '!.git/**' 'python[0-9.]* -m agent_toolkit|-m agent_toolkit' "$ROOT" || true
else
  ok "no python -m agent_toolkit invocations"
fi

# shellcheck disable=SC2016  # literal backtick phrase in helper header
if grep -q 'Never `import agent_toolkit`' "$HELPER"; then
  ok "helper documents no Python-library import"
else
  bad "helper missing MUST NOT import note"
fi

if grep -q 'agent-toolkit-bin' "$HELPER"; then
  ok "helper uses AUR package agent-toolkit-bin"
else
  bad "helper missing agent-toolkit-bin"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
