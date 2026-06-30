# ADR-008: Dev companion queue with plan-only default

## Status

Accepted

## Context

The dev companion supports both interactive (IDE-first) and background (queue-based) workflows. Background automation raises safety concerns:

- Unsupervised LLM-generated changes could introduce bugs or security issues
- Auto-merging to shared branches could disrupt team workflows
- Cross-account path access could leak data between client projects
- Long-running jobs without bounds could waste resources

We needed a queue system that is:

- **Safe by default** — no destructive actions without explicit opt-in
- **Observable** — all actions produce artifacts that can be reviewed
- **Bounded** — jobs have time limits, step limits, and cost budgets
- **Resumable** — partial progress is saved, not lost on failure

## Decision

Implement a file-based job queue under `~/.local/share/dots-ai/dev-companion/` with **plan-only as the default mode**:

- `dots-devcompanion enqueue` creates a job JSON file
- `dots-devcompanion run-once` processes the next job
- Jobs produce `plan.md` (LLM-generated plan) and `result.json` (metadata) artifacts
- Execution beyond planning requires explicit `"automation_level"` in the job or account pack
- Account packs enforce path allowlists and credential requirements

Safety invariants:

1. Single-flight per queue (file lock)
2. Bounded execution (wall time, step count, cost budget)
3. No auto-merge to shared branches without documented policy
4. Missing credentials → skip and stop (never prompt or guess)

## Consequences

### Positive

- Safe out-of-the-box — new users can't accidentally auto-merge or push
- Observable — every job produces reviewable artifacts
- Extensible — account packs add per-client boundaries without code changes
- Resumable — jobs can be retried or continued after transient failures

### Negative

- Plan-only default means extra steps for users who want full automation
- File-based queue is simpler but less scalable than a database-backed system
- Account pack configuration requires upfront setup per client engagement
