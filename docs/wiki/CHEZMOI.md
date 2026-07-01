# Chezmoi Workflow

> How `agentic-workstation` uses chezmoi for idempotent machine configuration.

---

## What is chezmoi?

[chezmoi](https://www.chezmoi.io/) manages your dotfiles across multiple machines. This repository uses it as the deployment engine: the `home/` directory is the **source state** that chezmoi applies to your home directory.

---

## Key concepts

| Concept | Meaning |
|---------|---------|
| **Source state** | `home/` in this repo — templates and files managed by chezmoi |
| **Target state** | Your actual `~` home directory |
| `.chezmoiroot` | Points chezmoi at `home/` instead of the repo root |
| `.chezmoidata/` | YAML data files (profiles, packages, skills) consumed by templates |
| `.chezmoiscripts/` | Scripts that run during `chezmoi apply` (installers, post-apply hooks) |
| `dot_` prefix | chezmoi convention — `dot_config/` becomes `~/.config/` |

---

## Lifecycle

### Initialize

```bash
cd /path/to/agentic-workstation
chezmoi init --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

This reads `.chezmoidata/` and prompts for profile choices.

### Preview

```bash
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml --dry-run
```

Shows what would change without making modifications.

### Apply

```bash
chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml
```

Creates/updates all files and runs installation scripts.

### Update

```bash
dots-update-check    # check if local is behind origin
chezmoi update      # git pull + apply in one command
dots-doctor          # verify compliance
```

### Diff

```bash
chezmoi diff        # compare source state vs target
```

---

## Profile-driven behavior

During `chezmoi init`, you choose profiles that control which packages and tools are installed. See [Profiles](PROFILES) for the full mapping.

---

## Adding new managed files

1. Create the file under `home/` using chezmoi naming conventions
2. Use `.tmpl` extension if the file needs template logic
3. Reference chezmoi data from `.chezmoidata/` as needed
4. Test with `chezmoi apply --source=. -c ~/.config/chezmoi/agentic-workstation.toml --dry-run`

---

**Technical context:** [`docs/README.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/README.md)
