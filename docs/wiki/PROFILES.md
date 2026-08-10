# Profiles

> Profile-driven configuration — choose what gets installed on your machine.

---

## How profiles work

During `chezmoi init`, you select one or more profiles. Each profile maps to a set of **package groups** that control which tools are installed.

---

## Available profiles

| Profile | Target audience | Installs |
|---------|----------------|----------|
| `technical` | Engineers | Git, Docker, dev tools, editors, **swarm: tmux + Herdr** |
| `non-technical` | Non-engineering staff | Minimal tooling + **swarm: tmux + Herdr** |
| `ai` | AI/ML practitioners | AI CLIs, skills, agents, MCP templates, **swarm: tmux + Herdr** |
| `node` | Frontend / fullstack devs | Node.js, npm/pnpm, frontend tools |
| `python` | Python developers | Python, pip, virtualenv tools |
| `data` | Data engineers | dbt, SQL tools, data stack, **swarm: tmux + Herdr** |
| `infra` | DevOps / infrastructure | Terraform, AWS CLI, k8s tools |
| `minimal` | Minimal setup | Core baseline only (no swarm) |
| `custom` | Custom | Answer every group question — opt-in `Install Agent Toolkit Swarms (tmux + Herdr)?` |

---

## Profile composition

Profiles are **additive** — you can select multiple:

```
technical + ai + node → full frontend AI stack
technical + ai + data → full data AI stack
```

---

## Feature groups

| Group | Flag | Description |
|-------|------|-------------|
| `swarm` | `install_group_swarm` | **Agent Toolkit Swarms — tmux + Herdr** (see [SWARM_SETUP](../../docs/SWARM_SETUP.md)). Provisioned via `run_onchange_42-install-swarm-tooling.sh.tmpl`: tmux via package manager, Herdr via brew→mise→`https://herdr.dev/install.sh` fallback, optional `herdr integration install opencode` |
| `ai` | `install_group_ai` | AI coding agents (Claude Code, OpenCode, pi, Copilot CLI, Muse) |
| `node` | `install_group_node` | fnm + Node.js LTS + pnpm |
| `python` | `install_group_python` | Python + uv + pipx |
| `docker` | `install_group_docker` | Docker CLI |
| `skills_productivity` | `install_group_skills_productivity` | Productivity CLIs (clickup, slack, rtk) |

> **Workstation installs tools, Toolkit owns orchestration.** Workstation ensures `tmux` + `Herdr` (+ `herdr integration install opencode`) exist; Toolkit owns `agent-toolkit swarm doctor` and `agent-toolkit swarm start --recipe pair --ui herdr|tmux --runner opencode`.

## Canonical mapping

The authoritative profile-to-package mapping lives in:

```
home/.chezmoidata/profiles.yaml
```

`swarm` group flag `install_group_swarm` defaults to `true` for `technical`, `non-technical`, `ai`, `data`; `false` for `minimal`/`custom` until opt-in. Verify with `dots-doctor` and `agent-toolkit swarm doctor`.

---

## Changing profiles

Re-run init to update your choices:

```bash
cd /path/to/agentic-workstation
chezmoi init --source=. -c ~/.config/chezmoi/agentic-workstation.toml
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

---

**Technical context:** [`docs/README.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/README.md)
