# Init Questionnaire

> How to answer the profile and feature prompts during `chezmoi init`.

---

## What the questionnaire controls

The questionnaire controls which package groups, AI tools, skills, and optional integrations are installed.

## Common choices

| Need | Choose |
|---|---|
| Full engineering workstation | `technical` + relevant language profile |
| AI tooling only | `ai` or skills-only install |
| Python work | `python` |
| Data workflows | `data` |
| Minimal setup | `minimal` |

## Optional integrations

Some integrations require explicit opt-in flags, such as Jira and Confluence assistant packs. Configure credentials first, then enable the relevant prompt or flag.

## Re-run the questionnaire

```bash
cd /path/to/agentic-workstation
chezmoi init --source=. -c ~/.config/chezmoi/agentic-workstation.toml
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

## See also

- [Profiles](PROFILES)
- [Credentials & Env Files](CREDENTIALS)
- [Integrations Overview](INTEGRATIONS)
