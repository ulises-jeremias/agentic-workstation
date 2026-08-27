# Jira Integration

> Jira issue workflows through the Agent Toolkit catalog.

---

## Best path

Use the Jira capabilities included in Agent Toolkit plus local env files. Jira does not use an MCP template here.

## Setup

```bash
cp ~/.config/agentic-workstation/env.d/jira.env.example ~/.config/agentic-workstation/env.d/jira.env
$EDITOR ~/.config/agentic-workstation/env.d/jira.env
```

Fill in your Atlassian site URL, email, and API token.

Then install the Toolkit catalog:

```bash
agent-toolkit install
```

## What you need

- `jira-as`
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
