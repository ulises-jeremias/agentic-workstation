# Dev Companion packs

Packs define **account** and **team** boundaries and defaults so automation can be:

- safe (domain ownership)
- portable (harness-agnostic)
- configurable (different accounts have different rules)

Installed path after `chezmoi apply`:

`~/.local/share/agentic-workstation/dev-companion/packs/`

## Layout

```
packs/
  accounts/<accountSlug>/pack.yaml
  teams/<teamSlug>/pack.yaml
  schemas/
    pack.schema.json
```

## Conventions

- `required_env` lists **variable names only** (no secrets).
- `allowed_paths` is an allowlist; anything outside should be rejected by runners.
- `automation_level_default` must be conservative (plan-only) unless the account explicitly opts into automation.
