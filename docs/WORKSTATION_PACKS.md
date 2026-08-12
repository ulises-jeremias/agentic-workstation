# Workstation Pack Provisioning (per #200)

Thin workstation pack selection — `agentic-workstation` provisions, `agent-toolkit` provides capabilities.

## Pack selection UX

Packs are **docs-only** curated workflow groupings per `agent-toolkit` ADR-0003 (`packs/` → `loops:` advisory, `distributions/products.yaml` → install).
Workstation does not install packs via `agent-toolkit install --pack`; it documents which packs to reference.

Declare the packs you use in chezmoi data or `~/.config/agentic-workstation/packs.yaml` as guidance:

```yaml
# ~/.config/agentic-workstation/packs.yaml — guidance only (not consumed by `agent-toolkit install`)
packs:
  - architecture
  - design-engineering
  - code-quality
  - agentic-security
```

`run_once_after_50-install-agent-toolkit.sh.tmpl` runs the thin-workstation install:

```bash
uv tool install --force agent-toolkit-cli
agent-toolkit install
```

Packs remain advisory (`skills:`/`agents:` not applied by `loop run --pack`; only `loops:` is applied). For product-scoped installation, edit `distributions/products.yaml` in `agent-toolkit` (see `docs/CONCEPTS.md#three-kinds-of-packs`).

## Doctor wiring

`dots-doctor` delegates to `agent-toolkit doctor` which validates provenance/pack/MCP consistency (per #387):

```bash
chezmoi apply --dry-run --verbose
agent-toolkit doctor --verbose
agent-toolkit inventory
agent-toolkit doctor --provenance
```

Probe inventory per product where needed (e.g. `agent-toolkit build --check`).

## Thin invariant

No `home/dot_local/share/agentic-workstation/skills/*` — capabilities delegated to `agent-toolkit` via `uv`. Runner logic `dev-companion/runner` retained.

Packs available: `oss-maintenance`, `engineering-workflow`, `delivery-discipline`, `agentic-security`, `architecture`, `code-quality`, `design-engineering` (7 total, per Toolkit `c5d35ef`).

Validation: `HOME=$(mktemp -d) chezmoi init --apply ulises-jeremias/agentic-workstation` → `agent-toolkit doctor` green.
