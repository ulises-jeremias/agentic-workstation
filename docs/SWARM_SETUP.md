# Swarm Setup — agentic-workstation

> **Machine provisioning for Agent Toolkit Swarms** — tmux + Herdr + OpenCode integration. Toolkit owns orchestration.

## Provisioning

```bash
# Interactive
chezmoi init --apply ulises-jeremias/agentic-workstation
# Choose profile: technical/ai/data include swarm group automatically
# Or custom → answer "Install Agent Toolkit Swarms (tmux + Herdr)?" yes

# Non-interactive
WORKSTATION_PROFILE=technical chezmoi init --apply ulises-jeremias/agentic-workstation
# Or force swarm:
WORKSTATION_PROFILE=custom chezmoi init --apply ... --promptString install_group_swarm=yes
```

## What Gets Installed

- **tmux** — always installed in core + swarm group (apt/brew/pacman/dnf). Verified: `tmux -V`. No custom `.tmux.conf` overwritten; Toolkit uses isolated socket `agent-toolkit-swarm-<run-id>`.
- **Herdr** — idempotent install via brew → mise → official `https://herdr.dev/install.sh` fallback. Skip in CI unless `SWARM_FORCE_INSTALL=1`. Check: `herdr --version`.
- **OpenCode Herdr integration** — optional, idempotent: `herdr integration install opencode` when both present. Creates `~/.config/opencode` safely if missing. Check: `herdr integration list --json`.

## Profile Options

`home/.chezmoidata/profiles.yaml` group `swarm` flag `install_group_swarm`. Enabled by default for `technical`, `non-technical`, `ai`, `data`. Opt-out via `custom` answering no.

Data fields (chezmoi):
```yaml
install_group_swarm: true          # master toggle
# swarm_integrations: [opencode]   # optional integrations list (default opencode)
```

## Doctor

```bash
dots-doctor                 # includes tmux, herdr, swarm checks
dots-doctor --json | jq
agent-toolkit swarm doctor  # toolkit-level swarm checks
```

When `install_group_swarm=false`, herdr missing is warning not failure. When true, tmux missing is failure, herdr missing is warning (fallback to tmux).

## Usage

Workstation installs tools, Toolkit owns orchestration:

```bash
herdr                        # start Herdr app
herdr integration install opencode
agent-toolkit swarm doctor
agent-toolkit swarm start --recipe pair --ui herdr --runner opencode "Task"
agent-toolkit swarm start --recipe pair --ui tmux --runner opencode "Task"
```

See [`agent-toolkit` docs](https://github.com/ulises-jeremias/agent-toolkit) — swarm orchestration lives there (`agent-toolkit swarm --help`).

## Updates & Removal

- Update: `chezmoi update` re-runs `run_onchange_42-install-swarm-tooling.sh.tmpl` if package manifest changed.
- Herdr update: `brew upgrade herdr` or re-run installer (idempotent, verbose about skips).
- Disable: `chezmoi init --promptChoice install_group_swarm=no` then `chezmoi apply`; no destructive overwrite of `~/.tmux.conf`.
- Uninstall: `dots-uninstall` does not auto-remove tmux/herdr; remove manually `brew uninstall herdr; sudo apt remove tmux`.

## Troubleshooting

- `herdr not found` → install via https://herdr.dev/docs/install/ or use `--ui tmux`
- `tmux not found` → `sudo apt install tmux` / `brew install tmux`
- `herdr integration outdated` → `herdr integration install opencode`
- `OpenCode config dir missing` → script creates `~/.config/opencode`; safe, no credentials written.
- CI: Herdr install skipped; mock with fake `herdr` binary in PATH for tests (`SWARM_FORCE_INSTALL=1`)

## Security

No credentials read/written. `curl | sh` only after brew/mise fallback, with log to `/tmp/herdr-install.log`. No sudo required for Herdr; tmux via package manager respects `can_sudo` check.

---

## See Also

- [ARCHITECTURE.md](ARCHITECTURE.md) — swarm provisioning layer (Workstation installs, Toolkit orchestrates)
- [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) — swarm orchestration owned by toolkit
- [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md) — platform support including swarm tooling
- [COMPATIBILITY.md](COMPATIBILITY.md) — swarm troubleshooting
- [`home/.chezmoidata/profiles.yaml`](../home/.chezmoidata/profiles.yaml) — profile group `swarm`
- [`home/.chezmoi.toml.tmpl`](../home/.chezmoi.toml.tmpl) — questionnaire prompt `Install Agent Toolkit Swarms (tmux + Herdr)?`
