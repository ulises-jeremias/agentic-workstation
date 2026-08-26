# The Complete Stack — agentic-workstation + agentic-harness

> Integrated tutorial: how all 3 layers of the Personal DX Stack work together.

**Time**: ~2.5 hours | **Prerequisites**: None — starts from zero

---

## The 3-Layer Architecture — L1 / L1.5 / L3 (thin host)

| Layer | Repository | What it provides |
|-------|-----------|-----------------|
| **L1 — Workstation** (thin, this repo) | **agentic-workstation** | Machine provisioning (chezmoi, shell, packages, LLM policy, tmux/Herdr) + Toolkit installation + host runner (`dots-devcompanion`); delegates capabilities |
| **L1.5 — Toolkit** | **[agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit)** | **116+ skills** (`agent-toolkit inventory`), 17 agents, 10 loops, 7 MCP templates, packs — sole capability source |
| **L3 — Harness / Project** | **agentic-harness** + your project repo | Memory, personas, packs, loops execution, job queues + project `AGENTS.md` routing |

> **Workstation installs tools, Toolkit owns orchestration.** Workstation provisions `tmux`/`Herdr` + Toolkit; Toolkit owns swarm recipes (`agent-toolkit swarm …`) and loop templates. Runner stays in Workstation (host LLM policy).

You can use L1 + L1.5 alone (provisioned machine with delegated skills, no harness memory). You can use L3 alone (harness memory without provisioned skills, limited). Together (L1→L1.5→L3), they form a complete AI-native development workflow.

---

## Part 1: Setup the Foundation (30 min)

### Install the workstation (L1)

Skills-only (fastest):

```bash
curl -fsSL https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.sh | bash
```

Or full workstation with dotfiles:

```bash
chezmoi init --apply ulises-jeremias/agentic-workstation
```

Verify:

```bash
dots-doctor
```

```text
Skills: 77 via agent-toolkit (agent-toolkit inventory)
Agents: 17 via agent-toolkit
MCP templates: 7 via agent-toolkit
CLI tools: dots-doctor, dots-skills, dots-devcompanion, dots-mcp, dots-loop (delegate to agent-toolkit)
```

### Clone the harness (L3)

```bash
git clone https://github.com/ulises-jeremias/agentic-harness ~/.ai-workspace
cd ~/.ai-workspace
bash scripts/workspace-init.sh
# or Toolkit-owned scaffolding:
agent-toolkit workspace init
```

Verify:

```bash
agent-toolkit workspace context
```

```text
=== Workspace Context Snapshot ===
Harness dir: /home/you/.ai-workspace
Workstation skills: detected (116+ skills via agent-toolkit inventory)
Knowledge entries: 0
Active packs: none
```

Both layers are connected — the harness discovers the workstation's provisioned Toolkit capabilities automatically (L1 provisions → L1.5 delegates → L3 consumes).

---

## Part 2: Configure Your First Project (20 min)

### Create the project

```bash
mkdir ~/projects/hello-stack
cd ~/projects/hello-stack
git init
cat > hello.py << 'EOF'
"""Hello Stack — demo project for the complete agentic stack."""
import argparse

def main():
    parser = argparse.ArgumentParser(description="Hello Stack CLI")
    parser.add_argument("--name", default="World", help="Name to greet")
    args = parser.parse_args()
    print(f"Hello, {args.name}!")

if __name__ == "__main__":
    main()
EOF
git add . && git commit -m "feat: initial hello-stack project"
```

### Add AGENTS.md (L3)

Create `AGENTS.md` in the project root:

```markdown
# AGENTS.md — hello-stack

## Routing

| Task | Delegate to |
|------|------------|
| Jira tasks | jira-assistant skill |
| Planning | planner subagent |
| Implementation | implementer subagent |
| Code review | code-reviewer subagent |
| PR creation | github-cli-workflow skill |

## Conventions

- Python 3.12+
- Conventional Commits: feat:, fix:, docs:, chore:
- pytest for testing
- argparse for CLI
```

### Link the project to the harness (Toolkit-owned)

```bash
cd ~/.ai-workspace
agent-toolkit project link ~/projects/hello-stack hello-stack
# legacy harness: ./bin/project-indexer link ~/projects/hello-stack hello-stack
```

### Create a pack

`~/.ai-workspace/packs/hello-stack.yaml`:

```yaml
name: hello-stack
repos:
  - path: projects/hello-stack
    primary: true
conventions:
  commits: conventional-commits
  language: python
  framework: argparse
  testing: pytest
```

---

## Part 3: End-to-End Task (45 min)

### Start your AI session

```bash
cd ~/.ai-workspace
agent-toolkit workspace context --pack packs/hello-stack.yaml
claude  # or opencode / cursor
```

```text
[AI reads AGENTS.md]
Workspace context loaded: hello-stack
Skills available: 77 (jira-assistant, github-cli-workflow, planner, implementer, code-reviewer, ...) via agent-toolkit inventory
Knowledge: 0 entries (new workspace)
```

### Find work to do

```text
Check if there are any GitHub issues on the hello-stack project.
```

The AI uses the **project-indexer** to find the repo, then `gh issue list`:

```text
No open issues. Let's create one: "Add --greeting flag to customize the greeting".
```

