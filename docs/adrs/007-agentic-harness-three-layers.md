# ADR-007: Agentic harness with three-layer architecture

## Status

Accepted

## Context

agentic-workstation needed a principled framework for AI-assisted software delivery that:

- Separates **infrastructure** (this workstation), **running instances** (workspaces), and **application repos** (client projects)
- Supports both **interactive** (IDE-first) and **background** (queue-based) execution
- Implements the **Ralph Loop** pattern: backing specifications → context engineering → persistent memory → fix the loop
- Allows **personas** to constrain agent behavior (implementer, reviewer, researcher, architect)
- Enables **account packs** to isolate client-specific context and credentials

Previous approaches had skills, configs, and runtime state mixed together, making it hard to reason about what belongs where and what each layer is responsible for.

## Decision

Implement a **three-layer architecture**:

| Layer | Purpose | Example |
|-------|---------|---------|
| **L1 — Infrastructure** | Tooling baseline, skills, agent configs, CLI helpers | `agentic-workstation` (this repo) |
| **L2 — Running Instance** | Session state, knowledge base, workspace context, packs | `ai-workspace` |
| **L3 — Application** | Client project repos with `AGENTS.md` and project-specific configs | Any client repo |

Each layer has clear ownership:

- **L1** is managed by chezmoi and updated centrally
- **L2** is per-developer and accumulates knowledge across sessions
- **L3** is per-project and follows the project's own conventions

The **Ralph Loop** maps onto this architecture:
- Backing specs → `AGENTS.md` templates (L1)
- Context engineering → Skills (L1) + Packs (L2)
- Persistent memory → Knowledge base (L2)
- Fix the loop → `dots-harness-knowledge-sync` skill (L1→L2)

## Consequences

### Positive

- Clear separation of concerns across three layers
- Each layer can evolve independently
- The Ralph Loop pattern ensures the system improves with use
- Personas provide safety constraints for multi-agent orchestration
- Account packs enforce client isolation without code changes

### Negative

- Three layers add conceptual complexity for new contributors
- The relationship between L1 (shipped) and L2 (runtime) requires documentation
- Packs must be maintained per-client engagement
- The Ralph Loop's "persistent memory" depends on the workspace being available
