# Dev Companion

> LLM-powered background job runner for autonomous delivery tasks.

---

## Overview

The Dev Companion is a background job system that uses AI models to generate intelligent plans and execute delivery tasks. It supports multiple LLM providers and works out-of-the-box with OpenCode's built-in `big-pickle` model.

---

## How it works

1. **Enqueue** a job with `dots-devcompanion enqueue <id>`
2. **Process** with `dots-devcompanion run-once`
3. The runner picks the best provider **allowed by the active LLM policy** (env / config file / per-job overrides)
4. A plan is generated and written as artifacts (or a `policy_violation` artifact if strict mode blocks the run)

> [!IMPORTANT]
> By default, the runner falls back to the first available provider (OpenCode → Ollama → Anthropic → OpenAI). For client engagements that mandate a single AI account, configure an **allowlist + strict** policy and verify with `dots-devcompanion llm-status`. See [`DEV_COMPANION_LLM.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/DEV_COMPANION_LLM.md) for the full reference.

---

## Companion layers

| Layer | Skill | Purpose |
|-------|-------|---------|
| **L1** | `dots-workstation-assistant` | Repository inspection and discovery |
| **L2** | `dots-workstation-dev-companion` | General delivery companion |
| **L3** | Workspace pack overlay | Client/account context |

L2 and L3 are **independent** — overlays are loaded from the user workspace (`~/.ai-workspace/packs/`).

---

## Delivery phases

The companion follows a structured delivery workflow:

1. **Plan** — understand requirements, break down tasks
2. **Implement** — write code following conventions
3. **Review** — code review and quality checks
4. **PR** — create draft pull request

Human gates are required between phases for non-trivial changes.

---

## Artifacts

When a job completes, the runner produces:

- `plan.md` — LLM-generated plan (or skeleton plan when LLM is disabled / policy blocks)
- `result.json` — metadata (provider, model, duration, **`llm_policy_applied`**)
- `~/.local/share/agentic-workstation/dev-companion/logs/llm-audit.log` — single-line JSON audit per run (metadata only, no prompts/output)

---

**Canonical doc:** [`docs/DEV_COMPANION.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/DEV_COMPANION.md)
