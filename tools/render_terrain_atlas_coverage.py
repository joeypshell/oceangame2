#!/usr/bin/env python3
"""Render a labeled terrain atlas coverage review sheet."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "assets" / "terrain_tiles" / "cave_tileset_v1_manifest.json"
DEFAULT_RENDERER = ROOT / "scripts" / "world" / "greybox_world.gd"
DEFAULT_OUTPUT = ROOT / "references" / "asset_reviews" / "cave_tileset_v1_coverage_review.png"

VECTOR_RE = re.compile(r"Vector2i\((-?\d+),\s*(-?\d+)\)")
ARRAY_CONST_RE = re.compile(r"const\s+([A-Z0-9_]+_COORDS)\s*:=\s*\[(.*?)\]")
SINGLE_CONST_RE = re.compile(r"const\s+([A-Z0-9_]+_COORD)\s*:=\s*Vector2i\((-?\d+),\s*(-?\d+)\)")
INT_CONST_RE = re.compile(r"const\s+([A-Z0-9_]+)\s*:=\s*(\d+)")

MASK_ROLE_NAMES = {
    0: "fill",
    1: "top",
    2: "right",
    3: "top_right_outer",
    4: "bottom",
    5: "top_bottom",
    6: "right_bottom_outer",
    7: "top_right_bottom",
    8: "left",
    9: "left_top_outer",
    10: "left_right",
    11: "left_top_right",
    12: "bottom_left_outer",
    13: "top_bottom_left",
    14: "left_right_bottom",
    15: "isolated",
}

SPECIAL_ROLE_LABELS = {
    "FILL_COORDS": "renderer fill variants",
    "TOP_COORDS": "renderer top variants",
    "RIGHT_COORDS": "renderer right variants",
    "BOTTOM_COORDS": "renderer bottom variants",
    "LEFT_COORDS": "renderer left variants",
    "TOP_RIGHT_OUTER_COORDS": "renderer top-right outer variants",
    "LEFT_TOP_OUTER_COORDS": "renderer left-top outer variants",
    "RIGHT_BOTTOM_OUTER_COORDS": "renderer right-bottom outer variants",
    "BOTTOM_LEFT_OUTER_COORDS": "renderer bottom-left outer variants",
    "ISOLATED_COORDS": "renderer isolated variants",
    "INNER_TOP_LEFT_COORD": "renderer inner top-left",
    "INNER_TOP_RIGHT_COORD": "renderer inner top-right",
    "INNER_BOTTOM_LEFT_COORD": "renderer inner bottom-left",
    "INNER_BOTTOM_RIGHT_COORD": "renderer inner bottom-right",
}

FALLBACK_MASKS = (5, 7, 10, 11, 13, 14)

BG = (17, 28, 36, 255)
PANEL = (26, 46, 58, 255)
PANEL_ALT = (33, 58, 72, 255)
TEXT = (232, 244, 246, 255)
MUTED = (159, 187, 194, 255)
ACCENT = (255, 202, 76, 255)
WATER = (24, 179, 220, 255)
ERROR = (255, 80, 96, 255)
GRID = (76, 114, 126, 255)


@dataclass
class TileEntry:
    coord: tuple[int, int]
    names: list[str] = field(default_factory=list)
    masks: set[int] = field(default_factory=set)
    inner_roles: set[str] = field(default_factory=set)
    open_sides: dict[str, bool] | None = None


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"Manifest not found: {rel(path)}")
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Manifest is not valid JSON: {rel(path)}: {exc}") from exc


def font(size: int) -> ImageFont.ImageFont:
    for name in ("arial.ttf", "segoeui.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def parse_manifest(path: Path) -> tuple[dict[tuple[int, int], TileEntry], int, Path]:
    manifest = read_json(path)
    tile_size = int(manifest.get("tile_size_px", 32))
    atlas_path = ROOT / str(manifest.get("atlas", "")).replace("/", "\\")
    entries: dict[tuple[int, int], TileEntry] = {}

    for tile in manifest.get("tiles", []):
        coord_value = tile.get("coord")
        if not isinstance(coord_value, list) or len(coord_value) != 2:
            raise SystemExit(f"Manifest tile is missing a valid coord: {tile}")
        coord = (int(coord_value[0]), int(coord_value[1]))
        entry = entries.setdefault(coord, TileEntry(coord=coord))
        entry.names.append(str(tile.get("name", "unnamed_tile")))
        if "mask" in tile:
            entry.masks.add(int(tile["mask"]))
        if "inner" in tile:
            entry.inner_roles.add(str(tile["inner"]))
        if isinstance(tile.get("open_sides"), dict):
            entry.open_sides = {key: bool(value) for key, value in tile["open_sides"].items()}

    return entries, tile_size, atlas_path


def parse_renderer(path: Path) -> tuple[dict[tuple[int, int], list[str]], int]:
    try:
        source = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise SystemExit(f"Renderer script not found: {rel(path)}")

    int_consts = {name: int(value) for name, value in INT_CONST_RE.findall(source)}
    columns = int_consts.get("CAVE_TILESET_COLUMNS", 8)

    roles: dict[tuple[int, int], list[str]] = {}

    for name, body in ARRAY_CONST_RE.findall(source):
        label = SPECIAL_ROLE_LABELS.get(name, name.lower())
        for x, y in VECTOR_RE.findall(body):
            roles.setdefault((int(x), int(y)), []).append(label)

    for name, x, y in SINGLE_CONST_RE.findall(source):
        if name == "NO_SPECIAL_COORD":
            continue
        label = SPECIAL_ROLE_LABELS.get(name, name.lower())
        roles.setdefault((int(x), int(y)), []).append(label)

    for mask in FALLBACK_MASKS:
        coord = (mask % columns, mask // columns)
        roles.setdefault(coord, []).append(f"renderer fallback mask {mask}: {MASK_ROLE_NAMES[mask]}")

    return roles, columns


def side_label(open_sides: dict[str, bool] | None, masks: set[int]) -> str:
    if not open_sides and masks:
        mask = sorted(masks)[0]
        open_sides = {
            "top": bool(mask & 1),
            "right": bool(mask & 2),
            "bottom": bool(mask & 4),
            "left": bool(mask & 8),
        }
    if not open_sides:
        return "open sides: n/a"
    order = [("top", "T"), ("right", "R"), ("bottom", "B"), ("left", "L")]
    values = [label for key, label in order if open_sides.get(key, False)]
    return "open sides: " + (" ".join(values) if values else "none")


def draw_mask_glyph(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], masks: set[int]) -> None:
    x0, y0, x1, y1 = box
    draw.rectangle(box, fill=(38, 71, 86, 255), outline=GRID)
    cx = (x0 + x1) // 2
    cy = (y0 + y1) // 2
    draw.rectangle((cx - 7, cy - 7, cx + 7, cy + 7), fill=(82, 112, 118, 255))
    if not masks:
        return
    mask = sorted(masks)[0]
    if mask & 1:
        draw.rectangle((cx - 7, y0 + 3, cx + 7, cy - 8), fill=WATER)
    if mask & 2:
        draw.rectangle((cx + 8, cy - 7, x1 - 3, cy + 7), fill=WATER)
    if mask & 4:
        draw.rectangle((cx - 7, cy + 8, cx + 7, y1 - 3), fill=WATER)
    if mask & 8:
        draw.rectangle((x0 + 3, cy - 7, cx - 8, cy + 7), fill=WATER)


def render_sheet(
    manifest_entries: dict[tuple[int, int], TileEntry],
    renderer_roles: dict[tuple[int, int], list[str]],
    tile_size: int,
    atlas_path: Path,
    output_path: Path,
) -> None:
    if not atlas_path.is_file():
        raise SystemExit(f"Atlas image not found: {rel(atlas_path)}")
    atlas = Image.open(atlas_path).convert("RGBA")

    coords = sorted(set(manifest_entries) | set(renderer_roles), key=lambda item: (item[1], item[0]))
    columns = 3
    card_w = 390
    card_h = 150
    margin = 24
    header_h = 126
    gap = 14
    rows = (len(coords) + columns - 1) // columns
    width = margin * 2 + columns * card_w + (columns - 1) * gap
    height = header_h + margin + rows * card_h + max(0, rows - 1) * gap

    image = Image.new("RGBA", (width, height), BG)
    draw = ImageDraw.Draw(image)
    title_font = font(24)
    body_font = font(13)
    small_font = font(11)
    tiny_font = font(10)

    missing = sorted(set(renderer_roles) - set(manifest_entries), key=lambda item: (item[1], item[0]))
    unused = sorted(set(manifest_entries) - set(renderer_roles), key=lambda item: (item[1], item[0]))

    draw.text((margin, 20), "Terrain Atlas Coverage Review", fill=TEXT, font=title_font)
    draw.text((margin, 54), f"Atlas: {rel(atlas_path)}", fill=MUTED, font=body_font)
    draw.text((margin, 74), f"Tiles: {len(manifest_entries)} manifest coords, {len(renderer_roles)} renderer-used coords", fill=MUTED, font=body_font)
    status = "coverage ok" if not missing else f"missing renderer coords: {len(missing)}"
    draw.text((margin, 96), status, fill=ACCENT if not missing else ERROR, font=body_font)

    if unused:
        draw.text((margin + 260, 96), f"manifest-only comparison coords: {len(unused)}", fill=MUTED, font=body_font)

    scale = 2
    preview_size = tile_size * scale

    for index, coord in enumerate(coords):
        col = index % columns
        row = index // columns
        x = margin + col * (card_w + gap)
        y = header_h + row * (card_h + gap)
        panel_color = PANEL if index % 2 == 0 else PANEL_ALT
        draw.rectangle((x, y, x + card_w, y + card_h), fill=panel_color, outline=GRID)

        entry = manifest_entries.get(coord)
        roles = renderer_roles.get(coord, [])
        sx, sy = coord
        source_box = (sx * tile_size, sy * tile_size, (sx + 1) * tile_size, (sy + 1) * tile_size)
        if entry and source_box[2] <= atlas.width and source_box[3] <= atlas.height:
            tile = atlas.crop(source_box).resize((preview_size, preview_size), Image.Resampling.NEAREST)
            image.alpha_composite(tile, (x + 12, y + 12))
        else:
            draw.rectangle((x + 12, y + 12, x + 12 + preview_size, y + 12 + preview_size), fill=(62, 31, 40, 255), outline=ERROR)
            draw.text((x + 20, y + 35), "missing", fill=ERROR, font=small_font)

        names = ", ".join(entry.names if entry else ["missing manifest entry"])
        masks = sorted(entry.masks) if entry else []
        mask_text = "masks: " + (", ".join(str(mask) for mask in masks) if masks else "none")
        inner_text = "inner: " + (", ".join(sorted(entry.inner_roles)) if entry and entry.inner_roles else "none")
        role_text = "; ".join(roles) if roles else "manifest-only / comparison"
        text_x = x + 92
        draw.text((text_x, y + 12), f"coord ({coord[0]},{coord[1]})", fill=TEXT, font=body_font)
        draw.text((text_x, y + 32), names[:48], fill=ACCENT if roles else MUTED, font=small_font)
        draw.text((text_x, y + 50), mask_text, fill=MUTED, font=small_font)
        draw.text((text_x, y + 67), inner_text, fill=MUTED, font=small_font)
        draw.text((text_x, y + 84), side_label(entry.open_sides if entry else None, set(masks)), fill=MUTED, font=small_font)

        role_lines = [role_text[i:i + 52] for i in range(0, len(role_text), 52)] or [""]
        for line_index, line in enumerate(role_lines[:2]):
            draw.text((text_x, y + 105 + line_index * 14), line, fill=TEXT if roles else MUTED, font=tiny_font)

        draw_mask_glyph(draw, (x + 16, y + 88, x + 70, y + 138), set(masks))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


def validate_coverage(
    manifest_entries: dict[tuple[int, int], TileEntry],
    renderer_roles: dict[tuple[int, int], list[str]],
) -> list[str]:
    errors: list[str] = []
    for coord in sorted(set(renderer_roles) - set(manifest_entries), key=lambda item: (item[1], item[0])):
        errors.append(f"renderer coord {coord} is missing from the terrain manifest")
    for coord, entry in sorted(manifest_entries.items(), key=lambda item: (item[0][1], item[0][0])):
        if not entry.names:
            errors.append(f"manifest coord {coord} has no tile name")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--renderer", type=Path, default=DEFAULT_RENDERER)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    manifest_path = args.manifest if args.manifest.is_absolute() else ROOT / args.manifest
    renderer_path = args.renderer if args.renderer.is_absolute() else ROOT / args.renderer
    output_path = args.output if args.output.is_absolute() else ROOT / args.output

    manifest_entries, tile_size, atlas_path = parse_manifest(manifest_path)
    renderer_roles, _columns = parse_renderer(renderer_path)
    errors = validate_coverage(manifest_entries, renderer_roles)
    render_sheet(manifest_entries, renderer_roles, tile_size, atlas_path, output_path)

    print(f"Wrote {rel(output_path)}")
    print(f"Validated {len(renderer_roles)} renderer-used coordinates against {rel(manifest_path)}")
    if errors:
        print("Coverage errors:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
