# AI Agent Guidelines for agentic-workstation

> For AI coding assistants and automation agents.
> Last Updated: 2026-03-16

## Purpose

This repository provides a reusable `chezmoi`-based agentic-workstation baseline for agentic-workstation.

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

## Required Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/AI_LAYER.md`](docs/AI_LAYER.md)
- [`docs/MCP_TEMPLATES.md`](docs/MCP_TEMPLATES.md)
- [`docs/CLIENT_AI_PLAYBOOKS.md`](docs/CLIENT_AI_PLAYBOOKS.md)
- [`docs/DEV_COMPANION.md`](docs/DEV_COMPANION.md)
- [`docs/DEV_COMPANION_LLM.md`](docs/DEV_COMPANION_LLM.md)
- [`docs/wiki/`](docs/wiki/) (wiki-synced content)
- [`docs/adrs/`](docs/adrs/) (architecture decisions)
