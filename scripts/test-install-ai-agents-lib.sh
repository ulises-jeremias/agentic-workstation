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
expect_eq "$(agent_npm_spec @github/copilot copilot_cli)" "@github/copilot@latest" "Copilot uses the current npm package"

PI_PIN="0.9.0"
expect_eq "$(agent_npm_spec @mariozechner/pi pi)" "@mariozechner/pi@0.9.0" "npm spec honors pin"
unset PI_PIN || true
CLAUDE_CODE_PIN="1.2.3"
if agent_pin_matches_output claude_code "Claude Code 1.2.3"; then
  ok "installed command output can satisfy an exact pin"
else
  bad "installed command output can satisfy an exact pin"
fi
if agent_pin_matches_output claude_code "Claude Code 11.2.30"; then
  bad "installed command output rejects a mismatched exact pin"
else
  ok "installed command output rejects a mismatched exact pin"
fi
unset CLAUDE_CODE_PIN

# --- channel plans ---
AGENTIC_WS_OS_RELEASE_ID=darwin
expect_eq "$(agent_channel_plan auto | tr '\n' ' ')" "brew mise script " "auto plan expands to brew/mise/script"

AI_AGENTS_INSTALL_CHANNEL=npm
expect_eq "$(agent_channel_plan npm)" "npm" "forced single channel passthrough"
expect_eq "$(agent_channel_plan auto)" "npm" "global channel override beats auto"
unset AI_AGENTS_INSTALL_CHANNEL || true

# --- Arch package preferences ---
expect_eq "$(agent_arch_packages claude_code | tr '\n' ' ')" "claude-code claude-code-bin " "Claude Code checks configured Arch packages first"
expect_eq "$(agent_arch_packages opencode)" "opencode" "OpenCode uses the native Arch package"
expect_eq "$(agent_arch_packages copilot_cli)" "github-copilot-cli" "Copilot CLI checks its Arch package"
expect_eq "$(agent_arch_packages muse_code)" "muse-code-bin" "Muse Code uses its AUR binary package"
expect_eq "$(agent_arch_packages pi)" "pi-coding-agent-bin" "Pi uses its AUR binary package"
expect_eq "$(agent_arch_packages gemini_cli)" "gemini-cli" "Gemini CLI uses the native Arch package"
expect_eq "$(agent_arch_packages codex)" "openai-codex" "Codex uses the native Arch package"
arch_mock_dir="$(mktemp -d)"
trap 'rm -rf "$arch_mock_dir"' EXIT
cat >"$arch_mock_dir/pacman" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  -Qq) exit 1 ;;
  -Si) [[ ${2:-} == claude-code-bin ]] ;;
  -S) printf 'pacman:%s\n' "${4:-}" >>"$MOCK_INSTALL_LOG" ;;
esac
EOF
cat >"$arch_mock_dir/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
cat >"$arch_mock_dir/yay" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == -Si && $2 == claude-code ]]; then
  exit 0
fi
printf 'yay:%s\n' "${2:-}" >>"$MOCK_INSTALL_LOG"
EOF
chmod +x "$arch_mock_dir/pacman" "$arch_mock_dir/sudo" "$arch_mock_dir/yay"
arch_lookup_output="$(
  PATH="$arch_mock_dir:$PATH" MOCK_INSTALL_LOG="$arch_mock_dir/install.log" \
    AGENTIC_WS_OS_RELEASE_ID=arch _aa_install_arch_package claude_code 2>&1
)"
if grep -q 'installed with pacman package claude-code-bin' <<<"$arch_lookup_output" &&
  grep -qx 'pacman:claude-code-bin' "$arch_mock_dir/install.log" &&
  ! grep -q '^yay:' "$arch_mock_dir/install.log"; then
  ok "all configured repository candidates are checked before AUR"
else
  bad "all configured repository candidates are checked before AUR"
fi

# AUR packages for Muse Code and Pi must install successfully and pass each
# agent's command verification gate.
mkdir -p "$arch_mock_dir/bin"
cat >"$arch_mock_dir/bin/pacman" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  -Qq|-Si) exit 1 ;;
esac
EOF
cat >"$arch_mock_dir/bin/yay" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == -Si && ( $2 == muse-code-bin || $2 == pi-coding-agent-bin ) ]]; then
  exit 0
fi
printf 'yay:%s\n' "${@: -1}" >>"$MOCK_INSTALL_LOG"
EOF
cat >"$arch_mock_dir/bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
for command_name in muse pi; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$arch_mock_dir/bin/$command_name"
done
chmod +x "$arch_mock_dir/bin/"*
if PATH="$arch_mock_dir/bin:$PATH" MOCK_INSTALL_LOG="$arch_mock_dir/install-aur.log" \
  AGENTIC_WS_OS_RELEASE_ID=arch install_catalog_agent muse_code force &&
  PATH="$arch_mock_dir/bin:$PATH" MOCK_INSTALL_LOG="$arch_mock_dir/install-aur.log" \
    AGENTIC_WS_OS_RELEASE_ID=arch install_catalog_agent pi force &&
  grep -qx 'yay:muse-code-bin' "$arch_mock_dir/install-aur.log" &&
  grep -qx 'yay:pi-coding-agent-bin' "$arch_mock_dir/install-aur.log"; then
  ok "Muse Code and Pi AUR packages install and pass command verification"
else
  bad "Muse Code and Pi AUR packages install and pass command verification"
fi

if AI_AGENTS_ALLOW_REMOTE_INSTALL=0 _aa_remote_fallback_allowed arch; then
  bad "Arch remote installer fallback is disabled by default"
else
  ok "Arch remote installer fallback is disabled by default"
fi
if AI_AGENTS_ALLOW_REMOTE_INSTALL=1 _aa_remote_fallback_allowed arch; then
  ok "Arch remote installer fallback requires an explicit opt-in"
else
  bad "Arch remote installer fallback requires an explicit opt-in"
fi

expect_fail "unknown channel rejected" agent_channel_plan teleport
expect_fail "retired gh-extension channel rejected" agent_channel_plan gh-extension

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
