# ClickUp Workflow Prompt

Use this prompt snippet in AI agents that do not auto-discover skill files, or to explicitly reinforce the preferred ClickUp workflow at the start of a session.

## System prompt snippet

Paste the block below into your agent's system prompt or at the start of a conversation:

---

Use the `clickup` CLI for all ClickUp operations instead of the ClickUp MCP server or raw API calls. The CLI is token-efficient, handles authentication automatically, and supports JSON output for structured reads.

**Core workflow for a coding task:**

1. Discover work if task ID is unknown:
   ```bash
   clickup task recent --json
   ```
2. Read the task requirements:
   ```bash
   clickup task view CU-<id> --json
   ```
3. Read comments for additional context:
   ```bash
   clickup comment list CU-<id>
   ```
4. Implement the work.
5. Update the task status:
   ```bash
   clickup status set "in progress" CU-<id>
   ```
6. Add a progress comment:
   ```bash
   clickup comment add CU-<id> "Brief summary of what was done"
   ```
7. Link the PR (after opening one):
   ```bash
   clickup link pr --task CU-<id>
   ```
8. Mark complete:
   ```bash
   clickup status set "done" CU-<id>
   ```

**For all other terminal commands, use `rtk` to compress output:**

```bash
rtk git status      # instead of: git status
rtk git diff HEAD~1 # instead of: git diff
rtk grep "term" .   # instead of: grep
rtk find "*.ts" .   # instead of: find
```

`rtk` removes ~89% of CLI noise before it reaches the context window, enabling longer and more focused sessions.

---

## Agent-specific setup

### Claude Code / OpenCode / pi

Chezmoi manages global skill symlinks to:

- `~/.claude/skills/clickup-cli`
- `~/.config/opencode/skills/clickup-cli`
- `~/.pi/agent/skills/clickup-cli`

These agents can auto-discover the skill from those host paths.

### Cursor

Chezmoi manages a global symlink at `~/.cursor/skills/clickup-cli/`. Cursor auto-discovers it at agent start.

### GitHub Copilot

Chezmoi manages a global symlink at `~/.copilot/skills/clickup-cli/`. Copilot coding agent loads it when relevant based on the skill description.

### Agents without skill discovery

Paste the system prompt snippet above at the start of the conversation.

## CI / non-interactive auth

```bash
echo "$CLICKUP_TOKEN" | clickup auth login --with-token
```

Store `CLICKUP_TOKEN` as a repository secret or environment variable. Never pass it as a command-line argument.
