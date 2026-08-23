#!/usr/bin/env bash
# Unit tests for install-ai-agents-lib.sh (no network).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="${ROOT}/home/dot_local/lib/agentic-workstation/install-ai-agents-lib.sh"
CATALOG="${ROOT}/home/.chezmoidata/ai.yaml"

if [[ ! -f $HELPER ]]; then
  echo "FAIL: missing ${HELPER}" >&2
  exit 1
fi

# shellcheck source=home/dot_local/lib/agentic-workstation/install-ai-agents-lib.sh
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

expect_fail() {
  local msg="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    bad "$msg (expected non-zero exit)"
  else
    ok "$msg"
  fi
}

# --- env name mapping ---
expect_eq "$(_aa_env_name claude_code)" "CLAUDE_CODE" "env name mapping with underscore"
expect_eq "$(_aa_env_name gemini_cli)" "GEMINI_CLI" "env name mapping gemini"

# --- pin resolution: <NAME>_PIN wins over <NAME>_VERSION, empty = latest ---
unset CLAUDE_CODE_PIN CLAUDE_CODE_VERSION || true
expect_eq "$(agent_pin claude_code)" "" "no pin configured -> latest"

CLAUDE_CODE_VERSION="1.2.3"
expect_eq "$(agent_pin claude_code)" "1.2.3" "VERSION alias used when PIN unset"

CLAUDE_CODE_PIN="4.5.6"
expect_eq "$(agent_pin claude_code)" "4.5.6" "PIN wins over VERSION"
unset CLAUDE_CODE_PIN CLAUDE_CODE_VERSION || true

# --- npm spec honoring pins ---
unset PI_PIN PI_VERSION || true
expect_eq "$(agent_npm_spec @mariozechner/pi pi)" "@mariozechner/pi@latest" "npm spec latest by default"

PI_PIN="0.9.0"
expect_eq "$(agent_npm_spec @mariozechner/pi pi)" "@mariozechner/pi@0.9.0" "npm spec honors pin"
unset PI_PIN || true

# --- channel plans ---
AGENTIC_WS_OS_RELEASE_ID=darwin
expect_eq "$(agent_channel_plan auto | tr '\n' ' ')" "brew mise script " "auto plan expands to brew/mise/script"

AI_AGENTS_INSTALL_CHANNEL=npm
expect_eq "$(agent_channel_plan npm)" "npm" "forced single channel passthrough"
expect_eq "$(agent_channel_plan auto)" "npm" "global channel override beats auto"
unset AI_AGENTS_INSTALL_CHANNEL || true

expect_fail "unknown channel rejected" agent_channel_plan teleport

# --- CI guard ---
AI_AGENTS_CI_BLOCKED=1
expect_fail "CI-blocked installers refuse to run" install_claude_code
AI_AGENTS_CI_BLOCKED=0
ok "CI override disabled"
unset AI_AGENTS_CI_BLOCKED || true

# --- catalog dispatcher coverage: every catalog agent resolves + has a check ---
catalog_agents="claude_code opencode muse_code copilot_cli pi gemini_cli codex herdr"
for agent in $catalog_agents; do
  # In CI-blocked mode every known agent must skip cleanly (warn + rc=1);
  # an unknown agent would print "unknown agent ..." from the dispatcher.
  out="$(AI_AGENTS_CI_BLOCKED=1 install_catalog_agent "$agent" 2>&1 || true)"
  if grep -q "unknown agent" <<<"$out"; then
    bad "dispatcher missing agent: ${agent}"
  else
    ok "dispatcher knows ${agent} (CI skip)"
  fi
done

expect_fail "unknown agent rejected by dispatcher" install_catalog_agent definitely_not_an_agent

# --- ai.yaml catalog consistency (schema PR contract) ---
if [[ ! -f $CATALOG ]]; then
  bad "missing catalog file ${CATALOG}"
else
  for agent in $catalog_agents; do
    if grep -qE "^  ${agent}:$" "$CATALOG"; then
      ok "catalog entry present: ${agent}"
    else
      bad "catalog entry missing in ai.yaml: ${agent}"
    fi
    if grep -A5 "^  ${agent}:$" "$CATALOG" | grep -q "channel:"; then
      ok "catalog entry declares channel: ${agent}"
    else
      bad "catalog entry missing channel: ${agent}"
    fi
  done
fi

# --- lib documents its pin envs (grep assertions like toolkit tests) ---
if grep -q '<NAME>_PIN' "$HELPER"; then
  ok "helper documents per-agent pin envs"
else
  bad "helper missing per-agent pin documentation"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
