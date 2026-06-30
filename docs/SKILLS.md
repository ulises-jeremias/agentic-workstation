# Skills

This document describes the dots-ai skill system — how skills are defined, distributed, installed, and made available to multiple AI tools.

## Skill Lifecycle

```mermaid
flowchart LR
    subgraph Sources
        B[Bundled<br/>chezmoi source]
        N[npm<br/>dots-skills install]
        G[GitHub/URL<br/>chezmoiexternal]
    end

    subgraph Install["Installation"]
        CA[chezmoi apply]
        NS[dots-skills install]
    end

    subgraph Store["Skill Store"]
        S1["~/.local/share/dots-ai/skills/"]
        S2["~/.local/share/dots-ai/skills-external/"]
    end

    subgraph Sync["dots-skills sync"]
        SJ["Read skill.json<br/>compatibility"]
    end

    subgraph Tools["AI Tool Symlinks"]
        T1["~/.claude/skills/"]
        T2["~/.config/opencode/skills/"]
        T3["~/.cursor/skills/"]
        T4["~/.copilot/skills/"]
    end

    B --> CA --> S1
    N --> NS --> S1
    G --> CA --> S2
    S1 --> SJ
    S2 --> SJ
    SJ --> T1
    SJ --> T2
    SJ --> T3
    SJ --> T4
```

> [!NOTE]
> `dots-skills sync` is called automatically on every `chezmoi apply`. You only need to run it manually after editing `skills-registry.yaml` directly.

## What is a skill?

A **skill** is a markdown document (plus optional supporting assets) that teaches an AI tool how to perform a specific workflow. Skills are loaded by AI tools at startup and influence how they respond to user requests.

Each skill lives in its own directory and always contains:

- `SKILL.md` — the main content read by AI tools (frontmatter + instructions)
- `skill.json` — machine-readable manifest (source, version, compatibility, requirements). External skills sourced via chezmoiexternal may omit it; they are treated as universally compatible.

The bundled **dots-ai-assistant** skill is the **dots-ai Assistant** and **orchestrator**: it defines a **repository inspection order** (README → docs → `AGENTS.md` → CONTRIBUTING → PR templates → task runners → devcontainer → CI → configs → code), **conflict heuristics**, and **anti-duplication** rules. It ships `references/REPO_INSPECTION.md`, `references/ORCHESTRATION.md` (routing and delegation), and `references/AGENTS_TEMPLATE.md`; a chezmoi **project** starter lives at `home/.chezmoitemplates/agents/AGENTS.project.md.tmpl`. **`skill-catalog.yaml`** next to bundled skills lists **WHAT vs HOW**, **triggers**, and **`depends_on`** for routing. It remains useful **outside** this repository by anchoring on the **applied machine** (`~/.local/share/dots-ai/`, `dots-*`) when relevant. Future org playbooks should be **read from shipped paths**, not hardcoded in the skill body.

## Directory structure

```
~/.local/share/dots-ai/skills/           # Bundled skills (managed by chezmoi)
│   skill-catalog.yaml                   # Routing metadata (WHAT/HOW, triggers, depends_on)
│   clickup-cli/
│   │   SKILL.md
│   │   skill.json
│   slack-cli/
│   │   SKILL.md
│   │   skill.json
│   │   references/
│   github-cli-workflow/
│   gitlab-cli-workflow/
│   dbt-validation/
│   snowflake-validation/
│   dots-ai-workflow-generic-project/
│   dots-ai-workflow-client-bootstrap/
│   dots-ai-dev-companion/
│   dots-slack-assistant/
│   dots-ai-workspace-knowledge-sync/
│   ui-ux-pro-max/
│   │   SKILL.md
│   │   skill.json
│   │   scripts/
│   │   data/
│   dots-ai-workstation-triage/
│   │   SKILL.md
│   │   skill.json
│   dots-ai-assistant/
│   │   SKILL.md
│   │   skill.json
│   │   references/
│   │       REPO_INSPECTION.md
│   │       ORCHESTRATION.md
│   │       AGENTS_TEMPLATE.md

~/.local/share/dots-ai/dev-companion/    # Optional queue + worker (see README.md)
~/.local/share/dots-ai/third-party/      # Small attributed third-party excerpts (e.g. everything-claude-code)

~/.local/share/dots-ai/skills-external/  # External skills (managed by chezmoiexternal + dots-skills)
    jira-admin/                          # ← extracted from JIRA-Assistant-Skills pack
    jira-agile/
    jira-issue/
    ...
    <npm-skill-name>/                    # ← symlinked from npm global
```

