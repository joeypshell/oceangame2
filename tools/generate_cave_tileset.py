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

ROCK_DARK = (19, 43, 56, 255)
ROCK_MID = (31, 62, 76, 255)
ROCK_MID_DARK = (25, 53, 67, 255)
ROCK_LIGHT = (43, 76, 90, 255)
ROCK_SHADOW = (9, 21, 30, 255)
ROCK_CRACK = (14, 31, 41, 255)
SAND = (188, 172, 128, 255)
SAND_LIGHT = (225, 210, 158, 255)
SAND_SHADOW = (153, 137, 99, 255)
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

    if variant % 3 == 0:
        draw.polygon([(0, 18), (8, 16), (17, 23), (31, 21), (31, 31), (0, 31)], fill=ROCK_SHADOW)
    elif variant % 3 == 1:
        draw.polygon([(0, 0), (10, 0), (7, 31), (0, 31)], fill=ROCK_SHADOW)
    else:
        draw.polygon([(20, 0), (31, 0), (31, 31), (25, 31), (22, 17)], fill=ROCK_MID_DARK)

    for index in range(3):
        seed = variant * 41 + index * 29
        cx = 3 + seed % 26
        cy = 3 + (seed * 7) % 26
        w = 10 + seed % 12
        h = 8 + (seed // 3) % 10
        skew = (seed % 7) - 3
        points = [
            (max(1, cx - w // 2), max(1, cy - h // 2)),
            (min(30, cx + w // 2 + skew), max(1, cy - h // 2 + 1)),
            (min(30, cx + w // 2), min(30, cy + h // 2)),
            (max(1, cx - w // 2 - skew), min(30, cy + h // 2 - 1)),
        ]
        color = ROCK_MID if (index + variant) % 3 else ROCK_MID_DARK
        draw.polygon(points, fill=color)

    crack_count = 1 if variant % 3 != 1 else 0
    for index in range(crack_count):
        seed = variant * 29 + index * 17
        x0 = 4 + seed % 22
        y0 = 7 + (seed * 5) % 18
        x1 = min(29, max(2, x0 + (seed % 7) - 3))
        y1 = min(29, max(2, y0 + 3 + seed % 4))
        draw.line((x0, y0, x1, y1), fill=ROCK_CRACK, width=1)

    if variant % 2 == 0:
        draw.line((5, 10 + variant % 8, 14, 11 + variant % 5), fill=ROCK_MID, width=1)


def draw_top_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    profiles = [
        {
            "top": [(0, 4), (5, 2), (11, 3), (18, 1), (25, 2), (31, 4)],
            "bottom": [(31, 8), (23, 9), (16, 7), (8, 9), (0, 8)],
            "highlights": [(3, 4, 8, 3), (17, 4, 25, 3)],
            "chips": [(10, 6, 14, 8), (25, 6, 28, 7)],
        },
        {
            "top": [(0, 5), (4, 3), (10, 1), (17, 3), (24, 2), (31, 5)],
            "bottom": [(31, 9), (26, 8), (19, 10), (11, 8), (4, 9), (0, 8)],
            "highlights": [(2, 5, 7, 4), (13, 4, 18, 4), (23, 4, 28, 5)],
            "chips": [(7, 6, 11, 7), (18, 8, 23, 9)],
        },
        {
            "top": [(0, 3), (7, 1), (13, 3), (20, 2), (27, 1), (31, 3)],
            "bottom": [(31, 7), (28, 9), (21, 8), (13, 10), (5, 8), (0, 9)],
            "highlights": [(4, 3, 10, 3), (19, 4, 26, 3)],
            "chips": [(13, 7, 17, 8), (22, 6, 26, 7)],
        },
    ]
    profile = profiles[variant % len(profiles)]
    points = profile["top"] + profile["bottom"]
    draw.polygon(points, fill=SAND)

    for highlight in profile["highlights"]:
        draw.line(highlight, fill=SAND_LIGHT, width=1)

    for chip in profile["chips"]:
        draw.rectangle(chip, fill=SAND_SHADOW)

    shadow_points = [(0, 9), (7, 11), (15, 10), (24, 11), (31, 10), (31, 13), (0, 13)]
    draw.polygon(shadow_points, fill=ROCK_SHADOW)


def draw_bottom_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    drop = variant % 3
    points = [(0, 23 - drop), (31, 22 + drop), (31, 31), (0, 31)]
    draw.polygon(points, fill=ROCK_SHADOW)
    draw.line((4, 24, 27, 23), fill=ROCK_LIGHT, width=1)
    draw.polygon([(6 + variant, 24), (11 + variant, 31), (15 + variant, 24)], fill=(14, 29, 39, 255))
    draw.polygon([(22 - variant, 23), (25 - variant, 31), (30 - variant, 24)], fill=(14, 29, 39, 255))


def draw_left_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    wiggle = variant % 3
    draw.polygon([(0, 0), (7 + wiggle, 2), (5, 13), (9 + wiggle, 22), (4, 31), (0, 31)], fill=ROCK_SHADOW)
    draw.line((8 + wiggle, 5, 7, 27), fill=ROCK_LIGHT, width=1)


def draw_right_edge(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    wiggle = variant % 3
    draw.polygon([(31, 0), (24 - wiggle, 3), (26, 14), (22 - wiggle, 23), (27, 31), (31, 31)], fill=ROCK_SHADOW)
    draw.line((23 - wiggle, 5, 24, 27), fill=ROCK_LIGHT, width=1)


def draw_inner_corner(draw: ImageDraw.ImageDraw, kind: str) -> None:
    if kind == "inner_top_left":
        draw.pieslice((-12, -12, 20, 20), 0, 90, fill=ROCK_SHADOW)
        draw.line((5, 0, 19, 15), fill=ROCK_LIGHT, width=1)
    elif kind == "inner_top_right":
        draw.pieslice((12, -12, 44, 20), 90, 180, fill=ROCK_SHADOW)
        draw.line((27, 0, 13, 15), fill=ROCK_LIGHT, width=1)
    elif kind == "inner_bottom_left":
        draw.pieslice((-12, 12, 20, 44), 270, 360, fill=ROCK_SHADOW)
        draw.line((5, 31, 19, 17), fill=ROCK_LIGHT, width=1)
    elif kind == "inner_bottom_right":
        draw.pieslice((12, 12, 44, 44), 180, 270, fill=ROCK_SHADOW)
        draw.line((27, 31, 13, 17), fill=ROCK_LIGHT, width=1)


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
