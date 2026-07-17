#!/usr/bin/env python3
"""Generate deterministic 32x32 material sprites and their review sheet."""

from __future__ import annotations

import argparse
import hashlib
import io
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "materials"
REVIEW_DIR = ROOT / "references" / "asset_reviews"
SPRITE_SIZE = 32
SCALE = 4
CANVAS = SPRITE_SIZE * SCALE
ASSET_PATHS = {
    "titanium_scrap": ASSET_DIR / "titanium_scrap_01.png",
    "rubber_sheet": ASSET_DIR / "rubber_sheet_01.png",
    "conductive_coil": ASSET_DIR / "conductive_coil_01.png",
}
REVIEW_PATH = REVIEW_DIR / "material_sprites_01_review.png"

OUTLINE = (24, 45, 52, 255)
METAL_DARK = (56, 89, 98, 255)
METAL = (134, 190, 198, 255)
METAL_LIGHT = (206, 237, 235, 255)
RUST = (160, 76, 42, 255)
RUBBER_DARK = (16, 29, 38, 255)
RUBBER = (53, 82, 92, 255)
RUBBER_LIGHT = (124, 164, 168, 255)
COPPER_DARK = (100, 49, 23, 255)
COPPER = (222, 130, 40, 255)
COPPER_LIGHT = (255, 202, 84, 255)
WATER = (24, 179, 220, 255)
PANEL = (9, 47, 61, 225)
LABEL = (232, 244, 246, 255)
MUTED = (164, 218, 226, 255)


def scaled(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    return [(x * SCALE, y * SCALE) for x, y in points]


def new_sprite() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image, "RGBA")


def downsample(image: Image.Image) -> Image.Image:
    return image.resize((SPRITE_SIZE, SPRITE_SIZE), Image.Resampling.LANCZOS)


def draw_titanium() -> Image.Image:
    image, draw = new_sprite()
    back = scaled([(4, 17), (12, 8), (25, 10), (28, 19), (18, 26), (6, 24)])
    front = scaled([(5, 20), (15, 13), (28, 17), (24, 26), (10, 27)])
    draw.polygon(back, fill=METAL_DARK, outline=OUTLINE)
    draw.line(back + [back[0]], fill=OUTLINE, width=2 * SCALE, joint="curve")
    draw.polygon(front, fill=METAL, outline=OUTLINE)
    draw.line(front + [front[0]], fill=OUTLINE, width=2 * SCALE, joint="curve")
    draw.polygon(scaled([(7, 21), (15, 16), (20, 18), (12, 23)]), fill=RUST)
    draw.line(scaled([(15, 14), (25, 17), (22, 20)]), fill=METAL_LIGHT, width=2 * SCALE)
    draw.line(scaled([(9, 11), (15, 7), (21, 9)]), fill=METAL_LIGHT, width=2 * SCALE)
    return downsample(image)


def draw_rubber() -> Image.Image:
    image, draw = new_sprite()
    back_fold = scaled([(6, 9), (23, 11), (26, 16), (9, 14)])
    front_fold = scaled([(5, 15), (24, 17), (27, 23), (8, 21)])
    draw.polygon(back_fold, fill=RUBBER_DARK, outline=OUTLINE)
    draw.line(back_fold + [back_fold[0]], fill=OUTLINE, width=2 * SCALE, joint="curve")
    draw.polygon(front_fold, fill=RUBBER, outline=OUTLINE)
    draw.line(front_fold + [front_fold[0]], fill=OUTLINE, width=2 * SCALE, joint="curve")
    draw.line(scaled([(8, 11), (22, 13)]), fill=RUBBER_LIGHT, width=2 * SCALE)
    draw.line(scaled([(7, 17), (23, 19)]), fill=RUBBER_LIGHT, width=2 * SCALE)
    draw.line(scaled([(10, 22), (25, 24)]), fill=RUBBER_DARK, width=2 * SCALE)
    draw.line(scaled([(16, 10), (15, 22)]), fill=RUBBER_LIGHT, width=2 * SCALE)
    return downsample(image)


def draw_coil() -> Image.Image:
    image, draw = new_sprite()
    spring = scaled([(7, 21), (10, 10), (13, 22), (16, 10), (19, 22), (22, 10), (25, 21)])
    draw.line(spring, fill=COPPER_DARK, width=7 * SCALE, joint="curve")
    draw.line(spring, fill=COPPER, width=4 * SCALE, joint="curve")
    highlight = scaled([(8, 19), (10, 12), (12, 19), (13, 20)])
    draw.line(highlight, fill=COPPER_LIGHT, width=1 * SCALE, joint="curve")
    for left, right in [(3, 8), (24, 29)]:
        draw.rounded_rectangle(
            (left * SCALE, 18 * SCALE, right * SCALE, 24 * SCALE),
            radius=1 * SCALE,
            fill=METAL,
            outline=OUTLINE,
            width=2 * SCALE,
        )
    draw.line(scaled([(5, 19), (7, 19)]), fill=METAL_LIGHT, width=SCALE)
    draw.line(scaled([(26, 19), (28, 19)]), fill=METAL_LIGHT, width=SCALE)
    return downsample(image)


def font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def build_review(sprites: dict[str, Image.Image]) -> Image.Image:
    cell_width = 240
    review = Image.new("RGBA", (cell_width * len(sprites), 236), WATER)
    draw = ImageDraw.Draw(review, "RGBA")
    title_font = font(15)
    label_font = font(11)
    for index, (material_id, sprite) in enumerate(sprites.items()):
        left = index * cell_width
        draw.rounded_rectangle((left + 8, 8, left + cell_width - 8, 228), radius=6, fill=PANEL)
        draw.text((left + 18, 18), material_id.replace("_", " "), fill=LABEL, font=title_font)

        review.alpha_composite(sprite, (left + 34, 62))
        draw.text((left + 22, 101), "desktop 32px", fill=MUTED, font=label_font)

        mobile = sprite.resize((17, 17), Image.Resampling.LANCZOS)
        review.alpha_composite(mobile, (left + 148, 69))
        draw.text((left + 134, 101), "mobile ~17px", fill=MUTED, font=label_font)

        detail = sprite.resize((96, 96), Image.Resampling.NEAREST)
        review.alpha_composite(detail, (left + 72, 124))
    return review


def png_bytes(image: Image.Image) -> bytes:
    output = io.BytesIO()
    image.save(output, format="PNG", optimize=False)
    return output.getvalue()


def generated_files() -> dict[Path, bytes]:
    sprites = {
        "titanium_scrap": draw_titanium(),
        "rubber_sheet": draw_rubber(),
        "conductive_coil": draw_coil(),
    }
    values = {ASSET_PATHS[name]: png_bytes(sprite) for name, sprite in sprites.items()}
    values[REVIEW_PATH] = png_bytes(build_review(sprites))
    return values


def run(check: bool) -> int:
    files = generated_files()
    failures: list[str] = []
    for path, content in files.items():
        relative = path.relative_to(ROOT).as_posix()
        digest = hashlib.sha256(content).hexdigest()[:12]
        if check:
            if not path.is_file() or path.read_bytes() != content:
                failures.append(relative)
                print(f"DRIFT {relative} sha256={digest}")
            else:
                print(f"OK {relative} sha256={digest}")
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        print(f"Wrote {relative} sha256={digest}")
    if failures:
        print("Regenerate material sprites: python tools/generate_material_sprites.py")
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail if committed outputs differ from deterministic generation.")
    return run(parser.parse_args().check)


if __name__ == "__main__":
    raise SystemExit(main())
