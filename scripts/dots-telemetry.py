#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
scripts/dots-telemetry.py
Local-only telemetry aggregator for agentic-workstation. Reads from
~/.local/state/agentic-workstation/telemetry/*.jsonl and produces usage summaries.

Commands:
    summary [--days N]    Usage summary (default: last 7 days)
    top [--n N]           Top N skills by invocation count
    drift                 Skills in registry but not deployed (or vice versa)
    enable                Create telemetry directory and show opt-in instructions
    disable               Remove telemetry directory and disable collection
"""
from __future__ import annotations

import json
import pathlib
import sys
from datetime import datetime, timezone, timedelta

STATE_DIR = pathlib.Path.home() / ".local" / "state" / "agentic-workstation" / "telemetry"
SHARE_DIR = pathlib.Path.home() / ".local" / "share" / "agentic-workstation"


def _events(days: int = 7) -> list[dict]:
    if not STATE_DIR.is_dir():
        return []
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    events = []
    for f in sorted(STATE_DIR.glob("*.jsonl")):
        for line in f.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
                ts_str = ev.get("ts", "")
                ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                if ts >= cutoff:
                    events.append(ev)
            except (json.JSONDecodeError, ValueError):
                pass
    return events


def cmd_summary(args: list[str]) -> None:
    days = 7
    if "--days" in args:
        idx = args.index("--days")
        if idx + 1 < len(args):
            days = int(args[idx + 1])

    events = _events(days)
    if not events:
        if STATE_DIR.is_dir():
            print(f"  No telemetry events in the last {days} days.")
            print("  Telemetry is enabled but no events recorded yet.")
        else:
            print("  Telemetry is disabled (directory not found).")
            print("  Run: python3 scripts/dots-telemetry.py enable")
        return

    by_event: dict[str, int] = {}
    by_skill: dict[str, int] = {}
    by_tool: dict[str, int] = {}
    failures = 0

    for ev in events:
        etype = ev.get("event", "unknown")
        by_event[etype] = by_event.get(etype, 0) + 1
        skill = ev.get("skill", "")
        if skill:
            by_skill[skill] = by_skill.get(skill, 0) + 1
        tool = ev.get("tool", "")
        if tool:
            by_tool[tool] = by_tool.get(tool, 0) + 1
        if "fail" in etype or ev.get("status") == "failure":
            failures += 1

    print(f"\n  Telemetry Summary (last {days} days)")
    print(f"  ─────────────────────────────────────")
    print(f"  Total events: {len(events)}")
    print(f"  Failures:     {failures}")
    print(f"\n  By event type:")
    for k, v in sorted(by_event.items(), key=lambda x: -x[1])[:5]:
        print(f"    {k:<30} {v}")
    if by_skill:
        print(f"\n  Top skills:")
        for k, v in sorted(by_skill.items(), key=lambda x: -x[1])[:10]:
            print(f"    {k:<40} {v}")
    if by_tool:
        print(f"\n  By tool:")
        for k, v in sorted(by_tool.items(), key=lambda x: -x[1]):
            print(f"    {k:<20} {v}")
    print()


def cmd_drift() -> None:
    registry_file = SHARE_DIR / "skills-registry.yaml"
    skills_dir = SHARE_DIR / "skills"

    if not registry_file.exists():
        print("  Registry not found at ~/.local/share/agentic-workstation/skills-registry.yaml")
        return

    # Parse registry names (simple line-based)
    registry_names: set[str] = set()
    for line in registry_file.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("- name:"):
            registry_names.add(stripped.split(":", 1)[1].strip())

    # Deployed skills
    deployed: set[str] = set()
    if skills_dir.is_dir():
        for d in skills_dir.iterdir():
            if d.is_dir() and (d / "SKILL.md").exists() or (d / "skill.json").exists():
                deployed.add(d.name)

    in_registry_not_deployed = registry_names - deployed
    deployed_not_in_registry = deployed - registry_names

    print("\n  Skill Drift Report")
    print("  ─────────────────────")
    if in_registry_not_deployed:
        print(f"\n  In registry but NOT deployed ({len(in_registry_not_deployed)}):")
        for n in sorted(in_registry_not_deployed):
            print(f"    - {n}")
    else:
        print("\n  ✓ All registry skills are deployed")

    if deployed_not_in_registry:
        print(f"\n  Deployed but NOT in registry ({len(deployed_not_in_registry)}):")
        for n in sorted(deployed_not_in_registry):
            print(f"    - {n}")
    else:
        print("  ✓ All deployed skills are in registry")
    print()


def cmd_enable() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    print(f"\n  Telemetry directory created: {STATE_DIR}")
    print("\n  To record events, your skill runner or dots-skills must write")
    print("  JSONL lines to that directory.")
    print("\n  Format:")
    print('  {"ts": "2026-06-30T08:00:00Z", "event": "skill.invoked", "skill": "x", "tool": "claude-code"}')
    print("\n  Privacy: all data stays local. Nothing is sent to any server.\n")


def cmd_disable() -> None:
    import shutil
    if STATE_DIR.is_dir():
        shutil.rmtree(STATE_DIR)
        print(f"  Telemetry data removed: {STATE_DIR}")
    else:
        print("  Telemetry is already disabled (directory not found).")
    print()


def main() -> None:
    argv = sys.argv[1:]
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        sys.exit(0)

    cmd = argv[0]
    rest = argv[1:]

    match cmd:
        case "summary":
            cmd_summary(rest)
        case "top":
            cmd_summary(rest)  # Same output for now
        case "drift":
            cmd_drift()
        case "enable":
            cmd_enable()
        case "disable":
            cmd_disable()
        case _:
            print(f"Unknown command: {cmd}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
