# Profiles

> Profile-driven configuration — choose what gets installed on your machine.

---

## How profiles work

During `chezmoi init`, you select one or more profiles. Each profile maps to a set of **package groups** that control which tools are installed.

---

## Available profiles

| Profile | Target audience | Installs |
|---------|----------------|----------|
| `technical` | Engineers | Git, Docker, dev tools, editors |
| `non-technical` | Non-engineering staff | Minimal tooling |
| `ai` | AI/ML practitioners | AI CLIs, skills, agents, MCP templates |
| `node` | Frontend / fullstack devs | Node.js, npm/pnpm, frontend tools |
| `python` | Python developers | Python, pip, virtualenv tools |
| `data` | Data engineers | dbt, SQL tools, data stack |
| `infra` | DevOps / infrastructure | Terraform, AWS CLI, k8s tools |

---

## Profile composition

Profiles are **additive** — you can select multiple:

```
technical + ai + node → full frontend AI stack
technical + ai + data → full data AI stack
```

---

## Canonical mapping

The authoritative profile-to-package mapping lives in:

```
home/.chezmoidata/profiles.yaml
```

---

## Changing profiles

Re-run init to update your choices:

```bash
cd /path/to/agentic-workstation
chezmoi init --source=. -c ~/.config/chezmoi/agentic-workstation.toml
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

---

**Technical context:** [`docs/README.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/README.md)
