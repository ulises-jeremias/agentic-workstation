# ADR-006: Multi-tool portability via symlinks and thin adapters

## Status

Accepted

## Context

The agentic-workstation workstation must support multiple AI tools simultaneously:

- Claude Code, OpenCode, Cursor, GitHub Copilot CLI, pi agent, Windsurf
- Each tool has its own config directory and skill loading mechanism
- Users may switch between tools or use multiple tools on the same machine
- Agent configuration files (`AGENTS.md`, `CLAUDE.md`, `copilot-instructions.md`) overlap in purpose

Maintaining separate copies of skills and agents for each tool would be:

- Fragile — updates would need to be applied N times
- Error-prone — copies inevitably drift
- Wasteful — most content is identical across tools

## Decision

Use **symlinks** as the primary portability mechanism:

- Skills are stored once in `~/.local/share/agentic-workstation/skills/` and symlinked to each tool's directory by `dots-skills sync`
- Agent instructions are symlinked between tools (e.g. `CLAUDE.md` → `AGENTS.md`, `copilot-instructions.md` → `AGENTS.md`)
- Per-tool **thin adapters** handle format differences (e.g. Claude Code's `allowed-tools` frontmatter)

The chezmoi template system generates tool-specific variants where needed:

- `AGENTS.md.tmpl` — canonical agent instructions
- `CLAUDE.md.tmpl` — symlink target or thin wrapper
- `copilot-instructions.md.tmpl` — symlink target

## Consequences

### Positive

- Single source of truth for all skills and agent instructions
- Updates propagate immediately via symlinks
- Adding a new AI tool only requires adding a symlink target to `dots-skills sync`
- Portability across Cursor, Claude Code, OpenCode, Copilot CLI, and pi agent

### Negative

- Symlinks can break if the source directory is moved or deleted
- Some tools may not follow symlinks correctly on all platforms (Windows Git Bash)
- Tool-specific features (e.g. Claude's `allowed-tools`) require knowledge of which fields are safe to ignore
- `dots-skills sync` must be run after any skill installation or removal
