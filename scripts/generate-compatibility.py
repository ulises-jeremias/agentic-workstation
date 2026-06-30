#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
scripts/generate-compatibility.py
Generate docs/COMPATIBILITY.md from skill.json compatibility matrices.

Usage:
    python3 scripts/generate-compatibility.py [--check]

Options:
    --check   Exit non-zero if docs/COMPATIBILITY.md is out of date (for CI).
"""
from __future__ import annotations

import json
import pathlib
import sys


REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "home" / "dot_local" / "share" / "dots-ai" / "skills"
OUT_FILE = REPO_ROOT / "docs" / "COMPATIBILITY.md"

# Ordered list of tools (columns in the table)
TOOLS = ["universal", "claude-code", "opencode", "cursor", "windsurf", "copilot-cli", "pi"]
TOOL_LABELS = {
    "universal":  "Universal",
    "claude-code": "Claude Code",
    "opencode":   "OpenCode",
    "cursor":     "Cursor",
    "windsurf":   "Windsurf",
    "copilot-cli": "Copilot CLI",
    "pi":         "Pi",
}


def load_skills() -> list[dict]:
    skills = []
    for f in sorted(SKILLS_DIR.rglob("skill.json")):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
            d["_path"] = f
            skills.append(d)
        except Exception as e:
            print(f"  [warn] {f}: {e}", file=sys.stderr)
    return skills


def supported(compat: dict, tool: str) -> str:
    info = compat.get(tool, {})
    if isinstance(info, dict):
        return "✅" if info.get("supported") else "❌"
    return "—"


def generate(skills: list[dict]) -> str:
    header_cols = ["Skill", "Version"] + [TOOL_LABELS[t] for t in TOOLS]
    sep_cols = [":---", ":---:"] + [":---:" for _ in TOOLS]

    rows = []
    for s in skills:
        name = s.get("name", "?")
        version = s.get("version", "—")
        compat = s.get("compatibility", {})
        cols = [f"`{name}`", version] + [supported(compat, t) for t in TOOLS]
        rows.append("| " + " | ".join(cols) + " |")

    header_row = "| " + " | ".join(header_cols) + " |"
    sep_row = "| " + " | ".join(sep_cols) + " |"
    table = "\n".join([header_row, sep_row] + rows)

    return f"""\
# Tool Compatibility Matrix

> Auto-generated from `skill.json` compatibility fields. Run
> `python3 scripts/generate-compatibility.py` to regenerate after editing skill manifests.
>
> {len(skills)} skills indexed.

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Supported |
| ❌ | Not supported |
| — | Not declared |

## Matrix

{table}

## Tools

| Tool | Description |
|------|-------------|
| Universal | Included for every AI tool that supports markdown skills |
| Claude Code | Anthropic Claude Code CLI (`~/.claude/skills/`) |
| OpenCode | OpenCode (`~/.config/opencode/skills/`) |
| Cursor | Cursor IDE (`~/.cursor/skills/`) |
| Windsurf | Windsurf IDE (`~/.windsurf/skills/`) |
| Copilot CLI | GitHub Copilot CLI (`~/.copilot/skills/`) |
| Pi | Pi agent (`~/.pi/agent/skills/`) |
"""


def main() -> None:
    check_mode = "--check" in sys.argv
    skills = load_skills()
    if not skills:
        print("No skill.json files found — check SKILLS_DIR path.", file=sys.stderr)
        sys.exit(1)

    content = generate(skills)

    if check_mode:
        if OUT_FILE.exists() and OUT_FILE.read_text(encoding="utf-8") == content:
            print(f"  ✓ {OUT_FILE.relative_to(REPO_ROOT)} is up to date ({len(skills)} skills)")
            sys.exit(0)
        else:
            print(f"  ✗ {OUT_FILE.relative_to(REPO_ROOT)} is out of date.", file=sys.stderr)
            print("    Run: python3 scripts/generate-compatibility.py", file=sys.stderr)
            sys.exit(1)

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(content, encoding="utf-8")
    print(f"  ✓ Written {OUT_FILE.relative_to(REPO_ROOT)} ({len(skills)} skills)")


if __name__ == "__main__":
    main()
