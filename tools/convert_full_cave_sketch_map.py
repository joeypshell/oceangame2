#!/usr/bin/env python3
"""Convert the supplied full cave sketch image into a greybox JSON draft."""

from __future__ import annotations

import json
import math
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_IMAGE = ROOT / "references" / "source_maps" / "full_cave_sketch_01.png"
MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
PREVIEW_PATH = ROOT / "references" / "greybox" / "full_cave_sketch_01.svg"
REVIEW_PATH = ROOT / "references" / "greybox" / "full_cave_sketch_01_conversion_review.png"

MAP_ID = "full_cave_sketch_01"
GODOT_TILE_SIZE_PX = 32
SOURCE_PIXELS_PER_TILE = 12
OPEN_PIXEL_THRESHOLD = 245
OPEN_TILE_FRACTION = 0.45
ICON_HOLE_FILL_LIMIT_PX = 9000
REVIEW_TILE_SCALE = 6
REVIEW_PANEL_GAP = 18
REVIEW_HEADER_HEIGHT = 30
REVIEW_FOOTER_HEIGHT = 104


def is_open_white(pixel: tuple[int, int, int]) -> bool:
    return min(pixel) >= OPEN_PIXEL_THRESHOLD


def build_open_pixel_mask(image: Image.Image) -> bytearray:
    width, height = image.size
    pixels = image.load()
    mask = bytearray(width * height)
    for y in range(height):
        row_offset = y * width
        for x in range(width):
            if is_open_white(pixels[x, y]):
                mask[row_offset + x] = 1
    return mask


def fill_small_non_open_holes(open_mask: bytearray, width: int, height: int) -> bytearray:
    filled = bytearray(open_mask)
    visited = bytearray(width * height)

    for y_start in range(height):
        for x_start in range(width):
            start_index = y_start * width + x_start
            if open_mask[start_index] or visited[start_index]:
                continue

            queue: deque[tuple[int, int]] = deque([(x_start, y_start)])
            visited[start_index] = 1
            component: list[tuple[int, int]] = []
            touches_border = False

            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                if x == 0 or y == 0 or x == width - 1 or y == height - 1:
                    touches_border = True

                for next_x, next_y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if next_x < 0 or next_y < 0 or next_x >= width or next_y >= height:
                        continue
                    next_index = next_y * width + next_x
                    if open_mask[next_index] or visited[next_index]:
                        continue
                    visited[next_index] = 1
                    queue.append((next_x, next_y))

            if not touches_border and len(component) <= ICON_HOLE_FILL_LIMIT_PX:
                for x, y in component:
                    filled[y * width + x] = 1

    return filled


def rasterize_open_cells(open_mask: bytearray, width: int, height: int) -> set[tuple[int, int]]:
    width_tiles = math.ceil(width / SOURCE_PIXELS_PER_TILE)
    height_tiles = math.ceil(height / SOURCE_PIXELS_PER_TILE)
    open_cells: set[tuple[int, int]] = set()

    for tile_y in range(height_tiles):
        y_start = tile_y * SOURCE_PIXELS_PER_TILE
        y_end = min(height, y_start + SOURCE_PIXELS_PER_TILE)
        for tile_x in range(width_tiles):
            x_start = tile_x * SOURCE_PIXELS_PER_TILE
            x_end = min(width, x_start + SOURCE_PIXELS_PER_TILE)
            total_pixels = (x_end - x_start) * (y_end - y_start)
            open_pixels = 0
            for y in range(y_start, y_end):
                row_offset = y * width
                open_pixels += sum(open_mask[row_offset + x_start : row_offset + x_end])

            if open_pixels / total_pixels >= OPEN_TILE_FRACTION:
                open_cells.add((tile_x, tile_y))

    return open_cells


