# Architecture Decision Records

This directory tracks major architectural decisions for `dots-ai`.

> [!NOTE]
> ADRs are immutable once accepted. If a decision is revisited, write a new ADR that **supersedes** the original rather than editing it.

## Format

Each ADR follows this structure:

- **Status**: Proposed, Accepted, Superseded, Deprecated
- **Context**: The situation and constraints that led to this decision
- **Decision**: What was decided, with key factors
- **Consequences**: Positive and negative impacts

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [001](001-chezmoi-home-source-state.md) | Use `home/` as chezmoi source state | Accepted |
| [002](002-profile-driven-tooling.md) | Profile-driven tooling model | Accepted |
| [003](003-ai-and-mcp-baseline.md) | AI and MCP baseline in shared local paths | Accepted |
| [004](004-skills-compatibility-matrix.md) | Skills system with per-tool compatibility matrix | Accepted |
| [005](005-llm-provider-abstraction.md) | LLM provider abstraction for dev companion runner | Accepted |
| [006](006-multi-tool-portability.md) | Multi-tool portability via symlinks and thin adapters | Accepted |
| [007](007-agentic-harness-three-layers.md) | Agentic harness with three-layer architecture | Accepted |
| [008](008-dev-companion-queue-safety.md) | Dev companion queue with plan-only default | Accepted |
| [009](009-keep-name-refresh-tagline.md) | Keep name, refresh tagline | Superseded by 010 |
| [010](010-rename-to-agentic-workstation.md) | Rename to agentic-workstation | Accepted |

---

## See Also

- [ARCHITECTURE.md](../ARCHITECTURE.md) — High-level architecture overview
- [SKILLS.md](../SKILLS.md) — Skills system documentation
- [DEV_COMPANION.md](../DEV_COMPANION.md) — Dev companion layers
- [AGENTIC_HARNESS.md](../AGENTIC_HARNESS.md) — Three-layer agentic framework
