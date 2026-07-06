#!/usr/bin/env python3
"""Generate first-pass collectible and hazard prop sprites."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "props"
REVIEW_DIR = ROOT / "references" / "asset_reviews"

SPRITE_SIZE = 32
SCALE = 4
CANVAS = SPRITE_SIZE * SCALE

ASSETS = {
    "crate": ASSET_DIR / "salvage_crate_01.png",
    "wreck_fragment": ASSET_DIR / "wreck_fragment_01.png",
    "relic": ASSET_DIR / "relic_01.png",
    "mine": ASSET_DIR / "mine_01.png",
    "jellyfish": ASSET_DIR / "jellyfish_01.png",
}
REVIEW_PATH = REVIEW_DIR / "prop_sprites_01_review.png"

OUTLINE = (45, 35, 25, 255)
CRATE_BODY = (190, 116, 44, 255)
CRATE_LIGHT = (245, 186, 64, 255)
CRATE_DARK = (100, 58, 27, 255)
METAL = (116, 150, 145, 255)
METAL_DARK = (37, 58, 62, 255)
RUST = (180, 84, 38, 255)
RELIC_TEAL = (14, 174, 180, 255)
RELIC_GLOW = (84, 238, 228, 130)
GOLD = (255, 201, 74, 255)
HAZARD = (235, 45, 79, 255)
HAZARD_DARK = (92, 11, 28, 255)
HAZARD_LIGHT = (255, 128, 151, 255)
JELLY = (227, 52, 142, 238)
JELLY_LIGHT = (255, 155, 202, 255)
WATER_REVIEW = (24, 179, 220, 255)
LABEL = (232, 244, 246, 255)


def scaled(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    return [(x * SCALE, y * SCALE) for x, y in points]


def downsample(image: Image.Image) -> Image.Image:
    return image.resize((SPRITE_SIZE, SPRITE_SIZE), Image.Resampling.LANCZOS)


def new_sprite() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image, "RGBA")


def draw_crate() -> Image.Image:
    image, draw = new_sprite()
    draw.rounded_rectangle((5 * SCALE, 7 * SCALE, 27 * SCALE, 25 * SCALE), radius=2 * SCALE, fill=CRATE_BODY, outline=OUTLINE, width=2 * SCALE)
    draw.line((5 * SCALE, 16 * SCALE, 27 * SCALE, 16 * SCALE), fill=CRATE_DARK, width=2 * SCALE)
    draw.line((16 * SCALE, 7 * SCALE, 16 * SCALE, 25 * SCALE), fill=CRATE_DARK, width=2 * SCALE)
    draw.line((8 * SCALE, 10 * SCALE, 14 * SCALE, 14 * SCALE), fill=CRATE_LIGHT, width=2 * SCALE)
    draw.rectangle((20 * SCALE, 9 * SCALE, 24 * SCALE, 12 * SCALE), fill=CRATE_LIGHT)
    return downsample(image)


def draw_wreck_fragment() -> Image.Image:
    image, draw = new_sprite()
    hull = scaled([(4, 13), (16, 7), (28, 12), (24, 23), (10, 25)])
    draw.polygon(hull, fill=METAL, outline=METAL_DARK)
    draw.line(scaled([(5, 14), (16, 9), (27, 13), (23, 22), (10, 24), (5, 14)]), fill=METAL_DARK, width=2 * SCALE)
    draw.polygon(scaled([(7, 14), (14, 11), (16, 18), (9, 21)]), fill=RUST)
    draw.polygon(scaled([(18, 10), (25, 13), (23, 16), (17, 14)]), fill=(178, 203, 195, 255))
    draw.line(scaled([(14, 8), (19, 5), (21, 9)]), fill=METAL_DARK, width=2 * SCALE)
    return downsample(image)


def draw_relic() -> Image.Image:
    image, draw = new_sprite()
    draw.ellipse((5 * SCALE, 5 * SCALE, 27 * SCALE, 27 * SCALE), fill=RELIC_GLOW)
    draw.ellipse((9 * SCALE, 9 * SCALE, 23 * SCALE, 23 * SCALE), fill=RELIC_TEAL, outline=(4, 76, 88, 255), width=2 * SCALE)
    draw.polygon(scaled([(10, 9), (22, 9), (25, 14), (7, 14)]), fill=GOLD, outline=OUTLINE)
    draw.line((9 * SCALE, 19 * SCALE, 23 * SCALE, 19 * SCALE), fill=GOLD, width=2 * SCALE)
    draw.ellipse((13 * SCALE, 12 * SCALE, 18 * SCALE, 17 * SCALE), fill=(154, 255, 240, 255))
    return downsample(image)


def draw_mine() -> Image.Image:
    image, draw = new_sprite()
    spikes = [
        (16, 2),
        (20, 10),
        (28, 8),
        (22, 16),
        (29, 23),
        (19, 21),
        (16, 30),
        (13, 21),
        (3, 23),
        (10, 16),
        (4, 8),
        (12, 10),
    ]
    draw.polygon(scaled(spikes), fill=HAZARD_DARK)
    draw.ellipse((7 * SCALE, 7 * SCALE, 25 * SCALE, 25 * SCALE), fill=HAZARD, outline=HAZARD_DARK, width=2 * SCALE)
    draw.ellipse((11 * SCALE, 10 * SCALE, 16 * SCALE, 15 * SCALE), fill=HAZARD_LIGHT)
    draw.rectangle((15 * SCALE, 4 * SCALE, 17 * SCALE, 9 * SCALE), fill=HAZARD_DARK)
    return downsample(image)


def draw_jellyfish() -> Image.Image:
    image, draw = new_sprite()
    bell = scaled([(5, 16), (8, 9), (13, 5), (20, 5), (25, 10), (28, 16), (24, 21), (20, 17), (16, 21), (12, 17), (8, 21)])
    draw.polygon(bell, fill=JELLY, outline=HAZARD_DARK)
    for points in [
        [(10, 19), (8, 25), (10, 29)],
        [(15, 20), (16, 26), (14, 30)],
        [(21, 19), (24, 25), (22, 29)],
    ]:
        draw.line(scaled(points), fill=JELLY_LIGHT, width=2 * SCALE)
    draw.ellipse((10 * SCALE, 9 * SCALE, 15 * SCALE, 14 * SCALE), fill=JELLY_LIGHT)
    return downsample(image)


def save_review(sprites: dict[str, Image.Image]) -> None:
    cell_w = 136
    cell_h = 104
    review = Image.new("RGBA", (cell_w * len(sprites), cell_h), WATER_REVIEW)
    draw = ImageDraw.Draw(review)
    try:
        font = ImageFont.truetype("arial.ttf", 12)
    except OSError:
        font = ImageFont.load_default()

    for index, (name, sprite) in enumerate(sprites.items()):
        x = index * cell_w
        enlarged = sprite.resize((SPRITE_SIZE * 2, SPRITE_SIZE * 2), Image.Resampling.NEAREST)
        review.alpha_composite(enlarged, (x + 36, 14))
        draw.text((x + 8, 82), name.replace("_", " "), fill=LABEL, font=font)

    review.save(REVIEW_PATH)


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    sprites = {
        "crate": draw_crate(),
        "wreck_fragment": draw_wreck_fragment(),
        "relic": draw_relic(),
        "mine": draw_mine(),
        "jellyfish": draw_jellyfish(),
    }
    for name, sprite in sprites.items():
        sprite.save(ASSETS[name])
        print(f"Wrote {ASSETS[name].relative_to(ROOT)}")

    save_review(sprites)
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
