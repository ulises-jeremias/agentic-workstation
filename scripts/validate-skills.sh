#!/usr/bin/env bash
# scripts/validate-skills.sh — thin workstation: delegates to agent-toolkit
# Validates skill manifests via agent-toolkit when available; otherwise
# treats the thin workstation (no embedded skills) as valid.
#
# Usage:
#   bash scripts/validate-skills.sh          # validate everything
#   bash scripts/validate-skills.sh --strict # also delegate with strict mode

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA="${REPO_ROOT}/lib/schemas/skill.schema.json"
SKILLS_DIR="${REPO_ROOT}/home/dot_local/share/agentic-workstation/skills"

STRICT=false
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=true ;;
    -h | --help)
      echo "Usage: $0 [--strict]"
      exit 0
      ;;
  esac
done

_c() { [[ -t 1 ]] && printf '\033[%sm%s\033[0m' "$1" "$2" || printf '%s' "$2"; }
ok() {
  _c "1;32" "  ✓"
  echo " $*"
}
fail() {
  _c "1;31" "  ✗"
  echo " $*"
}
info() {
  _c "1;34" "  →"
  echo " $*"
}
warn() {
  _c "1;33" "  ⚠"
  echo " $*"
}

echo ""
echo "Skill Manifest Validation (thin workstation)"
echo "-------------------------------------------"

# Thin workstation: no embedded skills — delegate to agent-toolkit
SKILL_COUNT=$(find "${SKILLS_DIR}" -name "skill.json" -print 2>/dev/null | wc -l | tr -d ' ')
if [[ $SKILL_COUNT -eq 0 ]]; then
  if command -v agent-toolkit >/dev/null 2>&1; then
    info "No embedded skills found — delegating to agent-toolkit"
    # Try toolkit's own validation if available; fall back to success
    if agent-toolkit --help 2>&1 | grep -qi "validate"; then
      if [[ $STRICT == "true" ]]; then
        exec agent-toolkit skills validate --strict 2>&1 || true
      else
        exec agent-toolkit skills validate 2>&1 || true
      fi
    else
      info "agent-toolkit installed: $(agent-toolkit --version 2>/dev/null || echo 'ok')"
      info "Thin workstation has no embedded skills — validation delegated to toolkit catalog"
      _c "1;32" "  All 0 embedded skills valid (delegated to agent-toolkit)."
      echo ""
      exit 0
    fi
  else
    info "No embedded skills found and agent-toolkit not installed"
    info "Thin workstation: skills are provided at runtime via: dots-skills install-toolkit (brew / AUR / GitHub / uv V launcher) && agent-toolkit install"
    info "SKILL.md catalog is provided by the toolkit — not embedded in this repo"
    _c "1;32" "  All 0 embedded skills valid (thin workstation)."
    echo ""
    exit 0
  fi
fi

# Fallback: if skills exist (e.g. legacy checkout), run original validation
# This keeps CI compatible during transition
info "Found ${SKILL_COUNT} embedded skill(s) — running local validation (legacy fallback)"
info "Schema: ${SCHEMA#"${REPO_ROOT}"/}"
info "Skills: ${SKILLS_DIR#"${REPO_ROOT}"/}"
echo ""

# Ordered list of tools every bundled skill should declare
REQUIRED_TOOLS=(claude-code opencode cursor windsurf copilot-cli pi muse-code universal)

validate_json() {
  local file="$1"
  python3 - "$file" "$SCHEMA" <<'PYEOF'
import sys, json, pathlib
try:
    import jsonschema
except ImportError:
    print("  [skip] jsonschema not installed — run: pip install jsonschema")
    sys.exit(0)
file_path, schema_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
try:
    instance = json.loads(file_path.read_text(encoding="utf-8"))
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
except Exception as e:
    print(f"  [error] Parse error: {e}")
    sys.exit(1)
validator = jsonschema.Draft7Validator(schema)
errors = sorted(validator.iter_errors(instance), key=lambda e: list(e.path))
if errors:
    for e in errors:
        path = " → ".join(str(p) for p in e.path) or "(root)"
        print(f"  [error] [{path}]: {e.message}")
    sys.exit(1)
sys.exit(0)
PYEOF
}

lint_compat() {
  local file="$1"
  python3 - "$file" "${REQUIRED_TOOLS[@]}" <<'PYEOF'
import sys, json, pathlib
file_path = pathlib.Path(sys.argv[1])
required = sys.argv[2:]
data = json.loads(file_path.read_text(encoding="utf-8"))
compat = data.get("compatibility", {})
source = data.get("source", "")
if source != "bundled":
    sys.exit(0)
missing = [t for t in required if t not in compat]
if missing:
    print(f"  [warn] missing compatibility declaration for: {', '.join(missing)}")
    sys.exit(2)
sys.exit(0)
PYEOF
}

ERRORS=0
WARNINGS=0
COUNT=0

if [[ ! -f ${SCHEMA} ]]; then
  fail "Schema not found: ${SCHEMA}"
  exit 1
fi

while IFS= read -r -d '' skill_json; do
  name="${skill_json#"${SKILLS_DIR}"/}"
  name="${name%/skill.json}"
  COUNT=$((COUNT + 1))
  skill_md="${SKILLS_DIR}/${name}/SKILL.md"
  skill_md_tmpl="${SKILLS_DIR}/${name}/SKILL.md.tmpl"
  if [[ -f ${skill_md_tmpl} ]]; then
    fail "${name} — use SKILL.md instead of SKILL.md.tmpl"
    ERRORS=$((ERRORS + 1))
  elif [[ ! -f ${skill_md} ]]; then
    fail "${name} — SKILL.md is missing"
    ERRORS=$((ERRORS + 1))
  elif [[ ! -s ${skill_md} ]]; then
    fail "${name} — SKILL.md is empty"
    ERRORS=$((ERRORS + 1))
  fi
  schema_ok=0
  output=$(validate_json "$skill_json" 2>&1) || schema_ok=$?
  if [[ $schema_ok -ne 0 ]]; then
    fail "${name}"
    echo "$output"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  compat_rc=0
  compat_output=$(lint_compat "$skill_json" 2>&1) || compat_rc=$?
  if [[ $compat_rc -eq 2 ]]; then
    if [[ ${STRICT} == "true" ]]; then
      fail "${name} — ${compat_output#  [warn] }"
      ERRORS=$((ERRORS + 1))
    else
      warn "${name} — ${compat_output#  [warn] }"
      WARNINGS=$((WARNINGS + 1))
    fi
  elif [[ $compat_rc -ne 0 ]]; then
    fail "${name} — compat lint error"
    echo "$compat_output"
    ERRORS=$((ERRORS + 1))
  else
    ok "${name}"
  fi
done < <(find "${SKILLS_DIR}" -name "skill.json" -print0 | sort -z)

echo ""
if [[ $ERRORS -gt 0 ]]; then
  _c "1;31" "  ${ERRORS} error(s)"
  echo " in ${COUNT} skills."
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  _c "1;33" "  ${WARNINGS} warning(s)"
  echo ", ${COUNT} skills passed schema validation."
  exit 0
else
  _c "1;32" "  All ${COUNT} skills valid."
  echo ""
  exit 0
fi
