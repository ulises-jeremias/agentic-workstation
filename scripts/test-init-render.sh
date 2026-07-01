#!/usr/bin/env bash
# test-init-render.sh — render every chezmoi script for every profile and
# confirm:
#   1. the .chezmoi.toml.tmpl questionnaire renders with WORKSTATION_PROFILE
#      (non-interactive path)
#   2. the resulting data is fed back into each .chezmoiscripts/*.tmpl
#   3. every rendered script passes `bash -n` (syntax validation)
#
# This is what CI runs; it is also safe to run locally.
#
# Usage:
#   ./scripts/test-init-render.sh                # test every profile
#   ./scripts/test-init-render.sh technical      # test just one
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# chezmoi resolves the actual source dir via .chezmoiroot (→ home/), so we
# always pass --source="$REPO_ROOT" to stay aligned with README.
CHEZMOI_SOURCE="$REPO_ROOT"
HOME_DIR="${REPO_ROOT}/home"
SCRIPTS_DIR="${HOME_DIR}/.chezmoiscripts"
EXTERNALS="${HOME_DIR}/dot_local/share/agentic-workstation/.chezmoiexternal.toml.tmpl"

PROFILES_DEFAULT=(technical non-technical ai node python data infra minimal custom)
if [[ $# -gt 0 ]]; then
  PROFILES=("$@")
else
  PROFILES=("${PROFILES_DEFAULT[@]}")
fi

if ! command -v chezmoi >/dev/null; then
  echo "error: chezmoi not found in PATH" >&2
  exit 2
fi

c_reset=$'\033[0m'
c_blue=$'\033[1;34m'
c_green=$'\033[1;32m'
c_red=$'\033[1;31m'
c_yellow=$'\033[1;33m'

pass=0
fail=0
out_dir="$(mktemp -d)"
trap 'rm -rf "$out_dir"' EXIT

render_profile() {
  local profile="$1"
  local tmpcfg="$out_dir/cfg-${profile}"
  mkdir -p "$tmpcfg"

  # Step 1 — render .chezmoi.toml.tmpl non-interactively.
  local rendered_toml="$tmpcfg/chezmoi.toml"
  WORKSTATION_PROFILE="$profile" chezmoi execute-template --init --stdinisatty=false \
    --source "$CHEZMOI_SOURCE" \
    <"$HOME_DIR/.chezmoi.toml.tmpl" >"$rendered_toml"

  # Step 2 — render every install script against those values.
  local any_fail=0
  for tmpl in "$SCRIPTS_DIR"/*.tmpl "$EXTERNALS"; do
    [[ -e $tmpl ]] || continue
    local script
    script="$out_dir/$(basename "$tmpl" .tmpl)--${profile}"
    if ! chezmoi --config "$rendered_toml" --source "$CHEZMOI_SOURCE" execute-template <"$tmpl" >"$script"; then
      printf '  %b✗ render failed%b %s\n' "$c_red" "$c_reset" "$(basename "$tmpl")"
      any_fail=1
      continue
    fi
    # Only syntax-check .sh outputs (externals → toml).
    if [[ $tmpl == *.sh.tmpl ]]; then
      if ! bash -n "$script" 2>/tmp/test-init-render.err; then
        printf '  %b✗ bash -n%b %s\n' "$c_red" "$c_reset" "$(basename "$tmpl")"
        sed 's/^/      /' /tmp/test-init-render.err
        any_fail=1
      fi
    fi
  done

  if ((any_fail == 0)); then
    printf '%b✓%b %s\n' "$c_green" "$c_reset" "$profile"
    pass=$((pass + 1))
  else
    printf '%b✗%b %s\n' "$c_red" "$c_reset" "$profile"
    fail=$((fail + 1))
  fi
}

printf '%bRendering chezmoi scripts for %d profile(s)...%b\n' "$c_blue" "${#PROFILES[@]}" "$c_reset"
for p in "${PROFILES[@]}"; do
  render_profile "$p"
done

echo
printf 'Passed: %d   Failed: %d\n' "$pass" "$fail"
if ((fail > 0)); then
  printf '%bSome profiles produced broken scripts.%b\n' "$c_red" "$c_reset" >&2
  exit 1
fi
printf '%bAll profiles render cleanly.%b\n' "$c_green" "$c_reset"

# Consistency check: every profile listed in profiles.yaml must be in the
# $PROFILES_DEFAULT array above. Use awk because we can't rely on yq being
# installed everywhere.
profiles_yaml="${HOME_DIR}/.chezmoidata/profiles.yaml"
if [[ -f $profiles_yaml ]]; then
  declared=$(awk '
    /^profiles:/ { in_profiles=1; next }
    in_profiles && /^[^ ]/ { in_profiles=0 }
    in_profiles && /^  [a-zA-Z0-9_-]+:/ {
      name=$1
      sub(/:.*$/, "", name)
      print name
    }
  ' "$profiles_yaml")
  missing=0
  for p in $declared; do
    if ! printf '%s\n' "${PROFILES_DEFAULT[@]}" | grep -qx "$p"; then
      printf '%bwarning%b: profile "%s" is declared in profiles.yaml but not tested\n' "$c_yellow" "$c_reset" "$p" >&2
      missing=1
    fi
  done
  if ((missing > 0)); then
    echo "Add the missing profile(s) to PROFILES_DEFAULT in scripts/test-init-render.sh"
    exit 1
  fi
fi
