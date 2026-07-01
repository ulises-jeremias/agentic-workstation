# Troubleshooting

> Common issues and fixes for the agentic-workstation workstation.

---

## `dots-doctor` reports failures

| Failure | Fix |
|---------|-----|
| Missing command (e.g., `opencode`) | Install the tool manually, then re-run `chezmoi apply` |
| Missing directory | Run `chezmoi apply` — it creates expected directories |
| Missing skill symlinks | Run `dots-skills sync` to regenerate |
| `NON-COMPLIANT` status | Fix all reported failures, then re-run `dots-doctor` |

---

## chezmoi prompts again on update

This is normal when new configuration questions are added upstream. Answer the prompts and re-apply:

```bash
chezmoi update
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

---

## Skills not appearing in AI tool

1. Check the skill is enabled: `dots-skills list`
2. Regenerate symlinks: `dots-skills sync`
3. Restart the AI tool (it loads skills at startup)

---

## AI tool doesn't recognize agents

Agents are installed to tool-specific directories during `chezmoi apply`:

- Claude Code: `~/.claude/agents/`
- OpenCode: `~/.config/opencode/agents/`

Verify the files exist, then restart the tool.

---

## WSL2 issues

| Problem | Fix |
|---------|-----|
| Install script hangs | Ensure WSL2 is installed and a default distro is set |
| `dots-*` commands not found | Open a **new terminal** after `chezmoi apply` |
| Permission errors | Run inside WSL2 Ubuntu, not PowerShell |

---

## Uninstall

To remove the workstation baseline from your machine:

```bash
# Remove chezmoi-managed files
chezmoi purge

# Remove AI resources
rm -rf ~/.local/share/agentic-workstation
rm -rf ~/.local/bin/dots-*

# Remove skill symlinks
rm -rf ~/.claude/skills/
rm -rf ~/.config/opencode/skills/
rm -rf ~/.cursor/skills/

# Remove agent definitions
rm -rf ~/.claude/agents/
rm -rf ~/.config/opencode/agents/
```

---

## Getting help

1. Check the [docs/](https://github.com/ulises-jeremias/agentic-workstation/tree/main/docs) directory
2. Run `dots-doctor` for diagnostics
3. Ask in #tech-support on Slack
4. Open an issue in the repository
