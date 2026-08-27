# Agent Toolkit Integration

> **Thin workstation** — agentic-workstation provisions the machine (chezmoi, shell, packages, LLM policy, tmux/Herdr, Toolkit installation) and delegates all capabilities via the **canonical V CLI**. **Workstation installs tools, Toolkit owns orchestration.**

---

## Overview

[`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit) is the **sole capability distribution layer** for agentic-workstation. It provides the curated library of skills, agent personas, loop templates, MCP templates, prompts, packs, and tool profiles — one source of truth deployed to every major AI coding assistant.

agentic-workstation's role is **machine provisioning and host-specific runner only**: chezmoi, shell tools, packages, LLM policy (host secrets + `DOTS_AI_DEVCOMPANION_LLM_*`), tmux/Herdr provisioning, Toolkit installation, and the `dev-companion/runner` (`dots-devcompanion` + policy enforcement). All skills/packs/personas/agents/MCPs/loops/prompts and generic queue behavior are delegated to `agent-toolkit`. **Why runner stays:** LLM policy must be enforceable per-host/per-engagement and fail closed (see [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md) and [DEV_COMPANION_IDE_ROADMAP.md](DEV_COMPANION_IDE_ROADMAP.md)); Toolkit remains vendor-neutral and stateless.

Workstation treats Agent Toolkit as a **CLI**, never as a Python library. Do not `import agent_toolkit`.

```mermaid
graph LR
    subgraph "agentic-workstation (L1 - thin)"
        AW["chezmoi apply<br/>dots-* CLIs<br/>LLM policy<br/>dev-companion runner"]
    end

    subgraph "agent-toolkit (L1.5)"
        AT["116+ skills<br/>17 agent personas<br/>10 loop templates<br/>7 tool profiles<br/>7 MCP templates<br/>7 solution packs"]
    end

    subgraph "AI tools"
        CC["Claude Code<br/>~/.claude/skills/"]
        OC["OpenCode<br/>~/.config/opencode/"]
        CU["Cursor<br/>~/.cursor/"]
        WS["Windsurf<br/>~/.codeium/windsurf/"]
        PI["Pi agent<br/>~/.pi/agent/skills/"]
        MC["Muse<br/>~/.config/muse/skills/"]
    end

    AW -->|"brew / AUR / GitHub / uv launcher<br/>agent-toolkit install"| AT
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
| Skills | 116+ (`agent-toolkit inventory`) | jira-assistant, confluence-assistant, github-cli-workflow, planning, dbt-validation, slack-cli |
| Agent personas | Live inventory | architect, planner, code-reviewer, security-reviewer, tdd-guide, agentic-security-reviewer |
| Loop templates | Live inventory | oss-pr-monitor, oss-triage, oss-daily-briefing, ci-sweeper |
| Tool profiles | Live inventory | Claude Code, Cursor, OpenCode, GitHub Copilot, Windsurf, Pi, Muse |
| MCP templates | Live inventory | github, slack, notion, linear, figma, clickup, chrome-devtools |
| Solution packs | Live inventory | oss-maintenance, engineering-workflow, delivery-discipline, agentic-security, architecture, code-quality, design-engineering |
| Prompts | — | clickup-cli, engineering-review, pr-fallback |

### Skill domains

| Domain | Key examples |
|--------|-------------|
| `core` | assistant, workspace, project, onboarding |
| `delivery` | prd, trd, adr, planning, epic, task, bug, incident, assessment |
| `design` | figma-implement-design, figma-code-connect, frontend-design |
| `forge` | github-cli-workflow, gitlab-cli-workflow, gh-fix-ci, worktree |
| `integrations` | jira-assistant, confluence-assistant, slack-cli, linear, clickup-cli, mcp |
| `data` | dbt-validation, snowflake-validation |
| `tooling` | jupyter-notebook, playwright-cli, herdr, inventory |
| `ops` | triage, docs-generator, swarm, llm-cost-advisor |
| `loops` | loop-runner |
| `agentic-security` | threat-modeling, mcp-audit |
| `cloud` | cloud-design-patterns |
| `architecture` | c4-model |
| `accessibility` | review |
| `quality` | megalinter, codeql |

Jira and Confluence are vendored upstream capabilities in `agent-toolkit`; `agent-toolkit install` deploys them with the catalog. Their `jira-as` and `confluence-as` CLIs are host dependencies provisioned by the Workstation AI group.

---

## How agentic-workstation integrates agent-toolkit (thin)

### Install channel preference

Bootstrap **prefers a platform-native adapter**, then falls back. Every path ends with the same CLI contract (`agent-toolkit install`, `doctor`, `inventory`). Shared helper: `~/.local/lib/agentic-workstation/install-agent-toolkit.sh`.

| Order | Platform | Channel | Notes |
|------:|----------|---------|-------|
| 1 | macOS | Homebrew `ulises-jeremias/homebrew-tap` formula `agent-toolkit` | Native V binary from GitHub Releases |
| 1 | Arch Linux | AUR `agent-toolkit-bin` | Native V binary. Do **not** install AUR `agent-toolkit` (Python; not the product) |
| 2 | Linux/macOS | GitHub Release floating binary + `SHA256SUMS` | ADR-018 names, verified sha256 into `~/.local/bin/agent-toolkit` |
| 3 | Any (chicken/egg) | `uv tool install --force 'agent-toolkit-cli>=1.11.0'` | PyPI wheel that **execs the bundled V binary** (ADR-021), not Python as the product |

Minimum version: **1.11.0** (first GitHub Release with native V binaries and V-launcher wheels).

### Automatic install via chezmoi — thin workstation

- **`run_once_after_50-install-agent-toolkit.sh.tmpl`** — runs once on first `chezmoi init`. Walks the preference table, then `agent-toolkit install`.
- **`run_onchange_45-install-ai-agents.sh.tmpl`** — retained for chezmoi onchange hashing. Same CLI install + `agent-toolkit install` + `dots-skills sync`. Workstation-only runner logic (`dev-companion/runner`, LLM policy) is not delegated.

### Manual install / update

```bash
# Walks brew → AUR → GitHub → uv, then agent-toolkit install + sync
dots-skills install-toolkit

# Explicit channels (all end on the V CLI)
brew tap ulises-jeremias/homebrew-tap && brew install agent-toolkit
yay -S agent-toolkit-bin
uv tool install --force 'agent-toolkit-cli>=1.11.0'

agent-toolkit install
```

### Rollback pin

Pin the previous CLI instead of importing Python modules:

```bash
# uv wheel
export AGENT_TOOLKIT_CLI_VERSION=1.11.0
dots-skills install-toolkit
# equivalent: uv tool install --force 'agent-toolkit-cli==1.11.0'

# GitHub binary
export AGENT_TOOLKIT_RELEASE=v1.11.0
dots-skills install-toolkit

# Homebrew / AUR: reinstall the previous formula/PKGBUILD version
brew reinstall agent-toolkit
# or: sudo pacman -U /var/cache/pacman/pkg/agent-toolkit-bin-<ver>-*.pkg.tar.zst
```

Force one channel: `export AGENT_TOOLKIT_INSTALL_CHANNEL=uv` (or `brew`, `aur`, `github`).

### dots-skills delegates to agent-toolkit

`dots-skills` is a thin wrapper that delegates to `agent-toolkit`:

```
dots-skills install-toolkit      brew/AUR/GitHub/uv CLI install + agent-toolkit install
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
| **agent-toolkit** | `dots-skills install-toolkit` then `agent-toolkit install` | `~/.local/share/agent-toolkit/` and tool-specific skill directories | 116+ cross-domain skills (`agent-toolkit inventory`), catalog via SKILL.md |

> [!IMPORTANT]
> **No bundled skills are shipped in this repository.** The `home/dot_local/share/agentic-workstation/skills/` directory is intentionally thin (placeholder `README.md` only; see [ARCHITECTURE.md](ARCHITECTURE.md) thin-host model). All capabilities come from `agent-toolkit` (verify with `agent-toolkit inventory`). Workstation-only host logic lives in `home/dot_local/share/agentic-workstation/dev-companion/runner` + LLM policy (`~/.config/agentic-workstation/env.d/`, `DOTS_*_LLM_*`) — see [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md). No `loops/*`, `mcp/*`, `prompts/*`, `agents/*` are embedded; check `agent-toolkit inventory` for dynamic counts.

---

## Validation & compatibility — delegated

- `scripts/validate-skills.sh` — delegates to `agent-toolkit` when no embedded skills exist (thin workstation exits 0).
- `scripts/generate-compatibility.py` — delegates to `agent-toolkit` or generates a thin-workstation placeholder `docs/COMPATIBILITY.md`.
- `scripts/dots-skills-search.py` — index is generated from the toolkit catalog at runtime.

---

## LLM policy is agentic-workstation-only — DevCompanion boundary

**Boundary:** `dots-devcompanion` (runner + `policy.py` + `DOTS_AI_DEVCOMPANION_LLM_*` + `~/.config/agentic-workstation/env.d/` + audit log) stays entirely in **agentic-workstation** because it is **host-specific** (secrets, per-engagement allowlist/denylist/strict, fail-closed). `agent-toolkit` owns **generic queue behavior** (job JSON schema, queue directories `pending/processing/done/failed`, `agent-toolkit devcompanion queue …` generic plumbing) but has **no LLM provider awareness** — it distributes static skill/agent content only.

**Why runner stays:** LLM policy must be enforced on the machine that holds the secrets and the `dots-devcompanion llm-status` check must be runnable without invoking a model; moving it to the stateless toolkit would couple vendor-neutral distribution to host billing/privacy constraints. See [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md) and [DEV_COMPANION_IDE_ROADMAP.md](DEV_COMPANION_IDE_ROADMAP.md).

> Toolkit generic queue vs Workstation runner: `agent-toolkit devcompanion queue/enqueue` (generic) → Workstation `dots-devcompanion run-once` + `policy.py` (host-specific enforcement) → audit to `~/.local/share/agentic-workstation/dev-companion/logs/llm-audit.log`.

For client engagements, configure the policy before queuing any background jobs:

```bash
export DOTS_AI_DEVCOMPANION_LLM_ALLOWLIST="anthropic"
export DOTS_AI_DEVCOMPANION_LLM_STRICT="1"
dots-devcompanion llm-status    # verify policy — never invokes a model
```

See [`docs/DEV_COMPANION_LLM.md`](DEV_COMPANION_LLM.md) for the full policy reference.

---

## Distribution boundary

> **Rule: Jira and Confluence are distributed only by `agent-toolkit`.** Workstation does not download or maintain separate archives, directories, or installer flags for them. Any future standalone third-party addition remains separate from Toolkit marketplace plugins and must declare its own provenance and installation path. *Historical `uipro-cli` / `ui-ux-pro-max` pack removed in [#197](https://github.com/ulises-jeremias/agentic-workstation/pull/197); do not add `uipro_cli` flags — productivity group now covers `clickup`, `slack`, `rtk` only.*

---

## Claude Code Plugin Marketplace (alternative)

agent-toolkit also ships as Claude Code and Cursor plugin bundles:

```
/plugin marketplace add ulises-jeremias/agent-toolkit
/plugin install agent-toolkit-core@agent-toolkit
/plugin install agent-toolkit-agents@agent-toolkit
/plugin install agent-toolkit-forge@agent-toolkit
```

On agentic-workstation machines, the `chezmoi apply` path (`dots-skills install-toolkit`) is preferred because it also configures per-tool profiles and loop templates.

---

## For contributors — bootstrap helper

Shared installer: `home/dot_local/lib/agentic-workstation/install-agent-toolkit.sh` (deployed to `~/.local/lib/agentic-workstation/install-agent-toolkit.sh`).

| Caller | When |
|--------|------|
| `home/.chezmoiscripts/run_once_after_50-install-agent-toolkit.sh.tmpl` | First `chezmoi apply` (skipped when `CI=true`) |
| `home/.chezmoiscripts/run_onchange_45-install-ai-agents.sh.tmpl` | Subsequent applies when AI/productivity groups are enabled |
| `dots-skills install-toolkit` | Manual install / upgrade (`--force`) |
| `dots-doctor` | Version gate: warn if CLI missing or `< 1.11.0` |

**Rules**

- Never `import agent_toolkit` from workstation scripts, chezmoi templates, or `dots-*` wrappers.
- Do not treat `pip install agent-toolkit-cli` or `python -m agent_toolkit` as the product.
- `uv tool install 'agent-toolkit-cli>=1.11.0'` is allowed only as the chicken/egg fallback (ADR-021 launcher execs V).
- AUR product package is `agent-toolkit-bin`. AUR `agent-toolkit` (Python) is not the product.

**Local checks** (from repo root):

```bash
bash scripts/test-install-agent-toolkit.sh
bash scripts/check-shell-syntax.sh
bash scripts/validate-repo-structure.sh
python3 scripts/generate-compatibility.py --check
```

Channel plan is unit-tested without network. Fresh-machine smoke (optional): install via the highest available channel, then `agent-toolkit --version`, `agent-toolkit doctor`, `agent-toolkit install`.

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
