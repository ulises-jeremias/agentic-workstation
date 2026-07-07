# Intelligent runner (spec + skeleton)

The queue worker (`~/.local/share/agentic-workstation/dev-companion/worker.sh`) is intentionally simple and stable.
To make background jobs “intelligent”, we introduce a **runner** that:

- reads a job request (JSON),
- loads local policies (skills/catalog + packs),
- produces artifacts (plan/checkpoints/results),
- optionally calls an LLM provider (OpenAI first),
- executes bounded tool actions via allowlists,
- and exits.

This directory defines the runner skeleton; implementations may evolve.

## Provider abstraction

Providers are configured via env vars (names only; secrets in `~/.config/agentic-workstation/env.d/*.env`):

- OpenAI: `OPENAI_API_KEY`
- Anthropic: `ANTHROPIC_API_KEY`
- Ollama: no key required (local)
- OpenCode: no key required (uses its own auth)

## Safety

- Default mode is **plan_only**.
- Any “edit/push/PR” requires `actions_allowed` in the job and account pack permission.

## Integration with agentic-harness `bin/loop`

`bin/loop` and `bin/devcompanion` in [agentic-harness](https://github.com/ulises-jeremias/agentic-harness)
try runners in this order: agentic-workstation runner → `claude --print` → skeleton.

To use this runner as the primary executor for agentic-harness loops:

```bash
export HARNESS_RUNNER_DIR=”$HOME/.local/share/agentic-workstation/dev-companion/runner”
```

This enables full multi-provider selection and LLM policy enforcement for every
loop run. Without it, agentic-harness falls back to `claude --print` (if `claude`
is in PATH) or the built-in skeleton plan.

Add to your shell profile (`~/.bashrc`, `~/.zshrc`) to make it permanent.
