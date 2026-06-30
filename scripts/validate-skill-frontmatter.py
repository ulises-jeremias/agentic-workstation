#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["jsonschema", "PyYAML"]
# ///
"""
scripts/validate-skill-frontmatter.py
Validate the YAML frontmatter of all bundled SKILL.md files against
lib/schemas/skill-md-frontmatter.schema.json.

Usage:
    python3 scripts/validate-skill-frontmatter.py
    python3 scripts/validate-skill-frontmatter.py --skill dots-ai-assistant
"""
from __future__ import annotations

import json
import pathlib
import sys

try:
    import yaml  # type: ignore
    _YAML = True
except ImportError:
    _YAML = False

try:
    import jsonschema  # type: ignore
    _SCHEMA = True
except ImportError:
    _SCHEMA = False

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "home" / "dot_local" / "share" / "dots-ai" / "skills"
SCHEMA_PATH = REPO_ROOT / "lib" / "schemas" / "skill-md-frontmatter.schema.json"


def extract_frontmatter(text: str) -> dict | None:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    end = next((i for i, l in enumerate(lines[1:], 1) if l.strip() == "---"), None)
    if end is None:
        return None
    fm_text = "\n".join(lines[1:end])
    if _YAML:
        return yaml.safe_load(fm_text) or {}
    return None


def main() -> int:
    filter_skill = ""
    if "--skill" in sys.argv:
        idx = sys.argv.index("--skill")
        if idx + 1 < len(sys.argv):
            filter_skill = sys.argv[idx + 1]

    if not _SCHEMA:
        print("[skip] jsonschema not installed — run: pip install jsonschema")
        return 0
    if not _YAML:
        print("[skip] PyYAML not installed — run: pip install PyYAML")
        return 0

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    validator = jsonschema.Draft202012Validator(schema)

    errors = 0
    checked = 0

    print("\nSKILL.md Frontmatter Validation")
    print("--------------------------------\n")

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        name = skill_dir.name
        if filter_skill and name != filter_skill:
            continue

        # Handle both SKILL.md and SKILL.md.tmpl
        skill_md = skill_dir / "SKILL.md"
        skill_md_tmpl = skill_dir / "SKILL.md.tmpl"
        target = skill_md if skill_md.exists() else skill_md_tmpl if skill_md_tmpl.exists() else None
        if target is None:
            print(f"  [skip] {name}: no SKILL.md")
            continue

        text = target.read_text(encoding="utf-8")
        fm = extract_frontmatter(text)
        if fm is None:
            print(f"  ⚠  {name}: no frontmatter (optional, not an error)")
            continue

        checked += 1
        errs = sorted(validator.iter_errors(fm), key=lambda e: list(e.path))
        if errs:
            print(f"  ✗  {name}:")
            for e in errs:
                path = " → ".join(str(p) for p in e.path) or "(root)"
                print(f"       [{path}] {e.message}")
            errors += len(errs)
        else:
            print(f"  ✓  {name}")

    print(f"\n  {checked} skills with frontmatter validated.")
    if errors:
        print(f"  {errors} violation(s) found.\n")
        return 1
    print("  All valid.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