def merge_solid_cells_to_rects(
    open_cells: set[tuple[int, int]], width_tiles: int, height_tiles: int
) -> list[dict]:
    rects: list[tuple[int, int, int, int]] = []
    active: dict[tuple[int, int], tuple[int, int, int, int]] = {}

    for y in range(height_tiles):
        row_runs: list[tuple[int, int]] = []
        x = 0
        while x < width_tiles:
            if (x, y) in open_cells:
                x += 1
                continue
            start_x = x
            while x < width_tiles and (x, y) not in open_cells:
                x += 1
            row_runs.append((start_x, x - start_x))

        next_active: dict[tuple[int, int], tuple[int, int, int, int]] = {}
        for start_x, width in row_runs:
            key = (start_x, width)
            if key in active:
                rect_x, rect_y, rect_w, rect_h = active[key]
                next_active[key] = (rect_x, rect_y, rect_w, rect_h + 1)
            else:
                next_active[key] = (start_x, y, width, 1)

        for key, rect in active.items():
            if key not in next_active:
                rects.append(rect)
        active = next_active

    rects.extend(active.values())

    return [
        {
            "id": f"solid_y{y:03d}_x{x:03d}_{x + width - 1:03d}",
            "type": "solid",
            "x": x,
            "y": y,
            "w": width,
            "h": height,
        }
        for x, y, width, height in rects
    ]


def open_components(open_cells: set[tuple[int, int]]) -> list[list[tuple[int, int]]]:
    remaining = set(open_cells)
    components: list[list[tuple[int, int]]] = []
    while remaining:
        start = remaining.pop()
        component = [start]
        queue: deque[tuple[int, int]] = deque([start])
        while queue:
            x, y = queue.popleft()
            for neighbor in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if neighbor not in remaining:
                    continue
                remaining.remove(neighbor)
                component.append(neighbor)
                queue.append(neighbor)
        components.append(component)
    components.sort(key=len, reverse=True)
    return components


def conversion_stats(
    raw_open_pixel_mask: bytearray,
    cleaned_open_pixel_mask: bytearray,
    open_cells: set[tuple[int, int]],
    components: list[list[tuple[int, int]]],
    width_tiles: int,
    height_tiles: int,
) -> dict:
    tile_count = width_tiles * height_tiles
    raw_open_pixels = sum(raw_open_pixel_mask)
    cleaned_open_pixels = sum(cleaned_open_pixel_mask)
    return {
        "raw_open_pixels": raw_open_pixels,
        "filled_icon_pixels": cleaned_open_pixels - raw_open_pixels,
        "open_tiles": len(open_cells),
        "solid_tiles": tile_count - len(open_cells),
        "open_tile_ratio": round(len(open_cells) / tile_count, 4),
        "open_component_count": len(components),
        "largest_open_components": [len(component) for component in components[:8]],
        "thin_corridor_tiles": count_thin_corridor_tiles(open_cells),
        "open_solid_edge_transitions": count_open_solid_edge_transitions(open_cells, width_tiles, height_tiles),
        "open_boundary_tiles": count_open_boundary_tiles(open_cells, width_tiles, height_tiles),
    }


def count_thin_corridor_tiles(open_cells: set[tuple[int, int]]) -> int:
    total = 0
    for x, y in open_cells:
        open_neighbors = sum(
            neighbor in open_cells
            for neighbor in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
        )
        if open_neighbors <= 2:
            total += 1
    return total


def count_open_solid_edge_transitions(
    open_cells: set[tuple[int, int]], width_tiles: int, height_tiles: int
) -> int:
    transitions = 0
    for y in range(height_tiles):
        for x in range(width_tiles):
            is_open = (x, y) in open_cells
            for nx, ny in ((x + 1, y), (x, y + 1)):
                if nx >= width_tiles or ny >= height_tiles:
                    continue
                if ((nx, ny) in open_cells) != is_open:
                    transitions += 1
    return transitions


def count_open_boundary_tiles(open_cells: set[tuple[int, int]], width_tiles: int, height_tiles: int) -> int:
    return sum(
        1
        for x, y in open_cells
        if x == 0 or y == 0 or x == width_tiles - 1 or y == height_tiles - 1
    )


