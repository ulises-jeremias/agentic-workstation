# agentic-workstation dev companion — optional local queue (Tier B)

**Default:** interactive IDE sessions only (**Tier A**). This directory supports an **optional** queue + worker for bounded background jobs (**Tier B**).

Installed path after `chezmoi apply`: `~/.local/share/agentic-workstation/dev-companion/`.

## Layout

| Path | Purpose |
| --- | --- |
| `queue/pending/` | Drop job files (`.job` extension) |
| `queue/processing/` | Worker moves one job here while running |
| `queue/done/` | Completed jobs (archived) |
| `queue/failed/` | Failed jobs + stderr |
| `run/` | Lock file `worker.lock` |
| `logs/` | `worker.log` (worker stdout/stderr) and `llm-audit.log` (one-line JSON per LLM run, **metadata only**) |

## Job file format (JSON)

Minimal schema:

```json
{
  "id": "example-1",
  "created_at": "2026-03-31T12:00:00Z",
  "note": "Describe intent; wire command yourself",
  "run": {
    "command": ["echo", "noop"],
    "timeout_sec": 300
  }
}
```

- **`run.command`**: argv array executed by the worker **only if** you opt in (bounded subprocess). Leave unset for a no-op move (log-only), useful for testing the queue.
- **`timeout_sec`**: optional; defaults to **300**.

## Worker

- Script: `worker.sh` (same directory after apply; source in git is **`executable_worker.sh`** so chezmoi sets **+x**). Run manually: `~/.local/share/agentic-workstation/dev-companion/worker.sh` or `bash .../worker.sh`, or install systemd units under `systemd/user/`.
- **Single-flight**: uses `flock` on `run/worker.lock`.
- **No cloud, no API keys** in this baseline script—you must supply safe commands.

## systemd (user) — optional

Copy `systemd/user/*.service` and `*.timer` into `~/.config/systemd/user/`, then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now dots-workstation-dev-companion-worker.timer
```

Edit `ExecStart` paths if your home layout differs.

## Guardrails

Read **`~/.local/share/agentic-workstation/skills/dots-workstation-dev-companion/references/LOOP_GUARDRAILS.md`** before enabling timers.

## LLM policy (privacy / billing)

The runner picks an LLM provider through an explicit policy (env vars,
optional `~/.config/agentic-workstation/devcompanion-llm.json`, per-job overrides). For
client engagements that mandate a single AI account:

```bash
export DOTS_WORKSTATION_DEVCOMPANION_LLM_ALLOWLIST="anthropic"   # or: opencode, openai, ollama
export DOTS_WORKSTATION_DEVCOMPANION_LLM_STRICT="1"
dots-devcompanion llm-status   # confirms; never invokes the model
```

When `strict=true` and no allowed provider is available, `run-once` writes a
`policy_violation` artifact and exits with code `2`. See
`docs/DEV_COMPANION_LLM.md` and `runner/policy.py` for the full reference.

## Workspace integration (opt-in)

The companion works **standalone** without any other repos. When `~/ai-workspace` is present (optional layer):

- **`runner/dots_ai_devcompanion_runner.py`** (`plan-only` command) automatically detects it
- Loads context from `projects.yaml`, `projects/`, and `knowledge/todos/pending.md`
- Enriches LLM prompts with the full workspace awareness
- Override detection: set `$AI_WORKSPACE` to any path

This means queue jobs generated from the workspace get smarter context automatically, while jobs from a bare workstation get the same skeleton prompts as before.

See **`runner/README.md`** for details.
