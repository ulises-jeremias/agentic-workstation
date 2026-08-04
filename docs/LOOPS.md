# Loop Engineering

> Loop engineering is the practice of designing autonomous, recurring AI-driven
> processes — loops — instead of prompting agents one-by-one.
>
> Inspired by Boris Cherny (Anthropic), Peter Steinberger, Addy Osmani, and
> Cobus Greyling's *Loop Engineering* (2026).

---

## The shift

| Before | After |
|--------|-------|
| You write a prompt → agent acts → you write next prompt | You design a loop → loop prompts the agent → loop decides next action |
| One shot | Recurring, stateful |
| You are in the loop | The loop runs unattended |

---

## Quick Start

agentic-workstation bundles the `dots-workstation-loop-runner` skill and `dots-loop` CLI. They wrap
[ai-workspace](https://github.com/ulises-jeremias/ai-workspace)'s `bin/loop`:

```bash
# Check status of all loops
dots-loop status

# Initialize a loop from a reference pattern
dots-loop init daily-triage

# Run it once (L1: observe only)
dots-loop run daily-triage

# Audit past runs
dots-loop audit daily-triage
```

**Prerequisite**: `ai-workspace` must be installed at `~/.ai-workspace`.
See: `https://github.com/ulises-jeremias/ai-workspace`

---

## Adoption Tiers

| Tier | Autonomy | Cost | When to use |
|------|----------|------|-------------|
| **L1** | Report-only | Low | Exploring a new loop; understanding what it would do |
| **L2** | Assisted, PR-gated | Medium–High | Ready to act, but want human review before merge |
| **L3** | Unattended on allowlist | High | Proven loop with tight allowlist and good coverage |

> **Rule**: always start new loops at L1. Graduate to L2 after 3+ clean runs.
> Graduate to L3 only when the allowlist is narrow and well-tested.

---

## Reference Patterns

7 patterns pre-installed under
`~/.local/share/agentic-workstation/loops/` after `chezmoi apply`.

| Pattern | Tier | Cadence | Cost | Use case |
|---------|------|---------|------|----------|
| `daily-triage` | L1 | 1d | Low | Propose labels for new issues |
| `issue-triage` | L1 | 4h | Low | Propose labels (higher frequency) |
| `changelog-drafter` | L1 | 1d | Low | Draft release notes from merged PRs |
| `post-merge-cleanup` | L2 | 6h | Low | Delete merged branches, close stale issues |
| `dep-sweeper` | L2 | 1d | Medium | Apply patch-level dep updates |
| `pr-babysitter` | L2 | 15m | High | Review and comment on open PRs |
| `ci-sweeper` | L2 | 15m | Very High | Fix failing CI runs |

> **OSS maintainers**: see `oss-pr-monitor`, `oss-triage`, `oss-daily-briefing` in the
> OSS Maintenance Patterns section below — these are purpose-built for multi-repo
> ecosystems with appropriate budget sizing.

To use a reference pattern:

```bash
cp -r ~/.local/share/agentic-workstation/loops/daily-triage ~/.ai-workspace/loops/
dots-loop init daily-triage   # or: edit LOOP.md directly
```

---

## Safety Defaults

All patterns ship with conservative defaults:

- `deny: [merge, force-push, close, delete-branch]` (unless the pattern specifically needs it)
- `budget.max_runs_per_day` capped appropriately per pattern
- `verifier` set for any pattern that touches code

Never widen the allowlist beyond what you have manually tested at L1 first.

---

## Cost Guidance

| Cost tier | Estimated per run | Cadence × runs/day = monthly |
|-----------|------------------|------------------------------|
| Low | ~$0.01–0.05 | `1d × 1 = $1–2/month` |
| Medium | ~$0.05–0.20 | `1d × 1 = $2–6/month` |
| High | ~$0.20–1.00 | `15m × 96 = $600–2900/month` ⚠ |
| Very High | ~$0.50–2.00 | `15m × 96 = $1500–5800/month` ⚠ |

> For high-cost loops (pr-babysitter, ci-sweeper): use `max_runs_per_day` to
> cap monthly spend. Start at `max_runs_per_day: 4` and increase gradually.

---

## More

- [ai-workspace docs/LOOPS.md](https://github.com/ulises-jeremias/ai-workspace/blob/main/docs/LOOPS.md) — full technical reference
- [dots-workstation-loop-runner skill](../home/dot_local/share/agentic-workstation/skills/dots-workstation-loop-runner/SKILL.md)
- [Loop engineering reference](https://github.com/cobusgreyling/loop-engineering)

---

## OSS Maintenance Patterns

For maintainers managing 20-50 OSS repos, three purpose-built patterns ship with
`agentic-harness` (copy them from `~/.local/share/agentic-workstation/loops/`):

| Pattern | Tier | Cadence | Budget | Use case |
|---------|------|---------|--------|----------|
| `oss-pr-monitor` | L2 | 1d | 300k tokens | Merge/close dependabot PRs, report human PRs |
| `oss-triage` | L1 | 1d | 150k tokens | Label issues, respond to questions |
| `oss-daily-briefing` | L1 | 1d | 80k tokens | Read-only activity briefing |

### Key lessons from production use

**Budget sizing matters.** A 40-repo scan requires 150k–300k tokens — the default
60k budgets in generic patterns are too small and cause mid-scan interruptions.
Always size budgets to `(repos × 5k tokens) + 50k overhead`.

**All OSS loops must be resumable.** Add this block to every `request.md`:

```
**Resumability (read first):**
Read loops/<name>/STATE.md. If `last_processed_repo` is set, skip all repos
before that name. After each repo: last_processed_repo: <owner>/<repo>.
On completion: clear last_processed_repo, set last_run_status: success.
```

This recovers interrupted runs without starting over — critical for 40+ repo scans
where a single timeout mid-scan previously wasted 20+ minutes of context.

**Ecosystem packs for repo lists.** Rather than hardcoding repo lists in `request.md`,
define a pack at `packs/my-ecosystem.yaml` with the repo list, then reference it
from the loop. This makes loops reusable across different ecosystems.
