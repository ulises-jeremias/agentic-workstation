# Tool Compatibility Matrix

> Thin workstation — compatibility is delegated to [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit).
> No embedded `skill.json` files are shipped in this repository.
> Thin workstation: skills are delegated to `agent-toolkit`. Install via `uv tool install --force agent-toolkit-cli && agent-toolkit install`.
>
> To regenerate from the toolkit catalog, ensure `agent-toolkit` is installed and run `agent-toolkit skills list`.

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Supported |
| ❌ | Not supported |
| — | Not declared |

## Matrix

| Skill | Version | Universal | Claude Code | Muse Code | OpenCode | Cursor | Windsurf | Copilot CLI | Pi |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| _delegated_ | — | — | — | — | — | — | — | — | — |

> This placeholder will be replaced by `agent-toolkit`'s catalog at install time (`agent-toolkit install`).

## Tools

| Tool | Description |
|------|-------------|
| Universal | Included for every AI tool that supports markdown skills |
| Claude Code | Anthropic Claude Code CLI (`~/.claude/skills/`) |
| Muse Code | Meta Muse Code (`~/.config/muse/skills/`) |
| OpenCode | OpenCode (`~/.config/opencode/skills/`) |
| Cursor | Cursor IDE (`~/.cursor/skills/`) |
| Windsurf | Windsurf IDE (`~/.windsurf/skills/`) |
| Copilot CLI | GitHub Copilot CLI (`~/.copilot/skills/`) |
| Pi | Pi agent (`~/.pi/agent/skills/`) |
