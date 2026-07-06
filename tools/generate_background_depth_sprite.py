#!/usr/bin/env python3
"""Generate the controlled background-depth sprite variant."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "terrain"
REVIEW_DIR = ROOT / "references" / "asset_reviews"

SPRITE_SIZE = (512, 256)
SCALE = 2
CANVAS_SIZE = (SPRITE_SIZE[0] * SCALE, SPRITE_SIZE[1] * SCALE)
SPRITE_PATH = ASSET_DIR / "background_rocks_02.png"
OLD_SPRITE_PATH = ASSET_DIR / "background_rocks_01.png"
REVIEW_PATH = REVIEW_DIR / "background_rocks_02_review.png"

PANEL = (12, 34, 44, 255)
WATER = (24, 179, 220, 255)
TEXT = (232, 244, 246, 255)
MUTED = (152, 198, 205, 255)
FAR = (16, 72, 98, 130)
MID = (21, 92, 120, 172)
NEAR = (25, 105, 130, 205)
EDGE = (68, 151, 169, 92)
LOWLIGHT = (8, 45, 64, 88)


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


def draw_arch(draw: ImageDraw.ImageDraw, bounds: tuple[int, int, int, int], fill: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = rect(bounds)
    draw.rounded_rectangle((x0, y0, x1, y1), radius=8 * SCALE, fill=fill)
    opening_w = int((x1 - x0) * 0.28)
    opening_h = int((y1 - y0) * 0.62)
    opening_x0 = int((x0 + x1) * 0.5 - opening_w * 0.5)
    opening_y0 = y0 + int((y1 - y0) * 0.30)
    opening_x1 = opening_x0 + opening_w
    opening_y1 = opening_y0 + opening_h
    draw.rounded_rectangle((opening_x0, opening_y0, opening_x1, opening_y1), radius=opening_w // 2, fill=(0, 0, 0, 0))


def draw_background() -> Image.Image:
	image = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
	draw = ImageDraw.Draw(image, "RGBA")

	# Far soft cave mass.
	draw.polygon(
		scaled(
			[
				(12, 218),
				(40, 172),
				(78, 154),
				(118, 166),
				(162, 130),
				(214, 138),
				(264, 112),
				(328, 126),
				(384, 104),
				(452, 124),
				(500, 178),
				(512, 228),
			]
		),
		fill=FAR,
	)

	# Main readable side-view cave silhouettes. These are deliberately organic and
	# non-collision: no grid-critical edges or gameplay ledges are implied.
	draw.polygon(
		scaled([(46, 216), (58, 166), (84, 136), (128, 128), (164, 146), (182, 192), (164, 224)]),
		fill=MID,
	)
	draw.polygon(
		scaled([(180, 224), (190, 118), (214, 72), (238, 48), (266, 64), (282, 114), (290, 224)]),
		fill=(29, 108, 137, 188),
	)
	draw.polygon(
		scaled([(314, 224), (326, 142), (362, 116), (414, 120), (452, 154), (482, 214), (462, 232)]),
		fill=MID,
	)
	draw.polygon(
		scaled([(0, 222), (48, 204), (104, 212), (156, 194), (220, 208), (276, 190), (348, 206), (424, 192), (512, 216), (512, 256), (0, 256)]),
		fill=NEAR,
	)

	# Carved arch openings and low troughs keep the silhouette cave-like.
	for bounds in [(86, 160, 130, 220), (368, 150, 418, 222), (222, 116, 262, 190)]:
		x0, y0, x1, y1 = rect(bounds)
		draw.rounded_rectangle((x0, y0, x1, y1), radius=(x1 - x0) // 2, fill=(0, 0, 0, 0))
	draw.polygon(scaled([(28, 226), (92, 208), (164, 220), (216, 206), (246, 232), (20, 240)]), fill=LOWLIGHT)
	draw.polygon(scaled([(302, 224), (376, 202), (484, 216), (512, 238), (320, 240)]), fill=LOWLIGHT)

	# Soft contour accents and broad planes prevent a flat rectangle read.
	for line in [
		[(58, 166), (96, 146), (146, 150), (174, 178)],
		[(194, 120), (222, 78), (252, 66), (278, 112)],
		[(330, 144), (372, 126), (424, 134), (468, 184)],
		[(42, 208), (100, 192), (158, 202)],
		[(318, 206), (386, 190), (474, 206)],
	]:
		draw.line(scaled(line), fill=EDGE, width=4 * SCALE, joint="curve")

	for values in [(70, 148, 134, 162), (206, 98, 266, 112), (348, 136, 424, 150), (174, 184, 244, 196), (286, 166, 348, 178)]:
		draw.rounded_rectangle(rect(values), radius=4 * SCALE, fill=(68, 154, 174, 46))

	return downsample(image)


def label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, font: ImageFont.ImageFont, fill: tuple[int, int, int, int] = TEXT) -> None:
    draw.text(xy, text, fill=fill, font=font)


def save_review(sprite: Image.Image) -> None:
    review = Image.new("RGBA", (980, 520), PANEL)
    draw = ImageDraw.Draw(review)
    title_font = load_font(20)
    label_font = load_font(13)

    label(draw, (20, 16), "Background Rocks 02", title_font)
    label(draw, (20, 44), "512x256 non-collision distant cave silhouette variant for authored background rectangles", label_font, MUTED)

    water_old = Image.new("RGBA", (430, 190), WATER)
    if OLD_SPRITE_PATH.exists():
        old_sprite = Image.open(OLD_SPRITE_PATH).convert("RGBA")
        water_old.alpha_composite(old_sprite.resize((384, 192), Image.Resampling.LANCZOS), (24, -2))
    review.alpha_composite(water_old, (24, 86))
    draw.rectangle((24, 86, 453, 275), outline=(126, 158, 168, 220), width=1)
    label(draw, (30, 282), "v1 comparison", label_font)

    water_new = Image.new("RGBA", (430, 190), WATER)
    water_new.alpha_composite(sprite.resize((384, 192), Image.Resampling.LANCZOS), (24, -2))
    review.alpha_composite(water_new, (520, 86))
    draw.rectangle((520, 86, 949, 275), outline=(126, 158, 168, 220), width=1)
    label(draw, (526, 282), "v2 candidate", label_font)

    enlarged = sprite.resize((SPRITE_SIZE[0], SPRITE_SIZE[1]), Image.Resampling.NEAREST)
    preview = Image.new("RGBA", SPRITE_SIZE, WATER)
    preview.alpha_composite(enlarged, (0, 0))
    review.alpha_composite(preview, (234, 338))
    draw.rectangle((234, 338, 745, 593), outline=(126, 158, 168, 220), width=1)
    label(draw, (240, 310), "actual asset over water; runtime still modulates and scales by JSON background rectangles", label_font, MUTED)

    review.convert("RGB").save(REVIEW_PATH)


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    sprite = draw_background()
    sprite.save(SPRITE_PATH)
    print(f"Wrote {SPRITE_PATH.relative_to(ROOT)}")

    save_review(sprite)
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
