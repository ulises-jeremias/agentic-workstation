# Creating Your First Skill

Welcome to `agentic-workstation`! If you're new to open source or this repository, this tutorial is the perfect place to start.

In this guide, you'll learn what "skills" are, how they are structured, and how to create your first Hello World skill that an AI tool (like Claude Code, pi, or Windsurf) can execute.

## Prerequisites

Before starting, ensure you have:
- Familiarity with basic Markdown and JSON formatting.
- `agentic-workstation` installed on your machine.
- An AI coding tool installed (e.g., Claude Code, pi, or Windsurf).

## Understanding Skill Anatomy

A **skill** is a document (plus optional supporting assets) that teaches an AI tool how to perform a specific workflow. When you interact with your AI, it loads these skills at startup, which guides how it responds to your requests.

Every skill lives inside a dedicated folder (e.g., `home/dot_local/share/agentic-workstation/skills/my-skill/`) and contains two primary files:

1. `SKILL.md` — The main content read by the AI tool. This contains the prompt instructions, boundaries, and a YAML frontmatter block for metadata.
2. `skill.json` — The machine-readable manifest. This declares what AI tools the skill is compatible with and any required command-line dependencies.

## Creating `SKILL.md`

`SKILL.md` is where the magic happens. It tells the AI exactly *what* to do and *how* to do it.

### YAML Frontmatter

At the very top of `SKILL.md`, you must include a YAML frontmatter block. This provides a human and machine-readable name and description.

```yaml
---
name: my-first-skill
description: A short description of what this skill does.
---
```

### The `## When to use` Section

Immediately below the introduction, always include a `## When to use` heading. This helps the orchestrator (and the user) understand precisely when this skill should be invoked.

```markdown
## When to use

- When the user asks to greet someone.
- When the user wants a simple Hello World example.
```

### Template Usage

To keep your `SKILL.md` small and focused on routing and guardrails, we heavily utilize templates. If your skill generates a specific report or requires long, reusable Markdown structures, place them inside a `references/default-template.md` file within your skill's directory. Your `SKILL.md` can then instruct the AI to read and use that template as a starting point.

### Writing good AI instructions

Writing for an AI is different from writing for a human. Keep these tips in mind:
- **Be Explicit**: Define clear boundaries (e.g., "Do not modify files outside of `src/`").
- **Use Checklists**: AI agents follow numbered lists very well.
- **Provide Examples**: Give brief examples of the expected output.

## Creating `skill.json`

The `skill.json` file provides metadata and compatibility routing for your skill. While `dots-skills sync` can discover and link skills without it (defaulting to universal compatibility), including it is strongly recommended to declare which AI tools your skill supports and any required CLI dependencies.

### Tool Compatibility

You must explicitly declare which tools your skill supports. Never assume a skill "works everywhere". `dots-skills sync` currently routes to `universal`, `claude-code`, `pi`, and `windsurf` — declare your target tools accordingly. If you only tested it in Claude Code, declare `true` for it and `false` for the rest.

```json
"compatibility": {
  "claude-code": { "supported": true },
  "pi": { "supported": true },
  "windsurf": { "supported": false, "notes": "Requires testing" }
}
```

## Hello World Example

Let's build a concrete, copy-pasteable example: a skill that greets the user.

### Folder Structure

Create a new directory for your skill:
```text
home/dot_local/share/agentic-workstation/skills/hello-world-cli/
├── SKILL.md
└── skill.json
```

### `SKILL.md`

Create `SKILL.md` and add the following:

```markdown
---
name: hello-world-cli
description: A simple skill that teaches the AI how to print a greeting.
---

# Hello World CLI

This skill instructs the AI on how to greet the user properly in the terminal.

## When to use

- When the user asks for a greeting.
- When the user types "Hello World".

## Workflow

1. Acknowledge the user's request politely.
2. Ask the user for their name if they didn't provide one.
3. Print out `Hello, <name>! Welcome to agentic-workstation.`

## Boundaries

- Do not create any new files.
- Keep the greeting under one sentence.
```

### `skill.json`

Create `skill.json` and add the following:

```json
{
  "$schema": "https://raw.githubusercontent.com/ulises-jeremias/agentic-workstation/main/lib/schemas/skill.schema.json",
  "name": "hello-world-cli",
  "version": "1.0.0",
  "description": "A simple skill that teaches the AI how to print a greeting.",
  "source": "bundled",
  "author": "agentic-workstation",
  "tags": [
    "demo",
    "hello-world"
  ],
  "requires": [],
  "compatibility": {
    "universal": {
      "supported": true
    },
    "claude-code": {
      "supported": true
    }
  }
}
```

### Expected Behavior

When a user opens their AI coding tool and types "Hello World", the AI will read this skill, acknowledge the user politely, and print the designated greeting.

## Routing and Triggers

Creating the skill files is only half the battle. You must tell the system how to discover it.

1. **Register the skill:** Add your skill to the `home/.chezmoidata/skills-registry.yaml` file so that `dots-skills sync` knows it exists.
   ```yaml
   - name: hello-world-cli
     source: bundled
     enabled: true
   ```
2. **Configure the Router Trigger:** Add your skill to `home/dot_local/share/agentic-workstation/skills/skill-catalog.yaml`. This file defines the `triggers`—the specific keywords or phrases that tell the orchestrator to route a task to your skill.

## Testing with `dots-skills sync`

Once your files are saved, it's time to run the sync process:

1. Open your terminal.
2. Run `chezmoi apply` or `dots-skills sync`. This reads your `skill.json` and creates symlinks for the compatible AI tools.
3. Open your AI tool (e.g., Claude Code) and type your trigger phrase to ensure it loads your new skill.

> [!TIP]
> Run `dots-skills list` to verify that your skill appears in the registry and shows as `✓ linked` under your supported tools.

### Common Mistakes
- **Forgetting `skill.json`**: Without this manifest, your skill will sync with universal compatibility — which may work, but limits your ability to declare tool-specific support and dependencies.
- **Assuming Universal Compatibility**: Always define the `compatibility` matrix.
- **Vague Triggers**: Ensure your `triggers` in `skill-catalog.yaml` are specific so the orchestrator doesn't route unrelated tasks to your skill.

## Submitting your Pull Request

Ready to share your skill with the world?

1. Ensure you have run all local validation checks:
   ```bash
   bash scripts/validate-repo-structure.sh
   bash scripts/check-shell-syntax.sh
   git diff --check
   ```
2. Create a branch following the `feat/` convention (e.g., `feat/add-hello-world-skill`).
3. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "docs: add creating a skill tutorial"
   ```
4. Push your branch and open a Pull Request. Explain what your skill does and list the validation steps you ran.

## Next Steps

- Check out the full [Skills Architecture Document](../SKILLS.md) for deeper technical details.
- Read about [MCP Templates](../MCP_TEMPLATES.md) to learn how to connect your skills to external APIs and data sources.
- Review [Contributing Guidelines](../../CONTRIBUTING.md) for more details on contributing to the repository.

Happy coding!
