# CLAUDE.md — Claude Code Instructions

> See AGENTS.md for full standards.

## Agents

agentic-workstation agents are deployed to `~/.claude/agents/` by chezmoi.
All agent files use the `dots-workstation-` prefix (e.g. `dots-workstation-code-reviewer.md`).

## Usage

```bash
@dots-workstation-planner design a feature
@dots-workstation-code-reviewer review this code
@dots-workstation-reference-lookup React state patterns
```

## agentic-workstation Skills

Delegate to skills:
- `dbt-validation` — dbt checks
- `snowflake-validation` — Snowflake checks
- `jira-*` — Jira operations
- `confluence-*` — Confluence operations
