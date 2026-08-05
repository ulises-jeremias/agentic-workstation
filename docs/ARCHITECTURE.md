# Architecture

> Layered design model and source state conventions for the **thin** agentic-workstation.

![agentic-workstation three-layer architecture](../static/architecture.svg)

---

`agentic-workstation` keeps repository governance and workstation state clearly separated. The thin workstation delegates all capability content to `agent-toolkit` via `uv`.

## Design principles

- Keep the source state simple and predictable — no embedded skills/packs/personas/agents/MCPs.
- Prefer profile-driven behavior over host-specific custom logic.
- Keep scripts idempotent and safe to re-run — single installer path (`uv tool install --force`).
- Treat docs, wiki, and ADRs as first-class product artifacts.

---

## Layered model — thin workstation

```mermaid
graph TD
    subgraph "Repository Layer"
        A[docs/ + ADRs + CI] --> B[home/ — chezmoi source state (thin)]
    end

    subgraph "Machine Layer (after chezmoi apply) - thin"
        B --> C["~/.local/bin/ — dots-* CLI helpers (thin, delegate)"]
        B --> D["~/.local/share/agentic-workstation/ — runner only"]
        B --> E["~/.config/ — tool configs"]
        D --> F["dev-companion/runner — workstation-only logic"]
        D --> G["scopes/ — workstation-only"]
        D -.->|"delegated via uv tool install --force agent-toolkit-cli"| H["agent-toolkit provides: skills, agents, MCP, prompts, loops"]
    end

    subgraph "Session Layer (AI workspace)"
        I["knowledge/ — persistent memory"]
        J["personas/ — scope constraints (via toolkit)"]
        K["packs/ — client context bundles (via toolkit)"]
    end

    H -.->|symlinks via dots-skills sync (delegated)| L["~/.claude/skills/"]
    H -.->|symlinks via dots-skills sync (delegated)| M["~/.config/opencode/skills/"]
    H -.->|symlinks via dots-skills sync (delegated)| N["~/.cursor/skills/"]
    H -.->|symlinks via dots-skills sync (delegated)| O["~/.agents/skills/"]
```

### Layer details — thin

1. **Data model** (`home/.chezmoidata`)
   Shared configuration for package groups, AI settings, profiles. Skills registry is empty — catalog comes from toolkit.
2. **Bootstrap scripts** (`home/.chezmoiscripts`)
   Thin install: `run_once_after_50-install-agent-toolkit.sh.tmpl` runs `uv tool install --force agent-toolkit-cli && agent-toolkit install`. `run_onchange_45` delegates to the same.
3. **Shared assets — thin** (`home/dot_local/share/agentic-workstation`)
   Only workstation-only runner logic: `dev-companion/runner`, `scopes`, `telemetry`, `pacman-hooks`. No `skills/*`, `loops/*`, `mcp/*`, `prompts/*`, `packs/teams`.
4. **CLI helpers — thin** (`home/dot_local/bin`)
   `dots-skills`, `dots-loop`, `dots-devcompanion` etc. delegate to `agent-toolkit` where applicable.

---

## Three-layer model — thin

agentic-workstation operates across three distinct layers with clear separation of concerns:

