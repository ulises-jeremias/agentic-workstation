# ADR-005: LLM provider abstraction for dev companion runner

## Status

Accepted

## Context

The dev companion background runner needs LLM capabilities to generate intelligent plans from job descriptions. However:

- Not all developers have access to paid API keys (Anthropic, OpenAI)
- Local LLM options (Ollama, vLLM) vary by machine and GPU availability
- OpenCode ships with `big-pickle`, a free local model available to all agentic-workstation developers
- The runner should work out-of-the-box without configuration for the common case

We needed a provider abstraction that:

- Automatically selects the best available provider
- Prioritizes free/local options over paid cloud APIs
- Degrades gracefully when no provider is available
- Is extensible for future providers

## Decision

Implement a **provider-agnostic LLM dispatcher** that auto-selects the first available provider in priority order:

1. **OpenCode (big-pickle)** — free, local, zero-config
2. **Ollama** — free, local, requires model pull
3. **Anthropic Claude** — paid, requires `ANTHROPIC_API_KEY`
4. **OpenAI** — paid, requires `OPENAI_API_KEY`

Each provider implements a common `LLMProvider` interface with `is_available()`, `get_priority()`, and `generate()` methods. The dispatcher checks availability and selects the first provider that responds.

When no provider is available, the runner generates a **skeleton plan** (structured template without LLM analysis) rather than failing.

## Consequences

### Positive

- Zero-config experience for most developers (OpenCode + big-pickle works immediately)
- No mandatory cloud API costs
- Graceful degradation — always produces output, even without an LLM
- Easy to add new providers (implement interface + register)

### Negative

- Local models produce lower-quality plans than Claude/GPT-4
- Provider priority is fixed (no per-user override yet)
- The skeleton plan fallback may be too generic for complex tasks
