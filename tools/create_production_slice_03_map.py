#!/usr/bin/env python3
"""Create the third focused production-slice greybox map."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
OUTPUT_MAP_PATH = ROOT / "maps" / "production_slice_03.greybox.json"

SLICE_BOUNDS = {"x": 0, "y": 8, "w": 76, "h": 82}
TILE_SIZE = 32
ENTRY = (67, 27)


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
        raise ValueError(f"Production slice 03 entry {entry} is inside solid terrain.")

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
        "id": "production_slice_03",
        "version": 1,
        "purpose": (
            "Third focused production-slice map from the upper-left room cluster of the supplied full cave sketch. "
            "This slice tests compact stacked-room navigation and a connector relay back toward the larger cave."
        ),
        "source": {
            "map": "maps/full_cave_sketch_01.greybox.json",
            "slice_bounds": SLICE_BOUNDS,
            "slice_role": "connector_landmark_room_cluster",
            "spawn_plan": (
                "Use an in-water relay spawn plus a base extraction zone near the east-side connector. "
                "The player enters from larger-map context, explores the upper-left cluster, and returns to the relay."
            ),
            "cleanup": {
                "sealed_edges": ["left", "right", "top", "bottom"],
                "filled_unreachable_open_cells": filled_open_cells,
                "notes": [
                    "The original full sketch map is left untouched for comparison.",
                    "Source sketch icons are ignored; gameplay objects are reauthored as JSON entities.",
                    "All crop edges are sealed so this upper-left cluster behaves as a bounded connector review slice.",
                    "No topology smoothing is applied in this first pass; the slice intentionally preserves high-fidelity sketch steps.",
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
            "base": "In-water relay/extraction zone for this connector slice",
            "spawn": "In-water relay entry point",
            "salvage": "Collectible objective",
            "hazard": "Avoidance pressure marker",
            "marker": "Non-gameplay annotation",
        },
        "terrain": row_run_terrain(solid),
        "zones": [
            {
                "id": "production_slice_03_bounds",
                "type": "marker",
                "x": 0,
                "y": 0,
                "w": SLICE_BOUNDS["w"],
                "h": SLICE_BOUNDS["h"],
                "intent": "Full extent of the third production slice crop.",
            },
            {
                "id": "relay_extraction_zone",
                "type": "base",
                "x": 62,
                "y": 24,
                "w": 11,
                "h": 7,
                "intent": "In-water relay entry and return zone placed in the east connector context.",
            },
            {
                "id": "east_connector_route",
                "type": "marker",
                "x": 53,
                "y": 17,
                "w": 22,
                "h": 22,
                "intent": "Connector context between the upper-left cluster and the larger central cave.",
            },
            {
                "id": "stacked_room_route",
                "type": "marker",
                "x": 7,
                "y": 7,
                "w": 26,
                "h": 32,
                "intent": "Compact upper-left stacked rooms and short room-to-room movement test.",
            },
            {
                "id": "central_crossing_route",
                "type": "marker",
                "x": 24,
                "y": 18,
                "w": 33,
                "h": 25,
                "intent": "Middle crossing that connects the stacked room cluster to the relay connector.",
            },
            {
                "id": "lower_return_route",
                "type": "marker",
                "x": 12,
                "y": 51,
                "w": 50,
                "h": 22,
                "intent": "Lower return path and deeper cluster context for a longer salvage route.",
            },
        ],
        "background": [
            {"id": "distant_stacked_rooms", "type": "background", "x": 8, "y": 8, "w": 20, "h": 28},
            {"id": "distant_connector_wall", "type": "background", "x": 51, "y": 16, "w": 23, "h": 23},
            {"id": "distant_central_crossing", "type": "background", "x": 27, "y": 20, "w": 26, "h": 24},
            {"id": "distant_lower_return", "type": "background", "x": 17, "y": 52, "w": 40, "h": 18},
        ],
        "entities": [
            {
                "id": "relay_sub_entry",
                "type": "spawn",
                "x": ENTRY[0],
                "y": ENTRY[1],
                "facing": "left",
                "intent": "In-water entry point for the connector relay/extraction zone.",
            },
            {"id": "salvage_upper_left_cache", "type": "salvage", "x": 13, "y": 14, "kind": "crate"},
            {"id": "salvage_stacked_room_relic", "type": "salvage", "x": 13, "y": 27, "kind": "relic"},
            {"id": "salvage_crossing_wreck", "type": "salvage", "x": 38, "y": 29, "kind": "wreck_fragment"},
            {"id": "salvage_lower_room_cache", "type": "salvage", "x": 24, "y": 62, "kind": "crate"},
            {"id": "salvage_return_route_relic", "type": "salvage", "x": 57, "y": 64, "kind": "relic"},
            {"id": "hazard_stacked_room_choke", "type": "hazard", "x": 22, "y": 28, "kind": "mine"},
            {"id": "hazard_connector_column", "type": "hazard", "x": 44, "y": 35, "kind": "jellyfish"},
            {"id": "hazard_lower_return_gate", "type": "hazard", "x": 46, "y": 63, "kind": "mine"},
        ],
        "camera_tests": [
            {
                "id": "production_slice_03_overview",
                "center_x": 38,
                "center_y": 41,
                "zoom": 0.46,
                "intent": "Third slice overview showing stacked rooms, connector relay, and lower return context.",
            },
            {
                "id": "production_slice_03_relay_entry",
                "center_x": 64,
                "center_y": 28,
                "zoom": 0.68,
                "intent": "In-water relay spawn, extraction zone, and east-side connector context review.",
            },
            {
                "id": "production_slice_03_stacked_rooms",
                "center_x": 18,
                "center_y": 24,
                "zoom": 0.64,
                "intent": "Compact upper-left room stack and nearby salvage/hazard review.",
            },
            {
                "id": "production_slice_03_connector",
                "center_x": 43,
                "center_y": 30,
                "zoom": 0.66,
                "intent": "Central crossing between the stacked rooms and connector relay.",
            },
            {
                "id": "production_slice_03_return_route",
                "center_x": 38,
                "center_y": 62,
                "zoom": 0.58,
                "intent": "Lower return path and deeper salvage context before returning to the relay.",
            },
        ],
        "review_questions": [
            "Does this slice read as a compact upper-left room cluster instead of another broad chamber?",
            "Does the east-side relay feel like believable larger-map context without forcing a top-water boat?",
            "Do the stacked rooms, central crossing, and lower return route create distinct route reads?",
            "Do the sealed crop edges feel like bounded cave walls rather than arbitrary cutoffs?",
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
