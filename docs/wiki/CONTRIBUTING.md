# Contributing

> How to contribute to the agentic-workstation platform.

---

## Scope

This repository is **private** and focused on:

- Repository-level quality and governance
- `chezmoi` source-state templates
- Internal automation and documentation
- AI skills and agent definitions

Avoid personal machine-specific additions.

---

## Workflow

1. Create a branch from `main`
2. Make focused changes
3. Run local quality checks
4. Open a pull request using the template

---

## Local quality checks

Run before opening a PR:

```bash
bash scripts/validate-repo-structure.sh
bash scripts/check-shell-syntax.sh
```

Optional full lint:

```bash
docker run --rm -v "$PWD":/tmp/lint -e VALIDATE_ALL_CODEBASE=true oxsecurity/megalinter:v9
```

---

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — code restructuring
- `chore:` — maintenance
- `test:` — test changes

Write short, imperative summaries. Explain "why" in the body.

---

## Pull request expectations

- Keep PRs small and reviewable
- Explain what changed and why
- List validation steps executed
- Update documentation when behavior changes

---

## Security

- Never commit credentials, tokens, or private keys
- Use environment variables in all examples
- Follow [`SECURITY.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/SECURITY.md) for vulnerability reporting

---

**Canonical doc:** [`CONTRIBUTING.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/CONTRIBUTING.md)
