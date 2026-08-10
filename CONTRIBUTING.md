# Contributing to agentic-workstation

[![Good First Issues](https://img.shields.io/github/issues-search/ulises-jeremias/agentic-workstation?query=is%3Aissue%20is%3Aopen%20label%3A%22good%20first%20issue%22&label=good%20first%20issue&color=7057ff)](https://github.com/ulises-jeremias/agentic-workstation/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
[![Help Wanted](https://img.shields.io/github/issues-search/ulises-jeremias/agentic-workstation?query=is%3Aissue%20is%3Aopen%20label%3A%22help%20wanted%22&label=help%20wanted&color=f59e0b)](https://github.com/ulises-jeremias/agentic-workstation/issues?q=is%3Aissue+is%3Aopen+label%3A%22help%20wanted%22)
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](https://github.com/ulises-jeremias/agentic-workstation/pulls)

Thanks for helping improve the agentic-workstation platform.

## How to contribute

We welcome contributions of all kinds! Here are some ways to help:

| What | Where to start |
|------|---------------|
| Fix a typo or broken link | Browse [docs/](docs/) and open a PR |
| Improve documentation | Check issues labeled [good first issue](https://github.com/ulises-jeremias/agentic-workstation/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) |
| Add a skill, agent, loop, or MCP template | Contribute to [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) (see [its contribution guide](https://github.com/ulises-jeremias/agent-toolkit/blob/main/CONTRIBUTING.md)) |
| Fix a bug | Pick any issue labeled `bug` or `type:task` |
| Propose a feature | Open an issue first to discuss the approach |
| Improve CI or tooling | Check the [12 CI workflows](.github/workflows/) |

**First time contributing?** Check out our [good first issues](https://github.com/ulises-jeremias/agentic-workstation/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) — they're designed for newcomers and have clear acceptance criteria.

## What belongs here vs Toolkit

agentic-workstation is the **thin L1 machine-provisioning layer**. It sources capabilities from [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) — the sole distribution layer for skills, agents, loops, MCP templates, prompts, packs, and tool profiles.

| What | Belongs in |
|------|-----------|
| chezmoi source-state templates | agentic-workstation (here) |
| Install scripts (`run_*`.sh.tmpl) | agentic-workstation (here) |
| Doctor / health checks (`dots-doctor`) | agentic-workstation (here) |
| Swarm provisioning (tmux, Herdr) | agentic-workstation (here) |
| Documentation, wiki, ADRs | agentic-workstation (here) |
| CI workflows and repository governance | agentic-workstation (here) |
| LLM policy (`dots-devcompanion`) | agentic-workstation (here) |
| Skills | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) |
| Agent personas | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) |
| Loop templates | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) |
| MCP templates | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) |
| Tool profiles | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) |
| Prompts and packs | [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) |

See [docs/AGENT_TOOLKIT.md](docs/AGENT_TOOLKIT.md) for the full thin-workstation integration reference and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the architecture diagram.

## Scope

This repository is public and accepts contributions focused on:

- repository-level quality and governance
- `chezmoi` source-state templates
- install scripts and bootstrap automation
- doctor and health checks
- swarm provisioning (tmux, Herdr)
- documentation, wiki, and ADRs
- CI workflows

Skills, agents, loops, MCP templates, tool profiles, prompts, and packs are distributed by [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit). To contribute a skill, agent, or loop template, open a PR against the [agent-toolkit repository](https://github.com/ulises-jeremias/agent-toolkit) and follow its [contribution guide](https://github.com/ulises-jeremias/agent-toolkit/blob/main/CONTRIBUTING.md).

Please avoid personal machine-specific additions (use local chezmoi overrides instead).

## Contribution workflow

1. Fork the repository to your own GitHub account.
2. Clone your fork and create a branch from `main`.
3. Make focused changes.
4. Run local checks.
5. Open a pull request from your fork's branch to `main` using the template.

## Local quality checks

Run these commands before opening a PR:

```bash
bash scripts/validate-repo-structure.sh
bash scripts/check-shell-syntax.sh
```

Optional full lint run:

```bash
docker run --rm -v "$PWD":/tmp/lint -e VALIDATE_ALL_CODEBASE=true oxsecurity/megalinter:v9
```

## Commit style

Use Conventional Commits:

- `feat:`
- `fix:`
- `docs:`
- `refactor:`
- `chore:`
- `test:`

Write short, imperative commit summaries and explain the reason in the body when needed.

## Pull request expectations

- Keep PRs small and reviewable.
- Explain what changed and why.
- List validation steps executed.
- Update documentation when behavior changes.

## Security and secrets

- Never commit credentials, tokens, private keys, or local secrets.
- Use environment variables in all examples.
- Follow `SECURITY.md` for vulnerability reporting.

## Community

- **Questions?** [Open an issue](https://github.com/ulises-jeremias/agentic-workstation/issues/new) with the `question` label
- **Feature ideas?** Check [open issues](https://github.com/ulises-jeremias/agentic-workstation/issues) first — if it's new, open an issue with the `enhancement` label
- **Found a bug?** Report it using the [bug report template](https://github.com/ulises-jeremias/agentic-workstation/issues/new) — include steps, expected behavior, and actual behavior
- **Want to propose a new skill, agent, or loop?** Open an issue or pull request in [agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit) — all capability content is distributed from the Toolkit repository
- **Recognition**: All contributors are acknowledged in the [CHANGELOG](CHANGELOG.md) and release notes
