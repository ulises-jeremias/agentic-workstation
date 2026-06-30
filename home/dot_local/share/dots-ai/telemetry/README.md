# Telemetry

This directory (`~/.local/state/dots-ai/telemetry/`) is the optional
local-only telemetry sink for dots-ai.

## Privacy

- **All data is local.** Nothing is sent to any server, ever.
- Files are written in append-only JSONL format.
- Enable with `dots-doctor telemetry --enable`.
- Disable (and optionally delete) with `dots-doctor telemetry --disable`.

## Format

Each invocation appends one JSON line:

```json
{"ts": "2026-06-30T08:00:00Z", "event": "skill.invoked", "skill": "dots-ai-assistant", "tool": "claude-code"}
```

## Reading

```bash
# Summary report
dots-doctor telemetry

# Raw JSONL
cat ~/.local/state/dots-ai/telemetry/*.jsonl
```
