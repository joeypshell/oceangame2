#!/usr/bin/env python3
"""Generate the controlled v2 cave terrain tileset."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from generate_cave_tileset import ATLAS_COLUMNS, ATLAS_ROWS, EXTRA_TILES, MASK_NAMES, TILE_SIZE


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "terrain_tiles"
REVIEW_DIR = ROOT / "references" / "asset_reviews"

ATLAS_PATH = ASSET_DIR / "cave_tileset_v2.png"
MANIFEST_PATH = ASSET_DIR / "cave_tileset_v2_manifest.json"
REVIEW_PATH = REVIEW_DIR / "cave_tileset_v2_review.png"

ROCK_DEEP = (14, 34, 45, 255)
ROCK_DARK = (22, 48, 61, 255)
ROCK_MID = (33, 66, 78, 255)
ROCK_BLUE = (38, 79, 94, 255)
ROCK_LIGHT = (70, 105, 113, 255)
CREVICE = (6, 18, 26, 255)
RIM = (191, 174, 131, 255)
RIM_LIGHT = (234, 216, 159, 255)
RIM_DARK = (116, 105, 79, 255)
WATER_REVIEW = (24, 179, 220, 255)
LABEL = (232, 244, 246, 255)


def seeded(value: int, salt: int) -> int:
    return (value * 1103515245 + salt * 12345 + 67891) & 0x7FFFFFFF


def polygon(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: tuple[int, int, int, int]) -> None:
    draw.polygon([(max(-4, min(TILE_SIZE + 4, x)), max(-4, min(TILE_SIZE + 4, y))) for x, y in points], fill=fill)


def draw_base(draw: ImageDraw.ImageDraw, variant: int) -> None:
    draw.rectangle((0, 0, TILE_SIZE, TILE_SIZE), fill=ROCK_DARK)

    shade = seeded(variant, 3)
    if shade % 3 == 0:
        polygon(draw, [(-2, 0), (9, 0), (13, 32), (-2, 34)], ROCK_DEEP)
    elif shade % 3 == 1:
        polygon(draw, [(19, -2), (34, -2), (34, 34), (25, 34), (22, 18)], ROCK_DEEP)
    else:
        polygon(draw, [(-2, 20), (8, 17), (18, 23), (34, 20), (34, 34), (-2, 34)], ROCK_DEEP)

    for index in range(4):
        seed = seeded(variant + index * 7, 11)
        cx = 3 + seed % 26
        cy = 2 + (seed // 5) % 27
        w = 9 + (seed // 19) % 15
        h = 7 + (seed // 37) % 15
        lean = (seed // 53) % 9 - 4
        color = [ROCK_MID, ROCK_BLUE, ROCK_DARK, ROCK_DEEP][(seed // 97) % 4]
        points = [
            (cx - w // 2, cy - h // 2),
            (cx + w // 2 + lean, cy - h // 2 + 1),
            (cx + w // 2, cy + h // 2),
            (cx - w // 2 - lean, cy + h // 2 - 1),
        ]
        polygon(draw, points, color)

    for index in range(2):
        seed = seeded(variant + index * 13, 23)
        x0 = 3 + seed % 24
        y0 = 4 + (seed // 11) % 22
        x1 = max(2, min(29, x0 + (seed // 17) % 11 - 5))
        y1 = max(2, min(29, y0 + 5 + (seed // 31) % 8))
        draw.line((x0, y0, x1, y1), fill=CREVICE, width=1)

    if variant % 2 == 0:
        draw.line((4, 8 + variant % 9, 20, 7 + variant % 7), fill=(49, 85, 96, 180), width=1)
    else:
        draw.line((14, 4, 25, 11), fill=(49, 85, 96, 160), width=1)


def draw_top_edge(draw: ImageDraw.ImageDraw, variant: int) -> None:
    profiles = [
        [(0, 5), (5, 2), (13, 3), (19, 1), (27, 3), (31, 5)],
        [(0, 4), (7, 3), (12, 1), (20, 3), (26, 2), (31, 4)],
        [(0, 6), (4, 3), (11, 2), (17, 4), (24, 2), (31, 5)],
    ]
    top = profiles[variant % len(profiles)]
    lower = [(31, 9), (23, 10), (16, 8), (8, 10), (0, 9)]
    draw.polygon(top + lower, fill=RIM)
    draw.line((2, 5, 10, 3), fill=RIM_LIGHT, width=1)
    draw.line((17, 4, 28, 4), fill=RIM_LIGHT, width=1)
    draw.polygon([(0, 10), (7, 12), (15, 11), (24, 12), (31, 11), (31, 15), (0, 15)], fill=CREVICE)
    for x in (7 + variant, 19 - variant % 4):
        draw.rectangle((x, 7, x + 3, 9), fill=RIM_DARK)


def draw_bottom_edge(draw: ImageDraw.ImageDraw, variant: int) -> None:
    sag = variant % 4
    draw.polygon([(0, 22 + sag), (10, 24), (20, 22), (31, 24 - sag), (31, 31), (0, 31)], fill=CREVICE)
    draw.line((4, 23 + sag, 15, 25), fill=ROCK_LIGHT, width=1)
    draw.line((19, 23, 29, 22 + sag), fill=ROCK_LIGHT, width=1)


def draw_left_edge(draw: ImageDraw.ImageDraw, variant: int) -> None:
    wobble = variant % 4
    draw.polygon([(0, 0), (7 + wobble, 2), (5, 11), (9, 20), (5 + wobble, 31), (0, 31)], fill=CREVICE)
    draw.line((8 + wobble, 4, 6, 27), fill=ROCK_LIGHT, width=1)
    draw.line((3, 9, 5, 14), fill=ROCK_BLUE, width=1)


def draw_right_edge(draw: ImageDraw.ImageDraw, variant: int) -> None:
    wobble = variant % 4
    draw.polygon([(31, 0), (24 - wobble, 2), (26, 12), (22, 22), (26 - wobble, 31), (31, 31)], fill=CREVICE)
    draw.line((23 - wobble, 4, 25, 27), fill=ROCK_LIGHT, width=1)
    draw.line((28, 10, 26, 16), fill=ROCK_BLUE, width=1)


def draw_inner_corner(draw: ImageDraw.ImageDraw, kind: str) -> None:
    if kind == "inner_top_left":
        draw.pieslice((-14, -14, 22, 22), 0, 90, fill=CREVICE)
        draw.arc((-11, -11, 25, 25), 0, 90, fill=ROCK_LIGHT, width=1)
    elif kind == "inner_top_right":
        draw.pieslice((10, -14, 46, 22), 90, 180, fill=CREVICE)
        draw.arc((7, -11, 43, 25), 90, 180, fill=ROCK_LIGHT, width=1)
    elif kind == "inner_bottom_left":
        draw.pieslice((-14, 10, 22, 46), 270, 360, fill=CREVICE)
        draw.arc((-11, 7, 25, 43), 270, 360, fill=ROCK_LIGHT, width=1)
    elif kind == "inner_bottom_right":
        draw.pieslice((10, 10, 46, 46), 180, 270, fill=CREVICE)
        draw.arc((7, 7, 43, 43), 180, 270, fill=ROCK_LIGHT, width=1)


def draw_tile(mask: int, variant: int = 0) -> Image.Image:
    tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile, "RGBA")
    draw_base(draw, mask * 17 + variant * 31)
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
    inner = item.get("inner")
    if inner:
        draw_inner_corner(ImageDraw.Draw(tile, "RGBA"), str(inner))
    return tile


def tile_coord(mask: int) -> tuple[int, int]:
    return mask % ATLAS_COLUMNS, mask // ATLAS_COLUMNS


def write_review(atlas: Image.Image, tiles: list[dict]) -> None:
    review_scale = 3
    label_h = 34
    review = Image.new(
        "RGBA",
        (ATLAS_COLUMNS * TILE_SIZE * review_scale, ATLAS_ROWS * (TILE_SIZE * review_scale + label_h)),
        WATER_REVIEW,
    )
    draw = ImageDraw.Draw(review)
    try:
        label_font = ImageFont.truetype("arial.ttf", 10)
    except OSError:
        label_font = ImageFont.load_default()

    for tile in tiles:
        x, y = tile["coord"]
        tile_img = atlas.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
        tile_img = tile_img.resize((TILE_SIZE * review_scale, TILE_SIZE * review_scale), Image.Resampling.NEAREST)
        px = x * TILE_SIZE * review_scale
        py = y * (TILE_SIZE * review_scale + label_h)
        review.alpha_composite(tile_img, (px, py))
        draw.text((px + 3, py + TILE_SIZE * review_scale + 2), str(tile["name"]).replace("_", "\n"), fill=LABEL, font=label_font)

    review.save(REVIEW_PATH)


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
        tiles.append(dict(extra))

    atlas.save(ATLAS_PATH)
    MANIFEST_PATH.write_text(
        json.dumps({
            "id": "cave_tileset_v2",
            "tile_size_px": TILE_SIZE,
            "atlas": ATLAS_PATH.relative_to(ROOT).as_posix(),
            "tiles": tiles,
        }, indent=2) + "\n",
        encoding="utf-8",
    )
    write_review(atlas, tiles)

    print(f"Wrote {ATLAS_PATH.relative_to(ROOT)}")
    print(f"Wrote {MANIFEST_PATH.relative_to(ROOT)}")
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
