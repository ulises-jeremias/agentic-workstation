# agentic-workstation Wiki

> agentic-workstation private workstation platform — bootstrap, AI skills, agents, CLI helpers, and dev companion.

Welcome to the **agentic-workstation** knowledge base. This wiki covers installation, configuration, AI tooling, and operations for agentic-workstation developers.

---

## What is agentic-workstation?

`agentic-workstation` standardizes AI developer tooling for developers across **Linux**, **macOS**, and **Windows**. It provisions:

For persistent workspace memory, project packs, personas, and indexed repository
context, pair this workstation layer with
[`ai-workspace`](https://github.com/ulises-jeremias/ai-workspace).

| Area | What you get |
|------|-------------|
| **Bootstrap** | Idempotent `chezmoi` source state with profile-driven behavior |
| **Skills** | 17+ bundled + opt-in JIRA/Confluence packs for Claude Code, OpenCode, Cursor, Windsurf, Copilot |
| **Agents** | 15 specialized subagents (code review, architecture, security, TDD, etc.) |
| **CLI** | `dots-*` commands for health checks, skill management, updates |
| **Dev Companion** | LLM-powered background job runner with multi-provider support |
| **MCP** | Ready-to-use GitHub, ClickUp, and Slack server templates |

---

## Quick links

### 🚀 Getting Started

- [Technical Quickstart](TECHNICAL_QUICKSTART) — 5-step bootstrap
- [Guided AI Install](GUIDED_AI_INSTALL) — skills-only setup
- [Chezmoi Workflow](CHEZMOI) — init, apply, and update flows
- [Profiles](PROFILES) — profile-to-package-group mapping
- [Init Questionnaire](QUESTIONNAIRE) — how to answer setup prompts
- [Windows Setup](WINDOWS) — WSL2, Git Bash, and skills-only modes
- [Releases & Updates](RELEASES) — update and release flows

### 🤖 AI System

- [AI Overview](AI) — skills system, agents, and the Ralph Loop
- [Skills System](SKILLS) — manifests, registry, compatibility, publishing
- [Dev Companion](DEV_COMPANION) — companion layers and delivery workflows
- [LLM Providers](LLM_PROVIDERS) — provider priority and configuration
- [Agentic Harness](AGENTIC_HARNESS) — three-layer architecture, personas, packs

### 🛠️ Tools & Reference

- [CLI Reference](CLI) — all `dots-*` commands with subcommands
- [MCP Templates](MCP) — Model Context Protocol server setup
- [Integrations Overview](INTEGRATIONS) — guided setup for each external service
- [Architecture](ARCHITECTURE) — layered model and design principles
- [ADRs](ADRS) — architecture decision records

### 📋 Operations

- [Security](SECURITY) — security practices and scanning
- [Troubleshooting](TROUBLESHOOTING) — common issues and fixes
- [Changelog](CHANGELOG) — version history
- [Contributing](CONTRIBUTING) — how to contribute

---

## Canonical documentation

> **Note:** This wiki provides user-friendly summaries. The canonical (full-depth) documentation lives in the [`docs/`](https://github.com/ulises-jeremias/agentic-workstation/tree/main/docs) directory of the repository.
