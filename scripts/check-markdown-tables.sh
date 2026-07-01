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

info() { printf '%b[markdown-tables]%b %s\n' "$c_blue" "$c_reset" "$*"; }
fail() { printf '%b[markdown-tables]%b %s\n' "$c_red" "$c_reset" "$*"; }
ok() { printf '%b[markdown-tables]%b %s\n' "$c_green" "$c_reset" "$*"; }

info "checking markdown table structure"

# The awk program is intentionally single-quoted so shell variables are not expanded.
# shellcheck disable=SC2016
if ! rg --files -g "*.md" | xargs awk '
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}

function is_fence(s) {
  s = trim(s)
  return s ~ /^```/ || s ~ /^~~~/
}

function is_table_row(s) {
  s = trim(s)
  return s ~ /^\|.*\|$/ || s ~ /[^|]\|[^|]/
}

function is_separator(s) {
  s = trim(s)
  return s ~ /^\|?[[:space:]:-]{3,}([[:space:]]*\|[[:space:]:-]{3,})+\|?$/
}

function has_visible_cell(s, cleaned) {
  cleaned = trim(s)
  gsub(/[|[:space:]:-]/, "", cleaned)
  return length(cleaned) > 0
}

function report(line, message) {
  printf "%s:%d: %s\n", FILENAME, line, message
  status = 1
}

BEGINFILE {
  in_fence = 0
  pending_separator = 0
  pending_separator_line = 0
  previous = ""
  previous_line = 0
}

{
  if (is_fence($0)) {
    in_fence = !in_fence
    previous = ""
    pending_separator = 0
    next
  }

  if (in_fence) {
    next
  }

  if (pending_separator) {
    if (!is_table_row($0) || is_separator($0) || !has_visible_cell($0)) {
      report(pending_separator_line, "table separator is not followed by a non-empty data row")
    }
    pending_separator = 0
  }

  if (is_table_row($0) && !is_separator($0) && !has_visible_cell($0)) {
    report(FNR, "table row has no visible cell content")
  }

  if (is_separator($0)) {
    if (!is_table_row(previous) || is_separator(previous) || !has_visible_cell(previous)) {
      report(FNR, "table separator is not preceded by a non-empty header row")
    }
    pending_separator = 1
    pending_separator_line = FNR
  }

  previous = $0
  previous_line = FNR
}

ENDFILE {
  if (pending_separator) {
    report(pending_separator_line, "table separator is not followed by a non-empty data row")
  }
}

END { exit status }
'; then
  fail "markdown table validation failed"
  exit 1
fi

ok "markdown tables passed validation"
