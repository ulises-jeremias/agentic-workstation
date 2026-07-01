# Dev Companion — IDE-bound LLM roadmap (Cursor / Copilot / Claude IDE)

> Operational guidance and acceptance criteria for engagements where the
> client mandates "use **only** their Cursor / Copilot / Claude account from
> the IDE; no headless API calls". Companion to
> [`DEV_COMPANION_LLM.md`](DEV_COMPANION_LLM.md).

---

## Why we need this doc

The dev-companion runner (`dots-devcompanion run-once`, `bin/devcompanion run-once`) calls an LLM **headlessly** through provider classes in
[`runner/providers/`](../home/dot_local/share/agentic-workstation/dev-companion/runner/providers/).
Today the only viable headless providers are:

| Provider | Headless transport |
|----------|--------------------|
| OpenCode | `opencode run --format json` |
| Ollama | `ollama run` |
| Anthropic | direct REST against `api.anthropic.com` |
| OpenAI | direct REST against `api.openai.com` |

There is **no stable, dots-workstation-supported headless equivalent for Cursor or
Copilot today** — both are designed around an interactive IDE session. That
is fine for users, but it means the runner cannot honor "only Cursor" or
"only Copilot" the same way it honors "only Anthropic via API".

This document captures the supported workarounds and the criteria a future
adapter must meet before we ship one.

---

## Mode A — Skeleton + IDE (immediate, recommended for compliance)

**When to use:** the client mandates a single IDE-bound AI tool (Cursor,
Copilot, Claude IDE, JetBrains AI, ...) and forbids headless API calls.

**How:**

1. Lock the queue out of LLM use. In the engagement env file
   (`~/.config/agentic-workstation/env.d/<client>.env`):
   ```bash
   export DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST=""        # nothing allowed
   export DOTS_WORKSTATION_DEVCOMPANION_LLM_DENYLIST="opencode,ollama,anthropic,openai"
   export DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT="1"
   ```
   With the empty allowlist plus strict mode, any attempt to run an LLM job
   produces a `policy_violation` artifact (exit code `2`) — this is the
   guard rail.
2. Always queue with `--no-llm` (or the per-job override `"llm": { "enabled": false }`):
   ```bash
   dots-devcompanion enqueue review-1 --request "code review of feature/x"
   dots-devcompanion run-once --no-llm
   ```
   The runner writes a **skeleton plan** with the request, repo path, and
   workspace context, but never calls a model.
3. Open the produced `plan.md` artifact in the IDE and let the developer
   drive Cursor / Copilot / Claude IDE from there using the **client's
   account**, exactly as they would for any other task.

**What you get:** queue traceability (jobs in `queue/done/` with audit log
entries), no headless model calls, full alignment with the engagement.

**What you don't get:** auto-generated plan content. That's intentional.

---

## Mode B — Delegated CLI provider (future work)

**When to use:** the client allows automation **iff** it is performed
through the same vendor CLI/IDE binary the developer uses (so all activity
shows up in their AI tool's audit trail under the client's tenant).

This requires a new `LLMProvider` subclass per vendor CLI. We do **not** ship
one today; below are the acceptance criteria a candidate adapter must meet
before it lands in `runner/providers/`.

### Acceptance criteria for a new IDE-bound provider

1. **Stable headless invocation.** The vendor CLI must support a non-interactive
   mode that takes a prompt on stdin or via flag and returns a deterministic
   exit code + plain text or JSON on stdout. Examples that would qualify:
   - `cursor agent run --prompt "..." --json`
   - `gh copilot suggest --prompt "..." --json`
   - `claude --headless --prompt-file ...`

   Anything that requires an active IDE window or a GUI interaction is
   **disqualified**.

2. **Pinned versions.** The provider must declare the minimum vendor CLI
   version in its `is_available()` check (parse `--version`). agentic-workstation will
   not silently use an upgraded CLI whose interface changed.

3. **Auditable identity.** The CLI must use the user's logged-in vendor
   account (e.g. `cursor whoami`, `gh auth status`) — never an env-var token
   we set. The provider records the reported identity (no PII more than
   needed) into the audit log so security can verify "who paid".

4. **No prompt leakage.** Any failure mode (timeout, parse error, vendor
   server error) must surface a sanitized error string; the audit log must
   not contain the prompt body.

