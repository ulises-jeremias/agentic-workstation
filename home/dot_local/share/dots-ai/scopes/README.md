# Skill Scopes (RBAC)

> Skill scopes restrict which bundled skills are active for a given engagement context.
> This is an **opt-in, additive** layer — without a scope file, all skills are enabled.

## Use case

When working on a client project that only allows specific AI tools or has confidentiality
constraints, you can define a scope that whitelists only the relevant skills:

```bash
# Enable a scope
dots-skills enable --scope client-a

# Sync active scope to AI tool directories
dots-skills sync

# Disable scope (back to all skills)
dots-skills enable --scope default
```

## Scope file format

Scope files live in `~/.local/share/dots-ai/scopes/<scope-name>.yaml`:

```yaml
# scopes/client-a.yaml
name: client-a
description: "Skills allowed for Acme Corp engagement"
skills:
  allow:
    - dots-ai-assistant
    - github-cli-workflow
    - dots-ai-code-reviewer
    - clickup-cli
  # Omit 'allow' to enable all skills
  deny:
    - snowflake-validation
    - dbt-validation
```

## Status

This is a **T3 experimental** feature. The scope manifest format is defined here
and honored by `dots-skills sync` when a `--scope` flag is passed. Full RBAC
(multi-tenant, per-org enforcement) is deferred to a later milestone.
