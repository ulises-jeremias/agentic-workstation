"""
agentic-workstation Dev Companion runner.

Executes jobs with intelligent LLM-powered plan generation.
Provider-agnostic: automatically selects the best available provider.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

import sys as _sys
from pathlib import Path as _Path

_sys.path.insert(0, str(_Path(__file__).parent))

from llm_dispatcher import create_dispatcher
from policy import LLMPolicy, PolicyError

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger(__name__)

QUEUE_DIR_NAME = ".local/share/agentic-workstation/dev-companion/queue"
TODOS_PATH = "knowledge/todos/pending.md"


def _find_workspace() -> Path | None:
    """Detect if ai-workspace is present and return its root path.

    Checks (in order):
    1. $AI_WORKSPACE environment variable
    2. $DOTS_WORKSTATION_WORKSPACE environment variable
    3. ~/.agentic-workstation-workspace
    4. ~/.ai-workspace
    5. ~/ai-workspace
    """
    home = _Path.home()
    candidates = (
        os.environ.get("AI_WORKSPACE"),
        os.environ.get("DOTS_WORKSTATION_WORKSPACE"),
        str(home / ".ai-workspace"),
        str(home / ".agentic-workstation-workspace"),
        str(home / ".ai-workspace"),
        str(home / "ai-workspace"),
    )
    for candidate in candidates:
        if not candidate:
            continue
        path = _Path(candidate).expanduser()
        if path.is_dir():
            return path
    return None


def _load_workspace_context(workspace: _Path) -> str:
    """Load useful context from the workspace to enrich the LLM prompt.

    Reads (if present):
    - projects.yaml        — indexed projects metadata
    - projects/            — symlinks to cloned repos
    - knowledge/todos/pending.md — pending todos (filtered to devcompanion)
    """
    lines: list[str] = []

    # ── projects.yaml ────────────────────────────────────────────────────────
    yaml_file = workspace / "projects.yaml"
    if yaml_file.is_file():
        lines.append("## Projects (projects.yaml)")
        try:
            content = yaml_file.read_text(encoding="utf-8")
            # Extract project names from yaml (simple key: value at top level)
            for match in re.finditer(
                r"^\s{2}(\w[\w_-]*)\s*[:|-]", content, re.MULTILINE
            ):
                lines.append(f"  - {match.group(1)}")
        except Exception as e:
            logger.debug("Could not read projects.yaml: %s", e)
        lines.append("")

    # ── projects/ symlinks ───────────────────────────────────────────────────
    projects_dir = workspace / "projects"
    if projects_dir.is_dir():
        symlinks = []
        for entry in projects_dir.iterdir():
            if entry.is_symlink():
                target = entry.resolve()
                symlinks.append(f"  - {entry.name} → {target}")
        if symlinks:
            lines.append("## Indexed projects (projects/)")
            lines.extend(symlinks)
            lines.append("")

    # ── knowledge/todos/pending.md ─────────────────────────────────────────
    todos_file = workspace / TODOS_PATH
    if todos_file.is_file():
        lines.append("## Pending todos (from workspace knowledge base)")
        try:
            content = todos_file.read_text(encoding="utf-8")
            for line in content.splitlines():
                if "devcompanion" in line.lower() or "dots-devcompanion" in line.lower():
                    # Strip table formatting, keep summary
                    cells = [c.strip() for c in line.split("|") if c.strip()]
                    if cells and cells[0].startswith("20"):
                        # Date row: show date + last meaningful column
                        relevant = [
                            c
                            for c in cells
                            if c
                            and not c.startswith("202")
                            and c != "devcompanion"
                            and c != "dots-devcompanion"
                        ]
                        lines.append(f"  - [{cells[0]}] {' | '.join(relevant[:3])}")
        except Exception as e:
            logger.debug("Could not read todos: %s", e)
        lines.append("")

    if len(lines) > 2:
        logger.info("Workspace context loaded from %s", workspace)
        return "\n".join(lines)
    return ""


def _workspace_section(workspace: _Path) -> str:
    """Return a workspace context block for the prompt, or empty string."""
    ctx = _load_workspace_context(workspace)
    if not ctx:
        return ""
    return f"\n\n## Workspace Context (~/{WORKSPACE_NAME})\n\n{ctx}"


PROMPT_TEMPLATE = """You are a agentic-workstation Dev Companion agent. Analyze the following task and produce a detailed plan.

## Task
{request}

{repo_context}

## Instructions

