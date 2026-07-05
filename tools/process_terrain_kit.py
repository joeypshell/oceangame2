#!/usr/bin/env python3
"""Process raw chroma-key terrain generations into exact-size draft assets."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFont


RAW_DIR = Path("tmp/imagegen/terrain_raw")
ASSET_DIR = Path("assets/terrain")
REVIEW_DIR = Path("references/asset_reviews")
KEY_COLOR = (255, 0, 255)


@dataclass(frozen=True)
class AssetSpec:
    source_name: str
    output_name: str
    size: tuple[int, int]
    label: str
    opacity: float = 1.0


ASSETS = [
    AssetSpec("terrain_floor_short_01_raw.png", "terrain_floor_short_01.png", (256, 128), "floor short"),
    AssetSpec("terrain_floor_long_01_raw.png", "terrain_floor_long_01.png", (512, 256), "floor long"),
    AssetSpec("terrain_wall_left_01_raw.png", "terrain_wall_left_01.png", (128, 256), "wall left"),
    AssetSpec("terrain_wall_right_01_raw.png", "terrain_wall_right_01.png", (128, 256), "wall right"),
    AssetSpec("terrain_ceiling_01_raw.png", "terrain_ceiling_01.png", (512, 128), "ceiling"),
    AssetSpec("terrain_arch_01_raw.png", "terrain_arch_01.png", (256, 256), "arch"),
    AssetSpec("background_rocks_01_raw.png", "background_rocks_01.png", (512, 256), "background", 0.72),
]


def key_distance(pixel: tuple[int, int, int, int]) -> float:
    return math.sqrt(
        (pixel[0] - KEY_COLOR[0]) ** 2
        + (pixel[1] - KEY_COLOR[1]) ** 2
        + (pixel[2] - KEY_COLOR[2]) ** 2
    )


def remove_chroma_key(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = key_distance((r, g, b, a))
            if distance < 70:
                pixels[x, y] = (r, g, b, 0)
            elif distance < 130:
                alpha = int(255 * ((distance - 70) / 60))
                pixels[x, y] = (r, g, b, min(a, alpha))

    return image


def alpha_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("No non-transparent pixels found after chroma-key removal.")
    return bounds


def fit_to_canvas(image: Image.Image, size: tuple[int, int], opacity: float) -> Image.Image:
    bounds = alpha_bounds(image)
    cropped = image.crop(bounds)
    target_w, target_h = size
    margin = 0.92
    scale = min((target_w * margin) / cropped.width, (target_h * margin) / cropped.height)
    new_size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    resized = cropped.resize(new_size, Image.Resampling.LANCZOS)

    if opacity < 1.0:
        alpha = resized.getchannel("A").point(lambda value: int(value * opacity))
        resized.putalpha(alpha)

    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    paste_x = (target_w - resized.width) // 2
    paste_y = (target_h - resized.height) // 2
    canvas.alpha_composite(resized, (paste_x, paste_y))
    return canvas


def make_contact_sheet(processed: list[tuple[AssetSpec, Image.Image]]) -> Image.Image:
    cell_w = 560
    cell_h = 320
    cols = 2
    rows = math.ceil(len(processed) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (18, 184, 232, 255))
    grid_color = (216, 247, 255, 48)

    for x in range(0, sheet.width, 32):
        for y in range(sheet.height):
            sheet.putpixel((x, y), grid_color)
    for y in range(0, sheet.height, 32):
        for x in range(sheet.width):
            sheet.putpixel((x, y), grid_color)

    for index, (spec, image) in enumerate(processed):
        col = index % cols
        row = index // cols
        x0 = col * cell_w
        y0 = row * cell_h
        asset_x = x0 + (cell_w - image.width) // 2
        asset_y = y0 + 42 + (cell_h - 84 - image.height) // 2
        sheet.alpha_composite(image, (asset_x, asset_y))

        # Simple label band so reviewers can identify modules; not used in game.
        label_band = Image.new("RGBA", (cell_w, 32), (5, 42, 57, 210))
        sheet.alpha_composite(label_band, (x0, y0))
        draw = ImageDraw.Draw(sheet)
        label = f"{spec.output_name} ({spec.size[0]}x{spec.size[1]})"
        draw.text((x0 + 12, y0 + 8), label, fill=(234, 255, 255, 255), font=ImageFont.load_default())

    return sheet


def main() -> int:
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    processed: list[tuple[AssetSpec, Image.Image]] = []
    for spec in ASSETS:
        raw_path = RAW_DIR / spec.source_name
        if not raw_path.is_file():
            raise FileNotFoundError(raw_path)

        image = Image.open(raw_path)
        keyed = remove_chroma_key(image)
        final = fit_to_canvas(keyed, spec.size, spec.opacity)
        final.save(ASSET_DIR / spec.output_name)
        processed.append((spec, final))

    contact_sheet = make_contact_sheet(processed)
    contact_sheet.save(REVIEW_DIR / "terrain_kit_01.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
