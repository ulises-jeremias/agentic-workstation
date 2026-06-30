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
    install <skill>       Print install order for a skill and all its dependencies

Usage:
    python3 scripts/skill-graph.py deps dots-ai-assistant
    python3 scripts/skill-graph.py check-cycles
    python3 scripts/skill-graph.py install dots-ai-workflow-generic-project
"""
from __future__ import annotations

import json
import pathlib
import sys
from typing import Iterator

try:
    import yaml  # type: ignore
    _YAML = True
except ImportError:
    _YAML = False

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG_PATH = REPO_ROOT / "home" / "dot_local" / "share" / "dots-ai" / "skills" / "skill-catalog.yaml"

# ── helpers ───────────────────────────────────────────────────────────────────

def load_catalog() -> dict[str, list[str]]:
    """Return {skill_name: [dep_name, ...]} from skill-catalog.yaml."""
    if not CATALOG_PATH.exists():
        print(f"Catalog not found: {CATALOG_PATH}", file=sys.stderr)
        sys.exit(1)

    text = CATALOG_PATH.read_text(encoding="utf-8")
    if _YAML:
        data = yaml.safe_load(text)
    else:
        print("[warn] PyYAML not installed; falling back to basic parser", file=sys.stderr)
        data = _parse_catalog_basic(text)

    if not isinstance(data, dict) or "skills" not in data:
        print("Unexpected catalog format — expected {version, skills: [...]}", file=sys.stderr)
        sys.exit(1)

    graph: dict[str, list[str]] = {}
    for entry in data["skills"]:
        name = entry.get("name", "")
        deps = entry.get("depends_on", []) or []
        if isinstance(deps, list):
            graph[name] = [d if isinstance(d, str) else d.get("name", "") for d in deps]
        else:
            graph[name] = []

    return graph


def _parse_catalog_basic(text: str) -> dict:
    """Very basic YAML reader for the catalog without PyYAML."""
    import re
    skills = []
    current: dict | None = None
    in_deps = False

    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("- name:") and not line.startswith("    "):
            current = {"name": stripped.split(":", 1)[1].strip(), "depends_on": []}
            skills.append(current)
            in_deps = False
        elif stripped == "depends_on: []" and current:
            in_deps = False
        elif stripped == "depends_on:" and current:
            in_deps = True
        elif in_deps and stripped.startswith("- ") and current:
            current["depends_on"].append(stripped[2:].strip())
        elif not stripped.startswith("-") and ":" in stripped:
            in_deps = False

    return {"version": 1, "skills": skills}


def transitive_deps(graph: dict[str, list[str]], name: str) -> list[str]:
    """Return topologically sorted list of all transitive deps (deepest-first)."""
    visited: set[str] = set()
    order: list[str] = []

    def visit(n: str, path: tuple[str, ...] = ()) -> None:
        if n in path:
            raise ValueError(f"Cycle detected: {' → '.join(path + (n,))}")
        if n in visited:
            return
        for dep in graph.get(n, []):
            visit(dep, path + (n,))
        visited.add(n)
        order.append(n)

    visit(name)
    return [x for x in order if x != name]


def detect_cycles(graph: dict[str, list[str]]) -> list[list[str]]:
    """Return list of cycle paths found (empty list = no cycles)."""
    cycles: list[list[str]] = []
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {n: WHITE for n in graph}
    path_stack: list[str] = []

    def dfs(n: str) -> None:
        color[n] = GRAY
        path_stack.append(n)
        for dep in graph.get(n, []):
            if dep not in color:
                color[dep] = WHITE
            if color[dep] == GRAY:
                idx = path_stack.index(dep)
                cycles.append(path_stack[idx:] + [dep])
            elif color[dep] == WHITE:
                dfs(dep)
        path_stack.pop()
        color[n] = BLACK

    for node in graph:
        if color[node] == WHITE:
            dfs(node)

    return cycles


def print_tree(
    graph: dict[str, list[str]],
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
        if dep in seen:
            print(f"{prefix}{connector}{dep} (already shown)")
            continue
        print(f"{prefix}{connector}{dep}")
        seen.add(dep)
        print_tree(graph, dep, prefix + extension, seen)


# ── commands ──────────────────────────────────────────────────────────────────

def cmd_deps(graph: dict[str, list[str]], args: list[str]) -> None:
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


def cmd_rdeps(graph: dict[str, list[str]], args: list[str]) -> None:
    if not args:
        print("Usage: skill-graph.py rdeps <skill>")
        sys.exit(1)
    target = args[0]
    rdeps = [n for n, deps in graph.items() if target in deps]
    if not rdeps:
        print(f"No skills depend on '{target}'.")
    else:
        print(f"\nSkills that depend on '{target}':")
        for n in sorted(rdeps):
            print(f"  - {n}")


def cmd_check_cycles(graph: dict[str, list[str]]) -> None:
    cycles = detect_cycles(graph)
    if cycles:
        print(f"\n✗ {len(cycles)} cycle(s) found:", file=sys.stderr)
        for cycle in cycles:
            print(f"  {' → '.join(cycle)}", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"\n✓ No cycles detected. Graph has {len(graph)} skills.")


def cmd_install(graph: dict[str, list[str]], args: list[str]) -> None:
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


def cmd_list(graph: dict[str, list[str]]) -> None:
    print(f"\n{len(graph)} skills in catalog:\n")
    for name in sorted(graph):
        deps = graph[name]
        dep_str = f"  ← depends on: {', '.join(deps)}" if deps else ""
        print(f"  {name}{dep_str}")


# ── main ──────────────────────────────────────────────────────────────────────

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
