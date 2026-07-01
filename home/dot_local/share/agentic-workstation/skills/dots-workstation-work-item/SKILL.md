---
name: dots-workstation-work-item
description: >-
  WHAT - Router for creating and refining epics, user stories, tasks, bugs, and incidents using agentic-workstation Best Practices work item hierarchy.
---

# Work Item Router (WHAT)

Use this skill when the user asks to create, refine, or evaluate work items.

## Default guardrails

1. Apply **`dots-workstation-output-handshake`** before producing final content or writing to a tool.
2. Use the smallest applicable skill:
   - Epic -> `dots-workstation-epic`
   - User story -> `dots-workstation-user-story`
   - Technical task -> `dots-workstation-task`
   - Bug -> `dots-workstation-bug`
   - Incident -> `dots-workstation-incident`
3. Use **`dots-workstation-planning`** when the item needs breakdown, estimation, prioritization, or capacity checks.
4. Use **`clickup-cli`** for ClickUp writes only after user approval.

## Hierarchy

Epic -> Story/Task/Bug -> Subtasks. Not every methodology uses every level; follow the engagement pack and ticket system.

## References

- `references/default-template.md`
- `references/example-routing-dashboard.md` — example routing decision classifying a feature request as user story
