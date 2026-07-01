#!/usr/bin/env bash
set -euo pipefail

# LLM Server management — colibri (RTX 3060 12GB)
#
# Profiles (one at a time, GPU memory constraint):
#   coding    → vLLM Docker  port 8000  Qwen2.5-Coder-7B-AWQ  ~400 tok/s
#   reasoning → Ollama        port 11434 DeepSeek-R1-7B-Q4      ~26 tok/s
#
# Switching stops the running profile before starting the new one.

# ── Paths & defaults ─────────────────────────────────────────────────────────

LLM_SERVER_CONFIG="${HOME}/.local/share/agentic-workstation/llm/config.env"
LLM_SERVER_LOG_CODING="${HOME}/.local/share/agentic-workstation/llm/coding.log"
LLM_SERVER_LOG_REASONING="${HOME}/.local/share/agentic-workstation/llm/reasoning.log"
LLM_PROFILE_FILE="${HOME}/.local/share/agentic-workstation/llm/active-profile"

VLLM_IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:v0.19.0-cu130}"
VLLM_PORT="${VLLM_PORT:-8000}"
VLLM_MAX_MODEL_LEN="${VLLM_MAX_MODEL_LEN:-16384}"
VLLM_CONTAINER="${VLLM_CONTAINER:-vllm-server}"
VLLM_MODEL="${VLLM_MODEL:-Qwen/Qwen2.5-Coder-7B-Instruct-AWQ}"

OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-deepseek-r1}"

# ── Colors ────────────────────────────────────────────────────────────────────

_colors() {
  if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
    c_reset=$'\033[0m'
    c_blue=$'\033[1;34m'
    c_green=$'\033[1;32m'
    c_red=$'\033[1;31m'
    c_yellow=$'\033[1;33m'
    c_dim=$'\033[2m'
  else
    c_reset='' c_blue='' c_green='' c_red='' c_yellow='' c_dim=''
  fi
}
_colors

log() { printf '%b[llm-server]%b %s\n' "$c_blue" "$c_reset" "$*"; }
ok() { printf '  %b✓%b %s\n' "$c_green" "$c_reset" "$*"; }
warn() { printf '  %b!%b %s\n' "$c_yellow" "$c_reset" "$*"; }
fail() { printf '  %b✗%b %s\n' "$c_red" "$c_reset" "$*"; }
dim() { printf '%b%s%b\n' "$c_dim" "$*" "$c_reset"; }

# ── Config ────────────────────────────────────────────────────────────────────

llm_load_config() {
  if [[ -f $LLM_SERVER_CONFIG ]]; then
    set -a
    source "$LLM_SERVER_CONFIG"
    set +a
  fi
}

llm_active_profile() {
  [[ -f $LLM_PROFILE_FILE ]] && cat "$LLM_PROFILE_FILE" || echo "none"
}

_set_profile() {
  mkdir -p "$(dirname "$LLM_PROFILE_FILE")"
  echo "$1" >"$LLM_PROFILE_FILE"
}

# ── vLLM (coding) ─────────────────────────────────────────────────────────────

_vllm_is_running() {
  docker ps -q --filter "name=${VLLM_CONTAINER}" 2>/dev/null | grep -q . && return 0
  return 1
}

# shellcheck disable=SC2120
_vllm_start() {
  llm_load_config
  local model="${1:-${VLLM_MODEL}}"
  log "Starting vLLM (coding) — ${model}"
  log "Port: ${VLLM_PORT}  VRAM: ~4.5 GB  Speed: ~400 tok/s"

  docker rm -f "$VLLM_CONTAINER" 2>/dev/null || true

  docker run -d --gpus all \
    --name "$VLLM_CONTAINER" \
    -v "${HOME}/.cache/huggingface:/root/.cache/huggingface" \
    -p "${VLLM_PORT}:8000" \
    --ipc=host \
    "$VLLM_IMAGE" \
    "$model" \
    --max-model-len "$VLLM_MAX_MODEL_LEN" \
    --enable-auto-tool-choice \
    --tool-call-parser hermes >/dev/null

  log "Waiting for vLLM to be ready..."
  local retries=60
  while [[ $retries -gt 0 ]]; do
    if curl -sf "http://localhost:${VLLM_PORT}/v1/models" >/dev/null 2>&1; then
      _set_profile "coding"
      ok "vLLM ready — http://colibri.skypiea.local:${VLLM_PORT}/v1"
      return 0
    fi
    sleep 5
    retries=$((retries - 1))
  done
  fail "vLLM failed to start"
  docker logs "$VLLM_CONTAINER" 2>&1 | tail -10
  return 1
}

_vllm_stop() {
  if _vllm_is_running; then
    log "Stopping vLLM..."
    docker stop "$VLLM_CONTAINER" >/dev/null
    ok "vLLM stopped"
  fi
}

# ── Ollama (reasoning) ────────────────────────────────────────────────────────

_ollama_is_running() {
  pgrep -f "ollama serve" >/dev/null 2>&1 && return 0
  return 1
}

_ollama_start() {
  llm_load_config
  log "Starting Ollama (reasoning) — ${OLLAMA_MODEL}"
  log "Port: ${OLLAMA_PORT}  VRAM: ~4.4 GB  Speed: ~26 tok/s (chain-of-thought)"

  OLLAMA_HOST="0.0.0.0:${OLLAMA_PORT}" nohup ollama serve \
    >"$LLM_SERVER_LOG_REASONING" 2>&1 &

  log "Waiting for Ollama to be ready..."
  local retries=30
  while [[ $retries -gt 0 ]]; do
    if curl -sf "http://localhost:${OLLAMA_PORT}/api/version" >/dev/null 2>&1; then
      _set_profile "reasoning"
      ok "Ollama ready — http://colibri.skypiea.local:${OLLAMA_PORT}/v1"
      ok "Model: ${OLLAMA_MODEL}"
      return 0
    fi
    sleep 2
    retries=$((retries - 1))
  done
  fail "Ollama failed to start"
  tail -10 "$LLM_SERVER_LOG_REASONING" 2>/dev/null || true
  return 1
}

