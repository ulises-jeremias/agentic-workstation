#!/usr/bin/env python3
"""Build pinned-version release artifacts from chezmoi target state.

Reads scripts/release-artifacts.json and produces archives under dist/.
Requires: chezmoi on PATH or CHEZMOI_BIN, prior chezmoi apply to HOME (CI).

Environment:
  VERSION or GITHUB_REF_NAME — tag (e.g. v0.1.3)
  GITHUB_WORKSPACE or cwd     — repository root
  HOME                        — chezmoi destination (default: actual home)
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path


def dest_relative(path: str) -> str:
    """Strip only a leading './'; never use str.lstrip('./') — it mangles '.local/...'."""
    p = path.strip()
    if p.startswith("./"):
        return p[2:]
    return p


def die(msg: str, code: int = 1) -> None:
    print(f"build-release-artifacts: {msg}", file=sys.stderr)
    raise SystemExit(code)


def main() -> None:
    version = os.environ.get("VERSION") or os.environ.get("GITHUB_REF_NAME") or ""
    if not version:
        die("Set VERSION or GITHUB_REF_NAME (e.g. v0.1.0)")

    repo_root = Path(os.environ.get("GITHUB_WORKSPACE", os.getcwd())).resolve()
    home = Path(os.environ.get("HOME", str(Path.home()))).resolve()

    manifest_path = repo_root / "scripts" / "release-artifacts.json"
    if not manifest_path.is_file():
        die(f"missing manifest: {manifest_path}")

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    source_rel = data.get("chezmoi_source_relpath", "home")
    source = (repo_root / source_rel).resolve()
    if not source.is_dir():
        die(f"chezmoi source not a directory: {source}")

    chezmoi = Path(os.environ.get("CHEZMOI_BIN", home / ".local" / "bin" / "chezmoi"))
    if not chezmoi.is_file():
        die(f"chezmoi not found at {chezmoi} (set CHEZMOI_BIN)")

    dist = repo_root / "dist"
    dist.mkdir(parents=True, exist_ok=True)

    upload_rel: list[str] = []

    for art in data["artifacts"]:
        out_tmpl = art["output"]
        if "{VERSION}" not in out_tmpl:
            die(f"artifact {art.get('id')}: output must contain {{VERSION}}")
        out_abs = (repo_root / out_tmpl.replace("{VERSION}", version)).resolve()
        out_abs.parent.mkdir(parents=True, exist_ok=True)

        engine = art.get("engine")
        if engine == "chezmoi_archive":
            targets: list[str] = art.get("targets") or []
            if not targets:
                die(f"artifact {art.get('id')}: no targets")

            # chezmoi archive/dump expect absolute paths inside the destination dir.
            abs_targets: list[str] = []
            for t in targets:
                rel = t if t.startswith(".") else f"./{t}"
                p = (home / rel).resolve()
                if not p.exists():
                    die(f"artifact {art.get('id')}: target path missing after apply: {t} -> {p}")
                abs_targets.append(str(p))

            fmt = art.get("format", "zip")
            cmd = [
                str(chezmoi),
                "archive",
                "-S",
                str(source),
                "-D",
                str(home),
                f"--output={out_abs}",
                f"--format={fmt}",
                *abs_targets,
            ]
            print("+ " + " ".join(cmd), flush=True)
            subprocess.run(cmd, check=True)
            upload_rel.append(str(out_abs.relative_to(repo_root)))

        elif engine == "tar_gz":
            base_rel = dest_relative(art.get("base_relative") or "")
            members: list[str] = art.get("members") or []
            prefix = art.get("archive_prefix") or "dots-workstation-assets"
            if not base_rel or not members:
                die(f"artifact {art.get('id')}: tar_gz needs base_relative and members")

            base = (home / base_rel).resolve()
            if not base.is_dir():
                die(f"artifact {art.get('id')}: base not a directory: {base}")

            for m in members:
                if not (base / m).exists():
                    die(f"artifact {art.get('id')}: member missing: {base / m}")

            # GNU tar: transform prefix so paths become dots-workstation-assets/skills/...
            xf = f"s,^,{prefix}/,"
            cmd = ["tar", "czf", str(out_abs), f"--transform={xf}", "-C", str(base), *members]
            print("+ " + " ".join(cmd), flush=True)
            subprocess.run(cmd, check=True)
            upload_rel.append(str(out_abs.relative_to(repo_root)))

        elif engine == "zip_materialize":
            # Copy paths under $HOME into a zip preserving their relative layout, but
            # following symlinks (real files). chezmoi_archive stores symlink entries;
            # unzip / .NET ZipFile then fail on symlink-only trees (e.g. skills, .cursor/rules).
            roots_spec = art.get("roots")
            if not isinstance(roots_spec, list) or not roots_spec:
                die(f"artifact {art.get('id')}: zip_materialize needs non-empty roots[]")
            for ent in roots_spec:
                rel_s = str(ent.get("path") or "")
                if not rel_s or ".." in rel_s or rel_s.startswith("/"):
                    die(f"artifact {art.get('id')}: invalid root path {rel_s!r}")
            out_abs.unlink(missing_ok=True)
            with tempfile.TemporaryDirectory() as td:
                tdp = Path(td)
                for ent in roots_spec:
                    rel_path = Path(str(ent["path"]))
                    src = (home / rel_path).resolve()
                    if not src.exists():
                        if ent.get("optional"):
                            continue
                        die(f"artifact {art.get('id')}: missing after apply: {src}")
                    dest = tdp / rel_path
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    if src.is_dir():
                        shutil.copytree(src, dest, symlinks=False, dirs_exist_ok=True)
                    elif src.is_file():
                        shutil.copy2(src, dest)
                    else:
                        die(f"artifact {art.get('id')}: unsupported node type: {src}")
                with zipfile.ZipFile(out_abs, "w", zipfile.ZIP_DEFLATED) as zf:
                    for f in tdp.rglob("*"):
                        if f.is_file():
                            zf.write(f, f.relative_to(tdp).as_posix())
            print(f"+ zip_materialize -> {out_abs}", flush=True)
            upload_rel.append(str(out_abs.relative_to(repo_root)))

        else:
            die(f"artifact {art.get('id')}: unknown engine {engine!r}")

    list_file = dist / ".release-upload-files.txt"
    list_file.write_text("\n".join(upload_rel) + "\n", encoding="utf-8")
    print(f"Wrote {list_file} ({len(upload_rel)} paths)", flush=True)


if __name__ == "__main__":
    main()
