#!/usr/bin/env python3
"""Convert the supplied full cave sketch image into a greybox JSON draft."""

from __future__ import annotations

import json
import math
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_IMAGE = ROOT / "references" / "source_maps" / "full_cave_sketch_01.png"
MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
PREVIEW_PATH = ROOT / "references" / "greybox" / "full_cave_sketch_01.svg"

MAP_ID = "full_cave_sketch_01"
GODOT_TILE_SIZE_PX = 32
SOURCE_PIXELS_PER_TILE = 12
OPEN_PIXEL_THRESHOLD = 245
OPEN_TILE_FRACTION = 0.45
ICON_HOLE_FILL_LIMIT_PX = 9000


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


def temporary_spawn(open_cells: set[tuple[int, int]], width_tiles: int) -> tuple[int, int]:
    top_band_limit = max(1, int(width_tiles * 0.18))
    candidates = sorted(open_cells, key=lambda cell: (cell[1], abs(cell[0] - width_tiles // 2)))
    for x, y in candidates:
        if abs(x - width_tiles // 2) <= top_band_limit:
            return x, y
    return candidates[0]


def camera_tests(width_tiles: int, height_tiles: int) -> list[dict]:
    return [
        {
            "id": "full_sketch_overview",
            "center_x": width_tiles / 2,
            "center_y": height_tiles / 2,
            "zoom": 0.13,
            "intent": "Whole-map topology review for the supplied high-fidelity cave sketch draft.",
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


def build_map() -> dict:
    image = Image.open(SOURCE_IMAGE).convert("RGB")
    source_width, source_height = image.size
    width_tiles = math.ceil(source_width / SOURCE_PIXELS_PER_TILE)
    height_tiles = math.ceil(source_height / SOURCE_PIXELS_PER_TILE)

    open_pixel_mask = build_open_pixel_mask(image)
    cleaned_open_pixel_mask = fill_small_non_open_holes(open_pixel_mask, source_width, source_height)
    open_cells = rasterize_open_cells(cleaned_open_pixel_mask, source_width, source_height)
    components = open_components(open_cells)
    spawn_x, spawn_y = temporary_spawn(set(components[0]), width_tiles)

    return {
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
            "notes": [
                "White source pixels are treated as playable open water.",
                "Gray and black source pixels are treated as solid terrain/collision.",
                "Small non-white holes fully enclosed by open water are filled to ignore icon/properties for topology draft 0.",
                "Temporary spawn is only for validation until boat/top-of-water spawning exists.",
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
            "spawn": "Temporary validation spawn only",
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
                "id": "temporary_validation_spawn",
                "type": "spawn",
                "x": spawn_x,
                "y": spawn_y,
                "facing": "right",
                "intent": "Temporary spawn for reachability validation; replace with boat spawn later.",
            }
        ],
        "camera_tests": camera_tests(width_tiles, height_tiles),
        "review_questions": [
            "Does the converted topology preserve the major room, corridor, and loop structure from the source sketch?",
            "Did icon removal accidentally open or close any meaningful passages?",
            "Is 12 source pixels per Godot tile high-fidelity enough, or too noisy for production iteration?",
            "Should future passes split this into authored regions or preserve the whole-map scale?",
        ],
    }


def main() -> int:
    map_data = build_map()
    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    MAP_PATH.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {MAP_PATH.relative_to(ROOT)}")
    print(f"Render preview with: python tools/render_greybox_map.py {MAP_PATH.relative_to(ROOT)} {PREVIEW_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
