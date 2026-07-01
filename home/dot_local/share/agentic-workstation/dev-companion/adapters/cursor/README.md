# Cursor adapter

Cursor loads skills via symlinks under `~/.cursor/skills/` created by `dots-skills sync`.

Cursor does not have a stable, cross-org “subagents directory” mechanism we can rely on, so we keep Cursor integration **thin**:

- Use **project** `.cursor/rules/*` to point at `AGENTS.md` and agentic-workstation skills.
- Keep rules short; policies live in skills and `AGENTS.md`.

See `docs/DEV_COMPANION.md` for a copy/paste rule stub.
