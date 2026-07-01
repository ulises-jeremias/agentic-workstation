# AGENTS.md — agentic-workstation Project Standards

> Cross-tool standard. See: https://github.com/ulises-jeremias/agentic-workstation

## Quick Reference

agentic-workstation agents are deployed per-tool by chezmoi:
- OpenCode: `~/.config/opencode/agents/`
- Claude Code: `~/.claude/agents/`
- Cursor / Windsurf: `~/.cursor/rules/` / `~/.windsurf/rules/` (`.mdc` files)

All agent files use the `dots-workstation-` prefix (e.g. `dots-workstation-code-reviewer.md`).

## Available Agents

| Agent | Purpose |
|------|---------|
| dots-workstation-planner | Feature planning |
| dots-workstation-code-reviewer | Code quality review |
| dots-workstation-security-reviewer | Security scanning |
| dots-workstation-tdd-guide | TDD workflow |
| dots-workstation-reference-lookup | public examples examples |
| dots-workstation-client-delivery | Client delivery overlays (workspace packs) |

## For Full Agent List

See: `~/.config/opencode/agents/` or `~/.claude/agents/`

## Tech Stack

- Frontend: React, Next.js, TypeScript, Tailwind
- Backend: Node.js, Python (FastAPI), Go
- Database: PostgreSQL, Supabase, Snowflake
- Data: dbt, AWS Glue

## agentic-workstation Conventions

1. README.md → 2. docs/*.md → 3. AGENTS.md → 4. CONTRIBUTING.md → 5. PR templates → 6. Makefile/npm scripts → 7. devcontainer → 8. code

**Never:** commit secrets, use `var`, skip tests