### Plan the feature

```text
Delegate to the planner subagent for this feature.
```

The **planner** (from workstation) produces a plan using the project's conventions (from the harness pack).

### Implement

```text
Implement the plan. Delegate to implementer.
```

The **implementer** subagent:
1. Reads project conventions from the pack
2. Creates branch: `feat/add-greeting-flag`
3. Writes code following Python patterns
4. Commits with Conventional Commits format

### Review

```text
Review the changes. Delegate to code-reviewer.
```

The **code-reviewer** subagent checks:
- Code quality and conventions
- Test coverage
- Security (via security-reviewer if needed)

### Create PR

```text
Push and create a PR. Use github-cli-workflow.
```

The **github-cli-workflow** skill creates a well-formatted PR with:
- Conventional Commits title
- What/Why/Changes/Testing sections
- Link to the issue

---

## Part 4: Automate with Loops (30 min)

Now that manual workflow works, automate recurring tasks.

### Create a daily triage loop (Toolkit owns loop templates)

```bash
cd ~/.ai-workspace
agent-toolkit loop init daily-triage --template daily-triage --tier 1
# or: dots-loop init daily-triage --template daily-triage --tier 1
```

Edit `loops/daily-triage/LOOP.md` to point at hello-stack:

```yaml
request: |
  Scan hello-stack for open issues. Write a report.
```

Run it:

```bash
agent-toolkit loop run daily-triage
# or: dots-loop run daily-triage
```

```text
[L1 - OBSERVE ONLY]
Issues found: 1 (ACME-456 — in progress)
Report saved: loops/daily-triage/report.md
```

### Schedule it

```bash
agent-toolkit loop schedule daily-triage
# or: dots-loop schedule daily-triage
```

```text
Next run: tomorrow 09:00
```

---

## Part 5: Cross-Session Memory (15 min)

### Session 1: Save learnings (harness memory, via `assistant-memory`)

```bash
assistant-memory add --type learning "hello-stack uses argparse with ArgumentDefaultsHelpFormatter"
assistant-memory add --type process "hello-stack workflow: planner → implementer → code-reviewer → github-cli-workflow"
assistant-memory add --type todo "Add CI workflow for hello-stack tests"
# when inside harness dir, legacy: ./bin/assistant-memory add ...
```

### Session 2: AI remembers

```bash
cd ~/.ai-workspace
assistant-memory inject
# or: ./bin/assistant-memory inject (legacy harness path)
claude
```

```text
Previous session learnings:
- hello-stack uses argparse with ArgumentDefaultsHelpFormatter
- hello-stack workflow: planner → implementer → code-reviewer → github-cli-workflow
- Pending: Add CI workflow for hello-stack tests

What would you like to work on?
```

The AI remembers everything from yesterday. No repetition needed.

---

## What You Built

```text
agentic-workstation (L1 thin)     agent-toolkit (L1.5)         agentic-harness (L3) + hello-stack (L3)
┌─────────────────────┐          ┌─────────────────────┐       ┌──────────────────┐
│ provisions: chezmoi │          │ 116+ skills            │       │ knowledge/        │
│ shell, packages,    │─installs─│ 17 agents            │─deleg─│ packs/hello-stack │
│ LLM policy, tmux +  │  Toolkit │ 10 loops             │  via  │ personas/         │
│ Herdr, Toolkit      │──────────│ 7 MCP templates      │ dots-*│ loops/daily-triage│
│ dots-* (thin)       │          │ packs + prompts      │       │ AGENTS.md        │
└─────────────────────┘          └─────────────────────┘       │ hello.py          │
                                                                │ tests/            │
                                                                │ .github/          │
                                                                └──────────────────┘
         Workstation installs tools, Toolkit owns orchestration → L3 consumes
```

### Layer interaction — L1 provisions, L1.5 distributes, L3 consumes

| Action | L1 (Workstation) provisions | L1.5 (Toolkit) distributes | L3 (Harness/Project) consumes |
|--------|----------------------------|---------------------------|-------------------------------|
| Plan feature | LLM policy + Toolkit install | planner subagent | Pack conventions + AGENTS.md routing |
| Implement | shell + packages | implementer subagent | Source code |
| Review | host checks | code-reviewer subagent | PR diff + persona guardrails |
| Create PR | git + gh CLI | github-cli-workflow | Branch + commits + pack config |
| Daily triage | tmux/Herdr provisioning | jira-assistant skill + loop templates | Issues + loop scheduler |
| Next session | maintains LLM policy | skills persist via inventory | Memory injection + knowledge/ |

---

## Related

- [Day in the Life](DAY_IN_THE_LIFE.md) — workstation-only workflow walkthrough
- [Your First PR](https://github.com/ulises-jeremias/agentic-harness/blob/main/docs/tutorials/FIRST_PR.md) — harness-specific first PR
- [Loop Creation Workshop](https://github.com/ulises-jeremias/agentic-harness/blob/main/docs/tutorials/LOOP_WORKSHOP/README.md) — build autonomous loops
- [Multi-Client Setup](https://github.com/ulises-jeremias/agentic-harness/blob/main/docs/tutorials/MULTI_CLIENT_SETUP.md) — manage multiple clients
