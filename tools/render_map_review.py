#!/usr/bin/env python3
"""Render a source/render/collision review sheet for a greybox map."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]

WATER = (24, 185, 238, 255)
WATER_DEEP = (12, 119, 183, 255)
SOLID = (36, 51, 63, 255)
SOLID_EDGE = (145, 169, 181, 255)
COLLISION_FILL = (255, 88, 132, 58)
COLLISION_EDGE = (255, 88, 132, 255)
MARKER = (255, 255, 255, 42)
BOAT = (240, 163, 58, 255)
SALVAGE = (255, 211, 74, 255)
HAZARD = (255, 75, 95, 255)
SURVEY = (105, 240, 220, 255)
TEXT = (232, 244, 246, 255)
MUTED_TEXT = (180, 209, 216, 255)
BACKGROUND = (22, 38, 47, 255)
PANEL_BACKGROUND = (12, 26, 34, 255)


def rect(item: dict, scale: int) -> tuple[int, int, int, int]:
    x0 = int(item["x"]) * scale
    y0 = int(item["y"]) * scale
    x1 = (int(item["x"]) + int(item.get("w", 1))) * scale
    y1 = (int(item["y"]) + int(item.get("h", 1))) * scale
    return x0, y0, x1, y1


def cell_count(terrain_items: list[dict]) -> int:
    return sum(int(item.get("w", 1)) * int(item.get("h", 1)) for item in terrain_items if item.get("type") == "solid")


def load_font(size: int) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def entity_center(entity: dict, scale: int) -> tuple[int, int]:
    return (
        int((float(entity.get("x", 0)) + 0.5) * scale),
        int((float(entity.get("y", 0)) + 0.5) * scale),
    )


def draw_grid(draw: ImageDraw.ImageDraw, width_tiles: int, height_tiles: int, scale: int) -> None:
    step = max(1, 4 * scale)
    for x in range(0, width_tiles * scale + 1, step):
        draw.line((x, 0, x, height_tiles * scale), fill=(216, 247, 255, 34), width=1)
    for y in range(0, height_tiles * scale + 1, step):
        draw.line((0, y, width_tiles * scale, y), fill=(216, 247, 255, 34), width=1)


def draw_entities(draw: ImageDraw.ImageDraw, map_data: dict, scale: int) -> None:
    for entity in map_data.get("entities", []):
        entity_type = str(entity.get("type", ""))
        if entity_type == "boat_spawn":
            x0, y0, x1, y1 = rect(entity, scale)
            hull = [
                (x0, y0 + max(1, (y1 - y0) // 4)),
                (x1, y0 + max(1, (y1 - y0) // 4)),
                (x1 - max(2, scale), y1),
                (x0 + max(2, scale), y1),
            ]
            draw.polygon(hull, fill=BOAT, outline=(110, 66, 16, 255))
            ex = int((float(entity.get("entry_x", entity.get("x", 0))) + 0.5) * scale)
            ey = int((float(entity.get("entry_y", entity.get("y", 0))) + 0.5) * scale)
            r = max(3, scale // 2)
            draw.ellipse((ex - r, ey - r, ex + r, ey + r), fill=(242, 214, 162, 255), outline=(112, 78, 34, 255))
        elif entity_type == "salvage":
            cx, cy = entity_center(entity, scale)
            r = max(4, scale // 2)
            draw.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=SALVAGE, outline=(127, 91, 0, 255))
        elif entity_type == "hazard":
            cx, cy = entity_center(entity, scale)
            r = max(4, scale // 2)
            draw.rectangle((cx - r, cy - r, cx + r, cy + r), fill=HAZARD, outline=(100, 18, 29, 255))


def draw_survey_targets(draw: ImageDraw.ImageDraw, map_data: dict, scale: int) -> None:
    for target in map_data.get("survey_targets", []):
        x0, y0, x1, y1 = rect(target, scale)
        draw.rectangle(
            (x0, y0, x1, y1),
            fill=(SURVEY[0], SURVEY[1], SURVEY[2], 70),
            outline=SURVEY,
            width=max(2, scale // 2),
        )
        presentation_id = target.get("scan_presentation_id")
        if presentation_id == "salvage_cutter_blueprint_case":
            anchor = target["scan_anchor"]
            cx = round((float(anchor["x"]) + 0.5) * scale)
            cy = round((float(anchor["y"]) + 0.5) * scale)
            half_w = max(4, scale)
            half_h = max(3, scale // 2)
            draw.rectangle((cx - half_w, cy - half_h, cx + half_w, cy + half_h), fill=(46, 74, 82, 255), outline=(143, 184, 179, 255))
            draw.rectangle((cx - half_w // 2, cy, cx + half_w // 2, cy + half_h - 1), fill=(31, 176, 184, 255))
        elif presentation_id == "northwest_wreck_relay_console":
            anchor = target["scan_anchor"]
            cx = round((float(anchor["x"]) + 0.5) * scale)
            cy = round((float(anchor["y"]) + 0.5) * scale)
            half_w = max(5, scale)
            half_h = max(4, scale * 3 // 4)
            draw.rectangle((cx - half_w, cy - half_h, cx + half_w, cy + half_h), fill=(26, 59, 66, 255), outline=(133, 189, 184, 255))
            draw.rectangle((cx - half_w + 2, cy - half_h + 2, cx + 1, cy + 1), fill=(10, 122, 135, 255))
            draw.line((cx + half_w // 2, cy - half_h, cx + half_w // 2, cy - half_h - scale), fill=(133, 189, 184, 255), width=max(1, scale // 3))
            r = max(2, scale // 3)
            draw.polygon([(cx + half_w // 2, cy - half_h - scale - r), (cx + half_w // 2 + r, cy - half_h - scale), (cx + half_w // 2, cy - half_h - scale + r), (cx + half_w // 2 - r, cy - half_h - scale)], fill=(255, 184, 61, 255))
        elif presentation_id == "western_chasm_navigation_transponder":
            anchor = target["scan_anchor"]
            cx = round((float(anchor["x"]) + 0.5) * scale)
            cy = round((float(anchor["y"]) + 0.5) * scale)
            body = [(cx - scale, cy - scale // 3), (cx + scale // 2, cy - scale // 2), (cx + scale, cy), (cx + scale // 2, cy + scale // 2), (cx - scale, cy + scale // 3)]
            draw.polygon(body, fill=(23, 71, 79, 255), outline=(122, 199, 191, 255))
            draw.line((cx - scale, cy, cx - scale * 2, cy), fill=(100, 159, 163, 255), width=max(1, scale // 3))
            draw.line((cx - scale // 2, cy, cx, cy - scale // 3, cx + scale // 2, cy), fill=(255, 209, 66, 255), width=max(1, scale // 3))
        elif presentation_id == "abyssal_shelf_navigation_transponder":
            anchor = target["scan_anchor"]
            cx = round((float(anchor["x"]) + 0.5) * scale)
            cy = round((float(anchor["y"]) + 0.5) * scale)
            r = max(5, scale)
            body = [(cx - r // 2, cy - r), (cx + r // 2, cy - r), (cx + r, cy - r // 2), (cx + r, cy + r // 2), (cx + r // 2, cy + r), (cx - r // 2, cy + r), (cx - r, cy + r // 2), (cx - r, cy - r // 2)]
            draw.polygon(body, fill=(31, 54, 87, 255), outline=(115, 179, 201, 255))
            draw.polygon([(cx, cy - r // 2), (cx + r // 2, cy), (cx, cy + r // 2), (cx - r // 2, cy)], fill=(16, 158, 175, 255))
            draw.line((cx - r * 2 // 3, cy - r * 2 // 3, cx - r // 3, cy - r // 3, cx - r // 2, cy, cx, cy + r // 2), fill=(173, 219, 221, 255), width=max(1, scale // 3))
        else:
            cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
            r = max(3, scale // 2)
            draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=SURVEY, width=max(1, scale // 3))


def draw_map_panel(map_data: dict, mode: str, scale: int) -> Image.Image:
    units = map_data["units"]
    width_tiles = int(units["width_tiles"])
    height_tiles = int(units["height_tiles"])
    image = Image.new("RGBA", (width_tiles * scale, height_tiles * scale), WATER)
    draw = ImageDraw.Draw(image)

    for y in range(height_tiles):
        t = y / max(1, height_tiles - 1)
        color = tuple(int(WATER[i] * (1.0 - t) + WATER_DEEP[i] * t) for i in range(3)) + (255,)
        draw.line((0, y * scale, width_tiles * scale, y * scale), fill=color, width=scale)

    for zone in map_data.get("zones", []):
        if zone.get("type") == "marker":
            draw.rectangle(rect(zone, scale), fill=MARKER, outline=(255, 255, 255, 90), width=max(1, scale // 4))

    terrain = [item for item in map_data.get("terrain", []) if item.get("type") == "solid"]
    if mode == "source":
        for item in terrain:
            draw.rectangle(rect(item, scale), fill=SOLID, outline=SOLID_EDGE, width=1)
    elif mode == "collision":
        for item in terrain:
            draw.rectangle(rect(item, scale), fill=(36, 51, 63, 145))
        for item in terrain:
            draw.rectangle(rect(item, scale), fill=COLLISION_FILL, outline=COLLISION_EDGE, width=max(1, scale // 3))

    draw_entities(draw, map_data, scale)
    draw_survey_targets(draw, map_data, scale)
    draw_grid(draw, width_tiles, height_tiles, scale)
    draw.rectangle((0, 0, width_tiles * scale - 1, height_tiles * scale - 1), outline=(196, 226, 232, 180), width=2)
    return image


def fit_capture(path: Path, size: tuple[int, int]) -> Image.Image:
    capture = Image.open(path).convert("RGBA")
    return ImageOps.fit(capture, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def render_review(map_data: dict, godot_capture: Path) -> Image.Image:
    units = map_data["units"]
    width_tiles = int(units["width_tiles"])
    height_tiles = int(units["height_tiles"])
    scale = max(2, min(8, 540 // max(width_tiles, height_tiles)))
    panel_size = (width_tiles * scale, height_tiles * scale)

    source_panel = draw_map_panel(map_data, "source", scale)
    collision_panel = draw_map_panel(map_data, "collision", scale)
    godot_panel = fit_capture(godot_capture, panel_size)

    margin = 18
    header_h = 92
    label_h = 32
    footer_h = 62
    width = margin * 4 + panel_size[0] * 3
    height = header_h + label_h + panel_size[1] + footer_h + margin
    review = Image.new("RGBA", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(review)
    title_font = load_font(20)
    label_font = load_font(15)
    small_font = load_font(13)

    map_id = str(map_data.get("id", "greybox_map"))
    terrain = [item for item in map_data.get("terrain", []) if item.get("type") == "solid"]
    stats = "%s | %dx%d tiles | %d solid cells | %d collision rects" % (
        map_id,
        width_tiles,
        height_tiles,
        cell_count(terrain),
        len(terrain),
    )
    draw.text((margin, 18), "Source / Render / Collision Review", fill=TEXT, font=title_font)
    draw.text((margin, 48), stats, fill=MUTED_TEXT, font=small_font)
    draw.text((margin, 68), "Collision panel uses JSON terrain rectangles; run parity to verify Godot runtime cells match.", fill=MUTED_TEXT, font=small_font)

    labels = [
        ("Authored JSON topology", source_panel),
        ("Expected collision footprint", collision_panel),
        ("Godot rendered overview", godot_panel),
    ]
    x = margin
    y = header_h
    for label, panel in labels:
        draw.rectangle((x, y, x + panel_size[0], y + label_h + panel_size[1]), fill=PANEL_BACKGROUND)
        draw.text((x + 8, y + 8), label, fill=TEXT, font=label_font)
        review.alpha_composite(panel, (x, y + label_h))
        x += panel_size[0] + margin

    footer_y = header_h + label_h + panel_size[1] + 16
    capture_label = godot_capture.relative_to(ROOT).as_posix() if godot_capture.is_relative_to(ROOT) else str(godot_capture)
    draw.text((margin, footer_y), f"Godot capture: {capture_label}", fill=MUTED_TEXT, font=small_font)
    draw.text((margin, footer_y + 22), "Open/solid/collision should agree in shape; visual art may differ in texture and edge treatment only.", fill=MUTED_TEXT, font=small_font)
    return review.convert("RGB")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path)
    parser.add_argument("output_png", type=Path)
    parser.add_argument(
        "--godot-capture",
        type=Path,
        default=ROOT / "visual_captures" / "production_slice_01" / "production_slice_overview.png",
        help="Godot overview capture to include in the rendered panel.",
    )
    args = parser.parse_args()

    map_path = args.map_json if args.map_json.is_absolute() else ROOT / args.map_json
    capture_path = args.godot_capture if args.godot_capture.is_absolute() else ROOT / args.godot_capture
    with map_path.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)
    if not capture_path.exists():
        raise FileNotFoundError(f"Missing Godot capture: {capture_path}")

    output_path = args.output_png if args.output_png.is_absolute() else ROOT / args.output_png
    output_path.parent.mkdir(parents=True, exist_ok=True)
    render_review(map_data, capture_path).save(output_path)
    print(f"Wrote {output_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
