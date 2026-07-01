# agentic-workstation Dev Companion Platform

> Platform-level design for Dev Companion automation across multiple harnesses and client accounts.

---

This document explains the **platform-level** design for agentic-workstation Dev Companion automation across **multiple harnesses** (Cursor, Claude Code, pi.dev, CLI), and across **multiple client accounts**.

Authoritative, machine-installed assets live under `~/.local/share/agentic-workstation/` after `chezmoi apply`.

## Goals

- **Multi-harness**: users can keep their preferred harness; agentic-workstation ships consistent policies.
- **Account separation**: agentic-workstation has multiple client accounts; not all workflows and access are generalizable.
- **Reliability**: background runs are bounded, observable, resumable, and safe by default.
- **Portability**: policies are defined as files (skills/catalog/packs), not hardcoded in one IDE.

## Mental model: policy vs runtime

### Policy (portable, stable)

- Skills under `~/.local/share/agentic-workstation/skills/`:
  - **Companion layers** (e.g. `dots-workstation-dev-companion`)
  - **Workflow skills** (WHAT) (e.g. `dots-workstation-workflow-generic-project`)
  - **Tool skills** (HOW) (e.g. `github-cli-workflow`, `dbt-validation`, `snowflake-validation`)
- Routing metadata: `~/.local/share/agentic-workstation/skills/skill-catalog.yaml`
- Account/team packs: `~/.local/share/agentic-workstation/dev-companion/packs/` (see below)

### Runtime (pluggable, optional)

- Interactive (default): Cursor or any harness that loads skills.
- Background: systemd user timer + queue worker under `~/.local/share/agentic-workstation/dev-companion/`.
- Multi-agent (optional): pi.dev teams or Claude Code agent teams/subagents.

> [!NOTE]
> Interactive (IDE-first) is the default runtime. Background and multi-agent runtimes are opt-in.

## Account/team packs

Packs allow agentic-workstation to ship **account-specific** boundaries without forcing every engineer to enable everything.

Installed path:

```
~/.local/share/agentic-workstation/dev-companion/packs/
  accounts/<accountSlug>/pack.yaml
  teams/<teamSlug>/pack.yaml
```

Each pack defines:

- **triggers**: how to detect the account/team context (repo paths, ticket keys, keywords)
- **allowed_paths**: where automation is allowed to operate
- **required_env**: env var *names* required for privileged operations (no secrets in repo)
- **tool_requirements**: required CLIs (dbt, gh, jira-as, etc.)
- **automation_level**: defaults and guardrails (plan-only vs PR automation)

> [!CAUTION]
> Never store secrets in pack files. Use `required_env` to declare env var **names** only — actual values come from `~/.config/agentic-workstation/env.d/`.

## Recommended defaults for agentic-workstation

- **Per-developer local runtime by default**: skills + optional worker/timer; developers opt into multi-agent runtime.
- **Per-account separation by allowlists first**:
  - `allowed_paths` prevents cross-account access on a single machine.
  - Credentials stay in `~/.config/agentic-workstation/env.d/*.env` and are scoped by naming convention.
- **Escalation-first**: if context is ambiguous, ask; if credentials missing, record "skipped" and stop.

## LLM Provider Abstraction

The runner includes a **provider-agnostic LLM layer** for intelligent plan generation:

```
~/.local/share/agentic-workstation/dev-companion/runner/
  providers/
    base.py              # Abstract LLMProvider interface
    opencode_provider.py # OpenCode (big-pickle, free)
    ollama_provider.py   # Ollama (local models, free)
    anthropic_provider.py # Anthropic Claude (paid)
    openai_provider.py   # OpenAI GPT (paid)
  llm_dispatcher.py      # Auto-selects best available provider
  prompts/
    plan.md.j2           # Prompt template
```

Priority: OpenCode → Ollama → Anthropic → OpenAI (first available wins).

## Where to put harness-specific assets

- Cursor: keep project rules thin (see [DEV_COMPANION.md](DEV_COMPANION.md)).
- Claude Code: project/user subagents under `.claude/agents/` and `~/.claude/agents/` (optional adapter shipped by this repo).
- pi.dev: optional teams runtime configuration and hooks (optional adapter shipped by this repo).

---

## See Also

- [DEV_COMPANION.md](DEV_COMPANION.md) — companion layers overview
- [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md) — LLM provider details
- [DEV_COMPANION_RELIABILITY.md](DEV_COMPANION_RELIABILITY.md) — reliability patterns
- [MULTI_AGENT_ORCHESTRATION.md](MULTI_AGENT_ORCHESTRATION.md) — multi-agent runtime
- [AGENTIC_HARNESS.md](AGENTIC_HARNESS.md) — three-layer architecture framework
