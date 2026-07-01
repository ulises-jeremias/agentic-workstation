# Integrations Overview

> Pick the integration path first, then follow the setup guide for that service.

---

## Start here

| Goal | Best path |
|---|---|
| Manage issues, docs, or projects | CLI or skill |
| Let an AI tool inspect external context | MCP |
| Authenticate once and reuse locally | `env.d` + shell loading |
| Debug a broken setup | `dots-doctor`, `dots-skills`, and auth status commands |

## Available integrations

| Integration | Primary path | AI support | Notes |
|---|---|---|---|
| GitHub | `gh` + GitHub MCP | Yes | Repo, PR, issue workflows |
| GitLab | `glab` + GitLab workflow | Yes | Merge request workflows |
| ClickUp | ClickUp CLI | Yes | MCP is legacy only |
| Jira | Atlassian token + skill pack | Yes | Optional external skill pack |
| Confluence | Atlassian token + skill pack | Yes | Uses same Atlassian token as Jira |
| Slack | Slack app tokens + MCP | Yes | Chat and channel access |
| Figma | Figma MCP | Yes | Design context and assets |
| Linear | Linear MCP | Yes | OAuth, no API token required |
| Notion | Notion MCP | Yes | API token based |

## Recommended setup order

1. Configure credentials in `~/.config/agentic-workstation/env.d/`.
2. Enable optional skill packs if the integration uses one.
3. Register MCP servers in the AI tool you actually use.
4. Run `dots-doctor` and `dots-skills list`.
5. Test one real workflow end to end.

## Quick links

- [Credentials & Env Files](CREDENTIALS)
- [GitHub](INTEGRATION_GITHUB)
- [GitLab](INTEGRATION_GITLAB)
- [ClickUp](INTEGRATION_CLICKUP)
- [Jira](INTEGRATION_JIRA)
- [Confluence](INTEGRATION_CONFLUENCE)
- [Slack](INTEGRATION_SLACK)
- [Figma](INTEGRATION_FIGMA)
- [Linear](INTEGRATION_LINEAR)
- [Notion](INTEGRATION_NOTION)
- [Troubleshooting](INTEGRATION_TROUBLESHOOTING)
