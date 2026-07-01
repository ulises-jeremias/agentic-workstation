# ADR-010: Rename to agentic-workstation

## Status

Accepted

## Context

Since ADR-009 (keep name, refresh tagline) was accepted, the agentic-workstation ecosystem has grown significantly. The companion workspace (`ai-workspace`) already decided in its ADR-0001 to rename to `agentic-harness`, but that rename was never executed because the two repos' identities are intertwined.

Several factors now favor revisiting the keep-name decision:

1. **Cross-repo naming friction** — The `dots-harness-knowledge-sync` skill literally combines both old names. Renaming one repo without the other would leave it disonant.
2. **Three-layer clarity** — ADR-007 established a three-layer architecture (L1: workstation, L2: running instance, L3: client repos). A cohesive naming scheme (`agentic-workstation` + `agentic-harness`) makes the layers self-evident from the repo names alone.
3. **The `dots-` prefix is independent** — The `dots-*` CLI prefix (60+ commands: `dots-doctor`, `dots-skills`, `dots-mcp`, `dots-wallpaper`, etc.) is a personal brand for all workstation scripts, not a derivation of the repo name. The rename does not affect it.
4. **Coordination opportunity** — Renaming both repos in tandem minimizes disruption and avoids a staggered migration.

## Decision

Rename the repository from `agentic-workstation` to `agentic-workstation` with the following scope:

### What changes

| Artifact | Old | New |
|----------|-----|-----|
| GitHub repo | `ulises-jeremias/agentic-workstation` | `ulises-jeremias/agentic-workstation` |
| chezmoi source dir | `~/.agentic-workstation` | `~/.agentic-workstation` |
| Install data dir | `~/.local/share/agentic-workstation` | `~/.local/share/agentic-workstation` |
| Config dir | `~/.config/agentic-workstation` | `~/.config/agentic-workstation` |
| Library dir | `~/.local/lib/agentic-workstation` | `~/.local/lib/agentic-workstation` |
| chezmoi config file | `~/.config/chezmoi/agentic-workstation.toml` | `~/.config/chezmoi/agentic-workstation.toml` |
| GitHub repo description | "Chezmoi-managed agentic workstation baseline..." | "Agentic Workstation Baseline — chezmoi-managed..." |
| Tagline | "Agentic Workstation Baseline — chezmoi-managed skills, agents, MCP, and loops for AI-assisted delivery." | Unchanged (already accurate) |

### What stays the same

| Artifact | Reason |
|----------|--------|
| CLI prefix `dots-*` (60+ commands) | Personal brand, independent of repo name |
| Skill prefix `dots-` | Consistent with CLI commands |
| chezmoi source root (`home/`) | Internal structure, not repo-bound |
| `.chezmoiroot` pointing to `home/` | Internal structure |
| Internal conventions (scripts, docs layout) | Not name-dependent |

## Consequences

### Positive

- Cohesive naming across L1 (`agentic-workstation`) and L2 (`agentic-harness`) — the three-layer model is self-evident
- Eliminates ambiguity about the project's purpose (it's an Agentic Workstation, not generic dots)
- Cross-repo skill `dots-harness-knowledge-sync` can cleanly rename to `dots-harness-knowledge-sync`
- GitHub redirects old URLs automatically — existing links continue to work
- The `dots-` CLI prefix is preserved — no muscle memory lost
- Coordinated rename with agentic-harness avoids staggered migration pain

### Negative

- Migration cost: updating ~1,500 references across docs, scripts, CI workflows, and templates
- All local clones need remote URL updates
- Install paths (`~/.local/share/agentic-workstation/`, `~/.config/agentic-workstation/`) require migration scripts
- chezmoi source state path changes — existing `~/.agentic-workstation/` must be moved
- External integrations referencing `ulises-jeremias/agentic-workstation` need updates
