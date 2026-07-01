# Documentation Index

> Technical documentation map for the agentic-workstation platform.

---

## Documentation Model

| Location | Purpose |
|---|---|
| `docs/` | Technical references, architecture, maintainer contracts |
| `docs/wiki/` | User-facing guides, setup flows, troubleshooting, integrations |
| `docs/adrs/` | Architecture Decision Records |

User-facing setup belongs in the wiki. Technical design and maintainer contracts belong in `docs/`.

## Technical References

| Document | Topic |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layered design model and source state |
| [AI_LAYER.md](AI_LAYER.md) | AI directory structure and Ralph Loop |
| [AGENTIC_HARNESS.md](AGENTIC_HARNESS.md) | Three-layer architecture, personas, packs |
| [CLIENT_AI_PLAYBOOKS.md](CLIENT_AI_PLAYBOOKS.md) | Client workflow skill conventions |
| [DEV_COMPANION.md](DEV_COMPANION.md) | Companion layers, Cursor rules, registry |
| [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md) | LLM provider priority and configuration |
| [DEV_COMPANION_PLATFORM.md](DEV_COMPANION_PLATFORM.md) | Platform schema and multi-harness design |
| [DEV_COMPANION_RELIABILITY.md](DEV_COMPANION_RELIABILITY.md) | Reliability patterns and error handling |
| [ECC_PATTERNS.md](ECC_PATTERNS.md) | Error correction and context patterns |
| [MCP_TEMPLATES.md](MCP_TEMPLATES.md) | MCP provider template reference |
| [MULTI_AGENT_ORCHESTRATION.md](MULTI_AGENT_ORCHESTRATION.md) | Multi-agent runtime and persona constraints |
| [REPOSITORY_GOVERNANCE.md](REPOSITORY_GOVERNANCE.md) | Change management and quality gates |
| [SKILLS.md](SKILLS.md) | Skills schema, registry, publishing, compatibility |
| [adrs/](adrs/) | Architecture Decision Records |

## User Guides

| Need | Wiki page |
|---|---|
| Install workstation | [wiki/TECHNICAL_QUICKSTART.md](wiki/TECHNICAL_QUICKSTART.md) |
| Install only AI skills | [wiki/GUIDED_AI_INSTALL.md](wiki/GUIDED_AI_INSTALL.md) |
| Answer setup prompts | [wiki/QUESTIONNAIRE.md](wiki/QUESTIONNAIRE.md) |
| Pick profiles | [wiki/PROFILES.md](wiki/PROFILES.md) |
| Use chezmoi | [wiki/CHEZMOI.md](wiki/CHEZMOI.md) |
| Use CLI helpers | [wiki/CLI.md](wiki/CLI.md) |
| Configure credentials | [wiki/CREDENTIALS.md](wiki/CREDENTIALS.md) |
| Configure integrations | [wiki/INTEGRATIONS.md](wiki/INTEGRATIONS.md) |
| Windows setup | [wiki/WINDOWS.md](wiki/WINDOWS.md) |
| Updates and releases | [wiki/RELEASES.md](wiki/RELEASES.md) |
| Troubleshooting | [wiki/TROUBLESHOOTING.md](wiki/TROUBLESHOOTING.md) |

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.
