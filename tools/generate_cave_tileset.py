#!/usr/bin/env python3
"""Generate the first grid-aligned cave terrain tileset."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


TILE_SIZE = 32
ATLAS_COLUMNS = 8
ATLAS_ROWS = 3

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

SPECIAL_TILES = [
    {"name": "fill_variant", "coord": [0, 2], "kind": "fill_variant"},
    {"name": "inner_top_left", "coord": [1, 2], "kind": "inner_top_left"},
    {"name": "inner_top_right", "coord": [2, 2], "kind": "inner_top_right"},
    {"name": "inner_bottom_left", "coord": [3, 2], "kind": "inner_bottom_left"},
    {"name": "inner_bottom_right", "coord": [4, 2], "kind": "inner_bottom_right"},
]


def draw_base(draw: ImageDraw.ImageDraw, variant: int = 0) -> None:
    draw.rectangle((0, 0, TILE_SIZE, TILE_SIZE), fill=ROCK_DARK)
    offset = variant * 3
    facets = [
        [(2, 5), (14, 2), (22, 8), (13, 13)],
        [(17, 3), (30, 5), (27, 16), (20, 14)],
        [(3, 18), (11, 13), (18, 22), (8, 29)],
        [(17, 19), (29, 16), (30, 30), (21, 28)],
    ]
    for index, points in enumerate(facets):
        moved = [((x + offset + index) % TILE_SIZE, y) for x, y in points]
        color = ROCK_MID if index % 2 == 0 else (30, 60, 74, 255)
        draw.polygon(moved, fill=color)
    draw.line((4, 14, 28, 14), fill=(48, 84, 99, 150), width=1)
    draw.line((7, 24, 24, 22), fill=(17, 33, 43, 170), width=1)


def draw_top_edge(draw: ImageDraw.ImageDraw) -> None:
    points = [(0, 2), (6, 0), (15, 2), (26, 1), (31, 4), (31, 9), (0, 9)]
    draw.polygon(points, fill=SAND)
    draw.line((2, 3, 29, 3), fill=SAND_LIGHT, width=2)
    draw.line((0, 10, 31, 12), fill=ROCK_SHADOW, width=3)


def draw_bottom_edge(draw: ImageDraw.ImageDraw) -> None:
    points = [(0, 23), (31, 22), (31, 31), (0, 31)]
    draw.polygon(points, fill=ROCK_SHADOW)
    draw.line((3, 24, 28, 23), fill=(54, 91, 106, 255), width=2)
    draw.polygon([(6, 24), (11, 31), (15, 24)], fill=(14, 29, 39, 255))
    draw.polygon([(22, 23), (25, 31), (30, 24)], fill=(14, 29, 39, 255))


def draw_left_edge(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(0, 0), (7, 2), (5, 13), (9, 22), (4, 31), (0, 31)], fill=ROCK_SHADOW)
    draw.line((8, 4, 7, 28), fill=ROCK_LIGHT, width=2)


def draw_right_edge(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(31, 0), (24, 3), (26, 14), (22, 23), (27, 31), (31, 31)], fill=ROCK_SHADOW)
    draw.line((23, 4, 24, 28), fill=ROCK_LIGHT, width=2)


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
        draw_top_edge(draw)
    if mask & 2:
        draw_right_edge(draw)
    if mask & 4:
        draw_bottom_edge(draw)
    if mask & 8:
        draw_left_edge(draw)
    return tile


def draw_special(kind: str) -> Image.Image:
    tile = draw_tile(0, 1)
    draw = ImageDraw.Draw(tile)
    if kind != "fill_variant":
        draw_inner_corner(draw, kind)
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

    for special in SPECIAL_TILES:
        x, y = special["coord"]
        atlas.alpha_composite(draw_special(special["kind"]), (x * TILE_SIZE, y * TILE_SIZE))
        tiles.append(special)

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
