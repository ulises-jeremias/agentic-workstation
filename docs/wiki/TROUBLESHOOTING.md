# Troubleshooting

> Common issues and fixes for the agentic-workstation workstation.

---

## `dots-doctor` reports failures

| Failure | Fix |
|---------|-----|
| Missing command (e.g., `opencode`) | Install the tool manually, then re-run `chezmoi apply` |
| Missing directory | Run `chezmoi apply` — it creates expected directories |
| Missing skill symlinks | Run `dots-skills sync` to regenerate |
| `tmux: command not found` (swarm enabled) | `sudo apt install tmux` / `brew install tmux` / `sudo pacman -S tmux` |
| `herdr: command not found` | `brew install herdr` or `curl -fsSL https://herdr.dev/install.sh \| sh`; or use `--ui tmux` fallback |
| `herdr integration outdated` | `herdr integration install opencode` and verify `herdr integration list --json` |
| `NON-COMPLIANT` status | Fix all reported failures, then re-run `dots-doctor` |

Swarm details: `dots-doctor` includes `tmux`/`herdr`/`herdr integration`; `agent-toolkit swarm doctor` is the toolkit-level check (see [SWARM_SETUP](../../docs/SWARM_SETUP.md) and [COMPATIBILITY](../../docs/COMPATIBILITY.md)). When `install_group_swarm=false`, `herdr` missing is a warning, not failure; when `true`, `tmux` missing is failure and `herdr` missing is warning (tmux fallback).

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

## Swarm troubleshooting

> **Workstation installs tools, Toolkit owns orchestration.** `herdr`, `herdr integration install opencode`, `agent-toolkit swarm doctor`, and `agent-toolkit swarm start --recipe pair` details live in [SWARM_SETUP](../../docs/SWARM_SETUP.md).

| Symptom | Fix |
|---------|-----|
| `herdr: command not found` | Install via https://herdr.dev/docs/install/ — preferred `brew install herdr` then `herdr --version`; fallback `curl -fsSL https://herdr.dev/install.sh \| sh` (logged to `/tmp/herdr-install.log`). Or use `agent-toolkit swarm start --recipe pair --ui tmux --runner opencode` |
| `tmux: command not found` | `sudo apt install tmux` / `brew install tmux` / `sudo pacman -S tmux` / `sudo dnf install tmux` — then `tmux -V` |
| `herdr integration outdated` or `herdr integration list --json` shows no `opencode` | `mkdir -p ~/.config/opencode` (safe, script does it), then `herdr integration install opencode`; check `/tmp/herdr-integration-opencode.log` |
| `OpenCode config dir missing` | Script creates `~/.config/opencode` safely; no credentials written |
| CI skips Herdr/tmux | Expected when `CI=true` and `SWARM_FORCE_INSTALL` unset; mock with fake `herdr` in `PATH` or run `SWARM_FORCE_INSTALL=1 chezmoi apply` |
| `agent-toolkit swarm doctor` fails | Run `agent-toolkit swarm doctor` (Toolkit-owned) for recipe/UI/runner diagnostics; provision missing tools via `chezmoi update` / `dots-doctor` |

**Verification:**

```bash
dots-doctor; echo "---"; agent-toolkit swarm doctor; herdr --version; tmux -V; herdr integration list --json | jq
herdr integration install opencode   # idempotent, safe to re-run
```

Profiles `technical`/`non-technical`/`ai`/`data` enable swarm by default (`install_group_swarm=true` in `home/.chezmoidata/profiles.yaml`); `custom` can opt-out. `chezmoi update` re-runs `run_onchange_42-install-swarm-tooling.sh.tmpl` idempotently. No `~/.tmux.conf` overwrite; Toolkit uses isolated socket `agent-toolkit-swarm-<run-id>`.

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
