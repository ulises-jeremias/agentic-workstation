<div align="center">

<img alt="agentic-workstation" src="static/hero-banner.svg" width="100%">

<br>
<br>

[![Layer](https://img.shields.io/badge/L1-Workstation%20Baseline-22d3ee?style=for-the-badge&labelColor=020617)](#personal-dx-stack)
[![Skills](https://img.shields.io/badge/77-AI%20Skill%20Packs-a78bfa?style=for-the-badge&labelColor=020617)](#what-you-get)
[![MCP](https://img.shields.io/badge/MCP-Ready-84cc16?style=for-the-badge&labelColor=020617)](#what-you-get)
[![CI](https://img.shields.io/github/actions/workflow/status/ulises-jeremias/agentic-workstation/devcontainer-chezmoi-validate.yml?style=for-the-badge&label=CI&labelColor=020617&color=22d3ee)](https://github.com/ulises-jeremias/agentic-workstation/actions/workflows/devcontainer-chezmoi-validate.yml)
[![Discord](https://img.shields.io/discord/1527933660764831825?style=for-the-badge&label=Discord&logo=discord&logoColor=white&labelColor=020617)](https://discord.gg/bR5VyATgka)

<h3>One command to turn a machine into an AI-native developer workstation.</h3>

<p>
  <strong>agentic-workstation</strong> is the baseline layer of my personal Developer Experience stack:<br>
  reproducible dotfiles, machine provisioning, and CLI guardrails optimized for deep flow.<br>
  <em>Thin-host: Workstation provisions the machine (chezmoi, shell, packages, LLM policy, tmux/Herdr, Toolkit installation) and delegates all capabilities to <a href="https://github.com/ulises-jeremias/agent-toolkit">agent-toolkit</a>. Verify skill count with <code>agent-toolkit inventory</code>.</em>
</p>

[Install](#quick-start) · [Architecture](#architecture) · [Wiki](https://github.com/ulises-jeremias/agentic-workstation/wiki) · [Integrations](#integrations) · [Personal DX Stack](#personal-dx-stack) · [Docs](docs/) · [Contributing](CONTRIBUTING.md)

</div>

---

**agentic-workstation** is an AI-first, chezmoi-managed workstation baseline — a **thin host** that provisions your machine (chezmoi, shell, packages, LLM policy, tmux/Herdr, and Toolkit installation) and delegates all capabilities to [`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit). Workstation installs tools, Toolkit owns orchestration — ready to go in one command.

Works with **Claude Code**, **Muse Code**, **opencode**, **Cursor**, **Gemini CLI**, **GitHub Copilot**, and any AI coding tool that supports agent skills.
> **Thin workstation** — this repository ships no embedded `skills/*`, `loops/*`, `mcp/*`, `prompts/*`, `agents/*`, or `packs/teams`. All capabilities are delegated to `agent-toolkit` via `dots-skills install-toolkit` (Homebrew / AUR `agent-toolkit-bin` / GitHub V binary / `uv tool install --force 'agent-toolkit-cli>=1.11.0'`). The `SKILL.md` catalog is provided by the toolkit at runtime (verify with `agent-toolkit inventory` — 77 skills, 17 agents, 10 loops). Workstation-only runner logic (`dev-companion/runner`, LLM policy) is retained — see boundary in [`docs/DEV_COMPANION_LLM.md`](docs/DEV_COMPANION_LLM.md) and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). See [`docs/AGENT_TOOLKIT.md`](docs/AGENT_TOOLKIT.md).



---

## What You Get

<table>
  <tr>
    <td width="33%" align="center">
      <br>
      <b>🧩 Skills System</b><br>
      <sub>77 reusable skills via <a href="https://github.com/ulises-jeremias/agent-toolkit">agent-toolkit</a> — ClickUp, Figma, GitHub, GitLab, Slack, dbt, Snowflake, Playwright, and more (<code>agent-toolkit inventory</code>)<br/><em>Jira (14) & Confluence (17) are opt-in third-party packs via <code>skills-external/</code> — <code>install_skill_jira_assistant=true</code> / <code>install_skill_confluence_assistant=true</code></em></sub>
    </td>
    <td width="33%" align="center">
      <br>
      <b>🤖 AI Agents</b><br>
      <sub>Pre-configured agents for code review, security audit, TDD, refactoring, planning, architecture, and E2E testing</sub>
    </td>
    <td width="33%" align="center">
      <br>
      <b>🔌 MCP Templates</b><br>
      <sub>Self-configuring MCP provider templates for LLM servers, APIs, and data sources — zero manual setup</sub>
    </td>
  </tr>
  <tr>
    <td width="33%" align="center">
      <br>
      <b>🛠️ CLI Helpers</b><br>
      <sub><code>agent-toolkit</code> · <code>dots-doctor</code> · <code>dots-skills</code> · <code>dots-mcp</code> · <code>dots-loadenv</code> — agent-toolkit powers skills, loops, MCP, and workspace operations</sub>
    </td>
    <td width="33%" align="center">
      <br>
      <b>🔄 Loop Engineering</b><br>
      <sub>Structured agent loops with cost estimation, telemetry, drift detection, and automated improvement cycles</sub>
    </td>
    <td width="33%" align="center">
      <br>
      <b>🎯 Multi-Tool Sync</b><br>
      <sub>One skill registration across Claude Code, Muse Code, opencode, Cursor, Copilot CLI, Pi, and Windsurf — no duplicates</sub>
    </td>
  </tr>
</table>

---

## Quick Start

### Just want the AI skills?

Add 77 AI skills to your existing setup — powered by **[agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit)**:

```bash
# Option A: one-shot via uvx (V launcher wheel, no install required)
uvx --from 'agent-toolkit-cli>=1.11.0' agent-toolkit install

# Option B: Homebrew (macOS / Linuxbrew)
brew tap ulises-jeremias/homebrew-tap && brew install agent-toolkit && agent-toolkit install

# Option C: Arch Linux via AUR (native V binary)
yay -S agent-toolkit-bin && agent-toolkit install

# Option D: uv tool (V launcher wheel)
uv tool install --force 'agent-toolkit-cli>=1.11.0' && agent-toolkit install

# Option E: install-skills.sh (agentic-workstation wrapper)
curl -fsSL https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.sh | bash
```

Works instantly with **Claude Code, Muse Code, opencode, Cursor, GitHub Copilot, and Gemini CLI**. [Learn more →](https://github.com/ulises-jeremias/agentic-workstation/wiki/GUIDED_AI_INSTALL)

### Full workstation (dotfiles + skills + everything)

```bash
chezmoi init --apply ulises-jeremias/agentic-workstation
```

<table>
  <tr>
    <th>If you want to…</th>
    <th>Follow this</th>
  </tr>
  <tr>
    <td>Set up your entire machine from scratch</td>
    <td><a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/TECHNICAL_QUICKSTART">📘 Wiki Quick Start</a></td>
  </tr>
  <tr>
    <td>Add AI skills to an existing setup</td>
    <td><a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/GUIDED_AI_INSTALL">📘 Guided AI Install</a></td>
  </tr>
  <tr>
    <td>Choose your profile and answer prompts</td>
    <td><a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/PROFILES">📘 Profiles</a> · <a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/QUESTIONNAIRE">📘 Questionnaire</a></td>
  </tr>
  <tr>
    <td>Configure credentials and integrations</td>
    <td><a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/CREDENTIALS">📘 Credentials</a> · <a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/INTEGRATIONS">📘 Integrations</a></td>
  </tr>
  <tr>
    <td>Use the CLI</td>
    <td><a href="https://github.com/ulises-jeremias/agentic-workstation/wiki/CLI">📘 CLI Reference</a></td>
  </tr>
</table>

---

## Integrations

Seamless skill packs for the tools you use every day:

<table>
  <tr>
    <td align="center"><b>📋 Jira</b></td>
    <td align="center"><b>📄 Confluence</b></td>
    <td align="center"><b>✅ ClickUp</b></td>
    <td align="center"><b>💬 Slack</b></td>
  </tr>
  <tr>
    <td align="center"><sub>Issues, sprints, epics, JQL, time tracking, admin</sub></td>
    <td align="center"><sub>Pages, spaces, search, permissions, templates, analytics</sub></td>
    <td align="center"><sub>Tasks, docs, sprints, goals, comments, templates</sub></td>
    <td align="center"><sub>Channels, messages, canvases, reactions, notifications</sub></td>
  </tr>
  <tr>
    <td align="center"><b>🐙 GitHub</b></td>
    <td align="center"><b>🦊 GitLab</b></td>
    <td align="center"><b>🎨 Figma</b></td>
    <td align="center"><b>📊 Linear</b></td>
  </tr>
  <tr>
    <td align="center"><sub>PRs, issues, CI, releases, comments, code review</sub></td>
    <td align="center"><sub>MRs, issues, CI/CD, pipelines, merge requests</sub></td>
    <td align="center"><sub>Designs, components, variables, code generation, code connect</sub></td>
    <td align="center"><sub>Issues, projects, cycles, teams, triage, roadmaps</sub></td>
  </tr>
  <tr>
    <td align="center"><b>🗄️ dbt</b></td>
    <td align="center"><b>❄️ Snowflake</b></td>
    <td align="center"><b>🎭 Playwright</b></td>
    <td align="center"><b>📓 Jupyter</b></td>
  </tr>
  <tr>
    <td align="center"><sub>Parse, compile, test, selective run, CI validation</sub></td>
    <td align="center"><sub>Read-only SQL validation, warehouse introspection</sub></td>
    <td align="center"><sub>E2E tests, browser automation, snapshots, traces</sub></td>
    <td align="center"><sub>Scaffold, run, refactor notebooks — reproducible science</sub></td>
  </tr>
</table>

---

## Architecture

<div align="center">
<img src="static/architecture.svg" alt="agentic-workstation three-layer architecture" width="96%">
</div>

| Layer | Repo | Responsibility |
|-------|------|----------------|
| **L1** | **agentic-workstation** (thin, this repo) | Machine provisioning + host runner — chezmoi, packages, shell, LLM policy, tmux/Herdr, Toolkit installation, `dev-companion/runner` (thin, no embedded skills) |
| **L1.5** | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) | **Sole** capability distribution — 77 skills, 17 agents, 10 loops, profiles, MCP, prompts, packs (verify with `agent-toolkit inventory`) |
| **L3** | Project repos / agentic-harness | Overlays — project `AGENTS.md`, engagement packs, client skills, knowledge, personas |

Details and Mermaid diagrams: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

### Agent Toolkit Swarms — tmux + Herdr

> **Workstation installs tools, Toolkit owns orchestration.** agentic-workstation provisions the host dependencies (chezmoi + packages + shell + LLM policy + tmux + Herdr + OpenCode integration + Toolkit installation); all swarm orchestration, recipes, and isolated tmux sessions (`agent-toolkit-swarm-<run-id>`) are owned by [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit). Workstation provisions, Toolkit orchestrates.

- **tmux** — terminal multiplexer installed via your system package manager (`apt`/`brew`/`pacman`/`dnf`). Verified: `tmux -V`. Workstation uses an isolated socket `agent-toolkit-swarm-<run-id>` and never overwrites `~/.tmux.conf`.
- **Herdr** — terminal-native app for orchestrating agents. Installed idempotently via `brew` → `mise` → `curl -fsSL https://herdr.dev/install.sh | sh` fallback. Check: `herdr --version`. Skipped in CI unless `SWARM_FORCE_INSTALL=1`.
- **OpenCode Herdr integration** — `herdr integration install opencode` (idempotent). Creates `~/.config/opencode` if missing, safe and credential-free. Verify: `herdr integration list --json`. Update outdated integrations with the same command.

**Verify swarm provisioning:**

```bash
dots-doctor                 # includes tmux, herdr, and swarm checks
dots-doctor --json | jq
agent-toolkit swarm doctor  # toolkit-level swarm health check
```

**Run a swarm (Toolkit owns orchestration):**

```bash
herdr                                          # start Herdr app
herdr integration install opencode             # one-time OpenCode integration
agent-toolkit swarm doctor                     # validate swarm prerequisites
agent-toolkit swarm start --recipe pair --ui herdr --runner opencode "Implement feature X"
agent-toolkit swarm start --recipe pair --ui tmux --runner opencode "Implement feature X"
# See agent-toolkit docs: agent-toolkit swarm --help
```

Profiles `technical`, `non-technical`, `ai`, and `data` enable the swarm group (`install_group_swarm`) by default; opt-out via `custom` questionnaire. See [`docs/SWARM_SETUP.md`](docs/SWARM_SETUP.md), [`docs/PLATFORM_SUPPORT.md`](docs/PLATFORM_SUPPORT.md), and [`docs/AGENT_TOOLKIT.md`](docs/AGENT_TOOLKIT.md).

---

## 📂 Repository Map

```text
agentic-workstation/
├── home/                    # Chezmoi source state → your $HOME
├── docs/                    # Architecture, ADRs, maintainer guides
├── scripts/                 # Validation, install, and CI helpers
├── static/                  # Banner and media assets
├── .github/workflows/       # 12 CI workflows
├── AGENTS.md                # AI agent guidelines
├── CHANGELOG.md             # Release history
├── CONTRIBUTING.md          # How to contribute
├── SECURITY.md              # Security policy
├── install.sh               # Bootstrap installer (Unix)
├── install.ps1              # Bootstrap installer (Windows)
└── .chezmoiroot → home/     # Chezmoi source root
```

---

## 📋 Architecture Decisions

Key decisions are recorded as ADRs — immutable once accepted, superseded by new ADRs when revisited.

| ADR | Decision | Status |
| --- | --- | --- |
| [001](docs/adrs/001-chezmoi-home-source-state.md) | Use `home/` as chezmoi source state | ✅ Accepted |
| [002](docs/adrs/002-profile-driven-tooling.md) | Profile-driven tooling model | ✅ Accepted |
| [003](docs/adrs/003-ai-and-mcp-baseline.md) | AI and MCP baseline in shared local paths | ✅ Accepted |
| [004](docs/adrs/004-skills-compatibility-matrix.md) | Skills system with per-tool compatibility matrix | ✅ Accepted |
| [005](docs/adrs/005-llm-provider-abstraction.md) | LLM provider abstraction for dev companion runner | ✅ Accepted |
| [006](docs/adrs/006-multi-tool-portability.md) | Multi-tool portability via symlinks and thin adapters | ✅ Accepted |
| [007](docs/adrs/007-agentic-harness-three-layers.md) | Agentic harness with three-layer architecture | ✅ Accepted |
| [008](docs/adrs/008-dev-companion-queue-safety.md) | Dev companion queue with plan-only default | ✅ Accepted |
| [009](docs/adrs/009-keep-name-refresh-tagline.md) | Keep name, refresh tagline | ⏪ Superseded |
| [010](docs/adrs/010-rename-to-agentic-workstation.md) | Rename to agentic-workstation | ✅ Accepted |

---

## Personal DX Stack

<table>
  <tr>
    <td width="33%" valign="top">
      <strong>dotfiles</strong><br>
      <sub>The personal operating layer: shell, editor, terminal, packages, and day-to-day ergonomics.</sub>
      <br><br>
      <a href="https://github.com/ulises-jeremias/dotfiles"><code>ulises-jeremias/dotfiles</code></a>
    </td>
    <td width="34%" valign="top">
      <strong>agentic-workstation</strong><br>
      <sub>The AI-native workstation baseline: skills, agents, MCP templates, CLI helpers, and setup automation.</sub>
      <br><br>
      <a href="https://github.com/ulises-jeremias/agentic-workstation"><code>ulises-jeremias/agentic-workstation</code></a>
    </td>
    <td width="33%" valign="top">
      <strong>agentic-harness</strong><br>
      <sub>The running instance layer: persistent memory, indexed repos, personas, packs, and background loops.</sub>
      <br><br>
      <a href="https://github.com/ulises-jeremias/agentic-harness"><code>ulises-jeremias/agentic-harness</code></a>
    </td>
  </tr>
</table>

Together, these three projects form my personal workspace: a polished Developer Experience / UX system that optimizes setup, context switching, AI-assisted delivery, and daily workflow automation.

---

## 🛠️ Development Checks

```bash
bash scripts/check-markdown-tables.sh
bash scripts/check-shell-syntax.sh
bash scripts/validate-repo-structure.sh
git diff --check
```

> **Contributing:** See [CONTRIBUTING.md](CONTRIBUTING.md) for PR guidelines, commit conventions, and branch naming.

---

## 🔒 Security

Never commit credentials, tokens, or private keys. Use the [wiki credentials flow](https://github.com/ulises-jeremias/agentic-workstation/wiki/CREDENTIALS) for local secrets.

---

<div align="center">

**⭐ Star this repo** if you use it — it helps others discover it.

[Report a bug](https://github.com/ulises-jeremias/agentic-workstation/issues/new?template=BUG_REPORT.md) · [Request a feature](https://github.com/ulises-jeremias/agentic-workstation/issues/new?template=FEATURE_REQUEST.md)

<sub>Built with ❤️ for AI-assisted software delivery</sub>

</div>

## 👥 Contributors

<a href="https://github.com/ulises-jeremias/agentic-workstation/contributors">
  <img alt="Contributors" src="https://contrib.rocks/image?repo=ulises-jeremias/agentic-workstation"/>
</a>

Made with [contributors-img](https://contrib.rocks).
