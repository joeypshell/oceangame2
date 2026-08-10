#!/usr/bin/env python3
"""Validate the generated Living Expedition 05 visual-evidence set."""

from __future__ import annotations

import json
import struct
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CAPTURE_DIR = ROOT / "visual_captures" / "living_expedition_05"
MANIFEST_PATH = CAPTURE_DIR / "capture_manifest.json"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
EXPECTED_CHECKPOINT = "living_expedition_05_start"
EXPECTED_SUBJECT = "Silt Hound rescue, selection, and deliberate Excavate payoff"
EXPECTED_STATES = (
    "rescue_cutting",
    "pending_boat_return",
    "three_partner_selection",
    "marl_following",
    "excavate_command",
    "excavate_anticipation",
    "excavate_impact",
    "deposit_opened",
    "cargo_full_preserved",
    "titanium_held",
)
EXPECTED_SIZES = {
    "1280x720": (1280, 720),
    "mobile_844x390": (693, 390),
}


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise ValueError("not a readable PNG")
    return struct.unpack(">II", header[16:24])


def fail(message: str) -> int:
    print(f"FAIL: {message}", file=sys.stderr)
    return 1


def main() -> int:
    if not MANIFEST_PATH.is_file():
        return fail(f"missing {MANIFEST_PATH.relative_to(ROOT).as_posix()}")
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return fail(f"could not read capture manifest: {exc}")

    state_ids = tuple(str(state.get("id", "")) for state in manifest.get("states", []))
    if state_ids != EXPECTED_STATES:
        return fail(f"manifest states differ: {state_ids}")
    if manifest.get("review_checkpoint") != EXPECTED_CHECKPOINT:
        return fail("capture did not use the isolated LE05 checkpoint")
    if manifest.get("baseline_accepted") is not False:
        return fail("capture manifest claims baseline acceptance")
    if manifest.get("bounds_verified") is not True:
        return fail("runtime bounds verification was not recorded")
    if manifest.get("subject") != EXPECTED_SUBJECT:
        return fail("manifest does not identify the Silt Hound proof")

    expected_files = {
        f"production_level_01_{state}_{suffix}.png": size
        for state in EXPECTED_STATES
        for suffix, size in EXPECTED_SIZES.items()
    }
    actual_files = {path.name for path in CAPTURE_DIR.glob("*.png") if path.is_file()}
    if actual_files != set(expected_files):
        missing = sorted(set(expected_files) - actual_files)
        extra = sorted(actual_files - set(expected_files))
        return fail(f"capture set differs; missing={missing}, extra={extra}")

    for filename, expected_size in sorted(expected_files.items()):
        path = CAPTURE_DIR / filename
        try:
            actual_size = png_size(path)
        except (OSError, ValueError) as exc:
            return fail(f"{filename}: {exc}")
        if actual_size != expected_size:
            return fail(f"{filename}: expected {expected_size}, found {actual_size}")
        if path.stat().st_size < 4096:
            return fail(f"{filename}: suspiciously small capture")

    tracked = subprocess.run(
        ["git", "ls-files", "--", "visual_captures/living_expedition_05/*.import"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if tracked.returncode != 0:
        return fail(f"could not inspect tracked import sidecars: {tracked.stderr.strip()}")
    sidecars = sorted(line for line in tracked.stdout.splitlines() if line)
    if sidecars:
        return fail(f"tracked generated import sidecars found: {sidecars}")

    print(
        "PASS: Living Expedition 05 captures "
        f"states={len(EXPECTED_STATES)} images={len(expected_files)} "
        "viewports=desktop+landscape_mobile bounds=runtime_verified baseline_accepted=false."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
