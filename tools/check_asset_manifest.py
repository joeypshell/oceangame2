#!/usr/bin/env python3
"""Check that committed asset-manifest entries still exist."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "docs" / "ASSET_MANIFEST.md"
COMMITTED_PREFIXES = ("assets/", "references/asset_reviews/")
REQUIRED_STATUSES = {"draft", "approved", "locked"}
ASSET_CELL_RE = re.compile(r"^`([^`]+)`$")


@dataclass(frozen=True)
class ManifestEntry:
    path: str
    status: str
    line: int


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def parse_manifest(path: Path) -> list[ManifestEntry]:
    entries: list[ManifestEntry] = []
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line.startswith("|") or "`" not in line:
            continue

        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 4:
            continue

        asset_match = ASSET_CELL_RE.fullmatch(cells[0])
        if not asset_match:
            continue

        asset_path = asset_match.group(1).replace("\\", "/").lstrip("./")
        status = cells[3].strip("` ").lower()
        if status not in REQUIRED_STATUSES:
            continue
        if not asset_path.startswith(COMMITTED_PREFIXES):
            continue

        entries.append(ManifestEntry(path=asset_path, status=status, line=line_number))
    return entries


def check_manifest(path: Path) -> int:
    if not path.is_file():
        print(f"Asset manifest not found: {rel(path)}", file=sys.stderr)
        return 1

    entries = parse_manifest(path)
    missing = [entry for entry in entries if not (ROOT / entry.path).is_file()]

    print(f"Asset manifest check: {rel(path)}")
    print(f"Required committed asset entries: {len(entries)}")
    for entry in entries:
        status = "ok" if (ROOT / entry.path).is_file() else "missing"
        print(f"- line {entry.line}: {entry.path} [{entry.status}] {status}")

    if missing:
        print("\nMissing committed assets:", file=sys.stderr)
        for entry in missing:
            print(f"- line {entry.line}: {entry.path} [{entry.status}]", file=sys.stderr)
        return 1

    print("All required manifest assets exist.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help="Manifest markdown file to check. Defaults to docs/ASSET_MANIFEST.md.",
    )
    args = parser.parse_args()
    manifest_path = args.manifest if args.manifest.is_absolute() else ROOT / args.manifest
    return check_manifest(manifest_path)


if __name__ == "__main__":
    raise SystemExit(main())
