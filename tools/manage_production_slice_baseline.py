#!/usr/bin/env python3
"""Accept and compare production-slice visual baselines."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = (20, 34, 42, 255)
PANEL = (10, 24, 32, 255)
TEXT = (232, 244, 246, 255)
MUTED = (176, 204, 212, 255)

SLICE_CONFIGS = {
    "production_slice_01": {
        "capture_dir": ROOT / "visual_captures" / "production_slice_01",
        "baseline_dir": ROOT / "visual_baselines" / "production_slice_01_accepted",
        "review_path": ROOT / "references" / "asset_reviews" / "production_slice_01_visual_baseline_review.png",
        # Slice 01 has six current captures, but the accepted baseline currently covers this original four-view set.
        "view_ids": [
            "production_slice_overview",
            "production_slice_entry_shaft",
            "production_slice_central_crossing",
            "production_slice_lower_loop",
        ],
    },
    "production_slice_02": {
        "capture_dir": ROOT / "visual_captures" / "production_slice_02",
        "baseline_dir": ROOT / "visual_baselines" / "production_slice_02_accepted",
        "review_path": ROOT / "references" / "asset_reviews" / "production_slice_02_visual_baseline_review.png",
        "view_ids": [
            "production_slice_02_overview",
            "production_slice_02_relay_entry",
            "production_slice_02_main_chamber",
            "production_slice_02_lower_terminal",
            "production_slice_02_return_route",
        ],
    },
    "production_slice_03": {
        "capture_dir": ROOT / "visual_captures" / "production_slice_03",
        "baseline_dir": ROOT / "visual_baselines" / "production_slice_03_accepted",
        "review_path": ROOT / "references" / "asset_reviews" / "production_slice_03_visual_baseline_review.png",
        "view_ids": [
            "production_slice_03_overview",
            "production_slice_03_relay_entry",
            "production_slice_03_stacked_rooms",
            "production_slice_03_connector",
            "production_slice_03_return_route",
        ],
    },
    "production_slice_04": {
        "capture_dir": ROOT / "visual_captures" / "production_slice_04",
        "baseline_dir": ROOT / "visual_baselines" / "production_slice_04_accepted",
        "review_path": ROOT / "references" / "asset_reviews" / "production_slice_04_visual_baseline_review.png",
        "view_ids": [
            "production_slice_04_overview",
            "production_slice_04_relay_entry",
            "production_slice_04_lower_left_loop",
            "production_slice_04_curved_corridor",
            "production_slice_04_return_route",
        ],
    },
}


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def resolve_path(path: Path) -> Path:
    return path if path.is_absolute() else ROOT / path


def load_font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def git_commit() -> str:
    env_sha = os.environ.get("GITHUB_SHA", "")
    if env_sha:
        return env_sha[:12]

    commands = [
        ["git", "rev-parse", "--short", "HEAD"],
        [r"C:\Program Files\Git\cmd\git.exe", "rev-parse", "--short", "HEAD"],
    ]
    for command in commands:
        try:
            result = subprocess.run(
                command,
                cwd=ROOT,
                check=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            continue
        commit = result.stdout.strip()
        if commit:
            return commit
    return "unknown"


def existing_capture_paths(directory: Path, view_ids: list[str]) -> list[Path]:
    paths: list[Path] = []
    missing: list[str] = []
    for view_id in view_ids:
        path = directory / f"{view_id}.png"
        if path.is_file():
            paths.append(path)
        else:
            missing.append(rel(path))
    if missing:
        raise FileNotFoundError("Missing required captures: " + ", ".join(missing))
    return paths


def accept_baseline(slice_id: str, capture_dir: Path, baseline_dir: Path, view_ids: list[str]) -> None:
    capture_paths = existing_capture_paths(capture_dir, view_ids)
    baseline_dir.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    for capture_path in capture_paths:
        output_path = baseline_dir / capture_path.name
        shutil.copy2(capture_path, output_path)
        copied.append(rel(output_path))

    manifest = {
        "baseline_id": baseline_dir.name,
        "slice_id": slice_id,
        "accepted_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source_capture_dir": rel(capture_dir),
        "accepted_from_commit": git_commit(),
        "view_ids": view_ids,
        "views": copied,
        "notes": [
            f"Accepted {slice_id} visual baseline.",
            "Update this baseline only after the current production slice is intentionally accepted.",
            "For regressions or disputed changes, keep the baseline fixed and create a follow-up issue.",
        ],
    }
    manifest_path = baseline_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Accepted {len(copied)} captures into {rel(baseline_dir)}")


def fit_image(path: Path, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(Image.open(path).convert("RGB"), size, method=Image.Resampling.LANCZOS)


def diff_image(baseline: Image.Image, current: Image.Image) -> Image.Image:
    diff = ImageChops.difference(baseline, current)
    diff = ImageEnhance.Contrast(diff).enhance(3.0)
    return diff


def render_comparison(
    slice_id: str,
    capture_dir: Path,
    baseline_dir: Path,
    output_path: Path,
    view_ids: list[str],
) -> None:
    existing_capture_paths(capture_dir, view_ids)
    existing_capture_paths(baseline_dir, view_ids)

    thumb_size = (360, 203)
    margin = 18
    header_h = 94
    label_h = 28
    row_gap = 16
    columns = ["Accepted baseline", "Current capture", "Difference"]
    width = margin * 4 + thumb_size[0] * 3
    row_h = label_h + thumb_size[1]
    height = header_h + len(view_ids) * row_h + (len(view_ids) - 1) * row_gap + margin

    sheet = Image.new("RGBA", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    title_font = load_font(20)
    label_font = load_font(14)
    small_font = load_font(12)

    draw.text((margin, 16), "Production Slice Visual Baseline Review", fill=TEXT, font=title_font)
    draw.text((margin, 42), f"Slice: {slice_id}", fill=MUTED, font=small_font)
    draw.text((margin, 60), f"Baseline: {rel(baseline_dir)}", fill=MUTED, font=small_font)
    draw.text((margin, 78), f"Current: {rel(capture_dir)}", fill=MUTED, font=small_font)

    x_positions = [margin, margin * 2 + thumb_size[0], margin * 3 + thumb_size[0] * 2]
    y = header_h
    for view_id in view_ids:
        baseline = fit_image(baseline_dir / f"{view_id}.png", thumb_size)
        current = fit_image(capture_dir / f"{view_id}.png", thumb_size)
        diff = diff_image(baseline, current)
        panels = [baseline, current, diff]

        for column, panel, x in zip(columns, panels, x_positions):
            draw.rectangle((x, y, x + thumb_size[0], y + row_h), fill=PANEL)
            draw.text((x + 8, y + 7), f"{view_id} - {column}", fill=TEXT, font=label_font)
            sheet.alpha_composite(panel.convert("RGBA"), (x, y + label_h))
            draw.rectangle((x, y + label_h, x + thumb_size[0] - 1, y + row_h - 1), outline=(126, 158, 168, 190), width=1)

        y += row_h + row_gap

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(output_path)
    print(f"Wrote {rel(output_path)}")


def parse_view_ids(value: str | None, defaults: list[str]) -> list[str]:
    if not value:
        return defaults
    view_ids = [item.strip() for item in value.split(",") if item.strip()]
    if not view_ids:
        raise ValueError("--views must include at least one view id.")
    return view_ids


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--slice",
        choices=sorted(SLICE_CONFIGS),
        default="production_slice_01",
        help="Production slice config to use. Defaults to production_slice_01 for backward compatibility.",
    )
    parser.add_argument("--capture-dir", type=Path, help="Override the current capture directory.")
    parser.add_argument("--baseline-dir", type=Path, help="Override the accepted baseline directory.")
    parser.add_argument(
        "--views",
        help="Comma-separated PNG view ids to compare or accept. Defaults to the configured slice views.",
    )
    parser.add_argument("--list-slices", action="store_true", help="Print configured slices and exit.")
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("accept", help="Copy current captures into the accepted baseline directory.")
    compare_parser = subparsers.add_parser("compare", help="Render baseline/current/difference review sheet.")
    compare_parser.add_argument("--output", type=Path, help="Output review sheet PNG.")

    args = parser.parse_args()
    if args.list_slices:
        for slice_id in sorted(SLICE_CONFIGS):
            print(slice_id)
        return 0
    if args.command is None:
        parser.error("the following arguments are required: command")

    config = SLICE_CONFIGS[args.slice]
    capture_dir = resolve_path(args.capture_dir) if args.capture_dir else config["capture_dir"]
    baseline_dir = resolve_path(args.baseline_dir) if args.baseline_dir else config["baseline_dir"]
    view_ids = parse_view_ids(args.views, list(config["view_ids"]))

    if args.command == "accept":
        accept_baseline(args.slice, capture_dir, baseline_dir, view_ids)
    elif args.command == "compare":
        output_path = resolve_path(args.output) if args.output else config["review_path"]
        render_comparison(args.slice, capture_dir, baseline_dir, output_path, view_ids)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
