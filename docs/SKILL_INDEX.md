# Skill Index

> Thin workstation — skill catalog is delegated to [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit).
> No embedded `skill.json` manifests are shipped in this repository.
> Run `agent-toolkit skills list` at runtime to list the 77 cross-domain skills,
> or see [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) for the full catalog reference.

> To regenerate from the toolkit catalog, ensure `agent-toolkit` is installed and run:
> `agent-toolkit skills list` or `python3 scripts/dots-skills-search.py generate-index` (thin placeholder).

## Thin-workstation skills (workstation-specific only)

| Skill | Purpose |
|-------|---------|
| `dots-workstation-assistant` | Workspace orchestration and routing |
| `dots-workstation-triage` | Workstation health triage |
| `dots-workstation-dev-companion` | Dev companion delivery layer |
| `dots-workstation-workflow-generic-project` | Generic project delivery phases |
| `dots-workstation-workflow-client-bootstrap` | Client bootstrap workflow |
| `dots-slack-assistant` | Slack workspace ops |
| `dots-harness-knowledge-sync` | Session knowledge persistence |

> All other cross-domain skills (116+ skills across 14 domains — `delivery`, `forge`, `integrations`, `data`, `tooling`, etc.)
> are provided by `agent-toolkit` via `dots-skills install-toolkit`
> and installed at `~/.local/share/agentic-workstation/skills-external/agent-toolkit/`.
> Third-party packs (Jira and Confluence) live in `skills-external/{jira,confluence}-assistant/` and never in `plugins/`.

## See Also

- [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) — full capability catalog (116+ skills, 17 agents, 10 loops)
- [SKILLS.md](SKILLS.md) — skill system and lifecycle (thin workstation)
- [ARCHITECTURE.md](ARCHITECTURE.md) — thin workstation architecture
