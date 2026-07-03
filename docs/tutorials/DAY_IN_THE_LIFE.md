# Day in the Life — agentic-workstation

> A complete walkthrough: from opening your terminal to a merged PR, using agentic-workstation skills and agents.

**Time to read**: 15 minutes | **Time to follow along**: ~45 minutes
**Prerequisites**: agentic-workstation installed (skills-only or full)

---

## Scenario

You're a developer on the `hello-harness` project. It's Monday morning. You open your terminal and start your AI coding tool (Claude Code, opencode, or Cursor). Here's how your day unfolds with agentic-workstation.

---

## 09:00 — Morning Context

Your AI reads `AGENTS.md` and knows:

```text
I'm working on hello-harness.
Conventions: Conventional Commits, feat/JIRA-123 branches
Skills available: Jira, GitHub, code-reviewer, planner, implementer
Knowledge base: patterns from previous sessions loaded
```

Instead of typing "I'm working on hello-harness, it's a Python project, we use Jira..." every morning, the AI already knows. You saved that context yesterday.

```bash
# What the AI does automatically:
assistant-memory inject    # Loads saved learnings
workspace-context          # Loads project packs
```

---

## 09:05 — Find Today's Task

You ask your AI:

```text
Check Jira for my assigned tasks in the current sprint.
```

The AI delegates to the **jira-assistant** skill:

```text
[Delegating to jira-assistant skill]

Jira query: assignee = currentUser() AND sprint in openSprints()

Results:
  ACME-456 — Add --name flag to hello.py (In Progress)
  ACME-457 — Add input validation for empty strings (To Do)
  ACME-458 — Write integration tests for CLI (To Do)
```

No more opening Jira in a browser, copying ticket numbers, pasting them into chat. The skill handles authentication, query construction, and formatting.

---

## 09:10 — Plan the Feature

```text
Plan the implementation for ACME-456. Delegate to the planner subagent.
```

The **planner** subagent produces:

```markdown
# Implementation Plan: ACME-456 — Add --name flag

## Files to change
- hello.py: Add argparse with --name argument
- (no other files affected)

## Steps
1. Import argparse at top of hello.py
2. Create ArgumentParser with --name parameter (default: "World")
3. Replace hardcoded "Hello, World!" with f"Hello, {args.name}!"
4. Add input validation: reject empty names
5. Update --help output

## Testing
- python hello.py → "Hello, World!"
- python hello.py --name Alice → "Hello, Alice!"
- python hello.py --name "" → Error: name cannot be empty

## Risks
- None — isolated change, no dependencies
```

---

## 09:15 — Implement

```text
Implement the plan. Create a branch and commit.
```

The **implementer** subagent:

```bash
git checkout -b feat/ACME-456-add-name-flag
# Edits hello.py with argparse
# Adds input validation
git add hello.py
git commit -m "feat: add --name flag with input validation

Adds argparse-based --name parameter to hello.py.
Default value is 'World'. Rejects empty names.

Closes ACME-456"
```

You review the diff. It's exactly what the plan described. No surprises.

---

## 09:20 — Self-Review

```text
Review the changes. Delegate to code-reviewer.
```

The **code-reviewer** subagent:

```markdown
# Code Review: feat/add-name-flag

## Summary
Clean implementation. Follows conventions. One suggestion.

## Suggestions
1. [nit] Consider using `argparse.ArgumentDefaultsHelpFormatter`
   for better --help output. Not blocking.

## Verdict
LGTM. No blockers.
```

You apply the suggestion (add `formatter_class=argparse.ArgumentDefaultsHelpFormatter`) and amend the commit.

---

## 09:25 — Create the PR

```text
Push the branch and create a pull request.
Use the github-cli-workflow skill.
```

The **github-cli-workflow** skill:

```bash
git push origin feat/ACME-456-add-name-flag
gh pr create \
  --title "feat: add --name flag with input validation" \
  --body "## What
Adds --name parameter to hello.py using argparse.

## Changes
- Import argparse
- Add --name flag with 'World' default
- Validate non-empty name input
- Use ArgumentDefaultsHelpFormatter

## Testing
```
python hello.py                # Hello, World!
python hello.py --name Alice   # Hello, Alice!
python hello.py --name ''      # Error: name cannot be empty
python hello.py --help         # Shows formatted help
```

Closes ACME-456"
```

