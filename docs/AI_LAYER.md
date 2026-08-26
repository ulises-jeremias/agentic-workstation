# AI Layer

Shared AI resources are installed under `~/.local/share/agentic-workstation/`.

> [!NOTE]
> This document describes the **deployed** AI layer on the target machine (thin host). For the **source state** (before `chezmoi apply`), look under `home/dot_local/share/agentic-workstation/` in the repository.
> **Thin-host:** Workstation provisions the machine (chezmoi, shell, packages, LLM policy, tmux/Herdr, Toolkit installation) and delegates all capabilities (116+ skills via `agent-toolkit inventory`, 17 agents, 10 loops, MCP) to `agent-toolkit`. **Workstation installs tools, Toolkit owns orchestration.**

## Directory structure — thin workstation

| Path | Purpose | Owner |
| --- | --- | --- |
| `prompts/` | Reusable internal prompts (placeholder README — delegated to Toolkit) | L1.5 |
| `skills/` | Workstation-specific orchestration only (assistant, triage, dev-companion, workflow-generic-project); includes **`skill-catalog.yaml`** — thin placeholder, 116+ skills via Toolkit | L1 / L1.5 |
| `skills-external/` | External skills installed via `agent-toolkit` + `dots-skills` + `chezmoiexternal` (`agent-toolkit/`, `jira-assistant/`, `confluence-assistant/`) | L1.5 + Workstation external packs |
| `dev-companion/runner` | Host-specific runner + LLM policy (`dots-devcompanion`, `policy.py`, audit log) — **not delegated** | L1 (host-specific) |
| `loops/` | Loop templates placeholder — delegated to Toolkit (`agent-toolkit loop`) | L1.5 |
| `mcp/` | MCP provider placeholders — delegated to Toolkit | L1.5 |
| `templates/` | Reusable text templates | L1 |
| `skills-registry.yaml` | Runtime skills registry (deployed from chezmoidata) — slimmed to 7 active + 2 deprecated `workflow-*` stubs (`enabled:false`) | L1 |
| `scopes/` | Workstation-only scopes | L1 |
| `telemetry/` | Local telemetry sink | L1 |

## Skills system

Skills are the primary AI-facing assets. Each skill lives in its own directory and contains:

- `SKILL.md` — the main content read by AI tools (frontmatter + instructions)
- `skill.json` — machine-readable manifest declaring source, version, and **per-tool compatibility**

Skills support multiple AI tools through a compatibility matrix in `skill.json`. `dots-skills sync` reads each skill's manifest and creates symlinks only in the directories of tools that declare `"supported": true`.

