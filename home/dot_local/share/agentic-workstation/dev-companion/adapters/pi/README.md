# pi.dev teams adapter (optional)

This repo is **not** forcing pi.dev usage, but pi.dev is a strong candidate runtime for the “multi-agent teams” experience.

## Install (example)

Install pi-agent-teams (upstream extension):

```bash
pi install npm:@tmustier/pi-agent-teams
```

## Recommended mapping

Map agentic-workstation policy assets to pi teams configuration:

- Leader prompt: `dots-workstation-assistant` + `dots-workstation-dev-companion`
- Workers: specialized roles (reviewer, data validator, forge PR, docs sync)
- Workspace mode: `worktree` (isolated branches per teammate)
- Hooks: run quality gates on task completion (repo-documented checks)

## Safety

- Use account packs (`~/.local/share/agentic-workstation/dev-companion/packs/accounts/*`) to enforce allowed paths and tool requirements.
- Keep credentials in `~/.config/agentic-workstation/env.d/*.env`.
