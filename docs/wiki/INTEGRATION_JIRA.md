# Jira Integration

> Jira issue workflows through the optional assistant skill pack.

---

## Best path

Use the Jira assistant skill pack plus local env files. Jira does not use an MCP template here.

## Setup

```bash
cp ~/.config/agentic-workstation/env.d/jira.env.example ~/.config/agentic-workstation/env.d/jira.env
$EDITOR ~/.config/agentic-workstation/env.d/jira.env
```

Fill in your Atlassian site URL, email, and API token.

Then enable the Jira assistant pack in your local chezmoi config:

```toml
[data]
install_skill_jira_assistant = true
```

## What you need

- `JIRA_SITE_URL`
- `JIRA_EMAIL`
- `JIRA_API_TOKEN`

## Common workflows

- Inspect or update issues
- Search and triage tickets
- Draft workflow automation helpers

## Verify

```bash
dots-doctor
dots-skills list
```

## See also

- [Credentials & Env Files](CREDENTIALS)
- [Troubleshooting](INTEGRATION_TROUBLESHOOTING)
