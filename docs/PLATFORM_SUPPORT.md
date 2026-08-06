# Platform Support

> Supported platforms, shells, and install paths for agentic-workstation.

---

## Supported Platforms

| Platform | Shell | Install path | Status |
|----------|-------|-------------|--------|
| **Linux** | `bash` (≥4.0), `sh` | `~/.local/bin/`, `~/.local/share/agentic-workstation/` | ✅ Full support |
| **macOS** | `bash` (via Homebrew, ≥4.0), `zsh`, `sh` | Same as Linux | ✅ Full support |
| **Windows (WSL2)** | `bash` in Ubuntu subsystem | Same as Linux | ✅ Supported |
| **Windows (Git Bash)** | `bash` in Git for Windows | Same as Linux | ✅ Supported (`install-skills.sh`) |
| **Windows (PowerShell)** | PowerShell 5.1+ or Core | `~\AppData\Local\agentic-workstation\` | ✅ `install-skills.ps1` |

> **macOS built-in bash (3.2)**: agentic-workstation requires bash 4.0+ (for associative arrays in `dots-skills`).
> Install a newer bash: `brew install bash`.

---

## Install Scripts

### `install-skills.sh` (Linux, macOS, WSL2, Git Bash)

```bash
# Download and run (latest release)
curl -fsSL https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.sh | sh

# Flags
--tool <claude|opencode|cursor|windsurf|copilot|muse|all>   Install for a specific AI tool (default: all)
--guided                                                Interactive prompts for tool selection
--dry-run                                               Preview install plan, no changes
```

### `install-skills.ps1` (Windows PowerShell)

```powershell
# Download and run (latest release)
irm https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.ps1 | iex

# Parameters
-Tool <claude|opencode|cursor|windsurf|copilot|muse|all>    Install for a specific AI tool (default: all)
-Guided                                                 Interactive prompts for tool selection
-DryRun                                                 Preview install plan, no changes
```

---

## Swarm Tooling — tmux + Herdr (Agent Toolkit Swarms)

> **Workstation installs tools, Toolkit owns orchestration.** See [SWARM_SETUP.md](SWARM_SETUP.md).

| Component | Purpose | Install method | Verify | Platform notes |
|-----------|---------|----------------|--------|----------------|
| **tmux** | Terminal multiplexer for swarm panes | `apt` / `brew` / `pacman` / `dnf` (via `run_onchange_42-install-swarm-tooling.sh.tmpl`, gated by `install_group_swarm`) | `tmux -V` | Respects `can_sudo`; uses isolated socket `agent-toolkit-swarm-<run-id>`; no `~/.tmux.conf` overwrite |
| **Herdr** | Orchestration UI for Agent Toolkit Swarms | `brew` → `mise` → `curl -fsSL https://herdr.dev/install.sh \| sh` fallback | `herdr --version` | No sudo; logged to `/tmp/herdr-install.log`; skipped in CI unless `SWARM_FORCE_INSTALL=1` |
| **OpenCode Herdr integration** | Connects `opencode` runner to Herdr | `herdr integration install opencode` (idempotent) | `herdr integration list --json` | Creates `~/.config/opencode` if missing; safe, no credentials; re-run if `outdated` |

**Profile gating:** `technical`, `non-technical`, `ai`, `data` profiles enable swarm (`install_group_swarm=true`) in `home/.chezmoidata/profiles.yaml`; `custom` prompts `Install Agent Toolkit Swarms (tmux + Herdr)?` in `home/.chezmoi.toml.tmpl`. Non-interactive: `WORKSTATION_PROFILE=technical chezmoi init --apply ...` or `WORKSTATION_PROFILE=custom chezmoi init --apply ... --promptString install_group_swarm=yes`.

**Doctor & usage:**

```bash
dots-doctor                 # includes tmux/herdr/swarm checks
agent-toolkit swarm doctor  # toolkit-level check
herdr integration install opencode
agent-toolkit swarm start --recipe pair --ui herdr --runner opencode "Task"
agent-toolkit swarm start --recipe pair --ui tmux --runner opencode "Task"
```

Toolkit owns all orchestration (`agent-toolkit swarm --help`); Workstation only ensures host tools exist. Full reference: [SWARM_SETUP.md](SWARM_SETUP.md), [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md).

---

## Skill Installation Paths

After install, skills are symlinked to the AI tool's expected directory:

| AI Tool | Skills path |
|---------|-------------|
| Claude Code | `~/.claude/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Cursor | `~/.cursor/skills/` |
| Windsurf | `~/.windsurf/skills/` |
| Copilot CLI | `~/.copilot/skills/` |
| Pi agent | `~/.pi/agent/skills/` |
| Muse Code | `~/.config/muse/skills/` (user) / `.agents/skills/` (project) |
| Universal | `~/.agents/skills/` |

---

## CI Matrix

The `install-methods-matrix` workflow tests every install path on:

- `ubuntu-latest`
- `macos-latest`
- `windows-latest` (PowerShell + Git Bash)

See `.github/workflows/install-methods-matrix.yml` for the full matrix.

---

## Notes

- **WSL2** is not independently tested in CI because WSL2 == Ubuntu under the hood. The `ubuntu-latest` jobs cover it transitively.
- **Arch Linux** installs are also not directly tested in CI matrix, but may fail on Docker pull limits (known flaky: `One-liner install.sh (archlinux)` — this is a Docker Hub rate-limit issue, not a code issue).

---

## See Also

- [SWARM_SETUP.md](SWARM_SETUP.md) — swarm provisioning — tmux + Herdr (Workstation installs, Toolkit orchestrates)
- [ARCHITECTURE.md](ARCHITECTURE.md) — three-layer architecture and swarm provisioning
- [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) — agent-toolkit integration including swarm orchestration
