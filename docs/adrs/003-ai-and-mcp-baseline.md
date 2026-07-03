# ADR-003: AI and MCP baseline in shared local paths

## Status

Accepted

## Context

agentic-workstation needs a reusable AI enablement layer that provides:

- **Skills** — modular markdown documents that teach AI tools specific workflows
- **Prompts** — reusable internal prompt templates
- **MCP templates** — Model Context Protocol server configurations for AI tools
- **Agent configs** — `AGENTS.md`, `CLAUDE.md`, and tool-specific agent instructions

Key constraints:

- Credentials must **never** be committed to the repository
- Templates must work across Claude Code, OpenCode, Cursor, Copilot CLI, and pi agent
- The layer must be auditable (team leads can verify what's deployed)
- Skills and configs must be easy to update centrally via `chezmoi apply`

## Decision

Ship AI assets and MCP templates under `~/.local/share/agentic-workstation/` and enforce env-var-only secrets. The directory structure:

<!-- markdownlint-disable MD040 -->
```
~/.local/share/agentic-workstation/
├── skills/               # Bundled skills (managed by chezmoi)
├── skills-external/      # External skills (chezmoiexternal + dots-skills)
├── skills-registry.yaml  # Runtime registry for dots-skills
├── prompts/              # Reusable internal prompts
├── templates/            # Text templates
├── mcp/                  # MCP provider examples and wrappers
└── third-party/          # Attributed third-party excerpts (MIT)
```
<!-- markdownlint-enable MD040 -->

MCP templates are **examples only** — they contain no credentials and require explicit local configuration via environment variables.

## Consequences

### Positive

- Consistent, auditable AI baseline across the entire team
- No credential leakage through repository files
- Easier enablement across teams and projects
- Centralized updates via `chezmoi apply` propagate to all tools simultaneously
- MCP templates lower the barrier to AI tool adoption

### Negative

- `~/.local/share/agentic-workstation/` is a non-standard location that new contributors must learn
- MCP templates require manual credential setup per machine
- The separation between `skills/` (bundled) and `skills-external/` (external) adds cognitive overhead
