# Contributing to agentic-workstation

Thanks for helping improve the agentic-workstation platform.

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