_ollama_stop() {
  if _ollama_is_running; then
    log "Stopping Ollama..."
    pkill -f "ollama serve" || true
    sleep 2
    ok "Ollama stopped"
  fi
}

# ── Public API ────────────────────────────────────────────────────────────────

llm_install() {
  log "Pulling vLLM Docker image: ${VLLM_IMAGE}..."
  docker pull "$VLLM_IMAGE"

  log "DeepSeek-R1 GGUF model status:"
  local gguf="${HOME}/.cache/llmfit/models/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
  if [[ -f $gguf ]]; then
    ok "GGUF already downloaded: $(du -sh "$gguf" | cut -f1)"
  else
    log "Downloading DeepSeek-R1-Distill-Qwen-7B Q4_K_M..."
    llmfit download bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF --quant Q4_K_M
  fi

  log "Registering DeepSeek-R1 in Ollama..."
  local modelfile="${HOME}/.local/share/agentic-workstation/llm/Modelfile.deepseek-r1"
  if ! ollama list 2>/dev/null | grep -q "deepseek-r1"; then
    _ollama_start
    sleep 2
    ollama create deepseek-r1 -f "$modelfile" 2>/dev/null || true
    _ollama_stop
  else
    ok "deepseek-r1 already registered in Ollama"
  fi

  mkdir -p "$(dirname "$LLM_SERVER_CONFIG")"
  cat >"$LLM_SERVER_CONFIG" <<EOF
VLLM_IMAGE=${VLLM_IMAGE}
VLLM_PORT=${VLLM_PORT}
VLLM_MAX_MODEL_LEN=${VLLM_MAX_MODEL_LEN}
VLLM_MODEL=${VLLM_MODEL}
VLLM_CONTAINER=${VLLM_CONTAINER}
OLLAMA_PORT=${OLLAMA_PORT}
OLLAMA_MODEL=${OLLAMA_MODEL}
EOF

  ok "Install complete. Run: dots-llm-server start"
  dim "  coding    → vLLM  port ${VLLM_PORT}  ${VLLM_MODEL}"
  dim "  reasoning → Ollama port ${OLLAMA_PORT}  ${OLLAMA_MODEL}"
}

llm_start() {
  llm_load_config
  local profile="${1:-coding}"

  case "$profile" in
    coding)
      if _vllm_is_running; then
        warn "vLLM already running on port ${VLLM_PORT}"
        return 0
      fi
      _ollama_stop
      _vllm_start
      ;;
    reasoning)
      if _ollama_is_running; then
        warn "Ollama already running on port ${OLLAMA_PORT}"
        return 0
      fi
      _vllm_stop
      _ollama_start
      ;;
    *)
      fail "Unknown profile: ${profile}. Use: coding | reasoning"
      return 1
      ;;
  esac
}

llm_stop() {
  llm_load_config
  _vllm_stop
  _ollama_stop
  _set_profile "none"
  ok "All LLM services stopped"
}

llm_switch() {
  local profile="${1:-}"
  if [[ -z $profile ]]; then
    local current
    current="$(llm_active_profile)"
    profile="$([[ $current == "coding" ]] && echo "reasoning" || echo "coding")"
    log "Switching from ${current} → ${profile}"
  fi
  llm_start "$profile"
}

llm_status() {
  llm_load_config
  echo
  printf '%bLLM Server Status — colibri%b\n' "$c_blue" "$c_reset"
  printf '%s\n' "───────────────────────────────────────"
  echo

  local active
  active="$(llm_active_profile)"
  printf '  Active profile: %b%s%b\n\n' "$c_yellow" "$active" "$c_reset"

  # vLLM
  printf '%bcoding%b  — vLLM  port %s\n' "$c_blue" "$c_reset" "$VLLM_PORT"
  if _vllm_is_running; then
    ok "RUNNING — http://colibri.skypiea.local:${VLLM_PORT}/v1"
    curl -s "http://localhost:${VLLM_PORT}/v1/models" 2>/dev/null |
      python3 -c "import json,sys; [print('  Model: ' + m['id']) for m in json.load(sys.stdin).get('data',[])]" 2>/dev/null || true
  else
    warn "stopped"
  fi
  echo

  # Ollama
  printf '%breasoning%b — Ollama port %s\n' "$c_blue" "$c_reset" "$OLLAMA_PORT"
  if _ollama_is_running; then
    ok "RUNNING — http://colibri.skypiea.local:${OLLAMA_PORT}/v1"
    printf '  Model: %s\n' "$OLLAMA_MODEL"
  else
    warn "stopped"
  fi
  echo

  printf '%bSwitch with:%b dots-llm-server switch [coding|reasoning]\n' "$c_dim" "$c_reset"
  echo
}

llm_logs() {
  llm_load_config
  local profile="${1:-$(llm_active_profile)}"
  case "$profile" in
    coding)
      if _vllm_is_running; then
        docker logs -f "$VLLM_CONTAINER"
      else
        warn "vLLM not running"
      fi
      ;;
    reasoning)
      if [[ -f $LLM_SERVER_LOG_REASONING ]]; then
        tail -f "$LLM_SERVER_LOG_REASONING"
      else
        warn "No reasoning log found"
      fi
      ;;
    *)
      fail "Usage: logs [coding|reasoning]"
      ;;
  esac
}
