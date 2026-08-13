#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
scripts/generate-compatibility.py — thin workstation: delegates to agent-toolkit
Generate docs/COMPATIBILITY.md from skill.json compatibility matrices.
For thin workstations, the matrix is provided by agent-toolkit.

Usage:
    python3 scripts/generate-compatibility.py [--check]

Options:
    --check   Exit non-zero if docs/COMPATIBILITY.md is out of date (for CI).
"""
from __future__ import annotations

import json
import pathlib
import shutil
import subprocess
import sys


REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "home" / "dot_local" / "share" / "agentic-workstation" / "skills"
OUT_FILE = REPO_ROOT / "docs" / "COMPATIBILITY.md"

# Ordered list of tools (columns in the table)
TOOLS = ["universal", "claude-code", "muse-code", "opencode", "cursor", "windsurf", "copilot-cli", "pi"]
TOOL_LABELS = {
    "universal": "Universal",
    "claude-code": "Claude Code",
    "muse-code": "Muse Code",
    "opencode": "OpenCode",
    "cursor": "Cursor",
    "windsurf": "Windsurf",
    "copilot-cli": "Copilot CLI",
    "pi": "Pi",
}


def try_agent_toolkit_generate() -> str | None:
    """Try to delegate to agent-toolkit for compatibility generation."""
    if shutil.which("agent-toolkit") is None:
        return None
    # Try known subcommands — toolkit may expose compatibility via different paths
    for cmd in [
        ["agent-toolkit", "compatibility", "generate"],
        ["agent-toolkit", "skills", "compatibility"],
        ["agent-toolkit", "generate-compatibility"],
    ]:
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout
        except Exception:
            continue
    return None


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
    # Thin workstation: no embedded skills — generate delegated placeholder (deterministic — no shutil.which branching for CI stability)
    if not skills:
        toolkit_note = "\n> Thin workstation: skills are delegated to `agent-toolkit`. Bootstrap prefers Homebrew / AUR `agent-toolkit-bin` / GitHub Release V binaries, then `uv tool install --force 'agent-toolkit-cli>=1.11.0'` (V launcher). Then `agent-toolkit install`."
        return f"""# Tool Compatibility Matrix

> Thin workstation — compatibility is delegated to [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit).
> No embedded `skill.json` files are shipped in this repository.{toolkit_note}
>
> To regenerate from the toolkit catalog, ensure `agent-toolkit` is installed and run `agent-toolkit skills list`.

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Supported |
| ❌ | Not supported |
| — | Not declared |

## Matrix

| Skill | Version | Universal | Claude Code | Muse Code | OpenCode | Cursor | Windsurf | Copilot CLI | Pi |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| _delegated_ | — | — | — | — | — | — | — | — | — |

> This placeholder will be replaced by `agent-toolkit`'s catalog at install time (`agent-toolkit install`).

## Tools

| Tool | Description |
|------|-------------|
| Universal | Included for every AI tool that supports markdown skills |
| Claude Code | Anthropic Claude Code CLI (`~/.claude/skills/`) |
| Muse Code | Meta Muse Code (`~/.config/muse/skills/`) |
| OpenCode | OpenCode (`~/.config/opencode/skills/`) |
| Cursor | Cursor IDE (`~/.cursor/skills/`) |
| Windsurf | Windsurf IDE (`~/.windsurf/skills/`) |
| Copilot CLI | GitHub Copilot CLI (`~/.copilot/skills/`) |
| Pi | Pi agent (`~/.pi/agent/skills/`) |

---

## Swarm Troubleshooting

> **Workstation installs tools, Toolkit owns orchestration.** Troubleshoot provisioning vs orchestration separately.

| Symptom | Cause | Fix |
|---------|-------|-----|
| `herdr: command not found` | Herdr not installed (opt-in group disabled or CI skip) | Install via `brew install herdr` or `curl -fsSL https://herdr.dev/install.sh \\| sh` (see [SWARM_SETUP.md](SWARM_SETUP.md)) or use `--ui tmux` fallback: `agent-toolkit swarm start --recipe pair --ui tmux --runner opencode "Task"` |
| `tmux: command not found` | tmux missing (swarm group enabled) | Install: `sudo apt install tmux` (Debian/Ubuntu), `brew install tmux` (macOS), `sudo pacman -S tmux` (Arch), `sudo dnf install tmux` (Fedora) |
| `herdr integration outdated` or missing `opencode` | Herdr integration not installed or stale | `herdr integration install opencode` (idempotent); verify `herdr integration list --json` contains `opencode` |
| `~/.config/opencode` missing | OpenCode config dir absent | Script creates it via `mkdir -p ~/.config/opencode` safely; no credentials written |
| `herdr --version` works but `herdr integration list --json` fails | herdr binary not fully initialized | Re-run `herdr integration install opencode`, check `/tmp/herdr-integration-opencode.log` |
| CI: Herdr install skipped | `CI=true` without `SWARM_FORCE_INSTALL=1` | For tests, create a fake `herdr` in `PATH` or run with `SWARM_FORCE_INSTALL=1` |
| `agent-toolkit swarm doctor` reports issues | Toolkit-level orchestration prereq missing | Run `agent-toolkit swarm doctor` (owned by toolkit) to see recipe/UI/runner gaps; provision missing tools via `dots-doctor` → `chezmoi apply` |

