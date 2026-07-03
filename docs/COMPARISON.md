# Comparison Guide — agentic-workstation

> How agentic-workstation compares to alternative tools and approaches.

---

## Shell & Terminal Tools

### vs oh-my-zsh / zsh4humans

| Aspect | oh-my-zsh | agentic-workstation |
|--------|-----------|-------------------|
| Focus | Shell configuration and plugins | AI-native developer workstation |
| AI integration | None built-in | 52+ AI skill packs, sub-agents, MCP templates |
| Setup | `sh -c "$(curl ...)"` | `chezmoi init --apply` with profile selection |
| Portability | Shell-specific | Cross-tool: Claude Code, opencode, Cursor, Copilot, Gemini |
| Skills | Community plugins | Curated skill packs with compatibility matrix |
| Profiles | Theme switching | Tool-specific profile groups (technical, ai, node, python, etc.) |

**When to use agentic-workstation**: You want AI skills integrated into your development workflow, not just a prettier shell prompt.

**When to use oh-my-zsh**: You just want shell enhancements and don't need AI tooling or skill orchestration.

### vs starship

| Aspect | starship | agentic-workstation |
|--------|----------|-------------------|
| Purpose | Shell prompt customization | Complete AI workstation baseline |
| Scope | Prompt only | Dotfiles, skills, agents, MCP, loops |
| AI features | None | Full AI layer with 52+ skills |

**Agentic-workstation includes** shell configuration. You can use starship as your prompt and still get the AI layer from agentic-workstation.

### vs chezmoi (vanilla)

| Aspect | chezmoi | agentic-workstation |
|--------|---------|-------------------|
| What you get | Dotfile manager | Dotfile manager + AI skills + agents + MCP + loops |
| Setup time | Write your own dotfiles | Pre-configured with profile-driven defaults |
| AI integration | Manual | Built-in: skills, agents, dev companion, loop engineering |
| Multi-tool | You configure each tool | One skill registration across 5+ AI tools |

**Agentic-workstation is built on chezmoi.** It adds the AI layer on top. If you already use chezmoi, you can layer agentic-workstation's AI features without replacing your dotfiles.

---

## AI Coding Tools

### vs Cursor (standalone)

| Aspect | Cursor | Cursor + agentic-workstation |
|--------|--------|------------------------------|
| Skills | Manual .cursor/rules/ | 52+ pre-built skill packs with routing |
| Memory | Session-only | Persistent knowledge across sessions |
| Work modes | Ad-hoc instructions | Persona system with allow/deny/handoff |
| Task automation | Manual | Loop engineering with scheduling |
| Multi-project | Open folder | Pack-based context switching |
| Code review | Manual | Background queue with LLM-powered runner |

**When to add agentic-workstation**: You use Cursor daily and want to stop repeating the same context and instructions every session.

### vs GitHub Copilot (standalone)

| Aspect | Copilot | Copilot + agentic-workstation |
|--------|---------|------------------------------|
| Context | Inline completions | Pack-based project context + knowledge base |
| Instructions | Single .github/copilot-instructions.md | Personas, packs, profiles |
| Delegation | No sub-agent support | 13+ specialized sub-agents via skills |
| Automation | None | Loop engineering and dev companion |
| Memory | None | Persistent cross-session knowledge |

**When to add agentic-workstation**: You want Copilot to remember your conventions and project context across sessions.

### vs Claude Code (standalone)

| Aspect | Claude Code | Claude Code + agentic-workstation |
|--------|-------------|----------------------------------|
| Projects | Manual CLAUDE.md per project | Pack-based context with profiles |
| Skills | Custom instructions | 52+ pre-built skill packs |
| Persistence | Project-level | Cross-project knowledge base |
| Automation | Manual | Loop engineering for recurring tasks |
| Multi-client | No isolation | Per-pack LLM policies with strict mode |

**When to add agentic-workstation**: You work across multiple projects/clients and need context isolation and automation.

---

## Dotfile Managers

### vs yadm

| Aspect | yadm | agentic-workstation |
|--------|------|-------------------|
| Approach | Git-based dotfile manager | chezmoi-based with AI layer |
| Templates | Limited (Git filters) | Full Go template engine |
| AI skills | None | 52+ skill packs |
| Community | Larger, more plugins | Opinionated, curated |

**Agentic-workstation is more than a dotfile manager** — it's an AI workstation baseline. yadm is excellent if you only need dotfile management.

### vs Nix / home-manager

| Aspect | Nix | agentic-workstation |
|--------|-----|-------------------|
| Reproducibility | Declarative, cryptographic | chezmoi templates with profiles |
| Learning curve | Steep (Nix language) | Moderate (YAML + shell) |
| AI skills | None | Full AI layer |
| Package management | Built-in | OS-native (apt, brew, pacman) |
| Cross-platform | Linux, macOS (Darwin) | Linux, macOS, Windows (WSL2/Git Bash) |

**When to use agentic-workstation**: You want AI skills without learning a new package management paradigm.

**When to use Nix**: Reproducible builds and declarative package management are your primary concerns.

---

## AI Agent Frameworks

### vs Continue.dev

| Aspect | Continue.dev | agentic-workstation |
|--------|-------------|-------------------|
| Scope | IDE plugin | System-wide workstation |
| AI tools | Continue extension | Claude Code, opencode, Cursor, Copilot, Gemini |
| Skills | Custom slash commands | 52+ curated skill packs |
| Memory | None built-in | Persistent knowledge base |
| Automation | None | Loop engineering and job queue |

**Overlap**: Both provide AI-enhanced developer tooling. Agentic-workstation is broader (system-wide vs IDE-only) and includes automation.

### vs opencode skills (standalone)

| Aspect | opencode skills | agentic-workstation |
|--------|----------------|-------------------|
| Skills | opencode-specific | Cross-tool: 5+ AI tools supported |
| Management | Manual skill.json | dots-skills CLI with sync, list, install |
| Sub-agents | None | 13+ specialized sub-agents |
| Memory | None | Knowledge base with assistant-memory CLI |
| Automation | None | Loop engineering, dev companion queue |

**Agentic-workstation includes opencode skill support** plus cross-tool portability.

---

## When to Use agentic-workstation

- You use AI coding tools daily and want to stop repeating context
- You work across multiple projects or clients
- You want your AI to remember conventions and patterns across sessions
- You need background task automation (code reviews, CI fixes, issue triage)
- You want one setup that works across Claude Code, opencode, Cursor, and Copilot

## When NOT to Use agentic-workstation

- You're happy with your current setup and don't need AI skills
- You only use one AI tool and have a simple, single-project workflow
- You prefer to build everything from scratch
- You don't use AI coding tools at all
- Your organization has strict restrictions on external AI tool configurations
