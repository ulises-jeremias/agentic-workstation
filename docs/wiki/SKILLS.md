# Skills System

> How agentic-workstation skills are defined, distributed, installed, and made available to AI tools.

---

## What is a skill?

A **skill** is a markdown document (plus optional supporting assets) that teaches an AI tool how to perform a specific workflow. Skills are loaded by AI tools at startup.

Each skill contains:

- `SKILL.md` — instructions read by AI tools (frontmatter + body)
- `skill.json` — manifest declaring source, version, and per-tool compatibility

---

## Bundled skills

| Skill | Purpose |
|-------|---------|
| `dots-workstation-assistant` | Workspace orchestration and routing |
| `dots-workstation-dev-companion` | General dev companion delivery layer |
| Workspace pack overlays | Client/account overlays |
| `dots-workstation-workflow-generic-project` | Generic project delivery phases |
| `dev-assistant` | Repository inspection and discovery |
| `dev-companion` | Delivery workflow pattern |
| `github-cli-workflow` | GitHub PR creation |
| `gitlab-cli-workflow` | GitLab MR creation |
| `dbt-validation` | dbt parse/compile/test |
| `snowflake-validation` | Read-only Snowflake checks |
| `clickup-cli` | ClickUp task management |
| `slack-cli` | Slack CLI for app development |
| `ui-ux-pro-max` | UI/UX design intelligence |
| `dots-harness-knowledge-sync` | Session knowledge persistence |
| `dots-workstation-output-handshake` | Required gate for final deliverables: destination + human review |
| `dots-workstation-prd`, `dots-workstation-trd`, `dots-workstation-adr` | Product, technical, and architecture decision artifacts |
| `dots-workstation-planning`, `dots-workstation-development-workflow` | Planning, estimation, workflow, DoR, DoD, and validation defaults |
| `dots-workstation-work-item`, `dots-workstation-epic`, `dots-workstation-user-story`, `dots-workstation-task`, `dots-workstation-bug`, `dots-workstation-incident` | Work item templates and routing |
| `dots-workstation-meeting-minutes`, `dots-workstation-decision-log`, `dots-workstation-agreement`, `dots-workstation-spike` | Meeting, decision, agreement, and research artifacts |
| `dots-workstation-project-assessment`, `dots-workstation-project-assessment-evidence`, `dots-workstation-technical-unit-assessment`, `dots-workstation-management-unit-assessment` | Interactive project assessments, evidence maps, and unit scorecards |

---

## Best Practices and Assessment Skills

The bundled Best Practices skills are intentionally atomic. The orchestrator loads the smallest skill needed instead of one large process document.

### Output handshake

Before producing a final artifact, the assistant must ask:

- Where should the final content live?
- Who will review it?

This applies to PRDs, TRDs, ADRs, work items, meeting minutes, assessment reports, scorecards, evidence maps, incidents, spikes, and PR/MR bodies.

### Project assessments

Project assessments use four skills:

| Skill | Role |
|-------|------|
| `dots-workstation-project-assessment` | Defines assessment purpose, period, audience, units, findings, and action plan |
| `dots-workstation-project-assessment-evidence` | Asks where evidence lives and tracks source quality, freshness, missing evidence, assumptions, and confidence |
| `dots-workstation-technical-unit-assessment` | Scores technical workloads: repositories, frontend, backend, infrastructure, data, UI/UX, and AI-native structural readiness |
| `dots-workstation-management-unit-assessment` | Scores management scope: governance, delivery, collaboration, culture, and AI-native management readiness |

The assistant must not score indicators without evidence. If evidence is unavailable, it should mark the indicator as missing evidence, not assessed, or low confidence with the assumption clearly stated.

### Example chats

End-to-end assessment:

```text
User: Run a project assessment for this engagement.
Assistant: I will use dots-workstation-project-assessment. Where should the final report live, and who will review it?
User: Put the draft in docs/assessment.md. I will review it.
Assistant: What period and units should be assessed? Should this cover management, technical units, or both?
User: Last quarter, both. Backend and data pipelines are in scope.
Assistant: I will collect evidence first. Where are the repositories, board, planning docs, dashboards, incidents, decisions, and stakeholder feedback?
```

Technical-only assessment:

```text
User: Assess the cloud infrastructure and CI/CD maturity.
Assistant: I will use dots-workstation-project-assessment-evidence and dots-workstation-technical-unit-assessment. Where are the IaC repo, pipeline history, deployment docs, monitoring dashboards, security scans, and incident records?
```

Management-only assessment:

```text
User: Review governance and delivery health.
Assistant: I will use dots-workstation-project-assessment-evidence and dots-workstation-management-unit-assessment. Where are the board, backlog, planning notes, retrospectives, risks, delivery reports, decisions, agreements, and stakeholder feedback?
```

Missing evidence:

```text
User: Score observability based on what you can see.
Assistant: I can inspect the repository, but observability scoring also needs dashboards, alerts, logs, or incident evidence. Where can I find those sources? If they are unavailable, I will mark the indicator as missing evidence or low confidence.
```

---

## External skills (opt-in)

| Skill | Install flag |
|-------|-------------|
| JIRA Assistant (14 skills) | `install_skill_jira_assistant = true` |
| Confluence Assistant (17 skills) | `install_skill_confluence_assistant = true` |

## Related integrations

- [ClickUp](INTEGRATION_CLICKUP)
- [Jira](INTEGRATION_JIRA)
- [Confluence](INTEGRATION_CONFLUENCE)
- [Figma](INTEGRATION_FIGMA)

---

## Skill lifecycle

1. Skills are defined in `home/dot_local/share/agentic-workstation/skills/`
2. `chezmoi apply` deploys them to `~/.local/share/agentic-workstation/skills/`
3. `dots-skills sync` reads each `skill.json` and creates symlinks to supported AI tools
4. AI tools load `SKILL.md` at startup

---

## Tool compatibility

Each `skill.json` declares which tools are supported:

| Tool | Skills directory |
|------|-----------------|
| Claude Code | `~/.claude/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Cursor | `~/.cursor/skills/` |
| Copilot CLI | `~/.copilot/skills/` |

---

**Canonical doc:** [`docs/SKILLS.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/SKILLS.md)
