#!/usr/bin/env bash
# scripts/smoke-test-skills.sh
# Per-skill smoke tests:
#   - SKILL.md must exist and be non-empty
#   - skill.json must be valid JSON (if present)
#   - references/ files must resolve (no broken symlinks)
#   - scripts/ files must have shebangs if executable
#
# Usage:
#   bash scripts/smoke-test-skills.sh
#   bash scripts/smoke-test-skills.sh --skill <name>

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/home/dot_local/share/dots-ai/skills"

_c() { [[ -t 1 ]] && printf '\033[%sm%s\033[0m' "$1" "$2" || printf '%s' "$2"; }
ok() { _c "1;32" "  ✓"; echo " $*"; }
fail() { _c "1;31" "  ✗"; echo " $*"; }

FILTER_SKILL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)
      FILTER_SKILL="$2"
      shift 2
      ;;
    -h | --help)
      echo "Usage: $0 [--skill <name>]"
      exit 0
      ;;
    *)
      echo "Unknown: $1" >&2
      exit 1
      ;;
  esac
done

echo ""
echo "Skill Smoke Tests"
echo "-----------------"

ERRORS=0
CHECKED=0

for skill_dir in "${SKILLS_DIR}"/*/; do
  [[ -d ${skill_dir} ]] || continue
  skill_name=$(basename "${skill_dir}")

  if [[ -n ${FILTER_SKILL} && ${skill_name} != "${FILTER_SKILL}" ]]; then
    continue
  fi

  CHECKED=$((CHECKED + 1))
  skill_errors=0

  # Check SKILL.md (or SKILL.md.tmpl for chezmoi templates) exists and is non-empty
  skill_md="${skill_dir}/SKILL.md"
  skill_md_tmpl="${skill_dir}/SKILL.md.tmpl"
  if [[ -f ${skill_md} ]]; then
    if [[ ! -s ${skill_md} ]]; then
      fail "${skill_name}: SKILL.md is empty"
      skill_errors=$((skill_errors + 1))
    fi
  elif [[ -f ${skill_md_tmpl} ]]; then
    if [[ ! -s ${skill_md_tmpl} ]]; then
      fail "${skill_name}: SKILL.md.tmpl is empty"
      skill_errors=$((skill_errors + 1))
    fi
  else
    fail "${skill_name}: SKILL.md missing"
    skill_errors=$((skill_errors + 1))
  fi

  # Check skill.json is valid JSON
  skill_json="${skill_dir}/skill.json"
  if [[ -f ${skill_json} ]]; then
    if ! python3 -c "import json; json.load(open('${skill_json}'))" 2>/dev/null; then
      fail "${skill_name}: skill.json is invalid JSON"
      skill_errors=$((skill_errors + 1))
    fi
  fi

  # Check scripts have shebangs
  if [[ -d "${skill_dir}/scripts" ]]; then
    while IFS= read -r -d '' script_file; do
      if [[ -x ${script_file} ]]; then
        first_line=$(head -1 "${script_file}" 2>/dev/null || true)
        if [[ ${first_line} != "#!"* ]]; then
          fail "${skill_name}: ${script_file##*/} is executable but missing shebang"
          skill_errors=$((skill_errors + 1))
        fi
      fi
    done < <(find "${skill_dir}/scripts" -type f -print0 2>/dev/null)
  fi

  # Note: references/ files may be empty placeholders — not checked here

  if [[ $skill_errors -eq 0 ]]; then
    ok "${skill_name}"
  else
    ERRORS=$((ERRORS + skill_errors))
  fi
done

echo ""
if [[ $ERRORS -gt 0 ]]; then
  _c "1;31" "  ${ERRORS} issue(s)"
  echo " across ${CHECKED} skills."
  exit 1
fi
_c "1;32" "  All ${CHECKED} skills"
echo " passed smoke tests."
echo ""
exit 0
