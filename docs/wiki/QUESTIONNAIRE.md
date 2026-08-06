# Init Questionnaire

> How to answer the profile and feature prompts during `chezmoi init`.

---

## What the questionnaire controls

The questionnaire controls which package groups, AI tools, skills, and optional integrations are installed.

## Common choices

| Need | Choose |
|---|---|
| Full engineering workstation | `technical` + relevant language profile |
| AI tooling only | `ai` or skills-only install |
| Python work | `python` |
| Data workflows | `data` |
| Minimal setup | `minimal` |

## What happens during `chezmoi init`

1. **Profile prompt** — choose `technical`, `non-technical`, `ai`, `node`, `python`, `data`, `infra`, `minimal`, or `custom`. `technical`/`non-technical`/`ai`/`data` automatically enable swarm (`install_group_swarm=true`).
2. **Group prompts** (when `custom` or when profile leaves a group optional) — including:
   - `Install Agent Toolkit Swarms (tmux + Herdr)?` → `install_group_swarm` (see [SWARM_SETUP](../../docs/SWARM_SETUP.md))
   - `Install AI coding agents group?` → `install_group_ai`
   - Jira/Confluence/productivity/tool-specific prompts
3. **Agent/editor prompts** — choose which AI agents and editors to install.

> **Workstation installs tools, Toolkit owns orchestration.** Answering “yes” to swarms installs `tmux` + `Herdr` + `herdr integration install opencode` idempotently (see `home/.chezmoidata/profiles.yaml` and `home/.chezmoi.toml.tmpl` comments). Swarm orchestration (`agent-toolkit swarm doctor`, `agent-toolkit swarm start --recipe pair --ui herdr|tmux --runner opencode`) lives in Toolkit.

**Non-interactive / CI:**

```bash
WORKSTATION_PROFILE=technical chezmoi init --apply ulises-jeremias/agentic-workstation
WORKSTATION_PROFILE=custom chezmoi init --apply . --promptString install_group_swarm=yes
chezmoi init --apply . --promptChoice install_group_swarm=yes
```

Verify after apply: `dots-doctor` (includes swarm checks) and `agent-toolkit swarm doctor`.

---

## Optional integrations

Some integrations require explicit opt-in flags, such as Jira and Confluence assistant packs. Configure credentials first, then enable the relevant prompt or flag. The **swarm group** is an opt-in/out feature group (not an external skill pack) — `install_group_swarm` toggles tmux/herdr provisioning via `run_onchange_42-install-swarm-tooling.sh.tmpl`.

The questionnaire prompt source is `home/.chezmoi.toml.tmpl` (comments document `install_group_swarm` and the `swarm` entry in `$profileGroupsMap`).

## Re-run the questionnaire

```bash
cd /path/to/agentic-workstation
chezmoi init --source=. -c ~/.config/chezmoi/agentic-workstation.toml
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

## See also

- [Profiles](PROFILES)
- [Credentials & Env Files](CREDENTIALS)
- [Integrations Overview](INTEGRATIONS)
