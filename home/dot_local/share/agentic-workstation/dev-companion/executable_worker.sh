#!/usr/bin/env bash
set -eo pipefail

# agentic-workstation dev companion — optional queue worker (bounded, single-flight).
# Does not auto-merge; does not load API keys. Wire run.command at your own risk.

base="${DOTS_WORKSTATION_DEV_COMPANION_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/agentic-workstation/dev-companion}"
queue="${base}/queue"
pending="${queue}/pending"
processing="${queue}/processing"
done_d="${queue}/done"
failed="${queue}/failed"
run_d="${base}/run"
logs="${base}/logs"
lockfile="${run_d}/worker.lock"
logfile="${logs}/worker.log"

mkdir -p "$pending" "$processing" "$done_d" "$failed" "$run_d" "$logs"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

log() { printf '%s %s\n' "$(ts)" "$*" >>"$logfile"; }

process_one() {
  local job path timeout_sec
  shopt -s nullglob
  local jobs=("${pending}"/*.job)
  shopt -u nullglob
  if ((${#jobs[@]} == 0)); then
    log "no pending jobs"
    return 0
  fi
  path="${jobs[0]}"
  job="$(basename "$path")"
  log "claim ${job}"
  mv "$path" "${processing}/${job}"

  if ! command -v jq >/dev/null 2>&1; then
    log "jq not installed; move ${job} to done without execution"
    mv "${processing}/${job}" "${done_d}/${job}"
    return 0
  fi

  if ! jq -e '.run.command | type == "array" and length > 0' "${processing}/${job}" >/dev/null 2>&1; then
    log "noop (no run.command array) — done ${job}"
    mv "${processing}/${job}" "${done_d}/${job}"
    return 0
  fi

  timeout_sec="$(jq -r '.run.timeout_sec // 300' "${processing}/${job}")"
  mapfile -t cmd < <(jq -r '.run.command[]' "${processing}/${job}")
  if ((${#cmd[@]} == 0)); then
    log "empty command — failed ${job}"
    mv "${processing}/${job}" "${failed}/${job}"
    return 0
  fi

  log "execute ${job} timeout=${timeout_sec}"
  if timeout "${timeout_sec}" "${cmd[@]}"; then
    mv "${processing}/${job}" "${done_d}/${job}"
    log "done ${job}"
  else
    mv "${processing}/${job}" "${failed}/${job}"
    log "failed ${job}"
  fi
}

(
  flock -n 9 || {
    log "another worker holds lock; exit"
    exit 0
  }
  process_one
) 9>"$lockfile"
