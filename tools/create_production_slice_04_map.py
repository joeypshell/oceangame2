#!/usr/bin/env python3
"""Create the fourth focused production-slice greybox map."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
OUTPUT_MAP_PATH = ROOT / "maps" / "production_slice_04.greybox.json"

SLICE_BOUNDS = {"x": 0, "y": 86, "w": 88, "h": 50}
TILE_SIZE = 32
ENTRY = (74, 18)


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
        raise ValueError(f"Production slice 04 entry {entry} is inside solid terrain.")

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
        "id": "production_slice_04",
        "version": 1,
        "purpose": (
            "Fourth focused production-slice map from the lower-left loop of the supplied full cave sketch. "
            "This slice tests a longer connector/return loop and curved-corridor cleanup cost."
        ),
        "source": {
            "map": "maps/full_cave_sketch_01.greybox.json",
            "slice_bounds": SLICE_BOUNDS,
            "slice_role": "connector_return_loop",
            "spawn_plan": (
                "Use an in-water relay spawn plus a base extraction zone near the east-side connector. "
                "The player enters from larger-map context, explores the lower-left loop, and returns to the relay."
            ),
            "cleanup": {
                "sealed_edges": ["left", "right", "top", "bottom"],
                "filled_unreachable_open_cells": filled_open_cells,
                "notes": [
                    "The original full sketch map is left untouched for comparison.",
                    "Source sketch icons are ignored; gameplay objects are reauthored as JSON entities.",
                    "All crop edges are sealed so this lower-left loop behaves as a bounded connector review slice.",
                    "No topology smoothing is applied in this first pass; curved sketch steps remain visible for review.",
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
            "base": "In-water relay/extraction zone for this connector loop slice",
            "spawn": "In-water relay entry point",
            "salvage": "Collectible objective",
            "hazard": "Avoidance pressure marker",
            "marker": "Non-gameplay annotation",
        },
        "terrain": row_run_terrain(solid),
        "zones": [
            {
                "id": "production_slice_04_bounds",
                "type": "marker",
                "x": 0,
                "y": 0,
                "w": SLICE_BOUNDS["w"],
                "h": SLICE_BOUNDS["h"],
                "intent": "Full extent of the fourth production slice crop.",
            },
            {
                "id": "relay_extraction_zone",
                "type": "base",
                "x": 68,
                "y": 15,
                "w": 13,
                "h": 7,
                "intent": "In-water relay entry and return zone placed in the east connector context.",
            },
            {
                "id": "east_connector_route",
                "type": "marker",
                "x": 61,
                "y": 11,
                "w": 25,
                "h": 18,
                "intent": "Connector context between the lower-left loop and the larger central cave.",
            },
            {
                "id": "return_to_boat_hub_connector",
                "type": "marker",
                "x": 70,
                "y": 17,
                "w": 7,
                "h": 3,
                "world_connector": True,
                "connector_label": "Boat hub",
                "destination_map_id": "production_slice_01",
                "destination_map_path": "res://maps/production_slice_01.greybox.json",
                "destination_entry_id": "surface_boat_entry",
                "connector_direction": "return",
                "intent": "Pass 21 return connector from the lower-left relay back toward the default boat hub.",
            },
            {
                "id": "upper_loop_route",
                "type": "marker",
                "x": 8,
                "y": 7,
                "w": 48,
                "h": 23,
                "intent": "Upper portion of the lower-left loop and first route-turn review.",
            },
            {
                "id": "lower_left_loop_route",
                "type": "marker",
                "x": 10,
                "y": 23,
                "w": 42,
                "h": 23,
                "intent": "Lower-left curved corridor and branch-turnaround route review.",
            },
            {
                "id": "return_route",
                "type": "marker",
                "x": 42,
                "y": 24,
                "w": 35,
                "h": 22,
                "intent": "Return path from the lower-left objectives back toward the relay extraction zone.",
            },
        ],
        "background": [
            {"id": "distant_upper_loop", "type": "background", "x": 10, "y": 8, "w": 38, "h": 17},
            {"id": "distant_lower_left_loop", "type": "background", "x": 12, "y": 26, "w": 34, "h": 18},
            {"id": "distant_return_wall", "type": "background", "x": 45, "y": 25, "w": 28, "h": 18},
            {"id": "distant_relay_context", "type": "background", "x": 64, "y": 12, "w": 21, "h": 17},
        ],
        "entities": [
            {
                "id": "relay_sub_entry",
                "type": "spawn",
                "x": ENTRY[0],
                "y": ENTRY[1],
                "facing": "left",
                "intent": "In-water entry point for the lower-left loop relay/extraction zone.",
            },
            {"id": "salvage_left_pocket", "type": "salvage", "x": 15, "y": 10, "kind": "crate"},
            {"id": "salvage_upper_turn_relic", "type": "salvage", "x": 33, "y": 9, "kind": "relic"},
            {
                "id": "slice_04_destination_cache",
                "type": "salvage",
                "x": 18,
                "y": 23,
                "kind": "relic",
                "tier": "valuable",
                "route_choice_id": "slice_04_destination_cache",
                "validation_route": "slice_04_destination_payoff",
                "destination_payoff_id": "slice_04_destination_payoff",
                "destination_payoff_label": "Destination cache",
                "destination_payoff_connector_id": "lower_left_loop_connector",
                "intent": "Pass 22 destination-side payoff for using the lower-left connector into production_slice_04.",
            },
            {"id": "salvage_mid_loop_wreck", "type": "salvage", "x": 44, "y": 27, "kind": "wreck_fragment"},
            {"id": "salvage_lower_turn_cache", "type": "salvage", "x": 24, "y": 35, "kind": "crate"},
            {"id": "salvage_return_relic", "type": "salvage", "x": 68, "y": 35, "kind": "relic"},
            {"id": "hazard_upper_choke", "type": "hazard", "x": 33, "y": 20, "kind": "mine"},
            {"id": "hazard_mid_bend", "type": "hazard", "x": 52, "y": 26, "kind": "jellyfish"},
            {"id": "hazard_lower_return", "type": "hazard", "x": 61, "y": 36, "kind": "mine"},
        ],
        "relay_follow_through_objectives": [
            {
                "id": "lower_left_relay_follow_through",
                "trigger": "destination_payoff_banked",
                "connector_id": "lower_left_loop_connector",
                "entry_id": "relay_sub_entry",
                "target_id": "slice_04_destination_cache",
                "label": "Relay lead confirmed",
                "result_label": "Lower-left relay investigated",
                "route_context": "lower_left_loop",
                "source_prompt_id": "deep_cache_next_dive_prompt",
                "intent": "Pass 24 follow-through for the Pass 23 next-dive prompt after reaching the lower-left relay destination cache.",
            },
        ],
        "camera_tests": [
            {
                "id": "production_slice_04_overview",
                "center_x": 44,
                "center_y": 25,
                "zoom": 0.45,
                "intent": "Fourth slice overview showing relay, lower-left loop, curved corridor, and return path.",
            },
            {
                "id": "production_slice_04_relay_entry",
                "center_x": 72,
                "center_y": 18,
                "zoom": 0.68,
                "intent": "In-water relay spawn, extraction zone, and east-side connector context review.",
            },
            {
                "id": "production_slice_04_lower_left_loop",
                "center_x": 22,
                "center_y": 22,
                "zoom": 0.64,
                "intent": "Lower-left loop pocket, first salvage spread, and route-turn review.",
            },
            {
                "id": "production_slice_04_curved_corridor",
                "center_x": 42,
                "center_y": 25,
                "zoom": 0.66,
                "intent": "Curved corridor and stair-stepped source conversion review.",
            },
            {
                "id": "production_slice_04_return_route",
                "center_x": 59,
                "center_y": 34,
                "zoom": 0.66,
                "intent": "Return route from loop objectives back to the relay extraction zone.",
            },
        ],
        "review_questions": [
            "Does this slice read as a lower-left connector loop instead of another chamber or first area?",
            "Does the east-side relay feel like believable larger-map context without forcing a top-water boat?",
            "Do the curved corridor bends create readable movement pressure without trapping the player?",
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
