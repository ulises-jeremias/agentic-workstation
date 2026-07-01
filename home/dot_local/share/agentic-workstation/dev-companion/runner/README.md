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

## Safety

- Default mode is **plan_only**.
- Any “edit/push/PR” requires `actions_allowed` in the job and account pack permission.
