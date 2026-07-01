# Architecture Decision Records

> Tracking significant architectural decisions for the workstation platform.

---

## What are ADRs?

Architecture Decision Records document the **context**, **decision**, and **consequences** of significant technical choices. They provide a historical record of why things are the way they are.

---

## Current ADRs

| ADR | Title | Status |
|-----|-------|--------|
| [001](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/001-chezmoi-home-source-state.md) | Use `home/` as chezmoi source state | Accepted |
| [002](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/002-profile-driven-tooling.md) | Profile-driven tooling model | Accepted |
| [003](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/003-ai-and-mcp-baseline.md) | AI and MCP baseline in shared local paths | Accepted |
| [004](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/004-skills-compatibility-matrix.md) | Skills system with per-tool compatibility matrix | Accepted |
| [005](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/005-llm-provider-abstraction.md) | LLM provider abstraction for dev companion runner | Accepted |
| [006](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/006-multi-tool-portability.md) | Multi-tool portability via symlinks and thin adapters | Accepted |
| [007](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/007-agentic-harness-three-layers.md) | Agentic harness with three-layer architecture | Accepted |

---

## Format

Each ADR follows this structure:

1. **Title** — short descriptive name
2. **Status** — Proposed / Accepted / Deprecated / Superseded
3. **Context** — why the decision was needed
4. **Decision** — what was decided
5. **Consequences** — positive and negative outcomes

---

## When to write an ADR

- Adding a new major component or tool
- Changing a fundamental architecture pattern
- Making a decision that's hard to reverse
- Choosing between significant alternatives

---

**Canonical doc:** [`docs/adrs/README.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/adrs/README.md)