1. If a repo_path is provided, perform a brief inspection:
   - Read AGENTS.md (if exists)
   - Check for relevant documentation in docs/
   - Identify the tech stack and conventions

2. Produce a plan in Markdown format with:
   - ## Summary: Brief description of the task
   - ## Steps: Numbered list of concrete actions
   - ## Files to touch: Specific files that would be modified
   - ## Quality checks: How to validate the work
   - ## Estimated complexity: low/medium/high

3. Keep the plan actionable and specific. Avoid generic advice.

## Output Format
Return the plan in Markdown format, ready to be saved as plan.md
"""


@dataclass(frozen=True)
class Job:
    id: str
    created_at: str
    request: str
    repo_path: str | None = None
    llm_enabled: bool = True
    timeout_sec: int = 300
    llm_overrides: dict | None = None


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_job(path: Path) -> Job:
    data = json.loads(path.read_text(encoding="utf-8"))
    for k in ("id", "created_at", "request"):
        if not data.get(k):
            raise ValueError(f"job missing required field: {k}")

    raw_llm = data.get("llm")
    # ``llm`` may be a bool (legacy: enabled flag) or an object with policy
    # overrides. We extract the enabled flag from either shape.
    if isinstance(raw_llm, bool):
        llm_enabled = raw_llm
        llm_overrides = None
    elif isinstance(raw_llm, dict):
        llm_enabled = bool(raw_llm.get("enabled", True))
        llm_overrides = raw_llm
    else:
        llm_enabled = True
        llm_overrides = None

    return Job(
        id=str(data["id"]),
        created_at=str(data["created_at"]),
        request=str(data["request"]),
        repo_path=(str(data["repo_path"]) if data.get("repo_path") else None),
        llm_enabled=llm_enabled,
        timeout_sec=int(data.get("limits", {}).get("timeout_sec", 300)),
        llm_overrides=llm_overrides,
    )


def build_prompt(job: Job) -> str:
    repo_context_parts: list[str] = []

    if job.repo_path:
        repo_context_parts.append(f"- Path: {job.repo_path}")
        repo_context_parts.append(f"- Job ID: {job.id}")
        repo_context_parts.append(f"- Created: {job.created_at}")

    # ── workspace context (opt-in, backward-compatible) ─────────────────────
    workspace = _find_workspace()
    if workspace:
        ws_section = _workspace_section(workspace)
        if ws_section:
            repo_context_parts.append(ws_section)
        else:
            repo_context_parts.append(
                f"- Workspace: ~/{WORKSPACE_NAME} detected (no context files found)"
            )

    repo_context = ""
    if repo_context_parts:
        repo_context = "## Repository Context\n" + "\n".join(repo_context_parts)

    return PROMPT_TEMPLATE.format(
        request=job.request,
        repo_context=repo_context,
    )


def write_skeleton_plan(
    out_dir: Path,
    job: Job,
    *,
    policy: LLMPolicy | None = None,
    notes: str = "Skeleton plan (no LLM provider available)",
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    workspace = _find_workspace()
    ws_info = f"\n- workspace: `~/{WORKSPACE_NAME}`" if workspace else ""
    policy_line = ""
    if policy and policy.sources:
        policy_line = (
            f"\n- llm_policy: allowlist={list(policy.allowlist) if policy.allowlist else 'any'}"
            f" strict={policy.strict} sources={list(policy.sources)}"
        )

    (out_dir / "plan.md").write_text(
        "\n".join(
            [
                "# Plan (skeleton)",
                "",
                f"- job: `{job.id}`",
                f"- created_at: `{job.created_at}`",
                f"- planned_at: `{utc_now_iso()}`",
                f"- repo_path: `{job.repo_path or 'N/A'}`",
                f"{ws_info}{policy_line}",
                "",
                "## Intent",
                job.request.strip(),
                "",
                "## Next",
                "- Load `dots-workstation-assistant` + `skill-catalog.yaml` routing",
                "- Select companion layer and workflow skill",
                "- Produce a tool-execution plan (bounded)",
                "",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    result_data: dict[str, object] = {
        "job_id": job.id,
        "status": "planned_only",
        "planned_at": utc_now_iso(),
        "repo_path": job.repo_path,
        "notes": notes,
    }
    if workspace:
        result_data["workspace"] = str(workspace)
    if policy is not None:
        result_data["llm_policy_applied"] = policy.to_audit()

    (out_dir / "result.json").write_text(
        json.dumps(result_data, indent=2) + "\n",
        encoding="utf-8",
    )


def write_llm_plan(
    out_dir: Path,
    job: Job,
    content: str,
    provider_name: str,
    model: str,
    duration_sec: float | None = None,
    policy: LLMPolicy | None = None,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    policy_header = ""
    if policy is not None and policy.sources:
        policy_header = (
            f"- llm_policy.allowlist: `{list(policy.allowlist) if policy.allowlist else 'any'}`\n"
            f"- llm_policy.strict: `{policy.strict}`\n"
            f"- llm_policy.sources: `{list(policy.sources)}`\n"
        )

    header = f"""# Plan (LLM-generated)

