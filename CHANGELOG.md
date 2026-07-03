# Changelog

All notable changes to `agentic-workstation` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> [!NOTE]
> For commit-level detail, see the [commit history](https://github.com/ulises-jeremias/agentic-workstation/commits/main).

---

<!-- markdownlint-disable MD024 -->
## [Unreleased]

### Added

- **Dev companion LLM policy** (`home/dot_local/share/dots-ai/dev-companion/runner/policy.py`): explicit allowlist/denylist/pinned-provider/pinned-model + **fail-closed `strict` mode**, composed from env vars (`DOTS_AI_DEVCOMPANION_LLM_ALLOWLIST`, `DOTS_AI_DEVCOMPANION_LLM_DENYLIST`, `DOTS_AI_DEVCOMPANION_LLM_PINNED_PROVIDER`, `DOTS_AI_DEVCOMPANION_LLM_PINNED_MODEL`, `DOTS_AI_DEVCOMPANION_LLM_STRICT`, `DOTS_AI_DEVCOMPANION_LLM_CONFIG`), an optional `~/.config/dots-ai/devcompanion-llm.json` and per-job `llm` overrides (job may only **restrict**, never widen). The runner now emits `llm_policy_applied` inside `result.json`, embeds the policy in the `plan.md` header, and appends a single-line JSON record to `~/.local/share/dots-ai/dev-companion/logs/llm-audit.log` (metadata only).
- New CLI subcommand **`dots-devcompanion llm-status [--job FILE] [--json]`** that shows the active policy and which provider would run **without invoking any model**. Exit code `1` when strict mode would block, `2` on policy violation, `0` otherwise.
- Unit tests for the policy and dispatcher under `home/dot_local/share/dots-ai/dev-companion/runner/tests/` (run with `python3 -m unittest tests.test_policy tests.test_dispatcher`).

### Changed

- **`LLMDispatcher`** (`runner/llm_dispatcher.py`) now respects `LLMPolicy`: providers are filtered/ordered by allowlist (preserving operator-specified order), pinned provider+model isolate the choice, denylist always wins, and strict mode returns the explicit `policy_no_provider_available` error instead of silently falling back to skeleton or another provider.
- **`dots_ai_devcompanion_runner.py`** writes `policy_violation` artifacts (exit code `2`) when a job tries to widen the global policy or when strict mode finds no allowed provider. Legacy `"llm": true|false` is still accepted; the new shape is `"llm": { "enabled": true, "allowlist": [...], "model": "...", "strict": true }`.
- Documentation overhaul: [`docs/DEV_COMPANION_LLM.md`](docs/DEV_COMPANION_LLM.md) now distinguishes **Default Mode** (dots-ai, OpenCode/big-pickle) from **Client-Restricted Mode** (allowlist + strict); cross-references added in `docs/wiki/DEV_COMPANION.md`, `docs/wiki/CLI.md`, `home/dot_local/share/dots-ai/dev-companion/README.md`, and `home/dot_local/share/dots-ai/skills/dots-ai-dev-companion/SKILL.md`. The **`dots-ai-assistant`** orchestration row mentions the policy gate. Cursor/Copilot guidance (no headless adapter today → use `--no-llm` skeleton + IDE) is documented explicitly.
- Renamed bundled skill **`workstation-triage`** → **`dots-ai-workstation-triage`** (directory, `skill.json`, symlinks under `~/.claude/skills/` / `~/.agents/skills/` / `~/.pi/agent/skills/` / `~/.windsurf/skills/`, `skill-catalog.yaml`, both `skills-registry.yaml` files, docs). Run **`dots-skills sync`** after `chezmoi apply`; stale `workstation-triage` symlinks are removed as **dangling** links at end of sync.
- **`dots-skills list`**: rewritten to use **one Python pass** over all skills instead of spawning `python3` per cell (was ~7 subprocesses per skill → very slow with many bundled + external skills). Output format unchanged; broken per-tool symlinks show as missing until `sync` cleans them.
- **`dots-skills sync`**: after creating links, removes **dangling** symlinks in each `TOOL_DIRS` target (leftover name after a rename or removal).
- **`home/.chezmoi.toml.tmpl`**: switched every prompt from `promptChoiceOnce`/`promptStringOnce` to `promptChoice`/`promptString`. Each prompt now always shows up on interactive `chezmoi init`, but the **default each prompt offers is your previously saved answer** (boolean values are coerced to `yes`/`no` via `ternary`). Previous behavior silently skipped any prompt whose value was already on disk, which felt like a "speed mode" that auto-pressed Enter for the user. `WORKSTATION_PROFILE=…` and the `--stdinisatty=false` non-interactive paths are unchanged. New raw multi-choice keys (`ai_agents_selection`, `editors_selection`, `vscode_extensions_selection`) are now persisted to `[data]` so re-init shows the previous comma-separated list as the default. Docs updated in [`docs/wiki/QUESTIONNAIRE.md`](docs/wiki/QUESTIONNAIRE.md).

### Added

- **Imported 10 curated skills** from [openai/skills](https://github.com/openai/skills) (`skills/.curated`, Apache-2.0) and adapted them to dots-ai conventions: `gh-address-comments`, `gh-fix-ci`, `linear`, `figma`, `figma-implement-design`, `figma-code-connect-components`, `figma-create-design-system-rules`, `figma-create-new-file`, `playwright-cli`, `jupyter-notebook`. Each skill ships its upstream `LICENSE.txt` plus a `NOTICE.txt` documenting dots-ai-side changes (Codex/`~/.codex` paths removed, `agents/openai.yaml` replaced with `skill.json`, vendor logo assets dropped, MCP setup made tool-agnostic). `playwright` was renamed to `playwright-cli` to disambiguate from `dots-ai-e2e-runner`. New MCP templates under `~/.local/share/dots-ai/mcp/{linear,figma}/`. New helper `dots-newnotebook` (wrapper for the bundled jupyter scaffolder). `skill-catalog.yaml` and both `skills-registry.yaml` files updated; symlink templates added for Claude Code, OpenCode (`~/.agents/`), and Windsurf.
- Bundled interactive Project Assessment skills for evidence intake, management unit scorecards, technical unit scorecards, and final assessment reports; scoring is evidence-based, tracks confidence/missing evidence, and routes final outputs through `dots-ai-output-handshake`
- Bundled atomic Best Practices skills for planning, development workflow, work items, bugs/incidents, meeting minutes, decisions, agreements, and spikes; all use default templates under `references/default-template.md` and route final outputs through `dots-ai-output-handshake`
- Bundled skills **`dots-ai-prd`**, **`dots-ai-trd`**, and **`dots-ai-adr`**: pointers to the dots-ai **Best Practices** ClickUp templates and ADR workflow (`skill-catalog.yaml` and `skills-registry.yaml` updated; delegation row added to `dots-ai-workflow-generic-project` SKILL)
- Bundled skills **`dots-ai-output-handshake`** (confirm where deliverables are stored + human review) and **`dots-ai-pr-fallback`** (default PR/MR body from ClickUp [Guidelines for Creating PRs](https://example.com/work-tracker) when a repo has no template); integrated with `github-cli-workflow`, `gitlab-cli-workflow`, and `dots-ai-dev-companion` delegation
- **Documentation overhaul (Phase 1–4)**:
  - Expanded wiki from 9 stub pages → 19 substantive pages with full content
  - README visual upgrade: hero section, for-the-badge badges, collapsible ToC, documentation index
  - 4 new ADRs: skills compatibility matrix, LLM provider abstraction, multi-tool portability, agentic harness three-layer architecture
  - Mermaid diagrams in ARCHITECTURE.md, SKILLS.md, DEV_COMPANION.md, MCP_TEMPLATES.md, AGENTIC_HARNESS.md
  - GitHub admonitions (`[!TIP]`, `[!NOTE]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`) across all docs/
  - "See Also" cross-reference sections in all documentation files
  - `docs/README.md` documentation index with directory tree
  - Root `CHANGELOG.md` (this file)
  - 10 new wiki pages: SKILLS, DEV_COMPANION, LLM_PROVIDERS, AGENTIC_HARNESS, ARCHITECTURE, ADRS, WINDOWS, SECURITY, TROUBLESHOOTING, CHANGELOG
- Expanded 3 existing ADRs from skeleton to full format (Context bullets, Decision rationale, Positive/Negative consequences)

### Changed

- **`dots-doctor`**: prints a **system / workstation snapshot** before compliance checks (host, OS/kernel, WSL, locale, disk on `$HOME`, profile groups, bundled skill count, optional `chezmoi` source git, optional `~/.dots-ai-workspace` git ref, legacy `workflow-*` symlink sanity). New flags: `--issue` / `--paste` (Markdown for tickets), `--json` (single-line summary via `python3`), `--no-snapshot` (checks only). Docs: `docs/wiki/CLI.md`; **`dots-ai-workstation-triage`** skill updated (formerly `workstation-triage`).
- **`dots-doctor`**: **integrations** section — `~/.config/dots-ai/env.d` file names (dots-loadenv), `gh` / `clickup` / `glab` auth hints (no tokens), and profile-aware warnings for missing JIRA/Confluence env files; `--json` adds an `integrations` object.
- Standardized local apply examples on `chezmoi apply --source=. -c ~/.config/chezmoi/dots-ai.toml` and made `install.sh` use the same dedicated config file
- Moved GitHub CLI (`gh`) into the core workstation baseline with explicit apt repository bootstrap support
- Removed `neovim`/`nvim` from core workstation package and health-check requirements; the default editor fallback is now `vi`

### Fixed

- `docs/DEV_COMPANION_LLM.md` duplicate `#` title header removed
- `AGENTS.md` required docs list made into clickable links
- `docs/MULTI_AGENT_ORCHESTRATION.md` references made clickable
- `docs/REPOSITORY_GOVERNANCE.md` governance files made clickable

---

## [0.1.0] — Initial Release

### Added

- Bundled atomic Best Practices skills for planning, development workflow, work items, bugs/incidents, meeting minutes, decisions, agreements, and spikes; all use default templates under `references/default-template.md` and route final outputs through `dots-ai-output-handshake`
- Chezmoi-managed workstation AI layer for Linux, macOS, and Windows
- 20+ bundled AI skills with multi-tool compatibility (Claude Code, OpenCode, Cursor, Copilot CLI, Windsurf)
- 13+ specialized AI subagents for Claude Code, OpenCode, Cursor, and Windsurf
- Profile-driven installation: `full`, `basic`, `minimal`
- MCP server templates: GitHub, ClickUp, Notion, Slack, JIRA
- Dev companion with LLM-powered background runner and plan-only default
- `dots-*` CLI helpers: `dots-doctor`, `dots-skills`, `dots-devcompanion`, `dots-llm-server`, `dots-bootstrap`, `dots-sync-ai`, `dots-update-check`, `dots-loadenv`
- External skill packs via chezmoiexternal: JIRA Assistant (14 skills), Confluence
- CI pipeline: `validate-workstation`, `megalinter-v9`, `wiki-sync`, `security-scan`, `release-ai-assets`, pre-commit hooks
- Windows support with 3 installation modes: WSL2 (full), Git Bash (basic), Skills-only
- Architecture Decision Records: ADR-001 through ADR-003
- 15 documentation files under `docs/`
- GitHub Wiki sync from `docs/wiki/`
- Agentic harness framework with three-layer architecture (Infrastructure → Running Instance → Application)
- Client AI playbooks for generic workflow and workspace overlays

<!-- markdownlint-enable MD024 -->

---

[Unreleased]: https://github.com/ulises-jeremias/agentic-workstation/compare/main...HEAD
[0.1.0]: https://github.com/ulises-jeremias/agentic-workstation/commits/main
