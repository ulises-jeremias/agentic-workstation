# Agent Toolkit Integration

> **Thin workstation** — agentic-workstation provisions the machine, agent-toolkit distributes all capabilities via `uv`.

---

## Overview

[`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit) is the **sole capability distribution layer** for agentic-workstation. It provides the curated library of skills, agent personas, loop templates, MCP templates, prompts, packs, and tool profiles — one source of truth deployed to every major AI coding assistant.

agentic-workstation's role is **machine provisioning and runner logic only**: chezmoi, shell tools, packages, LLM policy, and the dev-companion queue runner. All skills/packs/personas/agents/MCPs/loops/prompts are delegated.

```mermaid
graph LR
    subgraph "agentic-workstation (L1 - thin)"
        AW["chezmoi apply<br/>dots-* CLIs<br/>LLM policy<br/>dev-companion runner"]
    end

    subgraph "agent-toolkit (L1.5)"
        AT["77 skills / 9 domains<br/>17 agent personas<br/>10 loop templates<br/>7 tool profiles<br/>6 MCP templates<br/>7 solution packs"]
    end

    subgraph "AI tools"
        CC["Claude Code<br/>~/.claude/skills/"]
        OC["OpenCode<br/>~/.config/opencode/"]
        CU["Cursor<br/>~/.cursor/"]
        WS["Windsurf<br/>~/.codeium/windsurf/"]
        PI["Pi agent<br/>~/.pi/agent/skills/"]
        MC["Muse<br/>~/.config/muse/skills/"]
    end

    AW -->|"uv tool install --force agent-toolkit-cli<br/>agent-toolkit install"| AT
    AT -->|dots-skills sync (delegated)| CC
    AT -->|dots-skills sync (delegated)| OC
    AT -->|dots-skills sync (delegated)| CU
    AT -->|dots-skills sync (delegated)| WS
    AT -->|dots-skills sync (delegated)| PI
    AT -->|dots-skills sync (delegated)| MC
```

> **SKILL.md catalog is provided by the toolkit** — not embedded. The repository ships no `home/dot_local/share/agentic-workstation/skills/*` content; the catalog is discovered at runtime via `agent-toolkit install`.

---

## What agent-toolkit provides

| Category | Count | Examples |
|----------|-------|---------|
| Skills | 77 (9 domains) | code-review, github-cli-workflow, jira, confluence, dbt-validation |
| Agent personas | 17 | architect, planner, code-reviewer, security-reviewer, tdd-guide, agentic-security-reviewer |
| Loop templates | 10 | oss-pr-monitor, oss-triage, oss-daily-briefing, ci-sweeper |
| Tool profiles | 7 | Claude Code, Cursor, OpenCode, GitHub Copilot, Windsurf, Pi, Muse |
| MCP templates | 7 | github, slack, notion, linear, figma, clickup, chrome-devtools |
| Solution packs | 7 | oss-maintenance, engineering-workflow, delivery-discipline, agentic-security, architecture, code-quality, design-engineering |
| Prompts | — | clickup-cli, engineering-review, pr-fallback |

### Skill domains

| Domain | Skills | Key examples |
|--------|--------|-------------|
| `core` | 8 | memory, planning, context injection, session bootstrap |
| `delivery` | 21 | prd, trd, adr, planning, epic, task, bug, incident, assessment |
| `design` | 5 | figma-implement-design, figma-code-connect, design-system-rules |
| `forge` | 8 | github-cli-workflow, gitlab-cli-workflow, gh-fix-ci, gh-address-comments |
| `integrations` | 5 | slack-cli, slack-assistant, linear, clickup-cli, mcp |
| `data` | 2 | dbt-validation, snowflake-validation |
| `tooling` | 4 | jupyter-notebook, playwright-cli, herdr, inventory |
| `ops` | 6 | triage, docs-generator, swarm, llm-cost-advisor |
| `loops` | 1 | loop-runner |

---

## How agentic-workstation integrates agent-toolkit (thin)

### Automatic install via chezmoi — thin workstation

Only **one install path** is supported:

- **`run_once_after_50-install-agent-toolkit.sh.tmpl`** — runs once on first `chezmoi init`. Executes only:
  ```bash
  uv tool install --force agent-toolkit-cli
  agent-toolkit install
  ```
  This deploys skills, agents, profiles, loops, and MCP templates for all detected AI tools.

- **`run_onchange_45-install-ai-agents.sh.tmpl`** — retained for chezmoi onchange hashing. In the thin workstation it delegates to the same two commands (`uv tool install --force agent-toolkit-cli` + `agent-toolkit install`) and then runs `dots-skills sync`. Workstation-only runner logic (`dev-companion/runner`, LLM policy) is not delegated.

No AUR / pipx / pip fallbacks are used — `uv` is the sole installer.

### Manual install / update

```bash
# Thin workstation canonical path
uv tool install --force agent-toolkit-cli
agent-toolkit install

# Via dots-skills (delegates to the same two commands)
dots-skills install-toolkit

# Update to latest
uv tool install --force agent-toolkit-cli
agent-toolkit install
# or: dots-skills install-toolkit
```

### dots-skills delegates to agent-toolkit

`dots-skills` is a thin wrapper that delegates to `agent-toolkit`:

```
dots-skills install-toolkit      uv tool install --force agent-toolkit-cli + agent-toolkit install
dots-skills sync                 delegates to agent-toolkit install (regenerates per-tool symlinks)
dots-skills list                 delegates to agent-toolkit skills list (falls back to local when toolkit unavailable)
dots-skills check                delegates to agent-toolkit doctor
```

### dots-loop wraps agent-toolkit loop

```bash
dots-loop init oss-pr-monitor    # init from agent-toolkit loop template
dots-loop run oss-pr-monitor     # run via ai-workspace
dots-loop status                 # check all loop states
agent-toolkit loop sync          # pull latest loop templates from agent-toolkit
```

---

## Swarm orchestration — Workstation installs, Toolkit orchestrates

> **Workstation installs tools, Toolkit owns orchestration.** agentic-workstation provisions `tmux` + `Herdr` + `herdr integration install opencode` idempotently via `run_onchange_42-install-swarm-tooling.sh.tmpl` (gated by `install_group_swarm`). `agent-toolkit` owns swarm recipes, isolated tmux sockets (`agent-toolkit-swarm-<run-id>`), and orchestration lifecycle.

### What Workstation provisions

- **tmux** — package manager install (apt/brew/pacman/dnf), respects `can_sudo`. Verify: `tmux -V`. No `~/.tmux.conf` overwrite.
- **Herdr** — brew → mise → `curl -fsSL https://herdr.dev/install.sh | sh` fallback, logged to `/tmp/herdr-install.log`, no sudo. Verify: `herdr --version`. Skipped in CI unless `SWARM_FORCE_INSTALL=1`.
- **OpenCode Herdr integration** — `herdr integration install opencode` when both present; `mkdir -p ~/.config/opencode` safe if missing. Verify: `herdr integration list --json`; if `outdated`, re-run the install. Herdr is the preferred UI; tmux is the fallback.

### Doctor — Workstation + Toolkit

```bash
dots-doctor                 # profile-aware: tmux, herdr, herdr integration, agent-toolkit swarm doctor
dots-doctor --json | jq
agent-toolkit swarm doctor  # toolkit-level swarm health check (owned by toolkit)
herdr integration list --json  # inspect opencode integration status
```

When `install_group_swarm=false`, missing herdr is a warning (not failure). When `install_group_swarm=true`, `tmux` missing is a failure and `herdr` missing is a warning (tmux fallback).

### Recipes — Toolkit owns orchestration

```bash
herdr                                          # start Herdr UI
herdr integration install opencode             # ensure OpenCode integration (idempotent)
agent-toolkit swarm doctor                     # validate prerequisites
agent-toolkit swarm start --recipe pair --ui herdr --runner opencode "Implement feature X"
agent-toolkit swarm start --recipe pair --ui tmux --runner opencode "Implement feature X"
agent-toolkit swarm --help                     # full recipe/UI/runner reference lives in toolkit
```

See [SWARM_SETUP.md](SWARM_SETUP.md) for complete provisioning, questionnaire, and troubleshooting. Toolkit is the source of truth for swarm orchestration — Workstation only ensures the host tools exist.

---

## Skill sources — thin workstation

| Source | Install mechanism | Location | Examples |
|--------|------------------|----------|---------|
| **agent-toolkit** | `uv tool install --force agent-toolkit-cli && agent-toolkit install` | `~/.local/share/agentic-workstation/skills-external/agent-toolkit/` | 60 cross-domain skills, catalog via SKILL.md |

> [!IMPORTANT]
> **No bundled skills are shipped in this repository.** The `home/dot_local/share/agentic-workstation/skills/` directory is intentionally empty (placeholder README only). All capabilities come from `agent-toolkit`. Workstation-only runner logic lives in `home/dot_local/share/agentic-workstation/dev-companion/runner`.

---

## Validation & compatibility — delegated

- `scripts/validate-skills.sh` — delegates to `agent-toolkit` when no embedded skills exist (thin workstation exits 0).
- `scripts/generate-compatibility.py` — delegates to `agent-toolkit` or generates a thin-workstation placeholder `docs/COMPATIBILITY.md`.
- `scripts/dots-skills-search.py` — index is generated from the toolkit catalog at runtime.

---

## LLM policy is agentic-workstation-only

`dots-devcompanion` LLM policy enforcement stays entirely in agentic-workstation. agent-toolkit has no LLM provider awareness — it distributes static skill/agent content only.

For client engagements, configure the policy before queuing any background jobs:

```bash
export DOTS_AI_DEVCOMPANION_LLM_ALLOWLIST="anthropic"
export DOTS_AI_DEVCOMPANION_LLM_STRICT="1"
dots-devcompanion llm-status    # verify policy — never invokes a model
```

See [`docs/DEV_COMPANION_LLM.md`](DEV_COMPANION_LLM.md) for the full policy reference.

---

## Third-party boundary — plugins vs skills-external

> **Rule: third-party never to `plugins/`** — external npm / github / url packs (JIRA 14, Confluence 17, future `uipro-cli`-like) live in `skills-external/*` via `chezmoiexternal` + `dots-skills sync` and are **never** compiled into `agent-toolkit` marketplace `plugins/` (`distributions/products.yaml` is first-party-only). Workstation owns their opt-in lifecycle (`install_skill_*=true` → `chezmoi apply --refresh-externals`). Toolkit remains vendor-neutral public (per `agent-toolkit/AGENTS.md:81`, `docs/TRUST.md`). See `docs/SKILLS.md` “Skill sources”.

---

## Claude Code Plugin Marketplace (alternative)

agent-toolkit also ships as Claude Code and Cursor plugin bundles:

```
/plugin marketplace add ulises-jeremias/agent-toolkit
/plugin install agent-toolkit-core@agent-toolkit
/plugin install agent-toolkit-agents@agent-toolkit
/plugin install agent-toolkit-forge@agent-toolkit
```

On agentic-workstation machines, the `chezmoi apply` path (`uv tool install --force agent-toolkit-cli && agent-toolkit install`) is preferred because it also configures per-tool profiles and loop templates.

---

## See Also

- [SWARM_SETUP.md](SWARM_SETUP.md) — swarm provisioning — tmux + Herdr (Workstation installs, Toolkit orchestrates)
- [ARCHITECTURE.md](ARCHITECTURE.md) — Three-layer architecture (L1 / L1.5 / L3) — thin workstation
- [PLATFORM_SUPPORT.md](PLATFORM_SUPPORT.md) — platform support including swarm tooling
- [COMPATIBILITY.md](COMPATIBILITY.md) — tool compatibility and swarm troubleshooting
- [SKILLS.md](SKILLS.md) — Full skills system documentation
- [LOOPS.md](LOOPS.md) — Loop engineering and reference patterns
- [AI_LAYER.md](AI_LAYER.md) — AI directory structure and Ralph Loop model
- [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md) — LLM policy (agentic-workstation-only)
- [agent-toolkit repo](https://github.com/ulises-jeremias/agent-toolkit) — capability source
