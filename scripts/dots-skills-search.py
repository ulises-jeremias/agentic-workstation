#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
scripts/dots-skills-search.py
Skill discovery tool for dots-ai: search, explain, doctor, and index generation.

Commands:
    search <query>          Fuzzy search across name, description, triggers, capabilities
    explain <skill>         Show full skill detail: inputs, outputs, deps, compatibility
    doctor                  Warn on stale, conflicting, or broken skills
    generate-index          Write docs/SKILL_INDEX.md (for CI)
    check-index             Exit non-zero if SKILL_INDEX.md is stale (for CI)

Usage:
    python3 scripts/dots-skills-search.py search clickup
    python3 scripts/dots-skills-search.py explain dots-ai-assistant
    python3 scripts/dots-skills-search.py doctor
    python3 scripts/dots-skills-search.py generate-index
"""
from __future__ import annotations

import json
import pathlib
import re
import sys

try:
    import yaml  # type: ignore
    _YAML = True
except ImportError:
    _YAML = False

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "home" / "dot_local" / "share" / "dots-ai" / "skills"
CATALOG_PATH = SKILLS_DIR / "skill-catalog.yaml"
INDEX_PATH = REPO_ROOT / "docs" / "SKILL_INDEX.md"

TOOLS = ["universal", "claude-code", "opencode", "cursor", "windsurf", "copilot-cli", "pi"]

# ── data loading ──────────────────────────────────────────────────────────────

def load_catalog() -> list[dict]:
    if not CATALOG_PATH.exists():
        return []
    text = CATALOG_PATH.read_text(encoding="utf-8")
    if _YAML:
        data = yaml.safe_load(text) or {}
    else:
        data = {"skills": []}
    return data.get("skills", []) if isinstance(data, dict) else []


def load_skill_json(name: str) -> dict:
    f = SKILLS_DIR / name / "skill.json"
    if not f.exists():
        return {}
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def load_all_skills() -> list[dict]:
    """Load skill.json + catalog entry merged for every skill."""
    catalog = {e["name"]: e for e in load_catalog()}
    skills = []
    for d in sorted(SKILLS_DIR.iterdir()):
        if not d.is_dir():
            continue
        manifest = load_skill_json(d.name)
        if not manifest:
            continue
        entry = catalog.get(d.name, {})
        skills.append({**manifest, **{f"catalog_{k}": v for k, v in entry.items() if k != "name"}})
    return skills


# ── fuzzy search ──────────────────────────────────────────────────────────────

def _score(skill: dict, query: str) -> int:
    q = query.lower()
    score = 0
    name = skill.get("name", "").lower()
    desc = skill.get("description", "").lower()
    tags = " ".join(skill.get("tags", [])).lower()
    triggers = " ".join(skill.get("catalog_triggers", []) or []).lower()
    caps = " ".join(skill.get("catalog_capabilities", []) or []).lower()

    if q == name:
        score += 100
    elif name.startswith(q):
        score += 50
    elif q in name:
        score += 30
    if q in desc:
        score += 20
    if q in tags:
        score += 15
    if q in triggers:
        score += 10
    if q in caps:
        score += 5
    return score


def cmd_search(args: list[str]) -> int:
    if not args:
        print("Usage: dots-skills-search.py search <query>")
        return 1
    query = " ".join(args)
    skills = load_all_skills()
    if not skills:
        print("No skills found. Check SKILLS_DIR.")
        return 1

    scored = [(skill, _score(skill, query)) for skill in skills]
    scored = [(s, sc) for s, sc in scored if sc > 0]
    scored.sort(key=lambda x: -x[1])

    if not scored:
        print(f"\nNo skills match '{query}'.\n")
        return 0

    print(f"\nSearch results for '{query}' ({len(scored)} match(es)):\n")
    for skill, score in scored[:15]:
        name = skill.get("name", "?")
        desc = skill.get("description", "")[:80]
        compat = skill.get("compatibility", {})
        supported_tools = [t for t in TOOLS if compat.get(t, {}).get("supported")]
        tools_str = ", ".join(supported_tools) if supported_tools else "—"
        print(f"  {name}")
        print(f"    {desc}")
        print(f"    Tools: {tools_str}  (score={score})")
        print()
    return 0


# ── explain ───────────────────────────────────────────────────────────────────

def cmd_explain(args: list[str]) -> int:
    if not args:
        print("Usage: dots-skills-search.py explain <skill-name>")
        return 1
    name = args[0]
    catalog = {e["name"]: e for e in load_catalog()}
    manifest = load_skill_json(name)
    if not manifest:
        print(f"Skill '{name}' not found.")
        return 1
    entry = catalog.get(name, {})

    print(f"\n{'─' * 60}")
    print(f"  {manifest.get('name', name)}  v{manifest.get('version', '?')}")
    print(f"{'─' * 60}")
    print(f"\n  {manifest.get('description', '(no description)')}\n")

    # Compatibility
    print("  Compatibility:")
    compat = manifest.get("compatibility", {})
    for tool in TOOLS:
        info = compat.get(tool, {})
        icon = "✅" if info.get("supported") else "❌" if tool in compat else "—"
        notes = info.get("notes", "")
        print(f"    {icon} {tool:<15} {notes}")

    # Inputs (requires, pip_packages)
    requires = manifest.get("requires", [])
    pip_pkgs = manifest.get("pip_packages", [])
    deps = manifest.get("dependencies", [])
    if requires or pip_pkgs or deps:
        print("\n  Requires:")
        for r in requires:
            print(f"    CLI:  {r}")
        for p in pip_pkgs:
            print(f"    pip:  {p}")
        for d in deps:
            print(f"    skill: {d}")

    # Outputs / trigger points
    triggers = manifest.get("trigger_points", [])
    kt = manifest.get("knowledge_targets", [])
    if triggers or kt:
        print("\n  Trigger points / outputs:")
        for t in triggers:
            print(f"    event:  {t}")
        for k in kt:
            print(f"    writes: {k}")

    # Catalog entry
    if entry:
        domain = entry.get("domain", "")
        role = entry.get("role", "")
        responsibility = entry.get("responsibility", "")
        caps = entry.get("capabilities", [])
        depends_on = entry.get("depends_on", [])
        triggers_cat = entry.get("triggers", [])

        print(f"\n  Catalog: domain={domain}  role={role}  responsibility={responsibility}")
        if caps:
            print("  Capabilities:")
            for c in caps:
                print(f"    - {c}")
        if triggers_cat:
            print("  Triggers:")
            for t in triggers_cat:
                print(f"    - {t}")
        if depends_on:
            print(f"  Depends on: {', '.join(depends_on)}")
        hint = entry.get("usage_hints", "")
        if hint:
            print(f"  Usage hint: {hint}")

    print()
    return 0


# ── doctor ────────────────────────────────────────────────────────────────────

def cmd_doctor() -> int:
    skills = load_all_skills()
    catalog_names = {e["name"] for e in load_catalog()}
    issues = 0

    print("\nSkill Doctor\n─────────────\n")

    for skill in skills:
        name = skill.get("name", "?")
        warn_items = []

        # Missing source
        if not skill.get("source"):
            warn_items.append("missing 'source' field in skill.json")

        # Missing compat keys
        compat = skill.get("compatibility", {})
        if skill.get("source") == "bundled":
            missing = [t for t in TOOLS if t not in compat]
            if missing:
                warn_items.append(f"missing compat declarations: {', '.join(missing)}")

        # In catalog but skill.json missing
        if name in catalog_names and not (SKILLS_DIR / name / "skill.json").exists():
            warn_items.append("in catalog but skill.json is missing")

        # SKILL.md missing
        if not (SKILLS_DIR / name / "SKILL.md").exists():
            warn_items.append("SKILL.md missing")

        # Broken depends_on in catalog
        cat_deps = skill.get("catalog_depends_on", []) or []
        for dep in cat_deps:
            if isinstance(dep, str) and not (SKILLS_DIR / dep).exists():
                warn_items.append(f"depends_on '{dep}' not installed")

        if warn_items:
            print(f"  ⚠  {name}")
            for w in warn_items:
                print(f"     {w}")
            issues += 1
        else:
            print(f"  ✓  {name}")

    print()
    if issues:
        print(f"  {issues} skill(s) need attention.\n")
    else:
        print(f"  All {len(skills)} skills look healthy.\n")

    return 1 if issues else 0


# ── generate-index ────────────────────────────────────────────────────────────

def generate_index_content(skills: list[dict]) -> str:
    catalog = {e["name"]: e for e in load_catalog()}

    by_domain: dict[str, list[dict]] = {}
    for skill in skills:
        name = skill.get("name", "?")
        domain = catalog.get(name, {}).get("domain", "other")
        by_domain.setdefault(domain, []).append(skill)

    lines = [
        "# Skill Index",
        "",
        "> Auto-generated from `skill-catalog.yaml` and `skill.json` manifests.",
        "> Run `python3 scripts/dots-skills-search.py generate-index` to regenerate.",
        f">",
        f"> {len(skills)} skills indexed.",
        "",
    ]

    domain_order = ["orchestration", "workflow", "companion", "tool", "other"]
    for domain in domain_order + [d for d in by_domain if d not in domain_order]:
        domain_skills = by_domain.get(domain, [])
        if not domain_skills:
            continue
        title = domain.replace("-", " ").title()
        lines += [f"## {title}", ""]
        lines += ["| Skill | Description | Tools |", "|-------|-------------|-------|"]
        for skill in sorted(domain_skills, key=lambda s: s.get("name", "")):
            name = skill.get("name", "?")
            desc = skill.get("description", "")[:70]
            compat = skill.get("compatibility", {})
            supported = [t for t in TOOLS if compat.get(t, {}).get("supported")]
            tools = ", ".join(f"`{t}`" for t in supported) if supported else "—"
            lines.append(f"| `{name}` | {desc} | {tools} |")
        lines += [""]

    return "\n".join(lines)


def cmd_generate_index() -> int:
    skills = load_all_skills()
    if not skills:
        print("No skills found.", file=sys.stderr)
        return 1
    content = generate_index_content(skills)
    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    INDEX_PATH.write_text(content, encoding="utf-8")
    print(f"  ✓ Written {INDEX_PATH.relative_to(REPO_ROOT)} ({len(skills)} skills)")
    return 0


def cmd_check_index() -> int:
    skills = load_all_skills()
    if not skills:
        print("No skills found.", file=sys.stderr)
        return 1
    content = generate_index_content(skills)
    if INDEX_PATH.exists() and INDEX_PATH.read_text(encoding="utf-8") == content:
        print(f"  ✓ {INDEX_PATH.relative_to(REPO_ROOT)} is up to date ({len(skills)} skills)")
        return 0
    print(f"  ✗ {INDEX_PATH.relative_to(REPO_ROOT)} is stale.", file=sys.stderr)
    print("    Run: python3 scripts/dots-skills-search.py generate-index", file=sys.stderr)
    return 1


# ── main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    argv = sys.argv[1:]
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        sys.exit(0)

    cmd = argv[0]
    rest = argv[1:]

    match cmd:
        case "search":
            sys.exit(cmd_search(rest))
        case "explain":
            sys.exit(cmd_explain(rest))
        case "doctor":
            sys.exit(cmd_doctor())
        case "generate-index":
            sys.exit(cmd_generate_index())
        case "check-index":
            sys.exit(cmd_check_index())
        case _:
            print(f"Unknown command: {cmd}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
