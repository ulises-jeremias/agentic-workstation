# ECC Patterns (Reference Only)

`everything-claude-code` is used as a **pattern library**, not a dependency.

> [!NOTE]
> ECC is **never** installed as a dependency. We extract conceptual patterns and vendor only a tiny MIT subset for reference. This keeps the agentic-workstation harness independent and portable.

## What we borrow conceptually

- Loop guardrails: checkpoints, stall detection, retry caps, and explicit escalation.
- Hooks-as-quality-gates: deterministic checks on task completion.
- Configuration-driven orchestration: keep policy in files; keep runtime pluggable.

## What we vendored (bounded)

We intentionally vendor only a **tiny** subset (MIT) for reference:

- `~/.local/share/agentic-workstation/third-party/everything-claude-code/NOTICE.md`
- `~/.local/share/agentic-workstation/third-party/everything-claude-code/agents/loop-operator.md`
- `~/.local/share/agentic-workstation/third-party/everything-claude-code/rules/common/security.md`

## What we avoid

> [!WARNING]
> Do **not** vendor the entire ECC plugin. It creates maintenance burden and harness mismatch with the agentic-workstation three-layer architecture.

- Vendoring the entire plugin (maintenance + harness mismatch).
- Depending on ECC install flows to use agentic-workstation policies.

## Attribution

Small verbatim excerpts (MIT) are kept under:

`~/.local/share/agentic-workstation/third-party/everything-claude-code/`

See `NOTICE.md` in that directory.

---

## See Also

- [AGENTIC_HARNESS.md](AGENTIC_HARNESS.md) — agentic-workstation three-layer agentic framework
- [DEV_COMPANION_RELIABILITY.md](DEV_COMPANION_RELIABILITY.md) — Loop guardrails and reliability invariants
- [MULTI_AGENT_ORCHESTRATION.md](MULTI_AGENT_ORCHESTRATION.md) — Hook-based quality gates in multi-agent
- [AI_LAYER.md](AI_LAYER.md) — Where vendored content lives after apply
