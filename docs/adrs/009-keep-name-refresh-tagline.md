# ADR-009: Keep name, refresh tagline

## Status

Superseded by [ADR-010](010-rename-to-agentic-workstation.md)

## Context

As the project evolved from a personal chezmoi dotfiles repo to a portable agentic workstation baseline, contributors and users questioned whether the name `dots-ai` still fit. Two main alternatives emerged during issue #20 discussion:

1. **Rebrand** to a new name that better conveys the project's scope (agentic workstation, delivery automation, multi-tool orchestration)
2. **Keep `dots-ai`** but refresh the tagline to accurately describe what the project has become

The name `dots-ai` has existing recognition, a growing wiki, published integrations, and references in documentation, CI workflows, and community forks. A full rename would require updating dozens of references across the repo, the wiki, badges, and external tooling configs.

## Decision

Keep the name `dots-ai` and adopt a refreshed tagline that reflects the current scope and ambition:

**Tagline:** "Agentic Workstation Baseline — chezmoi-managed skills, agents, MCP, and loops for AI-assisted delivery."

**GitHub repo description:** "Chezmoi-managed agentic workstation baseline for AI-assisted software delivery."

All existing references, badges, URLs, and tooling remain unchanged. Future documentation should use the new tagline alongside the established name.

## Consequences

### Positive

- No migration cost — all existing links, docs, badges, and tooling continue to work
- Preserves brand recognition and community familiarity
- The refreshed tagline accurately describes the project's scope (skills, agents, MCP, delivery loops)
- Quick to implement — single ADR, README update, and repo description change

### Negative

- The name `dots-ai` remains somewhat ambiguous (doesn't explicitly say "workstation baseline" or "delivery")
- Newcomers may still need the tagline to understand the project's purpose
- Missed opportunity for a clean break and a more descriptive project name