| Tool | Skills directory |
|------|-----------------|
| Claude Code | `~/.claude/skills/` |
| Muse Code | `~/.config/muse/skills/` / `~/.agents/skills/` (project) |
| GitHub Copilot CLI | `~/.copilot/skills/` |
| Cursor | `~/.cursor/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| pi agent | `~/.pi/agent/skills/` |
| Universal (any tool) | `~/.agents/skills/` |

See [docs/SKILLS.md](SKILLS.md) for the full skills system documentation including how to add bundled or external skills.

**Dev companion** layers (general + workspace overlays) are documented for humans in [docs/DEV_COMPANION.md](DEV_COMPANION.md); companion skills live next to the workflow skills under `skills/`.

**Client/project** bundled skills ship in the same `skills/` tree. **Workflow** and **dev companion** skills default to **`enabled: true`** in `skills-registry.yaml` (override in private chezmoi data to opt out). Engagement overlays are stored in the workspace—see [docs/CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md) and [docs/DEV_COMPANION.md](DEV_COMPANION.md). Routing is summarized in **`skills/skill-catalog.yaml`**; full orchestration rules live in **`skills/dots-workstation-assistant/references/ORCHESTRATION.md`** (installed path).

**dots-workstation-assistant** (agentic-workstation Assistant) is the recommended **organization-wide orchestrator and fallback**: in **any** repo it drives a **document-first** pass (README, `docs/`, `AGENTS.md`, CONTRIBUTING, PR templates, task runners, devcontainer, CI, tooling config, then source), with **`AGENTS.md` as the primary agent contract** when present. It includes `references/REPO_INSPECTION.md`, `references/ORCHESTRATION.md`, and an optional **`AGENTS.project.md.tmpl`** in `home/.chezmoitemplates/agents/` for new application repos. On the baseline checkout it also uses `docs/` and `dots-*`. Future org playbooks should live under documented paths under `~/.local/share/agentic-workstation/` so the skill stays pointer-based.

## Conceptual model: The Ralph Loop — thin host

This workstation is the **provisioning (L1)** layer of a [Ralph Loop](https://ghuntley.com/loop/) implementation; **Toolkit (L1.5)** distributes the capability content. Each component is intentionally mapped to a Ralph concept:

| Ralph concept | What this workstation provides | Layer |
|---------------|-------------------------------|-------|
| **Backing specifications** | `AGENTS.md` templates in `home/.chezmoitemplates/agents/` — deployed to each repo/session | L1 |
| **Context engineering** | `agent-toolkit` skills (77 via `agent-toolkit inventory`) — symlinked via `dots-skills sync`; `~/.local/share/agentic-workstation/skills/` is thin (workstation-only) | L1.5 → L1 |
| **Persistent memory between loops** | `agentic-harness` `knowledge/` — the running harness knowledge base (L3) | L3 |
| **Fix the loop** | `dots-harness-knowledge-sync` skill — auto-syncs discoveries after each session | L1 → L3 |
| **Monolithic orchestrator** | `dots-workstation-assistant` as single entry point; multi-agent is optional and bounded (swarm via `agent-toolkit swarm …`) | L1 → L1.5 |
| **Forward mode** | Dev companion host runner (`dots-devcompanion` + policy) + Toolkit generic queue | L1 + L1.5 |
| **Reverse mode** | Sanitized Archive archiving procedure | L3 |

The conceptual model, operational guide, and session loop documentation live in the running instance:
**[ai-workspace/knowledge/learnings/general.md](https://github.com/ulises-jeremias/ai-workspace/blob/main/knowledge/learnings/general.md)**

For an overview of the agentic harness framework — three-layer architecture, session lifecycle, personas, and packs — see **[docs/AGENTIC_HARNESS.md](AGENTIC_HARNESS.md)**.

---

## Agent templates

Project-level assistant templates live in `home/.chezmoitemplates/agents/` and include:

- `AGENTS.md.tmpl` (this workstation repository)
- `AGENTS.project.md.tmpl` (starter for **application** repos — portable `AGENTS.md` body)
- `CLAUDE.md.tmpl`
- `copilot-instructions.md.tmpl`

## Init-time AI and editor setup

Interactive `chezmoi init` captures user choices for:

- AI agent CLIs (ClickUp, Slack, rtk, Claude Code, OpenCode, pi, Copilot CLI extension)
- Editor installation (VSCode, Cursor)
- VSCode extension installation (including Claude Code extension)

Those choices are persisted and used by `home/.chezmoiscripts/` installer scripts on future applies without re-prompting. At the end of each apply, `dots-skills sync` regenerates all skill symlinks.

## Agent catalog

Terminal coding agents are declared in **`home/.chezmoidata/ai.yaml`** under `ai.agent_catalog` — the canonical machine-readable source for first-class agent installs.

| Field | Type | Meaning |
| --- | --- | --- |
| `description` | string | Human-readable summary |
| `enabled` | bool | Opt-in switch (questionnaire selection / profile preset / private data override) |
| `channel` | enum | Install strategy: `native`, `script`, `npm`, `gh-extension`, `auto` |
| `pin` | string | `""` = latest; exact version otherwise. Overridable at install time via `<NAME>_PIN` / `<NAME>_VERSION` environment variables, consistent with the existing pin pattern in `install-agent-toolkit.sh` |
| `check` | string | Post-install gate: command that must succeed for the install to count as OK |
| `requires_node` | bool | `npm`-channel entries require the node group to be installed first |

### Channels

| Channel | Strategy | Used by |
| --- | --- | --- |
| `native` | Vendor installer without sudo | Claude Code |
| `script` | Official `curl … \| bash` installer | OpenCode, Muse Code |
| `npm` | Global npm package (needs node group) | pi, Gemini CLI, Codex |
| `gh-extension` | `gh extension install` | Copilot CLI |
| `auto` | Best-available chain (brew → mise → script) | Herdr |

### Catalog entries

`claude_code`, `opencode`, `muse_code`, `copilot_cli`, `pi`, `gemini_cli`, `codex`, `herdr`.

The legacy boolean flags under `agents` (e.g. `claude_code: false`) are **deprecated** and kept only until the questionnaire migrates to the catalog; new tooling must read `agent_catalog` exclusively. Installs are idempotent (`has_cmd` early-outs), CI/hermetic-guarded, and report a per-agent status line — the same conventions as the swarm and editors installers.

### Installer library

`home/dot_local/lib/agentic-workstation/install-ai-agents-lib.sh` implements one idempotent installer per catalog entry plus a thin dispatcher:

```bash
# shellcheck source=/dev/null
. "${HOME}/.local/lib/agentic-workstation/install-ai-agents-lib.sh"

install_catalog_agent claude_code   # one agent
install_ai_agents opencode pi       # several agents, summary rc
agent_pin claude_code               # CLAUDE_CODE_PIN ?? CLAUDE_CODE_VERSION ?? ""
verify_agent_install opencode       # post-install gate (ai.yaml `check`)
```

Unit tests live in `scripts/test-install-ai-agents-lib.sh` (pure helpers only — no network in CI).

## Local AI Audit

`dots-workstation-audit` inventories local AI tool installation, safe auth hints, config file presence, and privacy-related metadata for Claude Code, Cursor, GitHub Copilot, OpenCode, Codex, Windsurf, and Gemini. It is intentionally redacted: it never prints token values, raw auth files, prompt history, chat logs, or memory contents. Local subscription evidence is best-effort only; vendor admin consoles or APIs remain authoritative for plan ownership.

`dots-security-audit` provides a shallow workstation security check for sensitive file permissions, AI auth file permissions, and expected agentic-workstation baseline directories. Deep secret scanning is skipped by default to avoid noisy false positives.

## Safety guarantees

> [!CAUTION]
> Never commit credentials. MCP templates are **examples only** and require explicit local configuration with environment variables.

- No credentials are committed.
- Secrets are consumed via environment variables only.
- MCP templates are examples and require explicit local configuration.

---

## See Also

- [SKILLS.md](SKILLS.md) — Full skills system documentation
- [DEV_COMPANION.md](DEV_COMPANION.md) — Dev companion layers and architecture
- [CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md) — Client-specific AI workflows
- [MCP_TEMPLATES.md](MCP_TEMPLATES.md) — MCP provider templates and setup
- [AGENTIC_HARNESS.md](AGENTIC_HARNESS.md) — Three-layer agentic framework