```mermaid
graph TD
    subgraph "L1 — agentic-workstation (thin, this repo)"
        AW1["Machine provisioning<br/>(chezmoi, shell, packages)"]
        AW2["Secrets & LLM policy<br/>(dots-devcompanion, env.d)"]
        AW3["dots-* helpers (thin, delegate)<br/>(dots-skills, dots-loop, dots-doctor)"]
        AW4["dev-companion runner (kept)<br/>workstation-only"]
    end

    subgraph "L1.5 — agent-toolkit (sole capability source)"
        AT1["52 skills / 9 domains"]
        AT2["16 agent personas"]
        AT3["10 loop templates"]
        AT4["6 tool profiles<br/>(Claude Code, Cursor, OpenCode…)"]
        AT5["6 MCP templates"]
        AT6["Prompts + packs"]
    end

    subgraph "L3 — Project overlay"
        PO1["Project AGENTS.md"]
        PO2["Engagement packs"]
        PO3["Client-specific skills"]
    end

    AW1 -->|"uv tool install --force agent-toolkit-cli<br/>agent-toolkit install"| AT1
    AW1 -->|"uv tool install --force agent-toolkit-cli<br/>agent-toolkit install"| AT2
    AW1 -->|"uv tool install --force agent-toolkit-cli<br/>agent-toolkit install"| AT3
    AW1 -->|"uv tool install --force agent-toolkit-cli<br/>agent-toolkit install"| AT4
    AW1 -->|"uv tool install --force agent-toolkit-cli<br/>agent-toolkit install"| AT5
    AW3 -->|"dots-skills sync (delegated)"| AT1
    AW3 -->|"dots-loop init (delegated)"| AT3
    AT1 --> PO3
    AT4 --> PO1
```

### Layer responsibilities — thin

| Layer | Repo | Responsibility |
|-------|------|----------------|
| **L1** | `agentic-workstation` (thin) | Machine provisioning + runner — chezmoi, packages, shell, LLM policy, `dev-companion/runner` |
| **L1.5** | `agent-toolkit` (sole source) | Capability distribution — skills, agents, profiles, loops, MCP, prompts, packs |
| **L3** | Project repo | Overlays — project AGENTS.md, engagement packs, client skills |

> [!IMPORTANT]
> **Thin workstation: all capabilities are delegated.** No `skills/*`, `loops/*`, `mcp/*`, `prompts/*`, `packs/teams`, `agents/*`, `rules/*` are embedded. Install via `uv tool install --force agent-toolkit-cli && agent-toolkit install`. `SKILL.md` catalog is provided by the toolkit at runtime.

---

## Skills architecture — thin

Skills are **solely** distributed by [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) — 52 skills, 16 agent personas, 10 loop templates, 6 MCP templates. agentic-workstation's `home/dot_local/share/agentic-workstation/skills/` is a placeholder README. The toolkit installs to `~/.local/share/agentic-workstation/skills-external/agent-toolkit/` and `dots-skills sync` (delegated) creates symlinks.

- **agent-toolkit skills** — installed via `uv tool install --force agent-toolkit-cli && agent-toolkit install`
- **No bundled workstation skills** — previous bundled dirs have been removed; workstation-only logic remains in `dev-companion/runner`
- **No embedded loops/MCP/prompts/packs** — all provided by toolkit

Each toolkit skill contains `SKILL.md` frontmatter that declares compatibility. `agent-toolkit install` + `dots-skills sync` creates symlinks in tool-specific directories.

> [!NOTE]
> See [SKILLS.md](SKILLS.md) for the full skills system documentation.
> See [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) for the thin delegation reference.

---

## Source state convention

- `.chezmoiroot` points to `home`.
- The repository root stays dedicated to docs, CI, project metadata, and shared schemas.
- `lib/schemas/` contains JSON Schema definitions (e.g. `skill.schema.json`) — kept for reference but not used for embedded skills in thin mode.
- Thin placeholders (`README.md`) remain in emptied dirs to document delegation.

> [!IMPORTANT]
> Never place chezmoi-managed files at the repository root. All source state lives under `home/`. Thin workstation keeps only runner logic.

---

## See Also

- [SKILLS.md](SKILLS.md) — full skills system documentation
- [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) — agent-toolkit integration — thin workstation (uv only)
- [AI_LAYER.md](AI_LAYER.md) — AI directory structure and Ralph Loop model
- [AGENTIC_HARNESS.md](AGENTIC_HARNESS.md) — three-layer architecture framework
- [wiki/PROFILES.md](wiki/PROFILES.md) — profile selection and feature groups
- [adrs/](adrs/) — architecture decision records