5. **Tests.** Unit tests under `runner/tests/` mocking the subprocess call,
   exactly like `test_dispatcher.py` for the existing providers. CI runs
   `python3 -m unittest tests.test_policy tests.test_dispatcher tests.test_<new>`.

6. **Policy registration.** Add the provider name to `KNOWN_PROVIDERS` in
   [`policy.py`](../home/dot_local/share/agentic-workstation/dev-companion/runner/policy.py)
   and document it in [`DEV_COMPANION_LLM.md`](DEV_COMPANION_LLM.md).

7. **Default off.** New IDE-bound providers ship with `is_available()`
   returning `False` unless the vendor CLI is installed **and** the user
   opts in (e.g. via env var). They never displace OpenCode in the default
   priority order.

### Why we don't ship one today

- **Cursor agent CLI** is evolving; no dots-workstation-internal contract pins its
  version, JSON shape, or auth model.
- **GitHub Copilot CLI** is interactive-first. `gh copilot suggest` does
  not currently produce a deterministic, machine-parseable plan suitable for
  `plan.md`.
- **Claude / Anthropic IDE** integration ships through the API, which we
  already cover via the `anthropic` provider with the client's API key.

We will revisit when any of these vendors publish a stable, scriptable
non-interactive surface.

---

## Mode C — Remote runner in the client's account (engagement-specific)

**When to use:** the client requires that all data ingestion (prompts and
repo content) happen on infrastructure they control.

**How:** ship the runner (and the worker) to a VM the client provisions in
their cloud, configure dots-workstation-side `bin/devcompanion` to delegate to it
(SSH or a queue gateway), and lock down the local runner with strict
allowlist as in Mode A.

This is engagement infrastructure, not a agentic-workstation feature. It does not
require code changes; it does require an explicit agreement, a runbook in
the client's pack, and an extra layer in `dots-doctor` that warns when both
the local runner **and** the remote runner are reachable (we don't want a
job to run in two places).

---

## Decision matrix (which mode for which engagement)

| Engagement constraint | Mode |
|-----------------------|------|
| "Use our Anthropic API key, no other LLM" | Already supported — see [`DEV_COMPANION_LLM.md`](DEV_COMPANION_LLM.md), Client-Restricted Mode (env: `allowlist=anthropic`, `strict=1`) |
| "Use our OpenAI API key, no other LLM" | Same as above with `allowlist=openai` |
| "Use only OpenCode against our endpoint" | `allowlist=opencode` + verify the developer's `opencode` config points at the client's gateway |
| "Use only Cursor / Copilot / Claude IDE" | **Mode A** today (skeleton + IDE). Mode B once a stable CLI ships |
| "All inference must happen on our cloud" | **Mode C** (remote runner) + Mode A locks |
| "No AI in the queue at all" | Mode A with `--no-llm` queued by default |

---

## Operational checklist (before queuing client work)

- [ ] Engagement env file under `~/.config/agentic-workstation/env.d/<client>.env` exists and exports the right `DOTS_WORKSTATION_DEVCOMPANION_LLM_*` and credentials.
- [ ] `dots-devcompanion llm-status` reports the expected provider (or "would run: NONE" with strict + Mode A).
- [ ] If using Mode A: every queue command includes `--no-llm` or the template ships `"llm": { "enabled": false }`.
- [ ] `~/.local/share/agentic-workstation/dev-companion/logs/llm-audit.log` is rotated/archived per engagement retention policy (the runner only appends; rotation is operational).
- [ ] Workspace is wired to the workstation runner: `AI_WORKSPACE_RUNNER_DIR=$HOME/.local/share/agentic-workstation/dev-companion/runner`.

---

## See also

- [`DEV_COMPANION_LLM.md`](DEV_COMPANION_LLM.md) — policy reference, env vars, file format
- [`DEV_COMPANION.md`](DEV_COMPANION.md) — runner overview
- [`wiki/CLI.md`](wiki/CLI.md) — `dots-devcompanion` command list
- [`home/dot_local/share/agentic-workstation/skills/dots-workstation-dev-companion/references/LOOP_GUARDRAILS.md`](../home/dot_local/share/agentic-workstation/skills/dots-workstation-dev-companion/references/LOOP_GUARDRAILS.md) — autonomous loop guardrails
