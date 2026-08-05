# Architecture

> Layered design model and source state conventions for the agentic-workstation workstation.

![agentic-workstation three-layer architecture](../static/architecture.svg)

---

`agentic-workstation` keeps repository governance and workstation state clearly separated.

## Design principles

- Keep the source state simple and predictable.
- Prefer profile-driven behavior over host-specific custom logic.
- Keep scripts idempotent and safe to re-run.
- Treat docs, wiki, and ADRs as first-class product artifacts.

---

## Layered model

```mermaid
graph TD
    subgraph "Repository Layer"
        A[docs/ + ADRs + CI] --> B[home/ — chezmoi source state]
    end

    subgraph "Machine Layer (after chezmoi apply)"
        B --> C["~/.local/bin/ — dots-* CLI helpers"]
        B --> D["~/.local/share/agentic-workstation/ — AI resources"]
        B --> E["~/.config/ — tool configs"]
        D --> F["skills/ — bundled skills"]
        D --> G["mcp/ — MCP templates"]
        D --> H["prompts/ — shared prompts"]
    end

    subgraph "Session Layer (AI workspace)"
        I["knowledge/ — persistent memory"]
        J["personas/ — scope constraints"]
        K["packs/ — client context bundles"]
    end

    D -.->|symlinks via dots-skills sync| L["~/.claude/skills/"]
    D -.->|symlinks via dots-skills sync| M["~/.config/opencode/skills/"]
    D -.->|symlinks via dots-skills sync| N["~/.cursor/skills/"]
```

### Layer details

1. **Data model** (`home/.chezmoidata`)
   Shared configuration for package groups, AI settings, profiles, and the skills registry index.
2. **Bootstrap scripts** (`home/.chezmoiscripts`)
   Idempotent setup scripts executed by `chezmoi`. Includes skills sync via `dots-skills sync`.
3. **Templates** (`home/.chezmoitemplates`)
   Reusable AI instruction templates for projects and assistants.
4. **Shared assets** (`home/private_dot_local/share/agentic-workstation`)
   Prompts, skills, templates, MCP provider examples, and the runtime skills registry.
5. **CLI helpers** (`home/private_dot_local/bin`)
   Internal operations commands with `dots-` prefix, including `dots-skills`.

---

## Three-layer model

agentic-workstation operates across three distinct layers with clear separation of concerns:

```mermaid
graph TD
    subgraph "L1 — agentic-workstation (this repo)"
        AW1["Machine provisioning<br/>(chezmoi, shell, packages)"]
        AW2["Secrets & LLM policy<br/>(dots-devcompanion, env.d)"]
        AW3["dots-* helpers<br/>(dots-skills, dots-loop, dots-doctor)"]
        AW4["AGENTS.md templates<br/>(chezmoitemplates/agents/)"]
    end

    subgraph "L1.5 — agent-toolkit (separate repo)"
        AT1["52 skills / 9 domains"]
        AT2["16 agent personas"]
        AT3["10 loop templates"]
        AT4["6 tool profiles<br/>(Claude Code, Cursor, OpenCode…)"]
        AT5["6 MCP templates"]
    end

    subgraph "L3 — Project overlay"
        PO1["Project AGENTS.md"]
        PO2["Engagement packs"]
        PO3["Client-specific skills"]
    end

    AW1 -->|"AUR → uv → pipx → agent-toolkit install"| AT1
    AW1 -->|"AUR → uv → pipx → agent-toolkit install"| AT2
    AW1 -->|"AUR → uv → pipx → agent-toolkit install"| AT3
    AW1 -->|"AUR → uv → pipx → agent-toolkit install"| AT4
    AW1 -->|"AUR → uv → pipx → agent-toolkit install"| AT5
    AW3 -->|"dots-skills sync"| AT1
    AW3 -->|"dots-loop init"| AT3
    AT1 --> PO3
    AT4 --> PO1
```

### Layer responsibilities

| Layer | Repo | Responsibility |
|-------|------|----------------|
| **L1** | `agentic-workstation` | Machine provisioning — chezmoi, packages, shell, LLM policy |
| **L1.5** | `agent-toolkit` | Capability distribution — skills, agents, profiles, loops |
| **L3** | Project repo | Overlays — project AGENTS.md, engagement packs, client skills |

> [!IMPORTANT]
> **agentic-workstation's role is machine provisioning.** Skills, agent personas, and profiles come from [`agent-toolkit`](https://github.com/ulises-jeremias/agent-toolkit). `dots-skills` delegates to `agent-toolkit` for skill sync; `dots-loop` wraps `agent-toolkit loop`.

---

## Skills architecture

Skills are distributed by [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) — a separate repo with 52 skills, 16 agent personas, and 10 loop templates. agentic-workstation installs agent-toolkit during `chezmoi apply` and uses `dots-skills` to sync the resulting skills to per-tool directories.

- **agent-toolkit skills** — installed via `agent-toolkit install` (or `uv tool install agent-toolkit-cli && agent-toolkit install`)
- **Bundled workstation skills** — a small set of agentic-workstation-specific skills (triage, dev-companion, assistant) shipped in this repo for machine-local workflows
- **External skills** — installed from npm, GitHub, or URLs by `dots-skills install`, placed in `~/.local/share/agentic-workstation/skills-external/`

Each skill contains a `skill.json` manifest (or `SKILL.md` frontmatter for agent-toolkit skills) that declares compatibility with each AI tool. `dots-skills sync` reads those manifests and creates symlinks in tool-specific directories (e.g. `~/.claude/skills/`, `~/.copilot/skills/`).

> [!NOTE]
> See [SKILLS.md](SKILLS.md) for the full skills system documentation.
> See [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) for the agent-toolkit integration reference.

---

## Source state convention

- `.chezmoiroot` points to `home`.
- The repository root stays dedicated to docs, CI, project metadata, and shared schemas.
- `lib/schemas/` contains JSON Schema definitions (e.g. `skill.schema.json`).

> [!IMPORTANT]
> Never place chezmoi-managed files at the repository root. All source state lives under `home/`.

---

## See Also

- [SKILLS.md](SKILLS.md) — full skills system documentation
- [AGENT_TOOLKIT.md](AGENT_TOOLKIT.md) — agent-toolkit integration (skills, agents, profiles)
- [AI_LAYER.md](AI_LAYER.md) — AI directory structure and Ralph Loop model
- [AGENTIC_HARNESS.md](AGENTIC_HARNESS.md) — three-layer architecture framework
- [wiki/PROFILES.md](wiki/PROFILES.md) — profile selection and feature groups
- [adrs/](adrs/) — architecture decision records
