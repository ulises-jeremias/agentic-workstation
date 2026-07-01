#!/usr/bin/env bash
set -euo pipefail

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  c_reset=$'\033[0m'
  c_blue=$'\033[1;34m'
  c_red=$'\033[1;31m'
  c_green=$'\033[1;32m'
else
  c_reset=''
  c_blue=''
  c_red=''
  c_green=''
fi

info() { printf '%b[repo-structure]%b %s\n' "$c_blue" "$c_reset" "$*"; }
fail() { printf '%b[repo-structure]%b %s\n' "$c_red" "$c_reset" "$*"; }
ok() { printf '%b[repo-structure]%b %s\n' "$c_green" "$c_reset" "$*"; }

required_paths=(
  # Root project files
  ".chezmoiroot"
  "README.md"
  "CONTRIBUTING.md"
  "CHANGELOG.md"
  "SECURITY.md"
  "AGENTS.md"
  "install.sh"
  "install.ps1"

  # Documentation index
  "docs/README.md"

  # Architecture Decision Records
  "docs/adrs/README.md"
  "docs/adrs/001-chezmoi-home-source-state.md"
  "docs/adrs/002-profile-driven-tooling.md"
  "docs/adrs/003-ai-and-mcp-baseline.md"
  "docs/adrs/004-skills-compatibility-matrix.md"
  "docs/adrs/005-llm-provider-abstraction.md"
  "docs/adrs/006-multi-tool-portability.md"
  "docs/adrs/007-agentic-harness-three-layers.md"

  # Core documentation
  "docs/ARCHITECTURE.md"
  "docs/AI_LAYER.md"
  "docs/AGENTIC_HARNESS.md"
  "docs/CLIENT_AI_PLAYBOOKS.md"
  "docs/DEV_COMPANION.md"
  "docs/DEV_COMPANION_LLM.md"
  "docs/DEV_COMPANION_PLATFORM.md"
  "docs/DEV_COMPANION_RELIABILITY.md"
  "docs/ECC_PATTERNS.md"
  "docs/MCP_TEMPLATES.md"
  "docs/MULTI_AGENT_ORCHESTRATION.md"
  "docs/REPOSITORY_GOVERNANCE.md"
  "docs/SKILLS.md"

  # Wiki (synced via CI)
  "docs/wiki/_Sidebar.md"
  "docs/wiki/HOME.md"
  "docs/wiki/TECHNICAL_QUICKSTART.md"
  "docs/wiki/GUIDED_AI_INSTALL.md"
  "docs/wiki/QUESTIONNAIRE.md"
  "docs/wiki/CHEZMOI.md"
  "docs/wiki/CLI.md"
  "docs/wiki/PROFILES.md"
  "docs/wiki/WINDOWS.md"
  "docs/wiki/RELEASES.md"
  "docs/wiki/CREDENTIALS.md"
  "docs/wiki/INTEGRATIONS.md"
  "docs/wiki/CONTRIBUTING.md"
  "docs/wiki/CHANGELOG.md"
  "docs/wiki/SECURITY.md"
  "docs/wiki/TROUBLESHOOTING.md"

  # Visual assets
  "static/hero-banner.svg"

  # Chezmoi source state
  "home/.chezmoi.toml.tmpl"
  "home/.chezmoidata/base.yaml"
  "home/.chezmoiscripts/run_once_before_10-install-core-tools.sh.tmpl"

  # CLI helpers (chezmoi source paths)
  "home/dot_local/bin/executable_dots-doctor"
  "home/dot_local/bin/executable_dots-bootstrap"
  "home/dot_local/bin/executable_dots-skills"
  "home/dot_local/bin/executable_dots-loadenv"
  "home/dot_local/bin/executable_dots-devcompanion"
  "home/dot_local/bin/executable_dots-update-check"
  "home/dot_local/bin/executable_dots-sync-ai"
  "home/dot_local/lib/agentic-workstation/easy-options/easyoptions.sh"

  # CI workflows and scripts
  ".github/workflows/release-ai-assets.yml"
  ".github/workflows/install-methods-matrix.yml"
  "scripts/check-shell-syntax.sh"
  "scripts/check-markdown-tables.sh"
  "scripts/install-skills.sh"
  "scripts/install-skills.ps1"
  "scripts/release-artifacts.json"
  "scripts/build-release-artifacts.py"
  "scripts/verify-release-dump.sh"
  "scripts/check-ai-install-prereqs.sh"
  "scripts/check-ai-install-prereqs.ps1"
  "scripts/ci/serve-release-artifacts.sh"
  "scripts/ci/serve-release-artifacts.ps1"
  "scripts/ci/assert-install-layout.sh"
  "scripts/ci/assert-install-layout.ps1"
)

info "validating required repository paths (${#required_paths[@]} checks)"
errors=0
for path in "${required_paths[@]}"; do
  info "checking: ${path}"
  if [[ ! -e ${path} ]]; then
    fail "Missing required path: ${path}" >&2
    ((errors++))
  else
    ok "found: ${path}"
  fi
done

if ((errors > 0)); then
  fail "Repository structure validation FAILED: ${errors} missing path(s)."
  exit 1
fi

ok "Repository structure validation passed (${#required_paths[@]}/${#required_paths[@]})."