AI tools access skills through symlinks in their respective config directories:

| Tool | Skills directory |
|------|-----------------|
| Claude Code | `~/.claude/skills/` |
| GitHub Copilot CLI | `~/.copilot/skills/` |
| Cursor | `~/.cursor/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| pi agent | `~/.pi/agent/skills/` |

## Skill sources

Skills can come from four sources, using two different installation mechanisms:

| Source | Mechanism | Example |
|--------|-----------|---------|
| `bundled` | chezmoi source state | `clickup-cli`, `slack-cli` |
| `npm` | `dots-skills install` | `uipro-cli` (ui-ux-pro-max) |
| `github` | **chezmoi `.chezmoiexternal`** | `ulises-jeremias/JIRA-Assistant-Skills` |
| `url` | **chezmoi `.chezmoiexternal`** | `https://example.com/skill.tar.gz` |

**`github` and `url` sources are managed natively by chezmoi** via `.chezmoiexternal.toml.tmpl`. This means:
- No custom download code — chezmoi handles HTTP, extraction, caching
- Auto-refresh with `chezmoi apply --refresh-externals`
- Declarative opt-in via `chezmoidata` flags (`install_skill_*`)

## The `skill.json` manifest

Every skill must have a `skill.json` alongside its `SKILL.md`. This is the machine-readable manifest used by `dots-skills` for installation, syncing, and compatibility checks.

### Schema

```json
{
  "$schema": "https://raw.githubusercontent.com/ulises-jeremias/dots-ai/main/lib/schemas/skill.schema.json",
  "name": "my-skill",
  "version": "1.0.0",
  "description": "Short description used by AI tools in skill selection.",
  "source": "bundled",
  "author": "dots-ai",
  "tags": ["tag1", "tag2"],
  "requires": ["some-cli-tool"],
  "compatibility": {
    "claude-code":  { "supported": true },
    "copilot-cli":  { "supported": true },
    "cursor":       { "supported": true },
    "opencode":     { "supported": true },
    "pi":           { "supported": false, "notes": "Format not supported yet" },
    "windsurf":     { "supported": true }
  }
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique kebab-case identifier |
| `version` | Yes | Semver string, for example `"1.0.0"` |
| `description` | Yes | Short description for skill selection UI |
| `source` | Yes | `bundled`, `npm`, `github`, or `url` |
| `compatibility` | Yes | Per-tool support declarations |
| `package` | When `source: npm` | npm package name |
| `repo` | When `source: github` | `"owner/repo"` format |
| `ref` | When `source: github` | Git ref, defaults to `"main"` |
| `url` | When `source: url` | Direct download URL |
| `author` | No | Author or org name |
| `tags` | No | Searchable tags |
| `requires` | No | CLI tools that must be installed |
| `pip_packages` | No | Python packages to install via uv/pip |

The full JSON Schema lives at [`lib/schemas/skill.schema.json`](../lib/schemas/skill.schema.json).

### Compatibility matrix

The `compatibility` object must declare support for each AI tool. Only skills with `"supported": true` for a given tool will have a symlink created in that tool's skills directory.

Known tool keys:

| Key | Tool |
|-----|------|
| `claude-code` | Anthropic Claude Code |
| `copilot-cli` | GitHub Copilot CLI |
| `cursor` | Cursor editor |
| `opencode` | OpenCode terminal agent |
| `pi` | pi coding agent |
| `windsurf` | Windsurf editor |

> **Principle**: a skill must explicitly declare support for each tool. The system never assumes "works everywhere".
> Skills without `skill.json` (e.g. from chezmoiexternal) are treated as universally compatible.

> [!TIP]
> Use `dots-skills list` to see all installed skills with their per-tool symlink status at a glance.

## The Skills Registry (`skills-registry.yaml`)

`home/.chezmoidata/skills-registry.yaml` documents skills known to this baseline (same content as **`home/dot_local/share/dots-ai/skills-registry.yaml`**, which chezmoi deploys to `~/.local/share/dots-ai/skills-registry.yaml` for `dots-skills`). It is used by `dots-skills` for **bundled and npm** sources.

**`github` and `url` skills are no longer in this registry** — they are declared in `.chezmoiexternal.toml.tmpl` and installed natively by chezmoi.

```yaml
skills:
  # Bundled: installed by chezmoi source state
  - name: clickup-cli
    source: bundled
    enabled: true

  - name: workflow-generic-project
    source: bundled
    enabled: true

  # npm: installed by dots-skills install
  - name: ui-ux-pro-max
    source: npm
    package: uipro-cli
    enabled: true

  # github/url → see .chezmoiexternal.toml.tmpl