- job: `{job.id}`
- created_at: `{job.created_at}`
- planned_at: `{utc_now_iso()}`
- repo_path: `{job.repo_path or "N/A"}`
- provider: `{provider_name}`
- model: `{model}`
{policy_header}
"""

    if content.strip().startswith("#"):
        plan_content = content
    else:
        plan_content = header + content

    (out_dir / "plan.md").write_text(plan_content, encoding="utf-8")

    result: dict[str, object] = {
        "job_id": job.id,
        "status": "planned_via_llm",
        "planned_at": utc_now_iso(),
        "repo_path": job.repo_path,
        "provider": provider_name,
        "model": model,
        "notes": "LLM-powered plan generation",
    }
    workspace = _find_workspace()
    if workspace:
        result["workspace"] = str(workspace)
    if duration_sec:
        result["duration_sec"] = round(duration_sec, 2)
    if policy is not None:
        result["llm_policy_applied"] = policy.to_audit()

    (out_dir / "result.json").write_text(
        json.dumps(result, indent=2) + "\n",
        encoding="utf-8",
    )


def write_error_plan(
    out_dir: Path,
    job: Job,
    error: str,
    *,
    status: str = "error",
    policy: LLMPolicy | None = None,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    title = "# Plan (error)"
    if status == "policy_violation":
        title = "# Plan (policy violation)"

    (out_dir / "plan.md").write_text(
        f"{title}\n\n"
        f"- job: `{job.id}`\n"
        f"- planned_at: `{utc_now_iso()}`\n\n"
        f"## Error\n\n"
        f"```\n{error}\n```\n\n"
        f"## Intent\n\n"
        f"{job.request.strip()}\n",
        encoding="utf-8",
    )

    payload: dict[str, object] = {
        "job_id": job.id,
        "status": status,
        "planned_at": utc_now_iso(),
        "repo_path": job.repo_path,
        "error": error,
    }
    if policy is not None:
        payload["llm_policy_applied"] = policy.to_audit()

    (out_dir / "result.json").write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )


def _audit_log_path() -> Path:
    base = os.environ.get("DOTS_WORKSTATION_DEV_COMPANION_HOME") or os.path.join(
        os.environ.get("XDG_DATA_HOME", str(_Path.home() / ".local" / "share")),
        "agentic-workstation",
        "dev-companion",
    )
    return Path(base).expanduser() / "logs" / "llm-audit.log"


def append_audit_log(
    job: Job,
    policy: LLMPolicy,
    *,
    status: str,
    provider: str | None,
    model: str | None,
    error: str | None = None,
) -> None:
    """Append a single-line JSON record describing the policy decision. Never
    contains the prompt or model output, so it is safe for client engagements."""
    record = {
        "ts": utc_now_iso(),
        "job_id": job.id,
        "status": status,
        "provider": provider,
        "model": model,
        "policy": policy.to_audit(),
    }
    if error:
        record["error"] = error
    try:
        path = _audit_log_path()
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record) + "\n")
    except Exception as exc:  # pragma: no cover - audit must never break the run
        logger.debug("Could not append audit log: %s", exc)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(
        description="agentic-workstation Dev Companion runner with LLM support"
    )
    p.add_argument("--job", required=True, help="Path to a job JSON file")
    p.add_argument("--out", required=True, help="Artifacts output directory")
    p.add_argument(
        "--no-llm",
        action="store_true",
        help="Force skeleton mode (skip LLM)",
    )
    args = p.parse_args(argv)

    job_path = Path(args.job).expanduser()
    out_dir = Path(args.out).expanduser()

    job = read_job(job_path)
    logger.info(f"Processing job: {job.id}")

    # Resolve effective LLM policy: env -> file -> job (job can only restrict).
    try:
        policy = LLMPolicy.load(job_llm=job.llm_overrides)
    except PolicyError as exc:
        logger.error("Policy violation: %s", exc)
        empty_policy = LLMPolicy.empty()
        write_error_plan(
            out_dir,
            job,
            f"policy_violation: {exc}",
            status="policy_violation",
            policy=empty_policy,
        )
        append_audit_log(
            job,
            empty_policy,
            status="policy_violation",
            provider=None,
            model=None,
            error=str(exc),
        )
        print(
            f"[dots-devcompanion-runner] policy violation: {exc}",
            file=sys.stderr,
        )
        return 2

    for warning in policy.warnings:
        logger.warning("Policy warning: %s", warning)

    if args.no_llm or not job.llm_enabled:
        logger.info("LLM disabled, generating skeleton plan")
        write_skeleton_plan(
            out_dir,
            job,
            policy=policy,
            notes="Skeleton plan (LLM disabled by --no-llm or job.llm.enabled=false)",
        )
        append_audit_log(job, policy, status="skeleton_no_llm", provider=None, model=None)
        print(f"[dots-devcompanion-runner] skeleton artifacts written to {out_dir}")
        return 0

    dispatcher = create_dispatcher(policy=policy)
    provider_info = dispatcher.list_providers()
    logger.debug(f"Available providers: {provider_info}")

    provider = dispatcher.get_available_provider()

    if not provider:
        if policy.strict:
            error_msg = (
                "no LLM provider permitted by policy is available "
                f"(allowlist={list(policy.allowlist) if policy.allowlist else 'any'},"
                f" pinned={policy.pinned_provider}, denylist={list(policy.denylist)})"
            )
            logger.error("Strict policy: %s", error_msg)
            write_error_plan(
                out_dir,
                job,
                error_msg,
                status="policy_violation",
                policy=policy,
            )
            append_audit_log(
                job,
                policy,
                status="policy_violation",
                provider=None,
                model=None,
                error=error_msg,
            )
            print(
                f"[dots-devcompanion-runner] strict policy: {error_msg}",
                file=sys.stderr,
            )
            return 2

        logger.warning("No LLM provider available, falling back to skeleton")
        write_skeleton_plan(out_dir, job, policy=policy)
        append_audit_log(
            job, policy, status="skeleton_no_provider", provider=None, model=None
        )
        print(f"[dots-devcompanion-runner] skeleton artifacts written to {out_dir}")
        print(
            "[dots-devcompanion-runner] Install opencode or configure API keys for LLM plans"
        )
        return 0

    logger.info(f"Using provider: {provider.name} ({provider.get_model_name()})")

    prompt = build_prompt(job)
    repo_path = Path(job.repo_path) if job.repo_path else None

    try:
        response, error = dispatcher.generate(
            prompt=prompt,
            repo_path=repo_path,
            timeout_sec=job.timeout_sec,
        )

        if error:
            logger.error(f"LLM generation failed: {error}")
            write_error_plan(out_dir, job, error, policy=policy)
            append_audit_log(
                job,
                policy,
                status="error",
                provider=provider.name,
                model=provider.get_model_name(),
                error=error,
            )
            print(f"[dots-devcompanion-runner] error artifacts written to {out_dir}")
            return 1

        if response:
            write_llm_plan(
                out_dir=out_dir,
                job=job,
                content=response.content,
                provider_name=provider.name,
                model=provider.get_model_name(),
                duration_sec=response.duration_sec,
                policy=policy,
            )
            append_audit_log(
                job,
                policy,
                status="planned_via_llm",
                provider=provider.name,
                model=provider.get_model_name(),
            )
            print(f"[dots-devcompanion-runner] LLM artifacts written to {out_dir}")
            print(
                f"[dots-devcompanion-runner] provider={provider.name} model={provider.get_model_name()}"
            )
            if response.duration_sec:
                print(
                    f"[dots-devcompanion-runner] duration={response.duration_sec:.1f}s"
                )
            return 0

    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        write_error_plan(out_dir, job, str(e), policy=policy)
        append_audit_log(
            job,
            policy,
            status="error",
            provider=provider.name if provider else None,
            model=provider.get_model_name() if provider else None,
            error=str(e),
        )
        print(f"[dots-devcompanion-runner] error artifacts written to {out_dir}")
        return 1

    write_skeleton_plan(out_dir, job, policy=policy)
    append_audit_log(job, policy, status="skeleton_fallback", provider=None, model=None)
    print(f"[dots-devcompanion-runner] skeleton artifacts written to {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
