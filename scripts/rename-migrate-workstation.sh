#!/usr/bin/env bash
# scripts/rename-migrate-workstation.sh
# Migration helper for existing clones and local paths after the rename from
# agentic-workstation → agentic-workstation.
#
# Usage:
#   ./scripts/rename-migrate-workstation.sh
#
# This script is idempotent — safe to re-run.

set -euo pipefail

MIGRATE_FROM="ulises-jeremias/agentic-workstation"
MIGRATE_TO="ulises-jeremias/agentic-workstation"

SSH_PATTERN="git@github.com:${MIGRATE_FROM}"
HTTPS_PATTERN="https://github.com/${MIGRATE_FROM}"
SSH_NEW="git@github.com:${MIGRATE_TO}"
HTTPS_NEW="https://github.com/${MIGRATE_TO}"

declare -A DIR_MIGRATIONS=(
  ["${HOME}/.agentic-workstation"]="${HOME}/.agentic-workstation"
  ["${HOME}/.local/share/agentic-workstation"]="${HOME}/.local/share/agentic-workstation"
  ["${HOME}/.local/lib/agentic-workstation"]="${HOME}/.local/lib/agentic-workstation"
  ["${HOME}/.config/agentic-workstation"]="${HOME}/.config/agentic-workstation"
)

CHEZMOI_CONFIG_OLD="${HOME}/.config/chezmoi/agentic-workstation.toml"
CHEZMOI_CONFIG_NEW="${HOME}/.config/chezmoi/agentic-workstation.toml"

info()  { printf '\033[36m[migrate]\033[0m %s\n' "$*"; }
ok()    { printf '\033[32m  \xe2\x9c\x93\033[0m %s\n' "$*"; }
skip()  { printf '\033[33m  -\033[0m %s\n' "$*"; }

update_remote() {
  local dir="$1" label="$2"
  if [[ ! -d "${dir}/.git" ]]; then skip "${label}: not a git clone"; return; fi
  local url
  url="$(git -C "${dir}" remote get-url origin 2>/dev/null || true)"
  [[ -z "${url}" ]] && { skip "${label}: no origin remote"; return; }
  local new_url=""
  if [[ "${url}" == "${SSH_PATTERN}" || "${url}" == "${SSH_PATTERN}.git" ]]; then
    new_url="${SSH_NEW}"
  elif [[ "${url}" == "${HTTPS_PATTERN}" || "${url}" == "${HTTPS_PATTERN}.git" ]]; then
    new_url="${HTTPS_NEW}"
  fi
  [[ -z "${new_url}" ]] && { skip "${label}: remote ${url} does not match ${MIGRATE_FROM}"; return; }
  local nb="${new_url%.git}" rb="${url%.git}"
  [[ "${rb}" == "${nb}" ]] && { skip "${label}: already points to ${MIGRATE_TO}"; return; }
  info "${label}: updating remote origin -> ${new_url}"
  git -C "${dir}" remote set-url origin "${new_url}"
  ok "${label}: remote updated"
}

migrate_dir() {
  local src="$1" dst="$2"
  [[ ! -e "${src}" ]] && { skip "${src}: does not exist"; return; }
  [[ -e "${dst}" ]] && { skip "${src} -> ${dst}: destination already exists"; return; }
  mkdir -p "$(dirname "${dst}")"
  info "Moving ${src} -> ${dst}"
  mv "${src}" "${dst}"
  ok "${src} -> ${dst}"
}

update_chezmoi_config() {
  [[ ! -f "${CHEZMOI_CONFIG_OLD}" ]] && { skip "chezmoi config ${CHEZMOI_CONFIG_OLD}: not found"; return; }
  [[ -f "${CHEZMOI_CONFIG_NEW}" ]] && { skip "chezmoi config ${CHEZMOI_CONFIG_NEW}: already exists"; return; }
  cp "${CHEZMOI_CONFIG_OLD}" "${CHEZMOI_CONFIG_NEW}"
  local old_source="${HOME}/.agentic-workstation"
  local new_source="${HOME}/.agentic-workstation"
  if grep -q "${old_source}" "${CHEZMOI_CONFIG_NEW}" 2>/dev/null; then
    sed -i "s|${old_source}|${new_source}|g" "${CHEZMOI_CONFIG_NEW}"
  fi
  rm "${CHEZMOI_CONFIG_OLD}"
  ok "chezmoi config: ${CHEZMOI_CONFIG_OLD} -> ${CHEZMOI_CONFIG_NEW}"
}

main() {
  printf '\n\033[1m=== agentic-workstation -> agentic-workstation migration ===\033[0m\n\n'
  printf '\033[1m[1/3] Updating remotes\033[0m\n'
  update_remote "${HOME}/.agentic-workstation" ".agentic-workstation"
  update_remote "${HOME}/.ai-workspace/repos/github.com/ulises-jeremias/agentic-workstation" "repos/agentic-workstation"
  printf '\n\033[1m[2/3] Migrating directories\033[0m\n'
  for src in "${!DIR_MIGRATIONS[@]}"; do migrate_dir "${src}" "${DIR_MIGRATIONS[${src}]}"; done
  printf '\n\033[1m[3/3] Updating chezmoi config\033[0m\n'
  update_chezmoi_config
  printf '\n\033[1m=== Migration complete ===\033[0m\n'
  printf 'Verify:\n'
  printf '  git -C ~/.agentic-workstation remote -v\n'
  printf '  chezmoi apply --source=~/.agentic-workstation -c ~/.config/chezmoi/agentic-workstation.toml\n'
  printf '  dots-skills list\n'
}

main
