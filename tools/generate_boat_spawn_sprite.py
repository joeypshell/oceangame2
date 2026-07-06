#!/usr/bin/env python3
"""Generate the first controlled boat spawn entry sprite."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "vehicles"
REVIEW_DIR = ROOT / "references" / "asset_reviews"

SPRITE_SIZE = (192, 64)
SCALE = 4
CANVAS_SIZE = (SPRITE_SIZE[0] * SCALE, SPRITE_SIZE[1] * SCALE)
SPRITE_PATH = ASSET_DIR / "boat_spawn_01.png"
REVIEW_PATH = REVIEW_DIR / "boat_spawn_01_review.png"

OUTLINE = (48, 34, 23, 255)
HULL = (218, 126, 38, 255)
HULL_DARK = (101, 58, 30, 255)
HULL_LIGHT = (252, 190, 66, 255)
DECK = (238, 215, 164, 255)
DECK_DARK = (146, 118, 76, 255)
CABIN = (224, 197, 145, 255)
GLASS = (78, 220, 232, 235)
GLASS_DARK = (20, 106, 123, 255)
METAL = (117, 144, 139, 255)
WATER_REVIEW = (24, 179, 220, 255)
PANEL = (12, 34, 44, 255)
TEXT = (232, 244, 246, 255)
ENTRY = (246, 216, 92, 235)


def scaled(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    return [(x * SCALE, y * SCALE) for x, y in points]


def rect(values: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    return tuple(value * SCALE for value in values)


def downsample(image: Image.Image) -> Image.Image:
    return image.resize(SPRITE_SIZE, Image.Resampling.LANCZOS)


def load_font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def draw_boat() -> Image.Image:
    image = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    draw.ellipse(rect((20, 43, 174, 60)), fill=(20, 65, 76, 72))
    draw.polygon(scaled([(15, 28), (181, 28), (162, 52), (34, 52)]), fill=HULL_DARK)
    draw.polygon(scaled([(11, 22), (184, 22), (164, 49), (31, 49)]), fill=HULL, outline=OUTLINE)
    draw.line(scaled([(17, 25), (178, 25)]), fill=HULL_LIGHT, width=3 * SCALE)
    draw.line(scaled([(35, 48), (162, 48)]), fill=HULL_DARK, width=2 * SCALE)

    draw.rounded_rectangle(rect((48, 10, 116, 32)), radius=4 * SCALE, fill=CABIN, outline=OUTLINE, width=2 * SCALE)
    draw.rectangle(rect((52, 28, 132, 36)), fill=DECK, outline=DECK_DARK)
    draw.rounded_rectangle(rect((59, 14, 83, 25)), radius=2 * SCALE, fill=GLASS_DARK)
    draw.rounded_rectangle(rect((62, 15, 83, 24)), radius=2 * SCALE, fill=GLASS)
    draw.rounded_rectangle(rect((89, 14, 109, 25)), radius=2 * SCALE, fill=GLASS)

    draw.polygon(scaled([(124, 24), (166, 22), (155, 35), (122, 35)]), fill=DECK, outline=DECK_DARK)
    draw.line(scaled([(132, 21), (148, 11), (166, 21)]), fill=METAL, width=2 * SCALE)
    draw.line(scaled([(146, 12), (146, 22)]), fill=METAL, width=2 * SCALE)
    draw.rectangle(rect((72, 32, 94, 38)), fill=ENTRY, outline=OUTLINE)
    draw.line(scaled([(82, 38), (82, 51)]), fill=ENTRY, width=2 * SCALE)

    for x in (40, 118, 151):
        draw.line(scaled([(x, 26), (x + 12, 47)]), fill=(126, 70, 33, 160), width=1 * SCALE)

    return downsample(image)


def save_review(sprite: Image.Image) -> None:
    review = Image.new("RGBA", (680, 260), PANEL)
    draw = ImageDraw.Draw(review)
    title_font = load_font(18)
    label_font = load_font(13)

    draw.text((20, 16), "Boat Spawn Sprite 01", fill=TEXT, font=title_font)
    draw.text((20, 42), "192x64 craft body; source-defined entry tether remains positioned by boat_spawn data", fill=TEXT, font=label_font)

    water_panel = Image.new("RGBA", (300, 118), WATER_REVIEW)
    water_panel.alpha_composite(sprite, (54, 24))
    review.alpha_composite(water_panel, (24, 82))
    draw.rectangle((24, 82, 323, 199), outline=(126, 158, 168, 220), width=1)
    draw.text((30, 205), "actual size on water", fill=TEXT, font=label_font)

    enlarged = sprite.resize((SPRITE_SIZE[0] * 2, SPRITE_SIZE[1] * 2), Image.Resampling.NEAREST)
    review.alpha_composite(enlarged, (272, 76))
    draw.rectangle((272, 76, 272 + SPRITE_SIZE[0] * 2 - 1, 76 + SPRITE_SIZE[1] * 2 - 1), outline=(126, 158, 168, 220), width=1)
    draw.line((272 + 92 * 2, 76 + 35 * 2, 272 + 92 * 2, 76 + 76 * 2), fill=ENTRY, width=2)
    draw.text((278, 205), "2x review with entry cue reference", fill=TEXT, font=label_font)

    review.convert("RGB").save(REVIEW_PATH)


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    sprite = draw_boat()
    sprite.save(SPRITE_PATH)
    print(f"Wrote {SPRITE_PATH.relative_to(ROOT)}")

    save_review(sprite)
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