**Doctor commands:**

```bash
dots-doctor                 # profile-aware: validates tmux, herdr, integration, and delegates to agent-toolkit swarm doctor when available
agent-toolkit swarm doctor  # toolkit-level swarm health check
herdr --version; tmux -V; herdr integration list --json | jq
```

Profiles `technical`, `non-technical`, `ai`, `data` include swarm by default; `custom` opt-in via questionnaire `Install Agent Toolkit Swarms (tmux + Herdr)?`. See [SWARM_SETUP.md](SWARM_SETUP.md) and [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md).

---

## Security Notes (Swarm)

- No credentials read or written by swarm provisioning.
- `curl | sh` for Herdr only after `brew`/`mise` fallback fails, logged to `/tmp/herdr-install.log`, no `sudo` required for Herdr.
- `tmux` install via system package manager respects `can_sudo`; no `~/.tmux.conf` overwrite.
- Isolated tmux socket (`agent-toolkit-swarm-<run-id>`) prevents interference with user sessions.

---

## See Also

- [SWARM_SETUP.md](SWARM_SETUP.md) — full swarm provisioning, doctor, and troubleshooting
- [ARCHITECTURE.md](ARCHITECTURE.md) — thin workstation architecture and swarm layer
- [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) — swarm orchestration owned by toolkit
- [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md) — platform support including swarm tooling
"""

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

    return f"""# Tool Compatibility Matrix

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
| Muse Code | Meta Muse Code (`~/.config/muse/skills/`) |
| OpenCode | OpenCode (`~/.config/opencode/skills/`) |
| Cursor | Cursor IDE (`~/.cursor/skills/`) |
| Windsurf | Windsurf IDE (`~/.windsurf/skills/`) |
| Copilot CLI | GitHub Copilot CLI (`~/.copilot/skills/`) |
| Pi | Pi agent (`~/.pi/agent/skills/`) |
"""


def main() -> None:
    check_mode = "--check" in sys.argv

    # Try delegation first for thin workstation
    delegated = try_agent_toolkit_generate()
    if delegated and not load_skills():
        # If toolkit provided content and we have no local skills, use it
        content = delegated
        if check_mode:
            if OUT_FILE.exists() and OUT_FILE.read_text(encoding="utf-8") == content:
                print(f"  ✓ {OUT_FILE.relative_to(REPO_ROOT)} is up to date (delegated to agent-toolkit)")
                sys.exit(0)
            else:
                print(f"  ✗ {OUT_FILE.relative_to(REPO_ROOT)} is out of date (delegated).", file=sys.stderr)
                print("    Run: python3 scripts/generate-compatibility.py", file=sys.stderr)
                sys.exit(1)
        OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
        OUT_FILE.write_text(content, encoding="utf-8")
        print(f"  ✓ Written {OUT_FILE.relative_to(REPO_ROOT)} (delegated to agent-toolkit)")
        return

    skills = load_skills()
    # For thin workstation, empty skills is valid — generate placeholder
    if not skills and not check_mode:
        content = generate([])
        OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
        OUT_FILE.write_text(content, encoding="utf-8")
        print(f"  ✓ Written {OUT_FILE.relative_to(REPO_ROOT)} (thin workstation — delegated to agent-toolkit)")
        return

    if not skills:
        # In --check mode with no skills, generate placeholder and compare
        content = generate([])
        if check_mode:
            if OUT_FILE.exists() and OUT_FILE.read_text(encoding="utf-8") == content:
                print(f"  ✓ {OUT_FILE.relative_to(REPO_ROOT)} is up to date (thin workstation)")
                sys.exit(0)
            else:
                print(f"  ✗ {OUT_FILE.relative_to(REPO_ROOT)} is out of date.", file=sys.stderr)
                print("    Run: python3 scripts/generate-compatibility.py", file=sys.stderr)
                sys.exit(1)
        OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
        OUT_FILE.write_text(content, encoding="utf-8")
        print(f"  ✓ Written {OUT_FILE.relative_to(REPO_ROOT)} (thin workstation)")
        return

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
