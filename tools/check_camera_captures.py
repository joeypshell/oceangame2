#!/usr/bin/env python3
"""Check that a map's authored camera_tests have matching PNG captures."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
UNSAFE_FILENAME_CHARS = [" ", "\\", "/", ":", "*", "?", '"', "<", ">", "|"]


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def resolve_path(path: Path) -> Path:
    return path if path.is_absolute() else ROOT / path


def safe_filename(value: str) -> str:
    output = value.lower()
    for character in UNSAFE_FILENAME_CHARS:
        output = output.replace(character, "_")
    return output


def load_map(path: Path) -> dict:
    if not path.is_file():
        raise FileNotFoundError(f"Map JSON not found: {rel(path)}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Map JSON root must be an object: {rel(path)}")
    return data


def expected_capture_names(
    map_data: dict, camera_id_prefix: str = "", suffixes: tuple[str, ...] = ()
) -> tuple[list[str], list[str]]:
    camera_tests = map_data.get("camera_tests", [])
    if not isinstance(camera_tests, list):
        raise ValueError("camera_tests must be a list")

    names: list[str] = []
    duplicate_names: list[str] = []
    seen: set[str] = set()
    for index, camera_test in enumerate(camera_tests):
        if not isinstance(camera_test, dict):
            raise ValueError(f"camera_tests[{index}] must be an object")
        view_id = safe_filename(str(camera_test.get("id", "camera_test")))
        if camera_id_prefix and not view_id.startswith(safe_filename(camera_id_prefix)):
            continue
        capture_suffixes = suffixes or ("",)
        for suffix in capture_suffixes:
            safe_suffix = safe_filename(suffix)
            name = f"{view_id}_{safe_suffix}.png" if safe_suffix else f"{view_id}.png"
            if name in seen and name not in duplicate_names:
                duplicate_names.append(name)
            seen.add(name)
            names.append(name)
    return names, duplicate_names


def looks_like_png(path: Path) -> bool:
    try:
        with path.open("rb") as handle:
            return handle.read(len(PNG_SIGNATURE)) == PNG_SIGNATURE
    except OSError:
        return False


def check_captures(
    map_path: Path,
    capture_dir: Path,
    fail_on_stale: bool,
    camera_id_prefix: str = "",
    suffixes: tuple[str, ...] = (),
) -> int:
    map_data = load_map(map_path)
    expected_names, duplicate_names = expected_capture_names(
        map_data, camera_id_prefix, suffixes
    )
    if not expected_names:
        raise ValueError(
            f"No camera_tests matched prefix {camera_id_prefix!r}: {rel(map_path)}"
        )
    expected = set(expected_names)

    if not capture_dir.is_dir():
        print(f"Capture directory not found: {rel(capture_dir)}", file=sys.stderr)
        return 1

    actual = {path.name for path in capture_dir.glob("*.png") if path.is_file()}
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    unreadable = sorted(name for name in expected & actual if not looks_like_png(capture_dir / name))

    map_mtime = map_path.stat().st_mtime
    stale = sorted(
        name
        for name in expected & actual
        if (capture_dir / name).stat().st_mtime + 1.0 < map_mtime
    )

    print(f"Camera capture check: {rel(map_path)} -> {rel(capture_dir)}")
    if camera_id_prefix:
        print(f"Camera id prefix: {camera_id_prefix}")
    if suffixes:
        print(f"Capture suffixes: {', '.join(suffixes)}")
    print(f"Expected captures: {len(expected_names)}")
    for name in expected_names:
        status = "ok" if name in actual else "missing"
        print(f"- {name}: {status}")

    failed = False
    if duplicate_names:
        failed = True
        print("\nDuplicate expected capture names:")
        for name in duplicate_names:
            print(f"- {name}")
    if missing:
        failed = True
        print("\nMissing captures:")
        for name in missing:
            print(f"- {name}")
    if extra:
        failed = True
        print("\nExtra PNG captures:")
        for name in extra:
            print(f"- {name}")
    if unreadable:
        failed = True
        print("\nUnreadable or invalid PNG captures:")
        for name in unreadable:
            print(f"- {name}")
    if stale:
        if fail_on_stale:
            failed = True
            print("\nStale-looking captures older than the map JSON:")
        else:
            print("\nStale-looking captures older than the map JSON (warning only):")
        for name in stale:
            print(f"- {name}")

    if failed:
        return 1
    print("Capture set is complete.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path, help="Greybox map JSON containing camera_tests.")
    parser.add_argument("capture_dir", type=Path, help="Directory containing captured PNGs.")
    parser.add_argument(
        "--fail-on-stale",
        action="store_true",
        help="Fail if captures are older than the map JSON. By default stale-looking files are warnings.",
    )
    parser.add_argument(
        "--camera-id-prefix",
        default="",
        help="Check only authored camera ids beginning with this prefix.",
    )
    parser.add_argument(
        "--suffix",
        action="append",
        default=[],
        help="Expected filename suffix before .png; repeat for multiple capture sizes.",
    )
    args = parser.parse_args()

    try:
        return check_captures(
            resolve_path(args.map_json),
            resolve_path(args.capture_dir),
            args.fail_on_stale,
            args.camera_id_prefix,
            tuple(args.suffix),
        )
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
