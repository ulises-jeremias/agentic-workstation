# Client and Project AI Playbooks

This document defines how agentic-workstation ships **reusable AI skills** for **client engagements** in `agentic-workstation`. Workflow and companion skills are **enabled by default** in `skills-registry.yaml`; engineers can **opt out** via private chezmoi data if they want a slimmer symlink set.

> [!IMPORTANT]
> All client-facing skill outputs (ticket comments, PR text, commit messages) must be in **English** regardless of the user's conversation language.

**Authoritative agent behavior** for orchestration and routing is in the **installed** skill under `~/.local/share/agentic-workstation/skills/dots-workstation-assistant/` (see **`references/ORCHESTRATION.md`** there) and **`~/.local/share/agentic-workstation/skills/skill-catalog.yaml`**. This doc is a **human** summary; keep it short.

**Companion layers (L2/L3)** and Cursor rules patterns: [docs/DEV_COMPANION.md](DEV_COMPANION.md).

**Language:** skills that drive agent behavior for these workflows require **English** for ticket comments, PR text, and user-facing outputs.

## Workflow + workspace overlays

This repo ships a generic, reusable workflow skill. Client/account-specific overlays live in the user workspace as packs + knowledge.

| Layer | Mechanism | When to use |
| --- | --- | --- |
| **Workflow** | `dots-workstation-workflow-generic-project` | Default for client delivery phases, gates, traceability |
| **Overlay** | Workspace packs (`~/.ai-workspace/packs/`) | When the user/ticket/repo indicates a specific engagement (e.g. ticket prefix, repo path prefix) |

**HOW** (CLIs, forge, dbt, Snowflake) is implemented in **tool skills**—see the catalog—not in workflow `SKILL.md` bodies.

## Goals

- Keep **org-wide** skills (`dots-workstation-assistant`, `dots-workstation-triage`, etc.) separate from **client/project** workflows.
- Ship the generic workflow as `dots-workstation-workflow-generic-project` (WHAT: phases, gates, traceability; delegates to ClickUp, Jira pack, **github-cli-workflow** / **gitlab-cli-workflow**).
- Keep engagement specifics in the workspace (`packs/accounts/` + `knowledge/clients/`), not as bundled skills.
- Register new optional skills in `skills-registry.yaml`; the **bundled** workflows and **dev companions** default to **`enabled: true`** (see `home/.chezmoidata/skills-registry.yaml`).

## Slugs and naming

| Concept | Rule | Example |
| --- | --- | --- |
| Client slug | kebab-case from client name | `Acme Payments` → `acme-payments` |
| Project slug | kebab-case from project name | `Data Project` → `data-project` |
| Bundled skill directory | `home/dot_local/share/agentic-workstation/skills/<name>/` | `dots-workstation-workflow-generic-project` |
| Workflow skills | Prefer `dots-workstation-workflow-<purpose>` for org-wide workflows; use workspace overlays for client specifics | `dots-workstation-workflow-generic-project` |

Use `references/` under the skill for long annexes so `SKILL.md` stays concise.

**Orchestrator** and org-wide companion: **`dots-workstation-assistant`** (not a client workflow).

## Catalog (bundled client/project)

| Skill | Workflow | Purpose |
| --- | --- | --- |
| `dots-workstation-workflow-generic-project` | Generic Project | WHAT: Jira/ClickUp context, human approvals, English ticket traceability; delegates forge/tool steps |

## Registry and symlinks

Bundled skills are listed in `home/.chezmoidata/skills-registry.yaml`. The generic workflow (`dots-workstation-workflow-generic-project`) and `dots-workstation-dev-companion` default to **`enabled: true`** so `dots-skills sync` creates symlinks under `~/.cursor/skills/`, `~/.claude/skills/`, etc., after `chezmoi apply`.

To **disable** specific skills on a machine, merge or override chezmoi data and set `enabled: false` for those names (or edit the deployed `~/.local/share/agentic-workstation/skills-registry.yaml` if your setup copies it mutably—prefer chezmoi data merge long term).

Then run `chezmoi apply` (or `dots-skills sync` if only the registry changed).

Verify with:

```bash
dots-skills list
```

## Adding a new client/project skill

1. Read [docs/SKILLS.md](SKILLS.md) for bundled skill layout and `skill.json` schema.
2. Add a directory under `home/dot_local/share/agentic-workstation/skills/<skill-name>/` with `SKILL.md` and `skill.json`.
3. Add entries to **`skill-catalog.yaml`** (routing metadata) and **`skills-registry.yaml`** (`source: bundled`, `enabled: false` if the skill should stay off by default for most engineers).
4. Add a row to the **Catalog** above and state **workflow independence** vs 1/2 if relevant.

## Related docs

- [SKILLS.md](SKILLS.md) — skill system and registry
- [AI_LAYER.md](AI_LAYER.md) — where skills live after apply
