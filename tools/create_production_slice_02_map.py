#!/usr/bin/env python3
"""Create the second focused production-slice greybox map."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
OUTPUT_MAP_PATH = ROOT / "maps" / "production_slice_02.greybox.json"

SLICE_BOUNDS = {"x": 88, "y": 78, "w": 66, "h": 72}
TILE_SIZE = 32
ENTRY = (8, 34)


def rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
    }


def crop_solid_cells(source_map: dict) -> set[tuple[int, int]]:
    bounds_x = SLICE_BOUNDS["x"]
    bounds_y = SLICE_BOUNDS["y"]
    bounds_w = SLICE_BOUNDS["w"]
    bounds_h = SLICE_BOUNDS["h"]
    cells: set[tuple[int, int]] = set()

    for item in source_map.get("terrain", []):
        if item.get("type") != "solid":
            continue
        for source_x, source_y in rect_cells(item):
            if not (bounds_x <= source_x < bounds_x + bounds_w):
                continue
            if not (bounds_y <= source_y < bounds_y + bounds_h):
                continue
            cells.add((source_x - bounds_x, source_y - bounds_y))

    return cells


def seal_slice_edges(cells: set[tuple[int, int]]) -> None:
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]
    for y in range(height):
        cells.add((0, y))
        cells.add((width - 1, y))
    for x in range(width):
        cells.add((x, 0))
        cells.add((x, height - 1))


def reachable_open_cells(solid: set[tuple[int, int]], entry: tuple[int, int]) -> set[tuple[int, int]]:
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]
    if entry in solid:
        raise ValueError(f"Production slice 02 entry {entry} is inside solid terrain.")

    reachable: set[tuple[int, int]] = {entry}
    queue: deque[tuple[int, int]] = deque([entry])
    while queue:
        x, y = queue.popleft()
        for neighbor in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            nx, ny = neighbor
            if nx < 0 or ny < 0 or nx >= width or ny >= height:
                continue
            if neighbor in solid or neighbor in reachable:
                continue
            reachable.add(neighbor)
            queue.append(neighbor)
    return reachable


def fill_unreachable_open_cells(solid: set[tuple[int, int]], entry: tuple[int, int]) -> int:
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]
    reachable = reachable_open_cells(solid, entry)
    open_cells = {(x, y) for y in range(height) for x in range(width) if (x, y) not in solid}
    unreachable = open_cells - reachable
    solid.update(unreachable)
    return len(unreachable)


def row_run_terrain(cells: set[tuple[int, int]]) -> list[dict]:
    terrain: list[dict] = []
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]

    for y in range(height):
        run_start: int | None = None
        for x in range(width + 1):
            solid = (x, y) in cells if x < width else False
            if solid and run_start is None:
                run_start = x
            elif not solid and run_start is not None:
                terrain.append(
                    {
                        "id": f"solid_y{y:02d}_x{run_start:02d}_{x - 1:02d}",
                        "type": "solid",
                        "x": run_start,
                        "y": y,
                        "w": x - run_start,
                        "h": 1,
                    }
                )
                run_start = None

    return terrain


def build_map_data(source_map: dict) -> dict:
    solid = crop_solid_cells(source_map)
    before_cleanup_solid_count = len(solid)
    seal_slice_edges(solid)
    filled_open_cells = fill_unreachable_open_cells(solid, ENTRY)

    return {
        "id": "production_slice_02",
        "version": 1,
        "purpose": (
            "Second focused production-slice map from the lower-right chamber route of the supplied full cave sketch. "
            "This slice is a later-game destination/connector candidate, not an alternate first area."
        ),
        "source": {
            "map": "maps/full_cave_sketch_01.greybox.json",
            "slice_bounds": SLICE_BOUNDS,
            "slice_role": "later_game_destination",
            "spawn_plan": (
                "Use an in-water relay spawn plus a base extraction zone because this region has no natural "
                "top-water boat opening. A future larger map would connect this relay to upstream routes."
            ),
            "cleanup": {
                "sealed_edges": ["left", "right", "top", "bottom"],
                "filled_unreachable_open_cells": filled_open_cells,
                "notes": [
                    "The original full sketch map is left untouched for comparison.",
                    "Source sketch icons are ignored; gameplay objects are reauthored as JSON entities.",
                    "All crop edges are sealed so the second slice behaves as a bounded later-game review chamber.",
                ],
            },
            "stats": {
                "cropped_solid_cells_before_cleanup": before_cleanup_solid_count,
                "solid_cells_after_cleanup": len(solid),
            },
        },
        "units": {
            "tile_size_px": TILE_SIZE,
            "width_tiles": SLICE_BOUNDS["w"],
            "height_tiles": SLICE_BOUNDS["h"],
        },
        "legend": {
            "water": "Open swimmable space preserved from the selected full-sketch region",
            "solid": "Collision terrain preserved from the selected full-sketch region or cleanup seal",
            "base": "In-water relay/extraction zone for this later-game slice",
            "spawn": "In-water relay entry point",
            "salvage": "Collectible objective",
            "hazard": "Avoidance pressure marker",
            "marker": "Non-gameplay annotation",
        },
        "terrain": row_run_terrain(solid),
        "zones": [
            {
                "id": "production_slice_02_bounds",
                "type": "marker",
                "x": 0,
                "y": 0,
                "w": SLICE_BOUNDS["w"],
                "h": SLICE_BOUNDS["h"],
                "intent": "Full extent of the second production slice crop.",
            },
            {
                "id": "relay_extraction_zone",
                "type": "base",
                "x": 4,
                "y": 32,
                "w": 9,
                "h": 5,
                "intent": "In-water relay entry and return zone for a later-game destination slice.",
            },
            {
                "id": "approach_route",
                "type": "marker",
                "x": 2,
                "y": 28,
                "w": 24,
                "h": 21,
                "intent": "Left-side approach and return path from the relay extraction zone.",
            },
            {
                "id": "main_chamber_route",
                "type": "marker",
                "x": 24,
                "y": 24,
                "w": 38,
                "h": 25,
                "intent": "Primary lower-right chamber, salvage spread, and route-pressure read.",
            },
            {
                "id": "lower_terminal_route",
                "type": "marker",
                "x": 10,
                "y": 61,
                "w": 53,
                "h": 9,
                "intent": "Lower terminal passage for a deeper optional salvage destination.",
            },
        ],
        "background": [
            {"id": "distant_relay_wall", "type": "background", "x": 5, "y": 30, "w": 18, "h": 16},
            {"id": "distant_main_chamber", "type": "background", "x": 30, "y": 25, "w": 30, "h": 21},
            {"id": "distant_lower_terminal", "type": "background", "x": 13, "y": 62, "w": 46, "h": 8},
        ],
        "entities": [
            {
                "id": "relay_sub_entry",
                "type": "spawn",
                "x": ENTRY[0],
                "y": ENTRY[1],
                "facing": "right",
                "intent": "In-water entry point for the later-game relay/extraction zone.",
            },
            {"id": "salvage_approach_wreck", "type": "salvage", "x": 12, "y": 44, "kind": "wreck_fragment"},
            {"id": "salvage_mid_ruin", "type": "salvage", "x": 29, "y": 35, "kind": "relic"},
            {"id": "salvage_right_chamber", "type": "salvage", "x": 51, "y": 29, "kind": "crate"},
            {"id": "salvage_lower_cache", "type": "salvage", "x": 18, "y": 66, "kind": "crate"},
            {"id": "salvage_terminal_relic", "type": "salvage", "x": 57, "y": 64, "kind": "relic"},
            {"id": "hazard_left_choke", "type": "hazard", "x": 22, "y": 28, "kind": "mine"},
            {"id": "hazard_mid_drop", "type": "hazard", "x": 39, "y": 40, "kind": "jellyfish"},
            {"id": "hazard_right_chamber", "type": "hazard", "x": 55, "y": 36, "kind": "mine"},
            {"id": "hazard_lower_gate", "type": "hazard", "x": 46, "y": 63, "kind": "jellyfish"},
        ],
        "camera_tests": [
            {
                "id": "production_slice_02_overview",
                "center_x": 33,
                "center_y": 48,
                "zoom": 0.62,
                "intent": "Second slice overview showing relay, chamber, and lower terminal context.",
            },
            {
                "id": "production_slice_02_relay_entry",
                "center_x": 17,
                "center_y": 39,
                "zoom": 0.70,
                "intent": "In-water relay spawn, extraction zone, and approach route review.",
            },
            {
                "id": "production_slice_02_main_chamber",
                "center_x": 39,
                "center_y": 36,
                "zoom": 0.70,
                "intent": "Main chamber salvage and hazard pressure review.",
            },
            {
                "id": "production_slice_02_lower_terminal",
                "center_x": 37,
                "center_y": 58,
                "zoom": 0.70,
                "intent": "Lower terminal passage and deeper destination review.",
            },
            {
                "id": "production_slice_02_return_route",
                "center_x": 26,
                "center_y": 47,
                "zoom": 0.70,
                "intent": "Return route from chamber objectives back to relay extraction.",
            },
        ],
        "review_questions": [
            "Does this slice read as a deeper destination/connector rather than another first area?",
            "Does the in-water relay extraction plan feel appropriate without forcing a top-water boat?",
            "Do the main chamber and lower terminal create distinct salvage route choices?",
            "Do sealed crop edges feel like natural cave boundaries rather than arbitrary cutoffs?",
        ],
    }


def main() -> int:
    with SOURCE_MAP_PATH.open("r", encoding="utf-8") as handle:
        source_map = json.load(handle)

    map_data = build_map_data(source_map)
    OUTPUT_MAP_PATH.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8")
    print(
        f"Wrote {OUTPUT_MAP_PATH.relative_to(ROOT)} with "
        f"{len(map_data['terrain'])} solid row runs."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
