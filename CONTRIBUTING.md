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
| Add a new skill | See [docs/SKILLS.md](docs/SKILLS.md) for the skill authoring guide |
| Fix a bug | Pick any issue labeled `bug` or `type:task` |
| Propose a feature | Open an issue first to discuss the approach |
| Improve CI or tooling | Check the [12 CI workflows](.github/workflows/) |

**First time contributing?** Check out our [good first issues](https://github.com/ulises-jeremias/agentic-workstation/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) — they're designed for newcomers and have clear acceptance criteria.

## Scope

This repository is public and accepts contributions focused on:

- repository-level quality and governance
- `chezmoi` source-state templates
- automation and documentation
- bundled AI skills, agents, and MCP templates

Please avoid personal machine-specific additions (use local chezmoi overrides instead).

## Contribution workflow

1. Create a branch from `main`.
2. Make focused changes.
3. Run local checks.
4. Open a pull request using the template.

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
- **Want to propose a new skill?** Open an issue with label `theme:dx` and reference [docs/SKILLS.md](docs/SKILLS.md)
- **Recognition**: All contributors are acknowledged in the [CHANGELOG](CHANGELOG.md) and release notes
