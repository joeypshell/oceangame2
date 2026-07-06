#!/usr/bin/env python3
"""Generate the first controlled player/diver sprite."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "player"
REVIEW_DIR = ROOT / "references" / "asset_reviews"

SPRITE_SIZE = (96, 64)
SCALE = 4
CANVAS_SIZE = (SPRITE_SIZE[0] * SCALE, SPRITE_SIZE[1] * SCALE)
SPRITE_PATH = ASSET_DIR / "player_diver_01.png"
REVIEW_PATH = REVIEW_DIR / "player_sprite_01_review.png"

OUTLINE = (18, 35, 42, 255)
SUIT = (31, 73, 86, 255)
SUIT_DARK = (14, 36, 46, 255)
SUIT_LIGHT = (56, 116, 128, 255)
VISOR = (91, 229, 235, 245)
VISOR_DARK = (16, 91, 105, 255)
TANK = (78, 111, 116, 255)
TANK_DARK = (34, 55, 62, 255)
ACCENT = (245, 180, 65, 255)
WATER_REVIEW = (24, 179, 220, 255)
PANEL = (12, 34, 44, 255)
TEXT = (232, 244, 246, 255)
COLLISION = (255, 215, 92, 230)


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


def draw_diver() -> Image.Image:
    image = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    # Back tank and hose.
    draw.rounded_rectangle(rect((16, 21, 42, 37)), radius=5 * SCALE, fill=TANK_DARK)
    draw.rounded_rectangle(rect((19, 18, 45, 34)), radius=5 * SCALE, fill=TANK, outline=OUTLINE, width=2 * SCALE)
    draw.line(scaled([(43, 24), (52, 18), (64, 20)]), fill=ACCENT, width=2 * SCALE)

    # Flippers and trailing leg silhouette.
    draw.polygon(scaled([(14, 43), (3, 53), (22, 53), (34, 44)]), fill=SUIT_DARK, outline=OUTLINE)
    draw.polygon(scaled([(20, 36), (7, 43), (26, 47), (39, 39)]), fill=SUIT_DARK, outline=OUTLINE)

    # Main body, arm, and head face right by default.
    draw.polygon(
        scaled([(28, 25), (48, 18), (69, 21), (82, 31), (70, 43), (44, 45), (25, 38)]),
        fill=SUIT,
        outline=OUTLINE,
    )
    draw.line(scaled([(40, 27), (58, 34), (74, 34)]), fill=SUIT_LIGHT, width=4 * SCALE)
    draw.polygon(scaled([(36, 41), (52, 49), (68, 47), (53, 39)]), fill=SUIT_DARK, outline=OUTLINE)

    draw.ellipse(rect((58, 17, 84, 43)), fill=SUIT, outline=OUTLINE, width=2 * SCALE)
    draw.polygon(scaled([(66, 23), (83, 25), (88, 32), (82, 38), (65, 37), (61, 31)]), fill=VISOR_DARK)
    draw.polygon(scaled([(68, 25), (81, 27), (84, 32), (80, 36), (67, 35), (64, 31)]), fill=VISOR)
    draw.line(scaled([(71, 26), (80, 28)]), fill=(191, 255, 255, 230), width=2 * SCALE)

    # Small warm points keep continuity with boat/prop accents.
    draw.rectangle(rect((46, 23, 51, 28)), fill=ACCENT)
    draw.line(scaled([(30, 32), (44, 36)]), fill=ACCENT, width=2 * SCALE)

    return downsample(image)


def save_review(sprite: Image.Image) -> None:
    review = Image.new("RGBA", (640, 240), PANEL)
    draw = ImageDraw.Draw(review)
    title_font = load_font(18)
    label_font = load_font(13)

    draw.text((20, 16), "Player Diver Sprite 01", fill=TEXT, font=title_font)
    draw.text((20, 42), "96x64 centered sprite; collision remains 26x18 in Player.tscn", fill=TEXT, font=label_font)

    water_panel = Image.new("RGBA", (180, 130), WATER_REVIEW)
    water_panel.alpha_composite(sprite, (42, 33))
    review.alpha_composite(water_panel, (28, 80))
    draw.rectangle((28, 80, 207, 209), outline=(126, 158, 168, 220), width=1)
    draw.text((34, 214), "actual size", fill=TEXT, font=label_font)

    enlarged = sprite.resize((SPRITE_SIZE[0] * 3, SPRITE_SIZE[1] * 3), Image.Resampling.NEAREST)
    review.alpha_composite(enlarged, (278, 36))
    origin = (278 + SPRITE_SIZE[0] * 3 // 2, 36 + SPRITE_SIZE[1] * 3 // 2)
    collision_half = (26 * 3 // 2, 18 * 3 // 2)
    draw.rectangle(
        (
            origin[0] - collision_half[0],
            origin[1] - collision_half[1],
            origin[0] + collision_half[0],
            origin[1] + collision_half[1],
        ),
        outline=COLLISION,
        width=2,
    )
    draw.line((origin[0] - 8, origin[1], origin[0] + 8, origin[1]), fill=COLLISION, width=1)
    draw.line((origin[0], origin[1] - 8, origin[0], origin[1] + 8), fill=COLLISION, width=1)
    draw.text((278, 214), "3x review with collision box overlay", fill=TEXT, font=label_font)

    review.convert("RGB").save(REVIEW_PATH)


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    sprite = draw_diver()
    sprite.save(SPRITE_PATH)
    print(f"Wrote {SPRITE_PATH.relative_to(ROOT)}")

    save_review(sprite)
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
