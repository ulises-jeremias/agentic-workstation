# Guided AI Install

> Copy-paste setup for users who only need AI skills and agents.

---

## When to use this

Use skills-only mode when you want the shared AI layer without applying the full workstation baseline.

## Linux, macOS, or WSL2

```bash
curl -fsSL https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.sh | sh
```

## Windows PowerShell

```powershell
irm https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.ps1 | iex
```

## Verify

Open a new terminal and run:

```bash
dots-skills list
dots-doctor
```

## What gets installed

- Skills under `~/.local/share/agentic-workstation/skills/`
- Tool-specific skill links for supported AI tools
- Agent definitions for supported AI coding tools

## Next steps

- [Skills System](SKILLS)
- [CLI Reference](CLI)
- [Integrations Overview](INTEGRATIONS)
- [Troubleshooting](TROUBLESHOOTING)
