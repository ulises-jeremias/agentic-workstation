# Technical Quickstart

> From zero to a compliant agentic-workstation workstation in 5 steps.

---

## Prerequisites

- **Git** installed and configured
- **SSH key** added to GitHub (for `git clone`)
- **chezmoi** installed ([chezmoi.io/install](https://www.chezmoi.io/install/))
- Admin/sudo access on your machine

---

## Step 1 — Clone the repository

```bash
git clone git@github.com:ulises-jeremias/agentic-workstation.git
cd agentic-workstation
```

## Step 2 — Initialize chezmoi

```bash
chezmoi init --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

chezmoi will prompt you for profile choices (technical, AI tools, language stacks). Answer based on your role.

## Step 3 — Preview changes

```bash
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml --dry-run
```

Review what will be created or modified in your home directory.

## Step 4 — Apply

```bash
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

This installs all selected tools, skills, agents, CLI helpers, and MCP templates.

## Step 5 — Validate

Open a **new terminal** and run:

```bash
dots-doctor
```

All checks should pass with `COMPLIANT`.

---

## One-liner alternative

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/install.sh)
```

---

## Updating

```bash
dots-update-check    # check for upstream changes
chezmoi update      # pull and apply
dots-doctor          # re-validate
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `dots-doctor` reports missing command | Install the tool manually, then re-run `chezmoi apply` |
| Symlinks missing after apply | Run `dots-skills sync` to regenerate |
| chezmoi prompts again on update | Normal for new config questions — answer and re-apply |

→ Full guide: [Troubleshooting](TROUBLESHOOTING)

---

**Technical context:** [`docs/README.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/README.md)
