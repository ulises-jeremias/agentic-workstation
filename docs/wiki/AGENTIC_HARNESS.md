# Agentic Harness

> Three-layer architecture for AI-assisted development at agentic-workstation.

---

## Overview

The agentic harness is a framework for structuring AI agent interactions. It defines how agents discover context, make decisions, and deliver work — across any AI tool (Claude Code, OpenCode, Cursor, Windsurf).

---

## Three layers

| Layer | Name | Purpose |
|-------|------|---------|
| **L1** | Infrastructure | Workstation bootstrap, skills, agents (this repo) |
| **L2** | Session | Running workspace, knowledge base, personas, packs |
| **L3** | Delivery | Workflow execution, human gates, PR creation |

---

## Session lifecycle

1. **Init** — load workspace context, inject knowledge
2. **Discovery** — scan repo docs in fixed order (README → docs → AGENTS.md → ...)
3. **Plan** — break down work, identify risks
4. **Execute** — implement with quality checks
5. **Review** — self-review + human gate
6. **Deliver** — create PR, update tickets

---

## Personas

Personas constrain what an agent is allowed to do:

| Persona | Constraint |
|---------|-----------|
| `implementer` | Write code, bias toward action |
| `reviewer` | Analyze and critique, no changes |
| `researcher` | Explore and summarize, no implementation |
| `architect` | System design, tradeoffs, ADRs |

---

## Packs

Packs bundle context for a specific client or project:

- Repository paths and remote URLs
- Project/ticket IDs and conventions
- Tool-specific overrides
- Default automation level

---

## Key principles

- **Document-first**: Always read docs before code
- **`AGENTS.md` as contract**: Primary source of truth for agent behavior
- **Human gates**: Required between phases for non-trivial work
- **English artifacts**: All commits, PRs, and tickets in English

---

**Canonical doc:** [`docs/AGENTIC_HARNESS.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/AGENTIC_HARNESS.md)
