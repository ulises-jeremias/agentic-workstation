# Confluence Integration

> Confluence page workflows through the Agent Toolkit catalog.

---

## Best path

Use the Confluence capabilities included in Agent Toolkit plus local env files. Confluence does not use an MCP template here.

## Setup

```bash
cp ~/.config/agentic-workstation/env.d/confluence.env.example ~/.config/agentic-workstation/env.d/confluence.env
$EDITOR ~/.config/agentic-workstation/env.d/confluence.env
```

Fill in the same Atlassian site, email, and token used for Jira.

Then install the Toolkit catalog:

```bash
agent-toolkit install
```

## What you need

- `confluence-as`
- `CONFLUENCE_SITE_URL`
- `CONFLUENCE_EMAIL`
- `CONFLUENCE_API_TOKEN`

## Common workflows

- Create and update pages
- Search documentation
- Add comments and annotations

## Verify

```bash
dots-doctor
dots-skills list
```

## See also

- [Credentials & Env Files](CREDENTIALS)
- [Troubleshooting](INTEGRATION_TROUBLESHOOTING)
