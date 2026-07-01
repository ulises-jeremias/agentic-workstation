# Windows Setup

> Installing the agentic-workstation workstation on Windows via WSL2, Git Bash, or skills-only mode.

---

## Installation modes

| Mode | What you get | Requirements |
|------|-------------|--------------|
| **WSL2 (Recommended)** | Full workstation experience | WSL2 + Ubuntu |
| **Git Bash** | `dots-*` scripts only | Git for Windows |
| **Skills-only** | AI skills and agents | PowerShell |

---

## WSL2 (Recommended)

```powershell
# In PowerShell — auto-detects WSL2
irm https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/install.ps1 | iex
```

This installs everything inside your WSL2 Ubuntu environment.

---

## Git Bash

If you prefer Git Bash without WSL2:

```powershell
irm https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/install.ps1 | iex
# Choose "Git Bash" when prompted
```

Limited to `dots-*` CLI scripts — no full chezmoi source state.

---

## Skills-only

For AI skills and agents without the full toolchain:

```powershell
irm https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.ps1 | iex
```

---

## Validation

After installation, open a new terminal and run:

```bash
dots-doctor
```

---

**Technical context:** [`docs/README.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/README.md)
