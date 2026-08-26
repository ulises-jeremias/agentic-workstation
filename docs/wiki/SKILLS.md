# Skills System

> How agentic-workstation skills are defined, distributed, installed, and made available to AI tools.

---

## What is a skill?

A **skill** is a markdown document (plus optional supporting assets) that teaches an AI tool how to perform a specific workflow. Skills are loaded by AI tools at startup.

Each skill contains:

- `SKILL.md` — instructions read by AI tools (frontmatter + body)
- `skill.json` — manifest declaring source, version, and per-tool compatibility

---

## Bundled skills (thin workstation — workstation-only)

| Skill | Purpose | Source |
|-------|---------|--------|
| `dots-workstation-assistant` | Workspace orchestration and routing | workstation (L1) |
| `dots-workstation-dev-companion` | General dev companion delivery layer | workstation (L1) |
| `dots-workstation-workflow-generic-project` | Generic project delivery phases | workstation (L1) |
| `dots-workstation-workflow-client-bootstrap` | Client bootstrap workflow | workstation (L1) |
| `dots-workstation-triage` | Workstation health triage | workstation (L1) |
| `dots-slack-assistant` | Slack workspace ops | workstation (L1) |
| `dots-harness-knowledge-sync` | Session knowledge persistence | workstation (L1) |
| Workspace pack overlays | Client/account overlays | workstation (L1) |
| *All other cross-domain skills* (77 via `agent-toolkit inventory`: `delivery/prd`, `figma*`, `github-cli-workflow`, `dbt-validation`, etc.) | Delegated to `agent-toolkit` (L1.5) | `dots-skills install-toolkit` |

> **Thin boundary:** cross-domain skills (`clickup-cli`, `github-cli-workflow`, `figma*`, `dbt-validation`, `slack-cli`, `linear`, etc.) and best-practice artifacts (`prd`, `trd`, `adr`, `planning`, `project-assessment`) are now in `agent-toolkit` and cleaned via `.chezmoiremove`. Third-party packs (Jira and Confluence) live in `skills-external/` and never in `plugins/`.

---

## Best Practices and Assessment Skills (delegated to agent-toolkit)

Best-practice delivery skills are intentionally atomic and now live in [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) (delivery domain). The orchestrator loads the smallest skill needed instead of one large process document.

### Output handshake

Before producing a final artifact, the assistant must ask:

- Where should the final content live?
- Who will review it?

This applies to PRDs, TRDs, ADRs, work items, meeting minutes, assessment reports, scorecards, evidence maps, incidents, spikes, and PR/MR bodies.

### Project assessments

Project assessments use four skills:

| Skill | Role | Source |
|-------|------|--------|
| `project-assessment` | Defines assessment purpose, period, audience, units, findings, and action plan | `agent-toolkit` |
| `project-assessment-evidence` | Asks where evidence lives and tracks source quality, freshness, missing evidence, assumptions, and confidence | `agent-toolkit` |
| `technical-unit-assessment` | Scores technical workloads: repositories, frontend, backend, infrastructure, data, UI/UX, and AI-native structural readiness | `agent-toolkit` |
| `management-unit-assessment` | Scores management scope: governance, delivery, collaboration, culture, and AI-native management readiness | `agent-toolkit` |

> Workstation previously shipped these as `dots-workstation-*` — now delegated to `agent-toolkit`. Use `agent-toolkit` names above.

The assistant must not score indicators without evidence. If evidence is unavailable, it should mark the indicator as missing evidence, not assessed, or low confidence with the assumption clearly stated.

### Example chats

End-to-end assessment:

```text
User: Run a project assessment for this engagement.
Assistant: I will use project-assessment (via agent-toolkit). Where should the final report live, and who will review it?
User: Put the draft in docs/assessment.md. I will review it.
Assistant: What period and units should be assessed? Should this cover management, technical units, or both?
User: Last quarter, both. Backend and data pipelines are in scope.
Assistant: I will collect evidence first. Where are the repositories, board, planning docs, dashboards, incidents, decisions, and stakeholder feedback?
```

Technical-only assessment:

```text
User: Assess the cloud infrastructure and CI/CD maturity.
Assistant: I will use project-assessment-evidence and technical-unit-assessment (via agent-toolkit). Where are the IaC repo, pipeline history, deployment docs, monitoring dashboards, security scans, and incident records?
```

Management-only assessment:

```text
User: Review governance and delivery health.
Assistant: I will use project-assessment-evidence and management-unit-assessment (via agent-toolkit). Where are the board, backlog, planning notes, retrospectives, risks, delivery reports, decisions, agreements, and stakeholder feedback?
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
| Jira capabilities | `agent-toolkit install` |
| Confluence capabilities | `agent-toolkit install` |

## Related integrations

- [ClickUp](INTEGRATION_CLICKUP)
- [Jira](INTEGRATION_JIRA)
- [Confluence](INTEGRATION_CONFLUENCE)
- [Figma](INTEGRATION_FIGMA)

---

## Skill lifecycle (thin workstation)

1. Workstation-specific skills are defined in `home/dot_local/share/agentic-workstation/skills/`; cross-domain skills (77 via `agent-toolkit inventory`) are provided by `agent-toolkit` at `skills-external/agent-toolkit/` via `dots-skills install-toolkit`
2. `chezmoi apply` deploys workstation skills to `~/.local/share/agentic-workstation/skills/` and triggers `agent-toolkit install` for the cross-domain catalog
3. `dots-skills sync` (or delegated `agent-toolkit install`) reads each `skill.json`/`SKILL.md` and creates symlinks to supported AI tools
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
