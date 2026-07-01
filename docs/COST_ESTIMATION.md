# Cost Estimation

> Estimate LLM invocation costs from trace files for budget tracking and cost attribution.

---

## Overview

`scripts/estimate-cost.py` reads a [trace.jsonl](../home/dot_local/share/agentic-workstation/dev-companion/runner/README.md) file produced by the dev-companion runner or the `ai-workspace` loop engine and calculates the total token usage and estimated cost based on model-specific pricing.

---

## Usage

### Basic

```bash
# Pipe a trace file on stdin
python3 scripts/estimate-cost.py < ~/.ai-workspace/loops/pr-babysitter/runs/20260430T120000Z-abc123/trace.jsonl

# Pass as positional argument
python3 scripts/estimate-cost.py path/to/trace.jsonl
```

### Specify a model

```bash
python3 scripts/estimate-cost.py --model gpt-4o trace.jsonl
python3 scripts/estimate-cost.py --model claude-3-haiku trace.jsonl
```

### Machine-readable output

```bash
python3 scripts/estimate-cost.py --json trace.jsonl
```

JSON output:

```json
{
  "total_tokens": 12345,
  "input_tokens": 8000,
  "output_tokens": 4345,
  "event_count": 12,
  "estimated_cost": 0.089,
  "model": "gpt-4o",
  "model_display": "gpt-4o",
  "pricing": {
    "input_per_1m": 2.5,
    "output_per_1m": 10.0
  }
}
```

### List known models

```bash
python3 scripts/estimate-cost.py --list-models
```

Shows all registered pricing entries and model name aliases.

---

## Output

### Human-readable

```
Total tokens: 12,345 (input: 8,000 + output: 4,345)
Estimated cost: $0.89
Model: claude-sonnet-3.5
Events scanned: 12
```

### Fields

| Field | Description |
|-------|-------------|
| `total_tokens` | Sum of all input + output tokens across events |
| `input_tokens` | Cumulative `prompt_tokens` |
| `output_tokens` | Cumulative `completion_tokens` |
| `event_count` | Number of JSON lines scanned |
| `estimated_cost` | Computed cost in USD |
| `model` | Resolved pricing model key |

---

## Pricing table

| Model | Input ($/1M tokens) | Output ($/1M tokens) |
|-------|---------------------|----------------------|
| Claude 3.5 Sonnet | $3.00 | $15.00 |
| Claude 3 Haiku | $0.25 | $1.25 |
| GPT-4o | $2.50 | $10.00 |
| GPT-4o-mini | $0.15 | $0.60 |

Unknown or alias models fall back to Claude 3.5 Sonnet pricing. A warning is printed to stderr when an alias is resolved.

### How to add a new model

Add an entry to the `PRICING` dict in `scripts/estimate-cost.py:26`:

```python
PRICING: dict[str, dict[str, float]] = {
    ...
    "my-model": {"input": 5.0, "output": 20.0},
}
```

If the new model has a display name that differs from the pricing key, add an alias:

```python
MODEL_ALIASES: dict[str, str] = {
    ...
    "my-model-2026-01-01": "my-model",
}
```

To add pricing at runtime (e.g. from a config file), call `add_pricing_model()` before `estimate_cost()`:

```python
from scripts.estimate_cost import add_pricing_model

add_pricing_model("custom-model", input_price=1.0, output_price=4.0)
```

---

## Trace file format

The script accepts any newline-delimited JSON file where events contain `prompt_tokens` and/or `completion_tokens` fields. Supported shapes:

```jsonl
{"kind": "prompt", "prompt_tokens": 4000}
{"kind": "completion", "completion_tokens": 1000}
{"prompt_tokens": 2000, "completion_tokens": 500}
{"usage": {"prompt_tokens": 3000, "completion_tokens": 800}}
```

The loop runner and dev-companion runner both emit events in this format.

---

## CI integration

### Cost gate

Reject runs that exceed a budget threshold:

```bash
LIMIT=0.50
COST=$(python3 scripts/estimate-cost.py --json trace.jsonl | python3 -c "import sys,json; print(json.load(sys.stdin)['estimated_cost'])")
if (( $(echo "$COST > $LIMIT" | bc -l) )); then
  echo "Cost $COST exceeds limit $LIMIT — aborting"
  exit 1
fi
```

### GitHub Actions

```yaml
- name: Estimate cost
  run: |
    python3 scripts/estimate-cost.py --json trace.jsonl > cost.json
    cat cost.json
```

### Aggregating multiple runs

```bash
for trace in ~/.ai-workspace/loops/*/runs/*/trace.jsonl; do
  python3 scripts/estimate-cost.py --json "$trace" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'{d[\"total_tokens\"]},{d[\"estimated_cost\"]}')
"
done
```

---

## Script reference

```
usage: estimate-cost.py [-h] [--model MODEL] [--json] [--list-models] [trace]

Estimate LLM invocation cost from a trace.jsonl file.

positional arguments:
  trace          Path to trace.jsonl (default: stdin)

options:
  -h, --help     show this help message and exit
  --model MODEL  Model name for pricing (default: claude-sonnet-3.5)
  --json         Output machine-readable JSON
  --list-models  List all known models and their pricing
```

---

## See also

- [DEV_COMPANION.md](DEV_COMPANION.md) — dev-companion overview
- [DEV_COMPANION_LLM.md](DEV_COMPANION_LLM.md) — LLM provider selection
- [LOOPS.md](LOOPS.md) — loop engineering patterns and cost guidance
- [`scripts/estimate-cost.py`](../scripts/estimate-cost.py) — the estimation script
