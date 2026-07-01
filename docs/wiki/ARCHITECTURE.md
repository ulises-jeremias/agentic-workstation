# Architecture

> Layered design model for the agentic-workstation workstation platform.

---

## Design principles

1. **chezmoi as engine** — all machine state flows through chezmoi
2. **Profile-driven** — no host-specific logic; profiles control behavior
3. **Idempotent** — safe to re-run `chezmoi apply` at any time
4. **Extensible** — new tools and skills added without breaking existing setups

---

## Layer model

| Layer | Scope | Location |
|-------|-------|----------|
| **Repository** | Source state, docs, CI | This checkout |
| **Machine** | Deployed files, CLI helpers | `~/.local/`, `~/.config/` |
| **Session** | AI workspace, knowledge, packs | `ai-workspace/` |

---

## Source state structure

```
home/
├── .chezmoidata/         # profiles, packages, skills registry
├── .chezmoiscripts/      # install scripts (run during apply)
├── dot_local/
│   ├── bin/              # dots-* CLI helpers
│   └── share/agentic-workstation/    # AI resources (skills, prompts, mcp)
└── dot_config/           # tool configurations
```

---

## AI layer architecture

Skills and agents are deployed to well-known paths and symlinked to each AI tool's config directory. The `dots-skills sync` command manages these symlinks.

→ Full details: [AI Overview](AI)

---

**Canonical doc:** [`docs/ARCHITECTURE.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/ARCHITECTURE.md)
