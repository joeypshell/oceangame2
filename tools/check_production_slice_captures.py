#!/usr/bin/env python3
"""Check committed production-slice camera capture sets."""

from __future__ import annotations

import argparse
from pathlib import Path

from check_camera_captures import ROOT, check_captures


CAPTURE_CHECKS = {
    "production_slice_01": (
        ROOT / "maps" / "production_slice_01.greybox.json",
        [
            ROOT / "visual_captures" / "production_slice_01",
            ROOT / "visual_captures" / "production_slice_01_debug",
        ],
    ),
    "production_slice_02": (
        ROOT / "maps" / "production_slice_02.greybox.json",
        [
            ROOT / "visual_captures" / "production_slice_02",
            ROOT / "visual_captures" / "production_slice_02_debug",
        ],
    ),
    "production_slice_03": (
        ROOT / "maps" / "production_slice_03.greybox.json",
        [
            ROOT / "visual_captures" / "production_slice_03",
            ROOT / "visual_captures" / "production_slice_03_debug",
        ],
    ),
    "production_slice_04": (
        ROOT / "maps" / "production_slice_04.greybox.json",
        [
            ROOT / "visual_captures" / "production_slice_04",
            ROOT / "visual_captures" / "production_slice_04_debug",
        ],
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--slice",
        choices=sorted(CAPTURE_CHECKS),
        action="append",
        help="Limit the check to one production slice. May be passed more than once.",
    )
    parser.add_argument(
        "--fail-on-stale",
        action="store_true",
        help="Fail if captures are older than their map JSON. Best used locally after regenerating captures.",
    )
    args = parser.parse_args()

    selected = args.slice or sorted(CAPTURE_CHECKS)
    failures = 0
    for slice_id in selected:
        map_path, capture_dirs = CAPTURE_CHECKS[slice_id]
        for capture_dir in capture_dirs:
            if check_captures(Path(map_path), Path(capture_dir), args.fail_on_stale) != 0:
                failures += 1
            print()
    if failures:
        print(f"Production slice capture checks failed: {failures}")
        return 1
    print("All production slice capture checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
