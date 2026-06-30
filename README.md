<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="static/hero-banner.svg">
  <source media="(prefers-color-scheme: light)" srcset="static/hero-banner.svg">
  <img alt="dots-ai" src="static/hero-banner.svg" width="800">
</picture>

<h1>dots-ai</h1>
<h3>Portable AI workstation tooling for real delivery work</h3>

<p><strong>Chezmoi-managed • Skills-first • Multi-tool • Cross-platform</strong></p>

[Wiki](https://github.com/ulises-jeremias/dots-ai/wiki) .
[Quick Start](https://github.com/ulises-jeremias/dots-ai/wiki/TECHNICAL_QUICKSTART) .
[Guided AI Install](https://github.com/ulises-jeremias/dots-ai/wiki/GUIDED_AI_INSTALL) .
[Integrations](https://github.com/ulises-jeremias/dots-ai/wiki/INTEGRATIONS) .
[Technical Docs](docs/) .
[Contributing](CONTRIBUTING.md)

<br>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![chezmoi](https://img.shields.io/badge/chezmoi-managed-blue?style=for-the-badge&logo=chezmoi&logoColor=white)](https://www.chezmoi.io/)
[![dots-ai](https://img.shields.io/badge/dots--ai-public-7c3aed?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ulises-jeremias)

<br>

[![Validate Workstation](https://github.com/ulises-jeremias/dots-ai/actions/workflows/validate-workstation.yml/badge.svg)](https://github.com/ulises-jeremias/dots-ai/actions/workflows/validate-workstation.yml)
[![Devcontainer Chezmoi Validate](https://github.com/ulises-jeremias/dots-ai/actions/workflows/devcontainer-chezmoi-validate.yml/badge.svg)](https://github.com/ulises-jeremias/dots-ai/actions/workflows/devcontainer-chezmoi-validate.yml)
[![Pre-commit](https://github.com/ulises-jeremias/dots-ai/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/ulises-jeremias/dots-ai/actions/workflows/pre-commit.yml)
[![MegaLinter v9](https://github.com/ulises-jeremias/dots-ai/actions/workflows/megalinter-v9.yml/badge.svg)](https://github.com/ulises-jeremias/dots-ai/actions/workflows/megalinter-v9.yml)
[![Security Scan](https://github.com/ulises-jeremias/dots-ai/actions/workflows/security-scan.yml/badge.svg)](https://github.com/ulises-jeremias/dots-ai/actions/workflows/security-scan.yml)
[![Release AI Assets](https://github.com/ulises-jeremias/dots-ai/actions/workflows/release-ai-assets.yml/badge.svg)](https://github.com/ulises-jeremias/dots-ai/actions/workflows/release-ai-assets.yml)

</div>

---

## What Is dots-ai?

`dots-ai` is a portable workstation baseline for AI-assisted software delivery. It installs a chezmoi-managed layer of AI skills, agents, MCP templates, CLI helpers, and dev companion tooling across Linux, macOS, and Windows.

The wiki is the source of truth for setup and day-to-day usage. The repository `docs/` directory is for technical references, architecture notes, maintainer contracts, and ADRs.

## Highlights

- **Skills-first AI setup**: reusable workflows for coding agents, delivery tools, docs, PRs, and integrations.
- **Multi-tool portability**: shared skill registration for Claude Code, OpenCode, Cursor, Copilot CLI, and compatible tools.
- **Guided integration setup**: GitHub, GitLab, ClickUp, Jira, Confluence, Slack, Figma, Linear, Notion, and MCP templates.
- **Chezmoi source state**: deterministic home-directory management with profiles and questionnaire-driven options.
- **CLI guardrails**: `dots-*` helpers for health checks, skills, environment loading, updates, and dev companion workflows.
- **Maintainer checks**: shell syntax, Markdown table validation, repo structure validation, security scans, and CI automation.

## Quick Start

Start from the wiki unless you are maintaining the repository itself:

```bash
chezmoi init --apply ulises-jeremias/dots-ai
```

Need only the AI layer? Use the guided flow:

```bash
bash scripts/install-skills.sh
```

See [Wiki Quick Start](https://github.com/ulises-jeremias/dots-ai/wiki/TECHNICAL_QUICKSTART) and [Guided AI Install](https://github.com/ulises-jeremias/dots-ai/wiki/GUIDED_AI_INSTALL) for supported paths and prerequisites.

## Start Here

| Need | Go to |
|---|---|
| Install the workstation | [Wiki Quick Start](https://github.com/ulises-jeremias/dots-ai/wiki/TECHNICAL_QUICKSTART) |
| Install only AI skills and agents | [Guided AI Install](https://github.com/ulises-jeremias/dots-ai/wiki/GUIDED_AI_INSTALL) |
| Choose profiles or answer prompts | [Profiles](https://github.com/ulises-jeremias/dots-ai/wiki/PROFILES) and [Questionnaire](https://github.com/ulises-jeremias/dots-ai/wiki/QUESTIONNAIRE) |
| Configure credentials | [Credentials](https://github.com/ulises-jeremias/dots-ai/wiki/CREDENTIALS) |
| Configure ClickUp, Jira, Figma, Slack, etc. | [Integrations](https://github.com/ulises-jeremias/dots-ai/wiki/INTEGRATIONS) |
| Use `dots-*` commands | [CLI](https://github.com/ulises-jeremias/dots-ai/wiki/CLI) |
| Troubleshoot setup | [Troubleshooting](https://github.com/ulises-jeremias/dots-ai/wiki/TROUBLESHOOTING) |
| Understand architecture | [Technical Docs](docs/) |

## What It Provides

| Area | Outcome |
|---|---|
| Workstation bootstrap | Profile-driven chezmoi source state |
| AI layer | Shared skills and agents for supported AI coding tools |
| Integrations | Guided setup for GitHub, GitLab, ClickUp, Jira, Confluence, Slack, Figma, Linear, and Notion |
| CLI helpers | `dots-*` commands for validation, skills, updates, env loading, and dev companion workflows |
| MCP templates | Provider templates under `~/.local/share/dots-ai/mcp/` after apply |
| Technical governance | Architecture docs, ADRs, validation scripts, and CI checks |

## Related Project

Pair this workstation layer with [`ai-workspace`](https://github.com/ulises-jeremias/ai-workspace) for persistent memory, indexed repositories, personas, packs, and background job orchestration.

## Repository Map

| Path | Purpose |
|---|---|
| `home/` | Chezmoi source state applied to the user machine |
| `docs/wiki/` | User-facing wiki source |
| `docs/` | Technical references and maintainer contracts |
| `docs/adrs/` | Architecture Decision Records |
| `scripts/` | Validation, release, and install support scripts |
| `.github/workflows/` | CI and release automation |

## Architecture Decisions

Key decisions are recorded as [ADRs](docs/adrs/) — immutable once accepted,
superseded by new ADRs when revisited.

| ADR | Decision | Status |
|-----|----------|--------|
| [001](docs/adrs/001-chezmoi-home-source-state.md) | Use `home/` as chezmoi source state | Accepted |
| [002](docs/adrs/002-profile-driven-tooling.md) | Profile-driven tooling model | Accepted |
| [003](docs/adrs/003-ai-and-mcp-baseline.md) | AI and MCP baseline in shared local paths | Accepted |
| [004](docs/adrs/004-skills-compatibility-matrix.md) | Skills system with per-tool compatibility matrix | Accepted |
| [005](docs/adrs/005-llm-provider-abstraction.md) | LLM provider abstraction for dev companion runner | Accepted |
| [006](docs/adrs/006-multi-tool-portability.md) | Multi-tool portability via symlinks and thin adapters | Accepted |
| [007](docs/adrs/007-agentic-harness-three-layers.md) | Agentic harness with three-layer architecture | Accepted |
| [008](docs/adrs/008-dev-companion-queue-safety.md) | Dev companion queue with plan-only default | Accepted |

## Development Checks

```bash
bash scripts/check-markdown-tables.sh
bash scripts/check-shell-syntax.sh
bash scripts/validate-repo-structure.sh
git diff --check
```

## Security

Never commit credentials, tokens, or private keys. Use the wiki credentials flow for local secrets: [Credentials](https://github.com/ulises-jeremias/dots-ai/wiki/CREDENTIALS).
