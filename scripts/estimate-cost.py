#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""
scripts/estimate-cost.py — Per-invocation cost estimation from trace.jsonl.

Reads a trace.jsonl file (one JSON object per line) and estimates the total
cost based on the model used and token counts extracted from each event.

Usage:
    python3 scripts/estimate-cost.py < path/to/trace.jsonl
    python3 scripts/estimate-cost.py path/to/trace.jsonl
    python3 scripts/estimate-cost.py --model gpt-4o --json path/to/trace.jsonl
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

# ── pricing table ($USD per 1M tokens) ────────────────────────────────────

PRICING: dict[str, dict[str, float]] = {
    "claude-sonnet-3.5": {"input": 3.0, "output": 15.0},
    "claude-3-5-sonnet": {"input": 3.0, "output": 15.0},
    "claude-3-haiku": {"input": 0.25, "output": 1.25},
    "gpt-4o": {"input": 2.50, "output": 10.0},
    "gpt-4o-mini": {"input": 0.15, "output": 0.60},
}

MODEL_ALIASES: dict[str, str] = {
    "claude-sonnet-4": "claude-sonnet-3.5",
    "claude-sonnet-3.7": "claude-sonnet-3.5",
    "claude-3-5-sonnet-20241022": "claude-3-5-sonnet",
    "claude-3-5-haiku-20241022": "claude-3-haiku",
    "claude-opus-4": "claude-sonnet-3.5",
    "gpt-4o-2024-08-06": "gpt-4o",
    "gpt-4o-2024-05-13": "gpt-4o",
    "gpt-4o-mini-2024-07-18": "gpt-4o-mini",
    "gpt-4": "gpt-4o",
    "gpt-3.5-turbo": "gpt-4o-mini",
}

DEFAULT_MODEL = "claude-sonnet-3.5"


def resolve_model(model: str) -> str:
    """Resolve a model name to a known pricing key."""
    key = model.lower().strip()
    if key in PRICING:
        return key
    if key in MODEL_ALIASES:
        return MODEL_ALIASES[key]
    return DEFAULT_MODEL


def get_price(model_key: str) -> dict[str, float]:
    """Return {input, output} price per million tokens."""
    return PRICING.get(model_key, PRICING[DEFAULT_MODEL])


def extract_tokens(event: dict[str, Any]) -> tuple[int, int]:
    """Extract (prompt_tokens, completion_tokens) from a trace event.

    Supports multiple event shapes:
      - Direct fields: prompt_tokens, completion_tokens
      - Usage object (OpenAI-style): {"prompt_tokens": N, "completion_tokens": N}
      - Kind-based: kind="prompt" → prompt_tokens, kind="completion" → completion_tokens
    """
    p = event.get("prompt_tokens", 0) or 0
    c = event.get("completion_tokens", 0) or 0

    usage = event.get("usage", {})
    if isinstance(usage, dict):
        p = p or usage.get("prompt_tokens", 0) or 0
        c = c or usage.get("completion_tokens", 0) or 0

    kind = event.get("kind", "")
    if kind == "prompt":
        c = 0
    elif kind == "completion":
        p = 0

    return int(p), int(c)


def estimate_cost(
    trace_path: Path | None = None,
    model: str = DEFAULT_MODEL,
    json_output: bool = False,
) -> int:
    """Read trace events, compute cost, and print summary."""
    model_key = resolve_model(model)
    price = get_price(model_key)

    total_prompt = 0
    total_completion = 0
    event_count = 0

    # ── open input ───────────────────────────────────────────────────────
    if trace_path is None or str(trace_path) == "-":
        lines = sys.stdin.readlines()
    else:
        lines = trace_path.read_text(encoding="utf-8").splitlines()

    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        event_count += 1
        p, c = extract_tokens(event)
        total_prompt += p
        total_completion += c

    total_tokens = total_prompt + total_completion

    # ── cost calculation ─────────────────────────────────────────────────
    cost_input = (total_prompt / 1_000_000) * price["input"]
    cost_output = (total_completion / 1_000_000) * price["output"]
    total_cost = cost_input + cost_output

    # ── output ───────────────────────────────────────────────────────────
    if json_output:
        result = {
            "total_tokens": total_tokens,
            "input_tokens": total_prompt,
            "output_tokens": total_completion,
            "event_count": event_count,
            "estimated_cost": round(total_cost, 6),
            "model": model_key,
            "model_display": model,
            "pricing": {
                "input_per_1m": price["input"],
                "output_per_1m": price["output"],
            },
        }
        print(json.dumps(result, indent=2))
    else:
        print(f"Total tokens: {total_tokens:,} "
              f"(input: {total_prompt:,} + output: {total_completion:,})")
        print(f"Estimated cost: ${total_cost:.2f}")
        print(f"Model: {model_key}")
        if event_count:
            print(f"Events scanned: {event_count}")
        if model_key != resolve_model(model):
            print(f"Warning: '{model}' resolved to '{model_key}'", file=sys.stderr)

    return 0


def add_pricing_model(name: str, input_price: float, output_price: float) -> None:
    """Register a new model pricing entry (call before estimate_cost)."""
    PRICING[name] = {"input": input_price, "output": output_price}


def list_models() -> None:
    """Print all known pricing models."""
    print("Known models and their pricing ($USD per 1M tokens):")
    print(f"  {'Model':<30} {'Input $/1M':>12} {'Output $/1M':>13}")
    print(f"  {'─'*30} {'─'*12} {'─'*13}")
    for name, price in sorted(PRICING.items()):
        print(f"  {name:<30} {price['input']:>10.2f}  {price['output']:>10.2f}")
    print(f"\n  Aliases: {len(MODEL_ALIASES)} model name mappings registered.")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Estimate LLM invocation cost from a trace.jsonl file.",
    )
    parser.add_argument(
        "trace",
        nargs="?",
        default="-",
        help="Path to trace.jsonl (default: stdin)",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Model name for pricing (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Output machine-readable JSON",
    )
    parser.add_argument(
        "--list-models",
        action="store_true",
        help="List all known models and their pricing",
    )

    args = parser.parse_args()

    if args.list_models:
        list_models()
        return 0

    trace_path: Path | None
    if args.trace == "-":
        trace_path = None
    else:
        trace_path = Path(args.trace)
        if not trace_path.exists():
            print(f"Error: file not found: {trace_path}", file=sys.stderr)
            return 1

    return estimate_cost(
        trace_path=trace_path,
        model=args.model,
        json_output=args.json_output,
    )


if __name__ == "__main__":
    raise SystemExit(main())
