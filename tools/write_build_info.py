#!/usr/bin/env python3
"""Write optional runtime build metadata for preview review overlays."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def git_value(args: list[str]) -> str:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return ""
    return completed.stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "build_info.json")
    parser.add_argument("--sha", default=os.environ.get("GITHUB_SHA", ""))
    parser.add_argument("--ref", default=os.environ.get("GITHUB_REF_NAME", ""))
    args = parser.parse_args()

    git_sha = args.sha or git_value(["rev-parse", "HEAD"])
    git_ref = args.ref or git_value(["branch", "--show-current"]) or "detached"
    dirty = bool(git_value(["status", "--short", "--untracked-files=no"]))
    info = {
        "version": git_sha[:7] if git_sha else "local",
        "git_sha": git_sha,
        "git_ref": git_ref,
        "dirty": dirty,
        "generated_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }

    args.output.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {args.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
