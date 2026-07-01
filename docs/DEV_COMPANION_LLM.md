# LLM Integration for Dev Companion

> How the dev-companion runner picks an LLM, and how to constrain it to honor
> client privacy/billing requirements.

---

## TL;DR

- The runner now ships a **policy layer** ([`policy.py`](../home/dot_local/share/agentic-workstation/dev-companion/runner/policy.py)). You can keep the historical zero-config behaviour or **lock the runner to a single backend** (e.g. only Anthropic via the client's API key) and **fail closed** if that backend is unreachable.
- Inspect the active policy with `dots-devcompanion llm-status` (no model call).
- The policy is composed from three layers; later layers can only **restrict**, never widen:

```
env vars  →  ~/.config/agentic-workstation/devcompanion-llm.json  →  per-job "llm" block
```

> [!IMPORTANT]
> If a client engagement requires "**only** their Anthropic / OpenAI / OpenCode account", you **must** apply the [Client-Restricted Mode](#client-restricted-mode) below. The default mode is convenient for internal agentic-workstation work but does not enforce single-backend usage.

---

## Two Modes

### Default Mode (agentic-workstation)

Convenience-first. The dispatcher tries providers in this hard-coded order
and picks the first available one:

| Priority | Provider | Type | Cost | Requirements |
|----------|----------|------|------|--------------|
| 1 | OpenCode (`opencode/big-pickle`) | Local | Free | `opencode` installed |
| 2 | Ollama | Local | Free | `ollama` installed + models |
| 3 | Anthropic (Claude) | Cloud | Paid | `ANTHROPIC_API_KEY` |
| 4 | OpenAI | Cloud | Paid | `OPENAI_API_KEY` |

> [!TIP]
> This mode is fine for internal agentic-workstation exploration, training and demos. **Do not** use it for client repos when contracts mandate a single AI account.

### Client-Restricted Mode

Explicitly declare the only providers/identity you will use, and refuse to
fall back to anything else.

```bash
# Allow only Anthropic. Use the client's key, not agentic-workstation'.
export ANTHROPIC_API_KEY="<client key from their secret store>"
export DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST="anthropic"
export DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT="1"

dots-devcompanion llm-status     # confirm
dots-devcompanion run-once       # run; refuses to fall back to OpenCode/Ollama
```

If `anthropic` is unavailable, `run-once` writes a `policy_violation` artifact
and exits with code `2` instead of silently using OpenCode.

---

## Policy Layers

### 1. Environment Variables

| Variable | Type | Notes |
|----------|------|-------|
| `DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST` | comma list | Ordered preference, e.g. `anthropic,opencode` |
| `DOTS_WORKSTATION_DEVCOMPANION_LLM_DENYLIST` | comma list | Always blocked, even if allowlisted |
| `DOTS_WORKSTATION_DEVCOMPANION_LLM_PINNED_PROVIDER` | string | Only this provider is tried |
| `DOTS_WORKSTATION_DEVCOMPANION_LLM_PINNED_MODEL` | string | Override the provider's default model |
| `DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT` | `1`/`true`/`yes`/`on` | Fail closed if no allowed provider is available |
| `DOTS_WORKSTATION_DEVCOMPANION_LLM_CONFIG` | path | Override the policy file path |

Per-engagement env files under `~/.config/agentic-workstation/env.d/` are a good place to
set these (loaded by `dots-loadenv`).

### 2. Policy File

Optional JSON file at `~/.config/agentic-workstation/devcompanion-llm.json`:

```json
{
  "allowlist": ["anthropic"],
  "denylist": ["opencode", "ollama"],
  "pinned_model": "claude-3-7-sonnet-latest",
  "strict": true
}
```

Override the path with `DOTS_WORKSTATION_DEVCOMPANION_LLM_CONFIG=/some/other.json`.

### 3. Per-Job `llm` Block

Inside each `.job` file, the optional `llm` object can **further restrict**
the global policy. Trying to widen it (add a provider not allowed globally,
disable strict mode set globally, pin a denied provider) **fails the job
with `status: "policy_violation"`** and exit code `2`.

```json
{
  "id": "client-x-task-1",
  "created_at": "2026-04-30T12:00:00Z",
  "request": "Refactor auth middleware",
  "repo_path": "/repos/client-x",
  "llm": {
    "enabled": true,
    "allowlist": ["anthropic"],
    "model": "claude-3-7-sonnet-latest",
    "strict": true
  }
}
```

The legacy boolean form `"llm": true|false` is still accepted (acts as
`enabled` only, no overrides).

---

## `dots-devcompanion llm-status`

Shows the active policy and which provider would run **without** invoking any
model. Safe to run on customer machines.

```bash
dots-devcompanion llm-status
dots-devcompanion llm-status --json
dots-devcompanion llm-status --job ~/.local/share/agentic-workstation/dev-companion/queue/pending/foo.job
```

Exit codes:

| Exit | Meaning |
|------|---------|
| `0` | A provider would run, or the runner would fall back to skeleton (non-strict) |
| `1` | `strict=true` and no allowed provider is available |
| `2` | The policy itself is invalid (e.g. job widens global allowlist) |

---

## Artifacts and Audit

`result.json` now embeds the active policy (`llm_policy_applied`) and a
single-line JSON record is appended to
`~/.local/share/agentic-workstation/dev-companion/logs/llm-audit.log`:

```json
{
  "ts": "2026-04-30T12:00:05Z",
  "job_id": "client-x-task-1",
  "status": "planned_via_llm",
  "provider": "anthropic",
  "model": "claude-3-7-sonnet-latest",
  "policy": {
    "allowlist": ["anthropic"],
    "denylist": [],
    "pinned_provider": null,
    "pinned_model": "claude-3-7-sonnet-latest",
    "strict": true,
    "sources": ["env", "job"],
    "warnings": []
  }
}
```

> [!NOTE]
> The audit log is **metadata only** — prompts and model output are never written there, so it is safe to keep on customer machines and to share with security reviewers.

---

## Cursor / Copilot

The runner does **not** ship Cursor or Copilot adapters today. The full
roadmap, decision matrix, and acceptance criteria for a future delegated CLI
provider live in [`DEV_COMPANION_IDE_ROADMAP.md`](DEV_COMPANION_IDE_ROADMAP.md).

Short version:

| Strategy | Compliance | Effort | Status |
|----------|------------|--------|--------|
| **Mode A** — `--no-llm` skeleton + IDE-driven LLM with the client account | High (no headless LLM call) | Low | **Recommended today** |
| **Mode B** — delegated `LLMProvider` that shells out to a vendor CLI | Medium-High | High | Roadmap, criteria documented |
| **Mode C** — runner deployed on a VM in the client's account | High (network segregation) | Infra | Engagement-specific |

---

## How the Runner Picks a Provider

```
┌──────────────────────────────────────────────────────────────────┐
│  dots_ai_devcompanion_runner.py                                      │
│                                                                  │
│  1. Read job JSON (incl. optional `llm` overrides)               │
│  2. Compose policy: env  →  file  →  job (job restricts only)    │
│  3. Build dispatcher; provider list filtered by policy           │
│  4. First filtered provider with `is_available()` is selected    │
│  5. If none and `strict`: fail closed (`policy_violation`)       │
│  6. Else generate plan → write artifacts + append audit log      │
└──────────────────────────────────────────────────────────────────┘
```

---

## FAQ

**Q: How do I force "only the client's Anthropic key, never OpenCode"?**
A: Set `DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST=anthropic` and
`DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT=1` (per-engagement env file). Run
`dots-devcompanion llm-status` to confirm before queuing jobs.

**Q: Can a job widen the global allowlist?**
A: No. Job `llm` blocks may only **restrict** (subset, additional denies,
escalate to `strict=true`). Widening attempts produce a `policy_violation`
artifact and exit code `2`.

**Q: My job failed with `policy_violation: no LLM provider permitted by
policy is available`. What now?**
A: The strict policy is doing exactly what you asked. Either provision the
allowed provider (e.g. install `opencode` or set the right API key) or
relax the policy explicitly.

**Q: How do I debug?**
A: `DOTS_WORKSTATION_LLM_DEBUG=1 dots-devcompanion llm-status` shows full provider
detection. Check the audit log under
`~/.local/share/agentic-workstation/dev-companion/logs/llm-audit.log`.

**Q: Can I keep the old zero-config behaviour?**
A: Yes — leave the env vars unset and no policy file. The dispatcher behaves
exactly as before and `result.json` stays compatible.

---

## Extending Providers

Add new providers by implementing `LLMProvider` from
[`providers/base.py`](../home/dot_local/share/agentic-workstation/dev-companion/runner/providers/base.py):

```python
class MyProvider(LLMProvider):
    name = "myprovider"
    is_local = True
    is_free = True

    def is_available(self) -> bool:
        return shutil.which("my-cli") is not None

    def get_priority(self) -> int:
        return 1

    def generate(self, prompt, system_prompt, repo_path, timeout_sec) -> LLMResponse:
        ...
```

Register it in `providers/__init__.py` and add the name to
`policy.KNOWN_PROVIDERS` so policy validation accepts it.

---

## See Also

- [DEV_COMPANION.md](DEV_COMPANION.md) — overview and layers
- [DEV_COMPANION_IDE_ROADMAP.md](DEV_COMPANION_IDE_ROADMAP.md) — Cursor / Copilot / Claude IDE compliance modes and roadmap
- [DEV_COMPANION_PLATFORM.md](DEV_COMPANION_PLATFORM.md) — platform schema
- [DEV_COMPANION_RELIABILITY.md](DEV_COMPANION_RELIABILITY.md) — reliability patterns
- [wiki/CLI.md](wiki/CLI.md) — `dots-devcompanion` command reference