```

## Imported skills (Apache-2.0 from openai/skills)

Ten skills in this baseline are derived from the curated set in
[openai/skills](https://github.com/openai/skills) (`skills/.curated/`), all
Apache-2.0 licensed:

| dots-ai skill | Upstream | Domain | Notes |
|---|---|---|---|
| `gh-address-comments` | `gh-address-comments` | forge | PR review-comment triage via `gh`. Pairs with `github-cli-workflow`. |
| `gh-fix-ci` | `gh-fix-ci` | forge | GitHub Actions failure triage. Plan-before-implement. |
| `linear` | `linear` | linear | Linear MCP workflows for issues, cycles, and docs. |
| `figma` | `figma` | figma | Entry point for the Figma MCP family. |
| `figma-implement-design` | `figma-implement-design` | figma | Design to code with 1:1 fidelity. |
| `figma-code-connect-components` | `figma-code-connect-components` | figma | Code Connect mappings. |
| `figma-create-design-system-rules` | `figma-create-design-system-rules` | figma | Generate agent rules for design systems. |
| `figma-create-new-file` | `figma-create-new-file` | figma | Create a new Figma file from scratch. |
| `playwright-cli` | `playwright` | testing | CLI-first browser automation. Renamed to disambiguate from `dots-ai-e2e-runner`. |
| `jupyter-notebook` | `jupyter-notebook` | research | Scaffold reproducible notebooks; exposed via `dots-newnotebook`. |

Each imported skill keeps the upstream `LICENSE.txt` and adds a `NOTICE.txt`
documenting dots-ai-side modifications. Common changes:

- Removed Codex-specific paths (`CODEX_HOME`, `~/.codex/skills/...`) and
  flags (`sandbox_permissions`, `[features].rmcp_client`). Replaced with the
  chezmoi-managed install location and tool-agnostic guidance for Claude
  Code, Cursor, OpenCode and Windsurf.
- Replaced `agents/openai.yaml` and `metadata.short-description` with the
  dots-ai [`skill.json` schema](#the-skilljson-manifest).
- Dropped vendor logo assets (`assets/*.svg`, `assets/*.png`).
- Added cross-references to dots-ai counterparts (`github-cli-workflow`,
  `dots-ai-e2e-runner`, `dots-ai-planning`, etc.).

### Out-of-scope (opt-in pack, not bundled)

Two heavier skills from the same upstream are intentionally **not bundled**
because they ship large reference payloads and have very specific use cases.
They are documented as "opt-in pack" in cross-references inside the bundled
figma family:

- `figma-use` (~692 KB; includes the Figma Plugin API standalone typings) —
  required prerequisite for any `use_figma` MCP call.
- `figma-generate-design` and `figma-generate-library` — depend on `figma-use`.

A future PR will publish these as a separate opt-in skill pack, installable
via `chezmoiexternal` + an `install_skill_figma_use_pack` flag (analogous to
`install_skill_jira_assistant`). Until then, install them manually if you
need them — the bundled `figma-implement-design`, `figma-code-connect-components`
and `figma-create-new-file` cover the most common design-to-code workflows.

### MCP templates

Two new MCP templates ship with this batch (deployed to
`~/.local/share/dots-ai/mcp/`):

- `mcp/linear/` — streamable-HTTP, OAuth at `https://mcp.linear.app/mcp`. No
  env vars required.
- `mcp/figma/` — streamable-HTTP with `Authorization: Bearer
  ${FIGMA_OAUTH_TOKEN}` and `X-Figma-Region: ${FIGMA_REGION}`. Store the
  token in `~/.config/dots-ai/env.d/figma.env`.

See [`docs/MCP_TEMPLATES.md`](MCP_TEMPLATES.md) for the registration matrix.

## External Skills via chezmoi (`.chezmoiexternal`)

`github` and `url` skills are managed by chezmoi's native external mechanism. This lives at:

```
home/private_dot_local/share/dots-ai/.chezmoiexternal.toml.tmpl
```

Chezmoi handles download, extraction, caching, and refresh — no custom bash needed.

**Opt-in**: controlled by `install_skill_*` flags in chezmoidata/toml config:
```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
install_skill_jira_assistant = true
```

Or answered during `chezmoi init` interactive prompts.

**To refresh**: `chezmoi apply --refresh-externals`

### Skill Packs via chezmoiexternal

A **skill pack** is a GitHub repo with multiple skills under a subdirectory. Each pack gets its own unique key (target subdirectory) inside `skills-external/`, so multiple packs don't conflict:

```toml
# Key = target path relative to ~/.local/share/dots-ai/
# stripComponents=2 strips "RepoName-main/" and "skills/" from the archive paths
["skills-external/jira-assistant"]
    type            = "archive"
    url             = "https://github.com/ulises-jeremias/JIRA-Assistant-Skills/archive/refs/heads/main.tar.gz"
    stripComponents = 2          # "Repo-main/skills/jira-admin/SKILL.md" → "jira-admin/SKILL.md"
    include         = ["*/skills/**"]  # all files under skills/ subtree
    refreshPeriod   = "168h"
```

Result on disk:
```
skills-external/
  jira-assistant/         ← pack directory (unique key)
    jira-admin/           ← individual skill
      SKILL.md
    jira-agile/
      SKILL.md
    ...
```

`dots-skills sync` discovers 2 levels deep in `skills-external/` — it detects that `jira-assistant/` has no `SKILL.md` (it's a pack), so it scans one level deeper to find the individual skills.

`dots-ai/JIRA-Assistant-Skills` is a skill pack with 14 specialized JIRA skills:

| Skill | Purpose |
|-------|---------|
| `jira-assistant` | Meta-router: routes requests to the right JIRA skill |
| `jira-issue` | Issue CRUD: create, read, update, delete |
| `jira-search` | JQL queries and filters |
| `jira-lifecycle` | Workflow transitions, assignments, versions |
| `jira-agile` | Sprints, epics, story points |
| `jira-collaborate` | Comments, attachments, watchers |
| `jira-relationships` | Issue linking and dependency chains |
| `jira-time` | Time logging and worklogs |
| `jira-jsm` | Service desk, SLAs, queues |
| `jira-bulk` | Bulk operations on 10 to 50+ issues |
| `jira-dev` | Git and PR integration with JIRA |
| `jira-fields` | Custom field discovery |
| `jira-ops` | Cache, diagnostics, project discovery |
| `jira-admin` | Project settings, permissions, automation |

**To install** (requires JIRA credentials):

> [!CAUTION]
> Store JIRA credentials in `~/.config/dots-ai/env.d/jira.env` — never in `.env` files inside repositories or chezmoi source state.

```bash
# Recommended: store credentials in the opt-in global env.d mechanism:
mkdir -p ~/.config/dots-ai/env.d
$EDITOR ~/.config/dots-ai/env.d/jira.env

# Example ~/.config/dots-ai/env.d/jira.env:
# export JIRA_API_TOKEN="your-token"
# export JIRA_EMAIL="you@company.com"
# export JIRA_SITE_URL="https://company.atlassian.net"

# Enable in chezmoi config:
chezmoi edit-config   # add: install_skill_jira_assistant = true  under [data]
chezmoi apply         # downloads pack via chezmoiexternal + installs jira-as + syncs symlinks
```

**Multi-tool compatibility**: The JIRA skills use `SKILL.md` with YAML frontmatter — readable by all AI tools. The `allowed-tools` field in the frontmatter is Claude Code-specific and is safely ignored by other tools. Since there is no `skill.json`, `dots-skills sync` treats them as universally compatible and links them for all configured AI tools.

## Managing skills with `dots-skills`

`dots-skills` is the CLI helper for skill management. It works alongside chezmoi:

```
dots-skills list              List installed skills and their status per AI tool
dots-skills sync              Regenerate symlinks (reads skill.json or defaults to all tools)
dots-skills install <name>    Install an npm-sourced skill from the registry
dots-skills check             Validate required CLI tools and pip packages for each skill
dots-skills add npm:<pkg>     Add an npm skill to the registry
```

> **Note**: `github` and `url` skills are now managed by chezmoi (`.chezmoiexternal`), not by `dots-skills install`. Run `chezmoi apply` instead.

### `dots-skills list`

Shows all discovered skills with their source and symlink status per AI tool:

```
NAME                SOURCE   VERSION    claude-code    copilot-cli    cursor
clickup-cli    bundled  1.0.0      ✓ linked       ✓ linked       ✓ linked
jira-admin          external ?          ✓ linked       ✓ linked       ✓ linked
jira-agile          external ?          ✓ linked       ✓ linked       ✓ linked
ui-ux-pro-max       npm      1.0.0      ✓ linked       ✓ linked       ✓ linked
```

### `dots-skills sync`

Reads every skill directory (both `skills/` and `skills-external/`), checks the `skill.json` compatibility matrix (or assumes universal if absent), and creates/removes symlinks. Idempotent and safe to re-run.

If a skill is listed in `skills-registry.yaml` with **`enabled: false`**, it is **skipped** (no symlinks created), and any existing symlinks pointing at that skill are **removed**. Skills not listed in the registry are treated as enabled. **Workflow** and **dev companion** skills default to **`enabled: true`** in the baseline registry; use **`enabled: false`** to opt out (see [CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md)).

Called automatically by `run_onchange_45-install-ai-agents.sh.tmpl` on every `chezmoi apply`.
- **url**: downloads and extracts to `~/.local/share/dots-ai/skills-external/<name>/`

After installation, runs `dots-skills sync` automatically.

### `dots-skills check`

For each skill that is **not** disabled via `skills-registry.yaml` (`enabled: false`), checks that every tool listed in `requires` is available in `$PATH`. Reports missing tools with install suggestions.

## Bundled Best Practices skills

The workstation bundles atomic dots-ai Best Practices skills for common delivery artifacts. They stay small by keeping reusable Markdown bodies in each skill's `references/default-template.md`, while `SKILL.md` handles routing and guardrails.


Final artifacts must first run the `dots-ai-output-handshake`: confirm the destination and require human review. Repository instructions, project templates, and engagement packs override these defaults.

Project assessment skills are fully interactive: they ask where each evidence source lives, build an evidence map, and separate confirmed findings from assumptions and missing evidence before scoring management or technical units.

### Project Assessment Skills

Use the assessment skills when a user asks for a project assessment, maturity review, quality indicator review, delivery audit, technical unit assessment, management unit assessment, or AI-readiness review.


The default flow is:

1. Run `dots-ai-output-handshake` before final reports: ask where the final artifact should live and who will review it.
2. Use `dots-ai-project-assessment` to define purpose, period, audience, and assessment units.
3. Use `dots-ai-project-assessment-evidence` to ask where evidence lives. Evidence may be in repositories, boards, docs, dashboards, incident records, PRs, meeting notes, interviews, Slack, email, spreadsheets, or other systems.
4. Use `dots-ai-technical-unit-assessment` and/or `dots-ai-management-unit-assessment` to score only indicators with evidence.
5. Record confidence, assumptions, missing evidence, and validation needs before creating recommendations.
6. Create follow-up work items only after explicit approval, delegating writes to the relevant ticket tool skill.

### Project Assessment Use Cases


### Example Chats

End-to-end assessment:

```text
User: Run a project assessment for this engagement.
Assistant: I will use dots-ai-project-assessment. Where should the final report live, and who will review it?
User: Put the draft in docs/assessment.md. I will review it.
Assistant: What period and units should be assessed? Should this cover management, technical units, or both?
User: Last quarter, both. The backend and data pipeline are the technical units.
Assistant: I will collect evidence first. Where are the repositories, board, planning docs, dashboards, incidents, decisions, and stakeholder feedback?
```

Technical-only assessment:

```text
User: Assess the cloud infrastructure and CI/CD maturity.
Assistant: I will use dots-ai-project-assessment-evidence and dots-ai-technical-unit-assessment. Where are the IaC repo, pipeline history, deployment docs, monitoring dashboards, security scans, and incident records?
```

Management-only assessment:

```text
User: Review project governance and delivery health.
Assistant: I will use dots-ai-project-assessment-evidence and dots-ai-management-unit-assessment. Where are the board, backlog, planning notes, retrospectives, risks, delivery reports, decisions, agreements, and stakeholder feedback?
```

Missing evidence:

```text
User: Score observability based on what you can see.
Assistant: I can inspect the repository, but observability scoring also needs dashboards, alerts, logs, or incident evidence. Where can I find those sources? If they are unavailable, I will mark the indicator as missing evidence or low confidence.
```

Follow-up actions:

```text
User: Convert the assessment gaps into tasks.
Assistant: I can draft follow-up tasks from the confirmed findings. Which ticket system or file should receive them, and do you approve creating work items for the high-priority gaps?
```

## Adding a new skill

> [!IMPORTANT]
> For client/project skills, follow the naming and workflow rules in [CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md). Do not mix multiple workflow drivers on the same task.

### Client and project bundled skills

For **client engagement** or **project-specific** AI workflows, use the naming and **workflow** rules in [CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md). Register new skills in `skills-registry.yaml`; set **`enabled: false`** when a skill should stay off by default for most engineers.

### Bundled skill (in this repo)

1. Create `home/dot_local/share/dots-ai/skills/<name>/` (chezmoi source path under `home/`)
2. Add `SKILL.md` with YAML frontmatter and content
3. Add `skill.json` with the manifest
4. Add an entry to `home/.chezmoidata/skills-registry.yaml`
5. Run `chezmoi apply` — `dots-skills sync` will create the symlinks automatically

### External skill (from npm)

1. Find the npm package that exposes a `SKILL.md` (e.g. `uipro-cli`)
2. Add an entry to `skills-registry.yaml`:
   ```yaml
   - name: my-skill
     source: npm
     package: my-skill-npm-pkg
     enabled: true
   ```
3. Run `dots-skills install my-skill` or `chezmoi apply`

### External skill (from GitHub)

1. Create a repo with `SKILL.md` + `skill.json` at the root
2. Add an entry to `skills-registry.yaml`:
   ```yaml
   - name: my-skill
     source: github
     repo: myorg/my-skill
     ref: v1.0.0
     enabled: true
   ```
3. Run `dots-skills install my-skill`

## Multi-tool compatibility guidelines

When writing a skill, always declare compatibility explicitly. If you are unsure whether a tool supports the skill format, set `"supported": false` with a note.

**Do** declare support only after testing:
```json
"cursor": { "supported": true }
```

**Do** add notes when support is partial or has caveats:
```json
"pi": { "supported": false, "notes": "pi does not load external skill files yet" }
```

**Don't** assume "works everywhere" — the point of the compatibility matrix is to make this explicit and opt-in per tool.

## Publishing a skill to npm

If you want to share a skill publicly via npm:

1. Create a package with `SKILL.md` and `skill.json` at the root
2. The `skill.json` `source` should still reflect the intended distribution method (`npm`)
3. Publish normally: `npm publish`
4. Other users can add it to their `skills-registry.yaml` as an `npm` source skill

Example minimal `package.json` for a skill package:

```json
{
  "name": "my-awesome-skill",
  "version": "1.0.0",
  "description": "My awesome AI skill",
  "files": ["SKILL.md", "skill.json", "scripts/", "data/"]
}
```

---

## Knowledge Base Write API

Skills that sync discoveries to the ai-workspace knowledge base use the stable `assistant-memory` API with the `--from-skill` flag for origin tracking.

### API Reference

```bash
assistant-memory add --type <type> --from-skill <skill-name> [--tags a,b,c] <content>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--type` | Yes | Entry type: `skill`, `process`, `learning`, `todo` |
| `--from-skill` | Yes (for cross-repo skills) | Origin skill name |
| `--tags` | No | Comma-separated tags |
| `content` | Yes | Free-text entry content |

### Example (from a skill)

```bash
assistant-memory add --type learning --from-skill my-skill "Pattern: always verify X"
assistant-memory add --type skill --from-skill my-skill --tags jira,workflow "New workflow pattern"
```

### Version negotiation

Skills should probe for `--from-skill` support and fall back gracefully:

```bash
assistant-memory add --type learning --from-skill test "probe" >/dev/null 2>&1 \
  && echo "API available" \
  || echo "fall back to plain add"
```

---

## See Also

- [AI_LAYER.md](AI_LAYER.md) — AI layer overview and directory structure
- [CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md) — Client-specific skill workflows
- [DEV_COMPANION.md](DEV_COMPANION.md) — Dev companion layers (uses skills)
- [ARCHITECTURE.md](ARCHITECTURE.md) — High-level architecture overview
- [adrs/004-skills-compatibility-matrix.md](adrs/004-skills-compatibility-matrix.md) — ADR: Skills system design
- [ai-workspace docs/KNOWLEDGE.md](https://github.com/ulises-jeremias/ai-workspace/blob/main/docs/KNOWLEDGE.md) — Full API reference
