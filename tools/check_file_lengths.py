#!/usr/bin/env python3
"""Audit source/docs/config files for agent-friendly length targets."""

from __future__ import annotations

import argparse
import fnmatch
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAX_LINES = 500
TARGET_EXTENSIONS = {
    ".cjs",
    ".cfg",
    ".gd",
    ".js",
    ".json",
    ".md",
    ".py",
    ".yaml",
    ".yml",
}

CATEGORY_GENERATED = "generated/data"
CATEGORY_TEMPORARY_DEBT = "temporary human-authored debt"
CATEGORY_COHESIVE_OWNER = "documented cohesive owner exception"

IGNORED_PREFIXES = (
    ".godot/",
    ".import/",
    "builds/",
    "exports/",
    "tmp/",
    "scratch/",
    "__pycache__/",
)


@dataclass(frozen=True)
class AllowlistEntry:
    pattern: str
    category: str
    reason: str


ALLOWLIST: tuple[AllowlistEntry, ...] = (
    AllowlistEntry(
        "maps/*.greybox.json",
        CATEGORY_GENERATED,
        "generated/source map data; validate with map tooling",
    ),
    AllowlistEntry(
        "scripts/main/main.gd",
        CATEGORY_TEMPORARY_DEBT,
        "known large gameplay shell; follow-up refactor target",
    ),
    AllowlistEntry(
        "scripts/world/greybox_world.gd",
        CATEGORY_COHESIVE_OWNER,
        "cohesive world-state coordinator; split only at stable ownership boundaries",
    ),
    AllowlistEntry(
        "docs/current/PROJECT_CONTEXT.md",
        CATEGORY_TEMPORARY_DEBT,
        "known large session handoff; follow-up split/archive target",
    ),
    AllowlistEntry(
        "docs/current/TOOLING.md",
        CATEGORY_TEMPORARY_DEBT,
        "known large tooling index; follow-up split target",
    ),
)


@dataclass(frozen=True)
class FileLength:
    path: str
    lines: int
    allow_category: str | None = None
    allow_reason: str | None = None


def run_git(args: list[str]) -> list[str]:
    try:
        output = subprocess.check_output(["git", *args], cwd=ROOT, text=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        raise RuntimeError(f"git {' '.join(args)} failed: {exc}") from exc
    return [line for line in output.splitlines() if line]


def line_count(path: Path) -> int | None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None
    if "\0" in text:
        return None
    if not text:
        return 0
    return text.count("\n") + (0 if text.endswith("\n") else 1)


def is_ignored_path(path: str) -> bool:
    normalized = path.replace("\\", "/")
    return any(normalized.startswith(prefix) for prefix in IGNORED_PREFIXES)


def allowlist_entry(path: str) -> AllowlistEntry | None:
    for entry in ALLOWLIST:
        if fnmatch.fnmatchcase(path, entry.pattern):
            return entry
    return None


def candidate_paths() -> list[str]:
    tracked = set(run_git(["ls-files", "--cached"]))
    paths = run_git(["ls-files", "--cached", "--others", "--exclude-standard"])
    candidates: list[str] = []
    for path in paths:
        if is_ignored_path(path):
            continue
        suffix = Path(path).suffix.lower()
        if suffix not in TARGET_EXTENSIONS:
            continue
        if suffix == ".cfg" and path not in tracked:
            continue
        candidates.append(path)
    return sorted(set(candidates))


def find_oversized(
    max_lines: int,
) -> tuple[int, list[FileLength], list[FileLength], list[FileLength], list[FileLength]]:
    checked = 0
    failures: list[FileLength] = []
    temporary_debt: list[FileLength] = []
    cohesive_owners: list[FileLength] = []
    generated_large: list[FileLength] = []

    for path in candidate_paths():
        full_path = ROOT / path
        if not full_path.is_file():
            continue

        lines = line_count(full_path)
        if lines is None:
            continue

        checked += 1
        if lines <= max_lines:
            continue

        allow = allowlist_entry(path)
        entry = FileLength(
            path=path,
            lines=lines,
            allow_category=allow.category if allow else None,
            allow_reason=allow.reason if allow else None,
        )
        if allow and allow.category == CATEGORY_TEMPORARY_DEBT:
            temporary_debt.append(entry)
        elif allow and allow.category == CATEGORY_COHESIVE_OWNER:
            cohesive_owners.append(entry)
        elif allow and allow.category == CATEGORY_GENERATED:
            generated_large.append(entry)
        elif allow:
            failures.append(entry)
        else:
            failures.append(entry)

    failures.sort(key=lambda item: (-item.lines, item.path))
    temporary_debt.sort(key=lambda item: (-item.lines, item.path))
    cohesive_owners.sort(key=lambda item: (-item.lines, item.path))
    generated_large.sort(key=lambda item: (-item.lines, item.path))
    return checked, failures, temporary_debt, cohesive_owners, generated_large


def print_section(title: str, entries: list[FileLength], empty: str) -> None:
    print(title)
    if not entries:
        print(f"- {empty}")
        return
    for entry in entries:
        reason = f" [{entry.allow_reason}]" if entry.allow_reason else ""
        print(f"- {entry.lines} lines: {entry.path}{reason}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--max-lines",
        type=int,
        default=DEFAULT_MAX_LINES,
        help=f"Maximum allowed lines per checked file. Defaults to {DEFAULT_MAX_LINES}.",
    )
    args = parser.parse_args()

    try:
        checked, failures, temporary_debt, cohesive_owners, generated_large = find_oversized(
            args.max_lines
        )
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    print(f"File length audit: max {args.max_lines} lines")
    print(f"Checked text source/docs/config files: {checked}")
    print()
    print_section(
        "Oversized files requiring action:",
        failures,
        "none",
    )
    print()
    print_section(
        "Temporary human-authored allowlist debt:",
        temporary_debt,
        "none",
    )
    print()
    print_section(
        "Documented cohesive-owner exceptions:",
        cohesive_owners,
        "none",
    )
    print()
    print_section(
        "Allowlisted oversized generated/data files:",
        generated_large,
        "none",
    )
    print()

    if failures:
        print(f"FAIL: {len(failures)} non-allowlisted file(s) exceed {args.max_lines} lines.")
        return 1

    print("PASS: no non-allowlisted oversized files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
