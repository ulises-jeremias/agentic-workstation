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
--tool <claude|opencode|cursor|windsurf|copilot|all>   Install for a specific AI tool (default: all)
--guided                                                Interactive prompts for tool selection
--dry-run                                               Preview install plan, no changes
```

### `install-skills.ps1` (Windows PowerShell)

```powershell
# Download and run (latest release)
irm https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.ps1 | iex

# Parameters
-Tool <claude|opencode|cursor|windsurf|copilot|all>    Install for a specific AI tool (default: all)
-Guided                                                 Interactive prompts for tool selection
-DryRun                                                 Preview install plan, no changes
```

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
