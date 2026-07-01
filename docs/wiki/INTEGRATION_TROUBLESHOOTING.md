# Integration Troubleshooting

> Fast checks for auth, MCP registration, and missing skill packs.

---

## First checks

```bash
dots-doctor
dots-skills list
dots-skills check
dots-loadenv
```

## Common auth checks

```bash
gh auth status
clickup auth status
glab auth status
```

## If a local env file is missing

- Confirm the file ends in `.env`.
- Confirm it lives under `~/.config/agentic-workstation/env.d/`.
- Re-open a new terminal after editing it.

## If MCP does not connect

- Confirm the AI tool was restarted.
- Confirm the server entry matches the template.
- Confirm the token is present in your shell session.

## If a skill is missing

- Run `dots-skills list`.
- Re-run `dots-skills sync` after `chezmoi apply`.
- Check whether the skill pack was enabled in your local config.

## Support evidence

When asking for help, include the output of:

```bash
dots-doctor --issue
```
