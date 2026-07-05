#!/usr/bin/env python3
"""Accept and compare the production-slice visual baseline."""

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
DEFAULT_CAPTURE_DIR = ROOT / "visual_captures" / "production_slice_01"
DEFAULT_BASELINE_DIR = ROOT / "visual_baselines" / "production_slice_01_accepted"
DEFAULT_REVIEW_PATH = ROOT / "references" / "asset_reviews" / "production_slice_01_visual_baseline_review.png"
VIEW_IDS = [
    "production_slice_overview",
    "production_slice_entry_shaft",
    "production_slice_central_crossing",
    "production_slice_lower_loop",
]
BACKGROUND = (20, 34, 42, 255)
PANEL = (10, 24, 32, 255)
TEXT = (232, 244, 246, 255)
MUTED = (176, 204, 212, 255)


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


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


def existing_capture_paths(directory: Path) -> list[Path]:
    paths: list[Path] = []
    missing: list[str] = []
    for view_id in VIEW_IDS:
        path = directory / f"{view_id}.png"
        if path.is_file():
            paths.append(path)
        else:
            missing.append(rel(path))
    if missing:
        raise FileNotFoundError("Missing required captures: " + ", ".join(missing))
    return paths


def accept_baseline(capture_dir: Path, baseline_dir: Path) -> None:
    capture_paths = existing_capture_paths(capture_dir)
    baseline_dir.mkdir(parents=True, exist_ok=True)
    copied: list[str] = []
    for capture_path in capture_paths:
        output_path = baseline_dir / capture_path.name
        shutil.copy2(capture_path, output_path)
        copied.append(rel(output_path))

    manifest = {
        "baseline_id": baseline_dir.name,
        "accepted_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source_capture_dir": rel(capture_dir),
        "accepted_from_commit": git_commit(),
        "views": copied,
        "notes": [
            "Accepted production_slice_01 visual baseline.",
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


def render_comparison(capture_dir: Path, baseline_dir: Path, output_path: Path) -> None:
    existing_capture_paths(capture_dir)
    existing_capture_paths(baseline_dir)

    thumb_size = (360, 203)
    margin = 18
    header_h = 88
    label_h = 28
    row_gap = 16
    columns = ["Accepted baseline", "Current capture", "Difference"]
    width = margin * 4 + thumb_size[0] * 3
    row_h = label_h + thumb_size[1]
    height = header_h + len(VIEW_IDS) * row_h + (len(VIEW_IDS) - 1) * row_gap + margin

    sheet = Image.new("RGBA", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    title_font = load_font(20)
    label_font = load_font(14)
    small_font = load_font(12)

    draw.text((margin, 16), "Production Slice Visual Baseline Review", fill=TEXT, font=title_font)
    draw.text((margin, 46), f"Baseline: {rel(baseline_dir)}", fill=MUTED, font=small_font)
    draw.text((margin, 64), f"Current: {rel(capture_dir)}", fill=MUTED, font=small_font)

    x_positions = [margin, margin * 2 + thumb_size[0], margin * 3 + thumb_size[0] * 2]
    y = header_h
    for view_id in VIEW_IDS:
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--capture-dir",
        type=Path,
        default=DEFAULT_CAPTURE_DIR,
        help="Current production-slice capture directory.",
    )
    parser.add_argument(
        "--baseline-dir",
        type=Path,
        default=DEFAULT_BASELINE_DIR,
        help="Accepted production-slice baseline directory.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("accept", help="Copy current captures into the accepted baseline directory.")
    compare_parser = subparsers.add_parser("compare", help="Render baseline/current/difference review sheet.")
    compare_parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_REVIEW_PATH,
        help="Output review sheet PNG.",
    )

    args = parser.parse_args()
    capture_dir = args.capture_dir if args.capture_dir.is_absolute() else ROOT / args.capture_dir
    baseline_dir = args.baseline_dir if args.baseline_dir.is_absolute() else ROOT / args.baseline_dir

    if args.command == "accept":
        accept_baseline(capture_dir, baseline_dir)
    elif args.command == "compare":
        output_path = args.output if args.output.is_absolute() else ROOT / args.output
        render_comparison(capture_dir, baseline_dir, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
