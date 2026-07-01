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

info() { printf '%b[shell-syntax]%b %s\n' "$c_blue" "$c_reset" "$*"; }
fail() { printf '%b[shell-syntax]%b %s\n' "$c_red" "$c_reset" "$*"; }
ok() { printf '%b[shell-syntax]%b %s\n' "$c_green" "$c_reset" "$*"; }

status=0
info "checking bash syntax for all .sh files and chezmoi executables"
while IFS= read -r file; do
  info "checking: ${file}"
  if ! bash -n "${file}"; then
    fail "syntax error: ${file}"
    status=1
  else
    ok "valid: ${file}"
  fi
done < <(rg --files -g "*.sh")
while IFS= read -r file; do
  info "checking: ${file}"
  if ! bash -n "${file}"; then
    fail "syntax error: ${file}"
    status=1
  else
    ok "valid: ${file}"
  fi
done < <(rg --files -g "home/dot_local/bin/executable_dots-*" .)

if [[ ${status} -eq 0 ]]; then
  ok "all shell scripts passed syntax validation"
fi

exit "${status}"