```text
PR created: https://github.com/you/hello-harness/pull/12
```

---

## 09:30 — Queue Background Review

While you wait for human review, queue an automated background check:

```text
Queue a background code review for hello-harness.
```

```bash
dots-devcompanion queue hello-harness --template code-review
dots-devcompanion run-once
```

```text
Job queued: code-review-hello-harness-001
Running... plan.md generated at jobs/hello-harness/code-review-001/plan.md
Status: complete
```

The background runner:
1. Reads the latest PRs
2. Runs the code-reviewer agent
3. Produces a review report
4. Posts draft comments (if configured)

All without you waiting. You can check the results later.

---

## 10:00 — Address Review Feedback

A colleague reviewed PR #12 and left comments. You start a new session.

```text
Address review comments on my open PRs.
```

The AI uses **gh-address-comments** to:

```text
PR #12 — 2 comments:
  1. [reviewer] "Consider adding --greeting flag for custom greetings"
     → Response: Good idea, but out of scope for ACME-456. Created ACME-459.
  2. [reviewer] "Add type hints to the argument parsing function"
     → Applied: Added type hints. Amended commit.
```

You push the amendment. CI passes. The reviewer approves.

---

## 11:00 — Merge and Save Knowledge

```text
Merge the PR and save what we learned.
```

```bash
gh pr merge 12 --squash --delete-branch
```

Then save the learnings:

```bash
assistant-memory add --type learning "Use argparse.ArgumentDefaultsHelpFormatter for better CLI help"
assistant-memory add --type learning "PRs should include a Testing section with copy-pasteable commands"
assistant-memory add --type process "Standard workflow: jira-assistant → planner → implementer → code-reviewer → github-cli-workflow"
```

---

## 14:00 — Afternoon: Next Task

New session. The AI injects saved knowledge:

```text
Good afternoon. Here's what I know:
- You completed ACME-456 this morning
- You use argparse with ArgumentDefaultsHelpFormatter
- Your PR format includes a Testing section
- Your next task is ACME-457 (input validation improvements)

Ready to work on ACME-457?
```

No repetition. No context re-establishment. The AI picks up where you left off.

---

## What Made This Work

### Skills Delegation

Every tool integration was handled by a skill, not manual prompting:

| Task | Skill used |
|------|-----------|
| Find Jira tasks | `jira-assistant` |
| Plan feature | `planner` subagent |
| Write code | `implementer` subagent |
| Review code | `code-reviewer` subagent |
| Create PR | `github-cli-workflow` |
| Background review | `dots-devcompanion` |
| Address comments | `gh-address-comments` |
| Save learnings | `assistant-memory` |

### Persistent Memory

The AI remembered across sessions:

- Project conventions (Conventional Commits, branch naming)
- Python patterns (argparse with defaults formatter)
- PR format expectations (Testing section with commands)
- Current sprint context (ACME-457 next)

### No Repetition

You never typed:
- "I'm working on hello-harness"
- "We use Jira, my project is ACME"
- "We use Conventional Commits"
- "Here's my PR template"

The harness provided all of that from packs, knowledge, and AGENTS.md.

---

## Try It Yourself

### Setup (first time only)

```bash
# Install skills
curl -fsSL https://github.com/ulises-jeremias/agentic-workstation/releases/latest/download/install-skills.sh | bash

# Or full workstation
chezmoi init --apply ulises-jeremias/agentic-workstation
```

### First session

```text
Load workspace context. Check Jira/ClickUp for my tasks.
```

### Follow the flow

```text
Plan → Implement → Review → PR → Save knowledge
```

### Next session

```text
Inject knowledge. What did we work on yesterday?
```

---

## Related

- [Complete Stack Tutorial](https://github.com/ulises-jeremias/agentic-harness/blob/main/docs/tutorials/COMPLETE_STACK.md) — workstation + harness together
- [Loop Creation Workshop](https://github.com/ulises-jeremias/agentic-harness/blob/main/docs/tutorials/LOOP_WORKSHOP/README.md) — automate recurring tasks
- [Your First PR](https://github.com/ulises-jeremias/agentic-harness/blob/main/docs/tutorials/FIRST_PR.md) — harness-specific first PR walkthrough
