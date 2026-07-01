---
name: dots-workstation-dev-companion
description: >-
  WHAT — agentic-workstation Dev Companion (general): layered companion for client delivery; modes, gates,
  delegation to dots-workstation-assistant and dots-workstation-workflow-generic-project; no CLI matrices.
---

# agentic-workstation Dev Companion (WHAT) — general layer (L2)

This skill is the **general** dev companion for agentic-workstation work. It does **not** replace **`dots-workstation-assistant`** (orchestrator); it **sits above** workflows and names **what to invoke next**.

**Language:** English for ticket comments, PR text, and user-facing outputs when this companion drives delivery work.

## Layering

| Layer | Skill | Role |
| --- | --- | --- |
| L1 | **dots-workstation-assistant** | Repo inspection order, conflict resolution, fallback |
| **L2 (this skill)** | **dots-workstation-dev-companion** | Companion framing: modes, gates, delegation for client work |
| L3 | **Workspace pack overlay** | Client/account-specific context loaded from `~/.ai-workspace/packs/` |

If engagement triggers match, load the appropriate **workspace pack overlay** first, then proceed with **dots-workstation-workflow-generic-project**. Do not mix multiple workflow drivers on the same task.

## Mode selection

- **Default** for agentic-workstation/client delivery: use **dots-workstation-workflow-generic-project** for phased delivery.
- If the user mentions an engagement, ticket prefix, or repo context → load the matching pack from the workspace (overlay) and apply its boundaries/gates.
- If unclear → **ask** before applying L3.

## Delegation (HOW is in other skills)

| Need | Delegate to |
| --- | --- |
| Discovery, AGENTS conflict handling | **dots-workstation-assistant** |
| Generic client delivery phases | **dots-workstation-workflow-generic-project** |
| Planning / default workflow / validation | **dots-workstation-planning** / **dots-workstation-development-workflow** |
| Work items, incidents, meetings, decisions, agreements, spikes | **dots-workstation-work-item**, **dots-workstation-incident**, **dots-workstation-meeting-minutes**, **dots-workstation-decision-log**, **dots-workstation-agreement**, **dots-workstation-spike** |
| Project assessments, evidence maps, technical/management unit scorecards | **dots-workstation-project-assessment**, **dots-workstation-project-assessment-evidence**, **dots-workstation-technical-unit-assessment**, **dots-workstation-management-unit-assessment** |
| ClickUp | **clickup-cli** |
| Jira | External **jira-*** pack (**jira-assistant** router; CLI: `jira-as`) |
| Confluence | External **confluence-*** pack (**confluence-assistant** router; CLI: `confluence-as` or `confluence`) |
| Draft PR GitHub / GitLab | **github-cli-workflow** / **gitlab-cli-workflow** (for default body when the repo has no template: **dots-workstation-pr-fallback** first) |
| Where to save deliverables + human review | **dots-workstation-output-handshake** |
| UI depth | **ui-ux-pro-max** |
| Workstation health | **dots-workstation-triage** |

Do **not** paste forge or ticket CLI sequences here.

## Operating modes

- **Interactive (default):** IDE session; user steers each step.
- **Queued job (optional):** only when a local runner is configured; see `~/.local/share/agentic-workstation/dev-companion/README.md` (installed from chezmoi) and **references/LOOP_GUARDRAILS.md**.

The queue worker is **mandatory infrastructure** (installed by workstation). The **workspace** (`~/ai-workspace`) is optional — it provides project-aware wrappers, job templates, and knowledge base integration. When both are present, the runner automatically enriches LLM prompts with workspace context (`projects.yaml`, `projects/`, `knowledge/todos/`).

### LLM policy gate (client engagements)

Before queueing background jobs for a client repo, confirm the active LLM policy with **`dots-devcompanion llm-status`**. If the engagement requires a single AI account (e.g. only the customer's Anthropic key), the workstation/pack must set **`DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST`** and **`DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT=1`** so the runner fails closed instead of falling back to OpenCode. For Cursor/Copilot-only engagements, prefer **`run-once --no-llm`** (skeleton plan) plus IDE-driven execution. Full reference: **`docs/DEV_COMPANION_LLM.md`**.

## Checklist

- [ ] L3 not needed; if needed, user confirmed engagement context
- [ ] **dots-workstation-assistant** discovery pass before large edits
- [ ] **dots-workstation-workflow-generic-project** phases and gates when doing generic client delivery
- [ ] Tool skills used for all CLI operations
