# AI Agent Guidelines for agentic-workstation

> For AI coding assistants and automation agents.
> Last Updated: 2026-03-16

## Purpose

This repository provides a reusable `chezmoi`-based agentic-workstation baseline for agentic-workstation.

**agentic-workstation's role is thin-host machine provisioning**: chezmoi, shell tools, packages, LLM policy, tmux/Herdr, and Toolkit installation (via `dots-skills install-toolkit`). **Workstation installs tools, Toolkit owns orchestration** (swarm recipes, loops, generic queue). Skills, agent personas, and profiles are distributed by [`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit) — a separate repository installed automatically during `chezmoi apply`. `dots-skills` delegates to `agent-toolkit` for skill sync; `dots-loop` wraps `agent-toolkit loop`; `dots-devcompanion` runner + policy stays host-specific in Workstation (LLM policy, `env.d`), while `agent-toolkit devcompanion` owns generic queue behavior.

The bundled **`agentic-workstation-assistant`** skill is the **agentic-workstation Assistant**: use it **in any repository** (including client work), not only this checkout. It instructs agents to **inspect project documentation in a fixed order** (README → `docs/` → `AGENTS.md` → CONTRIBUTING → PR templates → official scripts → devcontainer → CI → configs → code), to **cite sources**, and to treat **`AGENTS.md` as the primary agent contract** when present. On this repo it also uses `docs/` and `dots-*`; elsewhere it still applies the same repo-inspection model plus machine-local agentic-workstation tooling when relevant.

## Core Principles

1. Keep the baseline simple and extensible.
2. Never commit secrets, tokens, or private credentials.
3. Prefer profile-driven configuration over host-specific logic.
4. Keep scripts idempotent and safe to re-run.
5. Treat documentation as part of the product.

## Script Standards

All shell scripts must:

- use `set -eo pipefail`
- avoid destructive behavior by default
- detect OS before package manager operations
- skip already-installed tools
- print clear human-readable error messages

## Naming and Structure

- Repository root is not the `chezmoi` source state.
- `.chezmoiroot` must point to `home`.
- Internal helper commands use `dots-` prefix.
- Keep docs in uppercase file names under `docs/`.

## Ecosystem — Three-Tier Model

This repo is **L1 (machine provisioning)** in a three-tier personal DX stack:

| Layer | Repo | Role |
|-------|------|------|
| **L1** | **agentic-workstation** (this repo) | Machine provisioning — chezmoi, shell, packages, LLM policy |
| **L1.5** | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) | Capability distribution — 116+ skills, loops, profiles, MCP |
| **L3** | [agentic-harness](https://github.com/ulises-jeremias/agentic-harness) | AI workspace scaffold for multi-repo orchestration |

## Skills and agents

Skills, agent personas, and loop templates are distributed by [`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit).

```bash
# Install agent-toolkit (done automatically by chezmoi apply)
uvx --from 'agent-toolkit-cli>=1.11.0' agent-toolkit  # one-shot, no install required
brew install ulises-jeremias/homebrew-tap/agent-toolkit
yay -S agent-toolkit-bin                               # Arch Linux via AUR (V binary)
uv tool install --force 'agent-toolkit-cli>=1.11.0'    # V launcher wheel

# Install/update skills and profiles
agent-toolkit install [--force]                # deploy to all detected AI tools
dots-skills install-toolkit                    # same — also runs dots-skills sync

# Discover capabilities
agent-toolkit inventory                        # list all 116+ skills
agent-toolkit doctor                           # verify installation health
dots-skills list                               # list skills with per-tool status

# Loops
agent-toolkit loop init <name>                 # scaffold from template
agent-toolkit loop run <name>                  # execute one iteration
agent-toolkit loop status                      # show all loop instances

# MCP providers
agent-toolkit mcp list                         # available providers
agent-toolkit mcp setup <provider>             # interactive setup wizard
```

- **Bundled machine-local skills**: a small set ships in this repo for machine-specific workflows (`dots-workstation-triage`, `dots-workstation-assistant`, `dots-workstation-dev-companion`)
- `dots-skills sync` reads SKILL.md compatibility and creates symlinks in `~/.claude/skills/`, `~/.config/opencode/skills/`, etc.


See [`docs/AGENT_TOOLKIT.md`](docs/AGENT_TOOLKIT.md) for the full integration reference.

## Required Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/AGENT_TOOLKIT.md`](docs/AGENT_TOOLKIT.md)
- [`docs/AI_LAYER.md`](docs/AI_LAYER.md)
- [`docs/MCP_TEMPLATES.md`](docs/MCP_TEMPLATES.md)
- [`docs/CLIENT_AI_PLAYBOOKS.md`](docs/CLIENT_AI_PLAYBOOKS.md)
- [`docs/DEV_COMPANION.md`](docs/DEV_COMPANION.md)
- [`docs/DEV_COMPANION_LLM.md`](docs/DEV_COMPANION_LLM.md)
- [`docs/wiki/`](docs/wiki/) (wiki-synced content)
- [`docs/adrs/`](docs/adrs/) (architecture decisions)

## CI/Monitoring Scripts

- Use `grep -wF` or `==` for exact-word matching in CI-wait scripts — never bare `grep pattern` that matches substrings (e.g. "skipping" matching "skip")
- Verify runbook/doc paths exist in target repos before referencing them in generated loops
- Test monitor scripts for false ALL_DONE events before arming
- Use exponential backoff: start at 15s, double up to 60s — no fixed 5s polling
- Prefer a dedicated `ci-wait` helper (from `ai-workspace/bin/ci-wait`) over inline monitoring logic

## Cross-Repo Links

- **agent-toolkit** → [`AGENTS.md`](https://github.com/ulises-jeremias/agent-toolkit/blob/main/AGENTS.md) | [`README.md`](https://github.com/ulises-jeremias/agent-toolkit)
- **agentic-harness** → [`AGENTS.md`](https://github.com/ulises-jeremias/agentic-harness/blob/main/AGENTS.md) | uses `agent-toolkit` for all workspace operations
