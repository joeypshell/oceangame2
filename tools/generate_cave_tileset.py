#!/usr/bin/env python3
"""Generate the first grid-aligned cave terrain tileset."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


TILE_SIZE = 32
ATLAS_COLUMNS = 8
ATLAS_ROWS = 5

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "terrain_tiles"
REVIEW_DIR = ROOT / "references" / "asset_reviews"

ATLAS_PATH = ASSET_DIR / "cave_tileset_v1.png"
MANIFEST_PATH = ASSET_DIR / "cave_tileset_v1_manifest.json"
REVIEW_PATH = REVIEW_DIR / "cave_tileset_v1_review.png"

ROCK_DARK = (22, 45, 58, 255)
ROCK_MID = (36, 70, 86, 255)
ROCK_LIGHT = (66, 108, 121, 255)
ROCK_SHADOW = (10, 22, 30, 255)
SAND = (215, 194, 145, 255)
SAND_LIGHT = (244, 226, 169, 255)
WATER_REVIEW = (24, 179, 220, 255)
LABEL = (232, 244, 246, 255)

MASK_NAMES = {
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

EXTRA_TILES = [
    {"name": "fill_variant_a", "coord": [0, 2], "mask": 0, "variant": 1},
    {"name": "inner_top_left", "coord": [1, 2], "mask": 0, "variant": 1, "inner": "inner_top_left"},
    {"name": "inner_top_right", "coord": [2, 2], "mask": 0, "variant": 1, "inner": "inner_top_right"},
    {"name": "inner_bottom_left", "coord": [3, 2], "mask": 0, "variant": 1, "inner": "inner_bottom_left"},
    {"name": "inner_bottom_right", "coord": [4, 2], "mask": 0, "variant": 1, "inner": "inner_bottom_right"},
    {"name": "fill_variant_b", "coord": [5, 2], "mask": 0, "variant": 2},
    {"name": "fill_variant_c", "coord": [6, 2], "mask": 0, "variant": 3},
    {"name": "fill_variant_d", "coord": [7, 2], "mask": 0, "variant": 4},
    {"name": "top_variant_a", "coord": [0, 3], "mask": 1, "variant": 1},
    {"name": "top_variant_b", "coord": [1, 3], "mask": 1, "variant": 2},
    {"name": "bottom_variant_a", "coord": [2, 3], "mask": 4, "variant": 1},
    {"name": "bottom_variant_b", "coord": [3, 3], "mask": 4, "variant": 2},
    {"name": "left_variant_a", "coord": [4, 3], "mask": 8, "variant": 1},
    {"name": "left_variant_b", "coord": [5, 3], "mask": 8, "variant": 2},
    {"name": "right_variant_a", "coord": [6, 3], "mask": 2, "variant": 1},
    {"name": "right_variant_b", "coord": [7, 3], "mask": 2, "variant": 2},
    {"name": "top_right_outer_variant", "coord": [0, 4], "mask": 3, "variant": 1},
    {"name": "left_top_outer_variant", "coord": [1, 4], "mask": 9, "variant": 1},
    {"name": "right_bottom_outer_variant", "coord": [2, 4], "mask": 6, "variant": 1},
    {"name": "bottom_left_outer_variant", "coord": [3, 4], "mask": 12, "variant": 1},
    {"name": "isolated_variant_a", "coord": [4, 4], "mask": 15, "variant": 1},
    {"name": "isolated_variant_b", "coord": [5, 4], "mask": 15, "variant": 2},
]


def draw_base(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    draw.rectangle((0, 0, TILE_SIZE, TILE_SIZE), fill=ROCK_DARK)
    for index in range(7):
        seed = variant * 37 + index * 19
        cx = 4 + seed % 24
        cy = 4 + (seed * 7) % 24
        w = 5 + seed % 8
        h = 4 + (seed // 3) % 7
        skew = (seed % 5) - 2
        points = [
            (max(1, cx - w // 2), max(1, cy - h // 2)),
            (min(30, cx + w // 2 + skew), max(1, cy - h // 2 + 1)),
            (min(30, cx + w // 2), min(30, cy + h // 2)),
            (max(1, cx - w // 2 - skew), min(30, cy + h // 2 - 1)),
        ]
        color = ROCK_MID if (index + variant) % 3 else (30, 60, 74, 255)
        draw.polygon(points, fill=color)

    crack_count = 2 + variant % 3
    for index in range(crack_count):
        seed = variant * 23 + index * 13
        x0 = 4 + seed % 22
        y0 = 7 + (seed * 5) % 18
        x1 = min(29, max(2, x0 + (seed % 9) - 4))
        y1 = min(29, max(2, y0 + 4 + seed % 5))
        draw.line((x0, y0, x1, y1), fill=(17, 33, 43, 150), width=1)

    if variant % 2 == 0:
        draw.line((3, 10 + variant % 8, 16, 12 + variant % 5), fill=(48, 84, 99, 120), width=1)
    else:
        draw.line((14, 22 - variant % 7, 29, 18 + variant % 5), fill=(48, 84, 99, 120), width=1)


def draw_top_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    lift = variant % 3
    points = [(0, 2 + lift), (6, 0), (15, 2 + lift), (26, 1), (31, 4), (31, 9), (0, 9)]
    draw.polygon(points, fill=SAND)
    draw.line((2, 3, 29, 3), fill=SAND_LIGHT, width=2)
    draw.line((0, 10, 31, 12), fill=ROCK_SHADOW, width=3)
    if variant:
        draw.rectangle((7 + variant * 3, 5, 10 + variant * 3, 7), fill=(187, 165, 118, 255))


def draw_bottom_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    drop = variant % 3
    points = [(0, 23 - drop), (31, 22 + drop), (31, 31), (0, 31)]
    draw.polygon(points, fill=ROCK_SHADOW)
    draw.line((3, 24, 28, 23), fill=(54, 91, 106, 255), width=2)
    draw.polygon([(6 + variant, 24), (11 + variant, 31), (15 + variant, 24)], fill=(14, 29, 39, 255))
    draw.polygon([(22 - variant, 23), (25 - variant, 31), (30 - variant, 24)], fill=(14, 29, 39, 255))


def draw_left_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    wiggle = variant % 3
    draw.polygon([(0, 0), (7 + wiggle, 2), (5, 13), (9 + wiggle, 22), (4, 31), (0, 31)], fill=ROCK_SHADOW)
    draw.line((8 + wiggle, 4, 7, 28), fill=ROCK_LIGHT, width=2)


def draw_right_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    wiggle = variant % 3
    draw.polygon([(31, 0), (24 - wiggle, 3), (26, 14), (22 - wiggle, 23), (27, 31), (31, 31)], fill=ROCK_SHADOW)
    draw.line((23 - wiggle, 4, 24, 28), fill=ROCK_LIGHT, width=2)


def draw_inner_corner(draw: ImageDraw.ImageDraw, kind: str) -> None:
    if kind == "inner_top_left":
        draw.pieslice((-12, -12, 20, 20), 0, 90, fill=ROCK_SHADOW)
        draw.line((5, 0, 19, 15), fill=ROCK_LIGHT, width=2)
    elif kind == "inner_top_right":
        draw.pieslice((12, -12, 44, 20), 90, 180, fill=ROCK_SHADOW)
        draw.line((27, 0, 13, 15), fill=ROCK_LIGHT, width=2)
    elif kind == "inner_bottom_left":
        draw.pieslice((-12, 12, 20, 44), 270, 360, fill=ROCK_SHADOW)
        draw.line((5, 31, 19, 17), fill=ROCK_LIGHT, width=2)
    elif kind == "inner_bottom_right":
        draw.pieslice((12, 12, 44, 44), 180, 270, fill=ROCK_SHADOW)
        draw.line((27, 31, 13, 17), fill=ROCK_LIGHT, width=2)


def draw_tile(mask: int, variant: int = 0) -> Image.Image:
    tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    draw_base(draw, variant)
    if mask & 1:
        draw_top_edge(draw, variant)
    if mask & 2:
        draw_right_edge(draw, variant)
    if mask & 4:
        draw_bottom_edge(draw, variant)
    if mask & 8:
        draw_left_edge(draw, variant)
    return tile


def draw_extra_tile(item: dict) -> Image.Image:
    tile = draw_tile(int(item["mask"]), int(item.get("variant", 0)))
    draw = ImageDraw.Draw(tile)
    inner = item.get("inner")
    if inner:
        draw_inner_corner(draw, inner)
    return tile


def tile_coord(mask: int) -> tuple[int, int]:
    return mask % ATLAS_COLUMNS, mask // ATLAS_COLUMNS


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    atlas = Image.new("RGBA", (ATLAS_COLUMNS * TILE_SIZE, ATLAS_ROWS * TILE_SIZE), (0, 0, 0, 0))
    tiles: list[dict] = []

    for mask in range(16):
        x, y = tile_coord(mask)
        atlas.alpha_composite(draw_tile(mask), (x * TILE_SIZE, y * TILE_SIZE))
        tiles.append({
            "name": MASK_NAMES[mask],
            "mask": mask,
            "coord": [x, y],
            "open_sides": {
                "top": bool(mask & 1),
                "right": bool(mask & 2),
                "bottom": bool(mask & 4),
                "left": bool(mask & 8),
            },
        })

    for extra in EXTRA_TILES:
        x, y = extra["coord"]
        atlas.alpha_composite(draw_extra_tile(extra), (x * TILE_SIZE, y * TILE_SIZE))
        tiles.append(extra)

    atlas.save(ATLAS_PATH)
    MANIFEST_PATH.write_text(
        json.dumps({
            "id": "cave_tileset_v1",
            "tile_size_px": TILE_SIZE,
            "atlas": ATLAS_PATH.relative_to(ROOT).as_posix(),
            "tiles": tiles,
        }, indent=2) + "\n",
        encoding="utf-8",
    )

    review_scale = 3
    label_h = 30
    review = Image.new(
        "RGBA",
        (ATLAS_COLUMNS * TILE_SIZE * review_scale, ATLAS_ROWS * (TILE_SIZE * review_scale + label_h)),
        WATER_REVIEW,
    )
    draw = ImageDraw.Draw(review)
    try:
        font = ImageFont.truetype("arial.ttf", 10)
    except OSError:
        font = ImageFont.load_default()

    for tile in tiles:
        x, y = tile["coord"]
        tile_img = atlas.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
        tile_img = tile_img.resize((TILE_SIZE * review_scale, TILE_SIZE * review_scale), Image.Resampling.NEAREST)
        px = x * TILE_SIZE * review_scale
        py = y * (TILE_SIZE * review_scale + label_h)
        review.alpha_composite(tile_img, (px, py))
        label = tile["name"].replace("_", "\n")
        draw.text((px + 3, py + TILE_SIZE * review_scale + 2), label, fill=LABEL, font=font)

    review.save(REVIEW_PATH)
    print(f"Wrote {ATLAS_PATH.relative_to(ROOT)}")
    print(f"Wrote {MANIFEST_PATH.relative_to(ROOT)}")
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
