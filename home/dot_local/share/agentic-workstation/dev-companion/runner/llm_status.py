"""Diagnostic for the dev-companion LLM policy.

Prints which providers are allowed, which one would run next, and where the
policy values come from — without making any LLM call. Used by
``dots-devcompanion llm-status``.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from llm_dispatcher import create_dispatcher  # noqa: E402
from policy import LLMPolicy, PolicyError  # noqa: E402


def _build_report(*, job_path: Path | None) -> dict:
    job_llm = None
    job_id = None
    if job_path is not None:
        try:
            data = json.loads(job_path.read_text(encoding="utf-8"))
        except Exception as exc:
            return {
                "ok": False,
                "error": f"could not read job {job_path}: {exc}",
            }
        job_id = data.get("id")
        raw = data.get("llm")
        if isinstance(raw, dict):
            job_llm = raw
        # Bool/None: nothing to merge from the job.

    try:
        policy = LLMPolicy.load(job_llm=job_llm)
    except PolicyError as exc:
        return {
            "ok": False,
            "error": f"policy_violation: {exc}",
            "job_id": job_id,
        }

    dispatcher = create_dispatcher(policy=policy)
    candidates = dispatcher.list_candidates()
    all_providers = dispatcher.list_all_providers()

    selected = next((c for c in candidates if c.get("available")), None)

    return {
        "ok": True,
        "job_id": job_id,
        "policy": policy.to_audit(),
        "selected": selected,
        "candidates": candidates,
        "all_providers": all_providers,
    }


def _format_human(report: dict) -> str:
    if not report.get("ok"):
        return f"ERROR: {report.get('error')}\n"

    lines: list[str] = []
    policy = report["policy"]
    lines.append("dots-devcompanion llm-status")
    lines.append("")
    lines.append("Policy")
    lines.append(
        "  allowlist:      "
        + (", ".join(policy["allowlist"]) if policy["allowlist"] else "any (no restriction)")
    )
    lines.append(
        "  denylist:       "
        + (", ".join(policy["denylist"]) if policy["denylist"] else "(empty)")
    )
    lines.append(f"  pinned_provider: {policy['pinned_provider'] or '(none)'}")
    lines.append(f"  pinned_model:    {policy['pinned_model'] or '(none)'}")
    lines.append(f"  strict:          {policy['strict']}")
    lines.append(
        "  sources:        "
        + (", ".join(policy["sources"]) if policy["sources"] else "(defaults)")
    )
    if policy.get("warnings"):
        lines.append("  warnings:")
        for warning in policy["warnings"]:
            lines.append(f"    - {warning}")
    lines.append("")

    selected = report.get("selected")
    if selected:
        lines.append(
            f"Would run: {selected['name']} ({selected['model']})"
        )
    else:
        if policy["strict"]:
            lines.append(
                "Would run: NONE — strict policy is set; run-once will FAIL."
            )
        else:
            lines.append(
                "Would run: NONE — falling back to skeleton plan (no LLM)."
            )
    lines.append("")

    lines.append("Candidates after policy filter (in evaluation order)")
    if not report["candidates"]:
        lines.append("  (none — every provider was filtered out)")
    for c in report["candidates"]:
        flag = "available" if c["available"] else "unavailable"
        lines.append(
            f"  - {c['name']:10s}  {flag:11s}  model={c['model']}  priority={c['priority']}"
        )
    lines.append("")

    lines.append("All known providers")
    for c in report["all_providers"]:
        in_policy = "allowed" if c["in_policy"] else "blocked"
        flag = "available" if c["available"] else "unavailable"
        lines.append(
            f"  - {c['name']:10s}  {in_policy:7s}  {flag:11s}  model={c['model']}"
        )
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Inspect the active LLM policy without invoking any model.",
    )
    parser.add_argument(
        "--job",
        help="Optional path to a .job file; merges its 'llm' overrides on top of the global policy.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON instead of the human report.",
    )
    args = parser.parse_args(argv)

    job_path = Path(args.job).expanduser() if args.job else None
    report = _build_report(job_path=job_path)

    if args.json:
        sys.stdout.write(json.dumps(report, indent=2) + "\n")
    else:
        sys.stdout.write(_format_human(report))

    if not report.get("ok"):
        return 2
    if report["policy"]["strict"] and report.get("selected") is None:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
