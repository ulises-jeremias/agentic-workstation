#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [PyYAML]
# ///
"""
scripts/check-skill-drift.py — Compare registry versions against deployed skill.json.

Detects version drift between skills-registry.yaml and installed skill.json manifests.
Reports mismatches and exits 1 if any found.

Usage:
    python3 scripts/check-skill-drift.py [--json]

Options:
    --json  Emit JSON output for machine parsing
"""
from __future__ import annotations

import json
import pathlib
import sys

try:
    import yaml
except ImportError:
    print("[check-skill-drift] PyYAML required. Install: pip install PyYAML", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
DEPLOYED_SKILLS_DIR = pathlib.Path.home() / ".local" / "share" / "agentic-workstation" / "skills"
REGISTRY_PATH = REPO_ROOT / "home" / "dot_local" / "share" / "agentic-workstation" / "skills-registry.yaml"


def load_registry() -> dict[str, dict]:
    data = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    registry: dict[str, dict] = {}
    for entry in data.get("skills", []):
        name = entry.get("name", "")
        if name:
            registry[name] = entry
    return registry


def load_deployed_versions() -> dict[str, str]:
    versions: dict[str, str] = {}
    if not DEPLOYED_SKILLS_DIR.is_dir():
        # In CI, check from repo instead
        alt = REPO_ROOT / "home" / "dot_local" / "share" / "agentic-workstation" / "skills"
        if alt.is_dir():
            for d in alt.iterdir():
                manifest = d / "skill.json"
                if manifest.exists():
                    data = json.loads(manifest.read_text(encoding="utf-8"))
                    versions[data["name"]] = data.get("version", "0.0.0")
    else:
        for d in DEPLOYED_SKILLS_DIR.iterdir():
            manifest = d / "skill.json"
            if manifest.exists():
                data = json.loads(manifest.read_text(encoding="utf-8"))
                versions[data["name"]] = data.get("version", "0.0.0")
    return versions


def main() -> None:
    use_json = "--json" in sys.argv

    registry = load_registry()
    deployed = load_deployed_versions()

    drift = []
    unmapped = []
    missing = []

    for name, reg_entry in registry.items():
        reg_version = reg_entry.get("version", "")
        dep_version = deployed.get(name)

        if dep_version is None:
            missing.append(name)
            continue

        if reg_version and dep_version != reg_version:
            drift.append({
                "skill": name,
                "registry_version": reg_version,
                "deployed_version": dep_version,
            })

    # Deployed skills not in registry
    for name in deployed:
        if name not in registry:
            unmapped.append(name)

    if use_json:
        print(json.dumps({
            "drift": drift,
            "unmapped": unmapped,
            "missing_from_deployed": missing,
            "drift_count": len(drift),
            "unmapped_count": len(unmapped),
            "missing_count": len(missing),
        }, indent=2))
    else:
        print("\n=== Skill Version Drift Report ===\n")

        if drift:
            print(f"✗ {len(drift)} skill(s) with version drift:\n")
            for d in drift:
                print(f"  {d['skill']}: registry={d['registry_version']} vs deployed={d['deployed_version']}")
            print()
        else:
            print("✓ No version drift detected.\n")

        if missing:
            print(f"⚠ {len(missing)} skill(s) in registry but not deployed:\n")
            for name in missing:
                print(f"  {name}")
            print()

        if unmapped:
            print(f"ℹ {len(unmapped)} deployed skill(s) not in registry:\n")
            for name in unmapped:
                print(f"  {name}")
            print()

        print(f"Summary: {len(registry)} in registry, {len(deployed)} deployed, "
              f"{len(drift)} drifted, {len(missing)} missing, {len(unmapped)} unmapped.\n")

    if drift:
        sys.exit(1)


if __name__ == "__main__":
    main()
