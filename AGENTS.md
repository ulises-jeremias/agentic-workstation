# AI Agent Guidelines for agentic-workstation

> For AI coding assistants and automation agents.
> Last Updated: 2026-03-16

## Purpose

This repository provides a reusable `chezmoi`-based agentic-workstation baseline for agentic-workstation.

**agentic-workstation's role is machine provisioning**: chezmoi, shell tools, packages, and LLM policy. Skills, agent personas, and profiles are distributed by [`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit) — a separate repository installed automatically during `chezmoi apply`. `dots-skills` delegates to `agent-toolkit` for skill sync; `dots-loop` wraps `agent-toolkit loop`.

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

## Skills and agents

Skills, agent personas, and loop templates are distributed by [`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit).

- **To install or update**: `dots-skills install-toolkit` (or `pip install agent-toolkit-cli && agent-toolkit install`)
- **Skills routing**: `dots-skills sync` reads each skill's compatibility manifest and creates symlinks in per-tool directories (`~/.claude/skills/`, `~/.config/opencode/skills/`, etc.)
- **Loop templates**: `agent-toolkit loop init <name>` or `dots-loop init <name>`
- **Bundled machine-local skills**: a small set ships in this repo for machine-specific workflows (`dots-workstation-triage`, `dots-workstation-assistant`, `dots-workstation-dev-companion`)

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
