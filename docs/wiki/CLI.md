# CLI Helpers

> `dots-*` commands for workstation management, diagnostics, and AI tooling.

---

## Commands

| Command | Description |
|---------|-------------|
| `dots-doctor` | Health check — validates tools, directories, compliance, plus **system snapshot**; use `--issue` for ticket-friendly Markdown |
| `dots-skills list` | Show installed skills and their per-tool symlink status |
| `dots-skills sync` | Regenerate symlinks for all skills across AI tools |
| `dots-skills install <name>` | Install a skill from the registry |
| `dots-devcompanion enqueue <id>` | Queue a background job for the LLM runner |
| `dots-devcompanion run-once` | Process the next queued job |
| `dots-loadenv` | Load environment variables from `~/.config/dots-ai/env.d/` |
| `dots-update-check` | Check if the local baseline is behind origin/main |
| `dots-bootstrap` | Re-run `chezmoi apply` with dry-run preview |
| `dots-ai-audit` | Inventory AI tool installs, auth hints, and privacy/config metadata without printing secrets |
| `dots-security-audit` | Run shallow workstation security checks for sensitive permissions and baseline paths |

---

## Common workflows

### Validate your setup

```bash
dots-doctor
```

Checks: installed commands, expected directories, compliance status. Default output includes host/OS/disk/profile context, **integrations** (`env.d` file names, `gh` / `clickup` / `glab` auth — no secrets); `dots-doctor --issue` emits Markdown for issues; `dots-doctor --json` prints one JSON line (needs `python3`).

### Update to latest baseline

```bash
dots-update-check    # check for changes
chezmoi update      # pull + apply
dots-doctor          # verify
```

### Manage skills

```bash
dots-skills list           # show all skills
dots-skills sync           # regenerate symlinks
dots-skills install jira   # install optional skill
```

### Run a dev companion job

```bash
dots-devcompanion enqueue my-task    # queue a job
dots-devcompanion run-once           # process next job
```

### Check integrations

```bash
dots-loadenv
dots-doctor
gh auth status
clickup auth status
glab auth status
```

### Audit AI tools and workstation security

```bash
dots-ai-audit --issue
dots-ai-audit --json
dots-security-audit --issue
dots-security-audit --json
```

`dots-ai-audit` reports safe metadata for local AI tools such as Claude Code, Cursor, GitHub Copilot, OpenCode, Codex, Windsurf, and Gemini. It never prints token values, raw auth files, prompt history, chat logs, or memory contents. Vendor subscription details are best-effort locally; authoritative plan ownership usually requires the vendor's admin console or API.

`dots-security-audit` runs low-noise checks for sensitive file permissions, AI auth file permissions, and expected dots-ai directories. Deep secret scanning is skipped by default.

---

**Technical context:** [`docs/README.md`](https://github.com/ulises-jeremias/dots-ai/blob/main/docs/README.md)