def top_water_entry(open_cells: set[tuple[int, int]], width_tiles: int) -> tuple[int, int]:
    top_band_limit = max(1, int(width_tiles * 0.18))
    candidates = sorted(open_cells, key=lambda cell: (cell[1], abs(cell[0] - width_tiles // 2)))
    for x, y in candidates:
        if abs(x - width_tiles // 2) <= top_band_limit:
            return x, y
    return candidates[0]


def camera_tests(width_tiles: int, height_tiles: int, boat_entry_x: int, boat_entry_y: int) -> list[dict]:
    return [
        {
            "id": "full_sketch_overview",
            "center_x": width_tiles / 2,
            "center_y": height_tiles / 2,
            "zoom": 0.13,
            "intent": "Whole-map topology review for the supplied high-fidelity cave sketch draft.",
        },
        {
            "id": "full_sketch_boat_entry",
            "center_x": boat_entry_x + 4,
            "center_y": boat_entry_y + 8,
            "zoom": 0.55,
            "intent": "Top-water boat_spawn entry and extraction marker review.",
        },
        {
            "id": "full_sketch_upper_left",
            "center_x": width_tiles * 0.25,
            "center_y": height_tiles * 0.25,
            "zoom": 0.34,
            "intent": "Upper-left route and room structure review.",
        },
        {
            "id": "full_sketch_center_crossing",
            "center_x": width_tiles * 0.52,
            "center_y": height_tiles * 0.43,
            "zoom": 0.32,
            "intent": "Central crossing and branching route review.",
        },
        {
            "id": "full_sketch_lower_right",
            "center_x": width_tiles * 0.74,
            "center_y": height_tiles * 0.70,
            "zoom": 0.30,
            "intent": "Lower-right chamber and long route review.",
        },
    ]


def draw_review_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str) -> None:
    font = ImageFont.load_default()
    x, y = xy
    bbox = draw.textbbox((x, y), value, font=font)
    draw.rectangle((bbox[0] - 4, bbox[1] - 3, bbox[2] + 4, bbox[3] + 3), fill=(8, 18, 24))
    draw.text((x, y), value, fill=(235, 250, 255), font=font)


def draw_major_grid(draw: ImageDraw.ImageDraw, width_tiles: int, height_tiles: int, scale: int) -> None:
    grid_color = (255, 255, 255, 46)
    for x in range(0, width_tiles + 1, 10):
        px = x * scale
        draw.line((px, 0, px, height_tiles * scale), fill=grid_color)
    for y in range(0, height_tiles + 1, 10):
        py = y * scale
        draw.line((0, py, width_tiles * scale, py), fill=grid_color)


def draw_boat_marker(draw: ImageDraw.ImageDraw, map_data: dict, offset_x: int, offset_y: int, scale: int) -> None:
    for entity in map_data.get("entities", []):
        if entity.get("type") != "boat_spawn":
            continue
        x = offset_x + int(entity["x"]) * scale
        y = offset_y + int(entity["y"]) * scale
        w = int(entity["w"]) * scale
        h = int(entity["h"]) * scale
        draw.rectangle((x, y, x + w, y + h), outline=(255, 184, 70), width=2)
        entry_x = offset_x + int(entity["entry_x"]) * scale + scale // 2
        entry_y = offset_y + int(entity["entry_y"]) * scale + scale // 2
        draw.ellipse((entry_x - 4, entry_y - 4, entry_x + 4, entry_y + 4), fill=(255, 212, 90))


def generated_tile_panel(open_cells: set[tuple[int, int]], width_tiles: int, height_tiles: int, scale: int) -> Image.Image:
    panel = Image.new("RGBA", (width_tiles * scale, height_tiles * scale), (36, 48, 60, 255))
    draw = ImageDraw.Draw(panel, "RGBA")
    for x, y in open_cells:
        draw.rectangle(
            (x * scale, y * scale, (x + 1) * scale - 1, (y + 1) * scale - 1),
            fill=(38, 186, 232, 255),
        )
    draw_major_grid(draw, width_tiles, height_tiles, scale)
    return panel


def overlay_panel(
    source_panel: Image.Image, open_cells: set[tuple[int, int]], width_tiles: int, height_tiles: int, scale: int
) -> Image.Image:
    overlay = source_panel.convert("RGBA")
    draw = ImageDraw.Draw(overlay, "RGBA")
    for y in range(height_tiles):
        for x in range(width_tiles):
            fill = (15, 195, 245, 112) if (x, y) in open_cells else (12, 22, 30, 126)
            draw.rectangle((x * scale, y * scale, (x + 1) * scale - 1, (y + 1) * scale - 1), fill=fill)
    draw_major_grid(draw, width_tiles, height_tiles, scale)
    return overlay


def write_conversion_review_artifact(
    image: Image.Image,
    open_cells: set[tuple[int, int]],
    map_data: dict,
    stats: dict,
    output_path: Path,
) -> None:
    width_tiles = int(map_data["units"]["width_tiles"])
    height_tiles = int(map_data["units"]["height_tiles"])
    scale = REVIEW_TILE_SCALE
    panel_width = width_tiles * scale
    panel_height = height_tiles * scale
    canvas_width = panel_width * 3 + REVIEW_PANEL_GAP * 2
    canvas_height = REVIEW_HEADER_HEIGHT + panel_height + REVIEW_FOOTER_HEIGHT

    source_panel = image.resize((width_tiles, height_tiles), Image.Resampling.LANCZOS)
    source_panel = source_panel.resize((panel_width, panel_height), Image.Resampling.NEAREST).convert("RGBA")
    generated_panel = generated_tile_panel(open_cells, width_tiles, height_tiles, scale)
    combined_panel = overlay_panel(source_panel, open_cells, width_tiles, height_tiles, scale)

    canvas = Image.new("RGB", (canvas_width, canvas_height), (18, 24, 30))
    panel_offsets = [
        0,
        panel_width + REVIEW_PANEL_GAP,
        panel_width * 2 + REVIEW_PANEL_GAP * 2,
    ]
    for offset, panel in zip(panel_offsets, [source_panel, generated_panel, combined_panel]):
        canvas.paste(panel.convert("RGB"), (offset, REVIEW_HEADER_HEIGHT))

    draw = ImageDraw.Draw(canvas)
    draw_review_label(draw, (8, 9), "Source sketch thumbnail")
    draw_review_label(draw, (panel_offsets[1] + 8, 9), "Generated open/solid tiles")
    draw_review_label(draw, (panel_offsets[2] + 8, 9), "Source + generated overlay")
    draw_boat_marker(draw, map_data, panel_offsets[1], REVIEW_HEADER_HEIGHT, scale)
    draw_boat_marker(draw, map_data, panel_offsets[2], REVIEW_HEADER_HEIGHT, scale)

    footer_y = REVIEW_HEADER_HEIGHT + panel_height + 12
    stat_lines = [
        f"open tiles: {stats['open_tiles']} / {width_tiles * height_tiles} ({stats['open_tile_ratio']})",
        f"filled icon/non-white pixels: {stats['filled_icon_pixels']}",
        f"open components: {stats['open_component_count']} largest={stats['largest_open_components'][:4]}",
        f"thin corridor tiles: {stats['thin_corridor_tiles']} | open-solid edge transitions: {stats['open_solid_edge_transitions']}",
        f"open boundary tiles: {stats['open_boundary_tiles']} | tile scale: {SOURCE_PIXELS_PER_TILE} source px per tile",
    ]
    for index, line in enumerate(stat_lines):
        draw.text((12, footer_y + index * 16), line, fill=(225, 238, 242), font=ImageFont.load_default())

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path)


def build_map() -> tuple[dict, Image.Image, set[tuple[int, int]], dict]:
    image = Image.open(SOURCE_IMAGE).convert("RGB")
    source_width, source_height = image.size
    width_tiles = math.ceil(source_width / SOURCE_PIXELS_PER_TILE)
    height_tiles = math.ceil(source_height / SOURCE_PIXELS_PER_TILE)

    open_pixel_mask = build_open_pixel_mask(image)
    cleaned_open_pixel_mask = fill_small_non_open_holes(open_pixel_mask, source_width, source_height)
    open_cells = rasterize_open_cells(cleaned_open_pixel_mask, source_width, source_height)
    components = open_components(open_cells)
    stats = conversion_stats(open_pixel_mask, cleaned_open_pixel_mask, open_cells, components, width_tiles, height_tiles)
    boat_entry_x, boat_entry_y = top_water_entry(set(components[0]), width_tiles)
    boat_width = min(8, width_tiles - boat_entry_x)

    map_data = {
        "id": MAP_ID,
        "version": 0,
        "purpose": (
            "Draft 0 high-fidelity topology conversion from supplied full cave sketch. "
            "Icons and gameplay props are intentionally ignored; only open/solid cave topology is represented."
        ),
        "source": {
            "image": "references/source_maps/full_cave_sketch_01.png",
            "source_pixels": {"w": source_width, "h": source_height},
            "source_pixels_per_tile": SOURCE_PIXELS_PER_TILE,
            "open_pixel_threshold": OPEN_PIXEL_THRESHOLD,
            "open_tile_fraction": OPEN_TILE_FRACTION,
            "icon_hole_fill_limit_px": ICON_HOLE_FILL_LIMIT_PX,
            "open_components": [len(component) for component in components[:8]],
            "conversion_stats": stats,
            "review_artifact": "references/greybox/full_cave_sketch_01_conversion_review.png",
            "notes": [
                "White source pixels are treated as playable open water.",
                "Gray and black source pixels are treated as solid terrain/collision.",
                "Small non-white holes fully enclosed by open water are filled to ignore icon/properties for topology draft 0.",
                "A boat_spawn entity marks the top-water entry/extraction point for validation and preview.",
                "The conversion review artifact compares the source thumbnail, generated tile classification, and overlay.",
            ],
        },
        "units": {
            "tile_size_px": GODOT_TILE_SIZE_PX,
            "width_tiles": width_tiles,
            "height_tiles": height_tiles,
        },
        "legend": {
            "water": "Open swimmable space inferred from white source regions",
            "solid": "Collision terrain inferred from gray and black source regions",
            "boat_spawn": "Top-water boat entry and extraction marker",
            "marker": "Non-gameplay annotation",
        },
        "terrain": merge_solid_cells_to_rects(open_cells, width_tiles, height_tiles),
        "zones": [
            {
                "id": "full_sketch_source_bounds",
                "type": "marker",
                "x": 0,
                "y": 0,
                "w": width_tiles,
                "h": height_tiles,
                "intent": "Full extent of the supplied source sketch conversion.",
            }
        ],
        "background": [],
        "entities": [
            {
                "id": "surface_boat_entry",
                "type": "boat_spawn",
                "x": boat_entry_x,
                "y": boat_entry_y,
                "w": boat_width,
                "h": 1,
                "entry_x": boat_entry_x,
                "entry_y": boat_entry_y,
                "facing": "right",
                "intent": "Top-water boat spawn and extraction marker for the draft full-map topology.",
            }
        ],
        "camera_tests": camera_tests(width_tiles, height_tiles, boat_entry_x, boat_entry_y),
        "review_questions": [
            "Does the converted topology preserve the major room, corridor, and loop structure from the source sketch?",
            "Did icon removal accidentally open or close any meaningful passages?",
            "Is 12 source pixels per Godot tile high-fidelity enough, or too noisy for production iteration?",
            "Should future passes split this into authored regions or preserve the whole-map scale?",
        ],
    }
    return map_data, image, open_cells, stats


def main() -> int:
    map_data, image, open_cells, stats = build_map()
    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    MAP_PATH.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8")
    write_conversion_review_artifact(image, open_cells, map_data, stats, REVIEW_PATH)
    print(f"Wrote {MAP_PATH.relative_to(ROOT)}")
    print(f"Wrote {REVIEW_PATH.relative_to(ROOT)}")
    print(
        "Conversion stats: "
        f"open_tiles={stats['open_tiles']} "
        f"solid_tiles={stats['solid_tiles']} "
        f"components={stats['open_component_count']} "
        f"thin_corridor_tiles={stats['thin_corridor_tiles']} "
        f"edge_transitions={stats['open_solid_edge_transitions']}"
    )
    print(f"Render preview with: python tools/render_greybox_map.py {MAP_PATH.relative_to(ROOT)} {PREVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
