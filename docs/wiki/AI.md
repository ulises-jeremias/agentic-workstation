# AI Layer

> How agentic-workstation provisions AI skills, agents, prompts, and templates.

---

## Overview

AI resources are deployed to `~/.local/share/agentic-workstation/` during `chezmoi apply`:

| Directory | Contents |
|-----------|----------|
| `prompts/` | Reusable internal prompts |
| `skills/` | Bundled skills (managed by chezmoi) + `skill-catalog.yaml` |
| `skills-external/` | External skills installed by `dots-skills` |
| `templates/` | Reusable text templates |
| `mcp/` | MCP provider examples and wrappers |
| `skills-registry.yaml` | Runtime registry for skill management |

---

## Skills

Skills teach AI tools how to perform specific workflows. Each skill has:

- `SKILL.md` — instructions read by AI tools
- `skill.json` — manifest with compatibility matrix

Skills are symlinked to each AI tool's config directory by `dots-skills sync`:

| Tool | Skills directory |
|------|-----------------|
| Claude Code | `~/.claude/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Cursor | `~/.cursor/skills/` |
| Copilot CLI | `~/.copilot/skills/` |

→ Full details: [Skills System](SKILLS)

---

## Agents

15 specialized subagents are installed to tool-specific directories:

- `~/.claude/agents/` (Claude Code)
- `~/.config/opencode/agents/` (OpenCode)
- Cursor and Windsurf rules directories

Use `@agent-name` to invoke in Claude Code or OpenCode.

---

## The Ralph Loop

The workstation implements a [Ralph Loop](https://ghuntley.com/loop/) pattern:

| Ralph concept | What the workstation provides |
|---------------|-------------------------------|
| **Backing specifications** | `AGENTS.md` templates deployed to each repo/session |
| **Context engineering** | Skills that prime each loop with domain context |
| **Persistent memory** | `ai-workspace/knowledge/` knowledge base |
| **Fix the loop** | `dots-harness-knowledge-sync` skill |
| **Monolithic orchestrator** | `dots-workstation-assistant` as single entry point |

---

**Canonical doc:** [`docs/AI_LAYER.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/AI_LAYER.md)
