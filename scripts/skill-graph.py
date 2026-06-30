#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
scripts/skill-graph.py — Skill dependency graph tool for dots-ai.

Commands:
    deps <skill>          Show transitive dependencies of a skill (tree)
    rdeps <skill>         Show skills that depend on a skill (reverse)
    check-cycles          Detect cycles in the dependency graph (exit 1 if found)
    check-versions        Validate semver constraints against registry
    install <skill>       Print install order for a skill and all its dependencies

Usage:
    python3 scripts/skill-graph.py deps dots-ai-assistant
    python3 scripts/skill-graph.py check-cycles
    python3 scripts/skill-graph.py check-versions
    python3 scripts/skill-graph.py install dots-ai-workflow-generic-project
"""
from __future__ import annotations

import json
import pathlib
import re
import sys
from typing import Any, Iterator

try:
    import yaml  # type: ignore
    _YAML = True
except ImportError:
    _YAML = False

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG_PATH = REPO_ROOT / "home" / "dot_local" / "share" / "dots-ai" / "skills" / "skill-catalog.yaml"
REGISTRY_PATH = REPO_ROOT / "home" / "dot_local" / "share" / "dots-ai" / "skills-registry.yaml"

# ── semver helpers ───────────────────────────────────────────────────────────

def _parse_version(v: str) -> tuple[int, int, int]:
    parts = v.strip().split(".")
    return (int(parts[0]), int(parts[1]), int(parts[2]))


def _satisfies(installed: str, constraint: str) -> bool:
    """Check if installed version satisfies a semver constraint.

    Supports: >=X.Y.Z, ~X.Y.Z (patch-level compatibility),
    ^X.Y.Z (major-level compatibility), and bare X.Y.Z (exact match).
    """
    iv = _parse_version(installed)
    cv = _parse_version(constraint.lstrip("~^>="))

    if constraint.startswith(">="):
        return iv >= cv
    elif constraint.startswith("~"):
        # ~1.2.3 means >=1.2.3 and <1.3.0
        return cv <= iv < (cv[0], cv[1] + 1, 0)
    elif constraint.startswith("^"):
        # ^1.2.3 means >=1.2.3 and <2.0.0
        return cv <= iv < (cv[0] + 1, 0, 0)
    else:
        return iv == cv


# ── catalog helpers ──────────────────────────────────────────────────────────

def _load_yaml(path: pathlib.Path) -> dict[str, Any]:
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)
    text = path.read_text(encoding="utf-8")
    if _YAML:
        return yaml.safe_load(text)
    else:
        print("[warn] PyYAML not installed", file=sys.stderr)
        return {}


def load_catalog() -> dict[str, list[dict | str]]:
    """Return {skill_name: [dep_name_or_object, ...]} from skill-catalog.yaml."""
    data = _load_yaml(CATALOG_PATH)
    if not isinstance(data, dict) or "skills" not in data:
        print("Unexpected catalog format — expected {version, skills: [...]}", file=sys.stderr)
        sys.exit(1)

    graph: dict[str, list[dict | str]] = {}
    for entry in data["skills"]:
        name = entry.get("name", "")
        deps = entry.get("depends_on", []) or []
        graph[name] = list(deps)

    return graph


def load_registry() -> dict[str, dict[str, Any]]:
    """Return {skill_name: {version, depends_on, ...}} from skills-registry.yaml."""
    data = _load_yaml(REGISTRY_PATH)
    registry: dict[str, dict[str, Any]] = {}
    for entry in data.get("skills", []):
        name = entry.get("name", "")
        if name:
            registry[name] = entry
    return registry


def _dep_name(dep: dict | str) -> str:
    return dep if isinstance(dep, str) else dep.get("name", "")


def _dep_version(dep: dict | str) -> str | None:
    return None if isinstance(dep, str) else dep.get("version")


# ── graph algorithms ────────────────────────────────────────────────────────

def transitive_deps(graph: dict[str, list[dict | str]], name: str) -> list[str]:
    """Return topologically sorted list of all transitive deps (deepest-first)."""
    visited: set[str] = set()
    order: list[str] = []

    def visit(n: str, path: tuple[str, ...] = ()) -> None:
        if n in path:
            raise ValueError(f"Cycle detected: {' → '.join(path + (n,))}")
        if n in visited:
            return
        for dep in graph.get(n, []):
            visit(_dep_name(dep), path + (n,))
        visited.add(n)
        order.append(n)

    visit(name)
    return [x for x in order if x != name]


def detect_cycles(graph: dict[str, list[dict | str]]) -> list[list[str]]:
    """Return list of cycle paths found (empty list = no cycles)."""
    cycles: list[list[str]] = []
    WHITE, GRAY, BLACK = 0, 1, 2

    names = list(graph.keys())

    for entry in graph.values():
        for dep in entry:
            dn = _dep_name(dep)
            if dn not in names:
                names.append(dn)

    color: dict[str, int] = {n: WHITE for n in names}
    path_stack: list[str] = []

    def dfs(n: str) -> None:
        color[n] = GRAY
        path_stack.append(n)
        for dep in graph.get(n, []):
            dn = _dep_name(dep)
            if dn not in color:
                color[dn] = WHITE
            if color[dn] == GRAY:
                idx = path_stack.index(dn)
                cycles.append(path_stack[idx:] + [dn])
            elif color[dn] == WHITE:
                dfs(dn)
        path_stack.pop()
        color[n] = BLACK

    for node in names:
        if color.get(node, WHITE) == WHITE:
            dfs(node)

    return cycles


def print_tree(
    graph: dict[str, list[dict | str]],
    name: str,
    prefix: str = "",
    seen: set[str] | None = None,
) -> None:
    if seen is None:
        seen = set()
    deps = graph.get(name, [])
    for i, dep in enumerate(deps):
        last = i == len(deps) - 1
        connector = "└── " if last else "├── "
        extension = "    " if last else "│   "
        label = _dep_name(dep)
        ver = _dep_version(dep)
        label = f"{label} ({ver})" if ver else label
        if label in seen:
            print(f"{prefix}{connector}{label} (already shown)")
            continue
        print(f"{prefix}{connector}{label}")
        seen.add(label)
        print_tree(graph, label, prefix + extension, seen)


# ── commands ─────────────────────────────────────────────────────────────────

def cmd_deps(graph: dict[str, list[dict | str]], args: list[str]) -> None:
    if not args:
        print("Usage: skill-graph.py deps <skill>")
        sys.exit(1)
    name = args[0]
    if name not in graph:
        print(f"Skill '{name}' not found in catalog.", file=sys.stderr)
        sys.exit(1)
    print(f"\n{name}")
    print_tree(graph, name)
    try:
        deps = transitive_deps(graph, name)
        print(f"\nTotal transitive deps: {len(deps)}")
        if deps:
            print(f"Install order: {' → '.join(deps)} → {name}")
    except ValueError as e:
        print(f"\n⚠ {e}", file=sys.stderr)


def cmd_rdeps(graph: dict[str, list[dict | str]], args: list[str]) -> None:
    if not args:
        print("Usage: skill-graph.py rdeps <skill>")
        sys.exit(1)
    target = args[0]
    rdeps = [n for n, deps in graph.items() if target in [_dep_name(d) for d in deps]]
    if not rdeps:
        print(f"No skills depend on '{target}'.")
    else:
        print(f"\nSkills that depend on '{target}':")
        for n in sorted(rdeps):
            print(f"  - {n}")


def cmd_check_cycles(graph: dict[str, list[dict | str]]) -> None:
    cycles = detect_cycles(graph)
    if cycles:
        print(f"\n✗ {len(cycles)} cycle(s) found:", file=sys.stderr)
        for cycle in cycles:
            print(f"  {' → '.join(cycle)}", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"\n✓ No cycles detected. Graph has {len(graph)} skills.")


def cmd_check_versions(graph: dict[str, list[dict | str]]) -> None:
    """Validate all version constraints against the registry."""
    registry = load_registry()
    violations = 0
    checked = 0

    for skill_name, deps in sorted(graph.items()):
        for dep in deps:
            constraint = _dep_version(dep)
            if not constraint:
                continue
            checked += 1
            dep_name = _dep_name(dep)
            reg_entry = registry.get(dep_name)
            if not reg_entry:
                print(f"  ⚠ {skill_name} → {dep_name}: not in registry (skipped)")
                continue
            installed = reg_entry.get("version", "")
            if not installed:
                print(f"  ⚠ {skill_name} → {dep_name}: no version in registry (skipped)")
                continue
            if not _satisfies(installed, constraint):
                print(f"  ✗ {skill_name} requires {dep_name} {constraint}, registry has {installed}")
                violations += 1
            else:
                print(f"  ✓ {skill_name} → {dep_name} {constraint} (installed: {installed})")

    print(f"\nChecked {checked} version constraint(s).")
    if violations:
        print(f"✗ {violations} violation(s) found.", file=sys.stderr)
        sys.exit(1)
    else:
        print("✓ All constraints satisfied.")


def cmd_install(graph: dict[str, list[dict | str]], args: list[str]) -> None:
    if not args:
        print("Usage: skill-graph.py install <skill>")
        sys.exit(1)
    name = args[0]
    if name not in graph:
        print(f"Skill '{name}' not found in catalog.", file=sys.stderr)
        sys.exit(1)
    try:
        deps = transitive_deps(graph, name)
    except ValueError as e:
        print(f"✗ Cannot compute install order: {e}", file=sys.stderr)
        sys.exit(1)

    all_skills = deps + [name]
    print(f"\nInstall order for '{name}' ({len(all_skills)} skills):")
    for i, s in enumerate(all_skills, 1):
        marker = "← target" if s == name else ""
        print(f"  {i:2}. {s} {marker}")


def cmd_list(graph: dict[str, list[dict | str]]) -> None:
    print(f"\n{len(graph)} skills in catalog:\n")
    for name in sorted(graph):
        deps = graph[name]
        dep_strs = []
        for d in deps:
            dn = _dep_name(d)
            dv = _dep_version(d)
            dep_strs.append(f"{dn} ({dv})" if dv else dn)
        dep_str = f"  ← depends on: {', '.join(dep_strs)}" if dep_strs else ""
        print(f"  {name}{dep_str}")


# ── main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    argv = sys.argv[1:]
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        sys.exit(0)

    graph = load_catalog()
    command = argv[0]
    rest = argv[1:]

    match command:
        case "deps":
            cmd_deps(graph, rest)
        case "rdeps":
            cmd_rdeps(graph, rest)
        case "check-cycles":
            cmd_check_cycles(graph)
        case "check-versions":
            cmd_check_versions(graph)
        case "install":
            cmd_install(graph, rest)
        case "list":
            cmd_list(graph)
        case _:
            print(f"Unknown command: {command}", file=sys.stderr)
            print("Run 'skill-graph.py --help' for usage.", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
