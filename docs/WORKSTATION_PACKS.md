# Workstation Pack Provisioning (per #200)

Thin workstation pack selection — `agentic-workstation` provisions, `agent-toolkit` provides capabilities.

## Pack selection UX

Packs are declared in chezmoi data or `~/.config/agentic-workstation/packs.yaml`:

```yaml
packs:
  - architecture
  - design-engineering
  - code-quality
  - agentic-security
```

`run_once_after_50-install-agent-toolkit.sh.tmpl` runs:

```bash
uv tool install --force agent-toolkit-cli
agent-toolkit install --pack <pack>  # per-pack install (once implemented in #395/#390)
```

If `--pack` not yet in CLI, workstation falls back to `agent-toolkit install` (all detected tools) and `agent-toolkit inventory --pack <name>` for validation.

## Doctor wiring

`dots-doctor` delegates to `agent-toolkit doctor` which now validates provenance/pack/MCP (per #387):

```bash
chezmoi apply --dry-run --verbose
agent-toolkit doctor --verbose
agent-toolkit inventory --pack design-engineering
```

## Thin invariant

No `home/dot_local/share/agentic-workstation/skills/*` — capabilities delegated to `agent-toolkit` via `uv`. Runner logic `dev-companion/runner` retained.

Depends on Toolkit packs #390 (design-engineering, agentic-security, code-quality, architecture).

Validation: `HOME=$(mktemp -d) chezmoi init --apply ulises-jeremias/agentic-workstation` → `agent-toolkit doctor` green.

Scaffold per #200.
