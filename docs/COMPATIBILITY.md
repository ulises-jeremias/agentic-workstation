# Tool Compatibility Matrix

> Thin workstation — compatibility is delegated to [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit).
> No embedded `skill.json` files are shipped in this repository.
> Thin workstation: skills are delegated to `agent-toolkit`. Install via `uv tool install --force agent-toolkit-cli && agent-toolkit install`.
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
| `herdr: command not found` | Herdr not installed (opt-in group disabled or CI skip) | Install via `brew install herdr` or `curl -fsSL https://herdr.dev/install.sh \| sh` (see [SWARM_SETUP.md](SWARM_SETUP.md)) or use `--ui tmux` fallback: `agent-toolkit swarm start --recipe pair --ui tmux --runner opencode "Task"` |
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
