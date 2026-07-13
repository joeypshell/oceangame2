#!/usr/bin/env python3
"""Create the first focused production-slice greybox map."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from production_slice_01_gameplay_source import gameplay_sections

ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
OUTPUT_MAP_PATH = ROOT / "maps" / "production_slice_01.greybox.json"

SLICE_BOUNDS = {"x": 58, "y": 0, "w": 72, "h": 84}
TILE_SIZE = 32
BOAT_ENTRY_SOURCE = (91, 0)
BOAT_WIDTH = 8

TARGETED_REMOVE_SOLID_CELLS = {
    (29, 27),
    (35, 32),
    (46, 35),
    (64, 38),
    (13, 66),
    (35, 78),
    (60, 78),
    (2, 79),
    (58, 80),
}
PASS_08_ROUTE_EXTENSION_REMOVE_SOLID_CELLS = {
    (23, 75),
    (23, 76),
    (23, 77),
    (24, 75),
    (24, 76),
    (24, 77),
    (25, 75),
    (25, 76),
    (25, 77),
    (26, 75),
    (26, 76),
    (26, 77),
}
ISSUE_829_CURRENT_POCKET_REMOVE_SOLID_CELLS = {
    (x, y) for y in range(43, 47) for x in range(67, 71)
}
TARGETED_FILL_OPEN_CELLS = {
    (1, 22),
    (1, 23),
    (1, 24),
    (28, 27),
    (34, 33),
    (1, 45),
    (1, 80),
    (59, 80),
}


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
        cells.add((x, height - 1))


def reachable_open_cells(
    solid: set[tuple[int, int]], entry: tuple[int, int]
) -> set[tuple[int, int]]:
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]
    if entry in solid:
        raise ValueError(f"Production slice entry {entry} is inside solid terrain.")

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


def fill_unreachable_open_cells(
    solid: set[tuple[int, int]], entry: tuple[int, int]
) -> int:
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]
    reachable = reachable_open_cells(solid, entry)
    open_cells = {
        (x, y)
        for y in range(height)
        for x in range(width)
        if (x, y) not in solid
    }
    unreachable = open_cells - reachable
    solid.update(unreachable)
    return len(unreachable)


def apply_targeted_topology_cleanup(solid: set[tuple[int, int]]) -> dict:
    removed_solid_tips: list[tuple[int, int]] = []
    filled_open_notches: list[tuple[int, int]] = []

    for cell in sorted(TARGETED_REMOVE_SOLID_CELLS):
        if cell in solid:
            solid.remove(cell)
            removed_solid_tips.append(cell)

    pass_08_route_extension: list[tuple[int, int]] = []
    for cell in sorted(PASS_08_ROUTE_EXTENSION_REMOVE_SOLID_CELLS):
        if cell in solid:
            solid.remove(cell)
            pass_08_route_extension.append(cell)

    current_pocket_extension: list[tuple[int, int]] = []
    for cell in sorted(ISSUE_829_CURRENT_POCKET_REMOVE_SOLID_CELLS):
        if cell in solid:
            solid.remove(cell)
            current_pocket_extension.append(cell)

    for cell in sorted(TARGETED_FILL_OPEN_CELLS):
        if cell not in solid:
            solid.add(cell)
            filled_open_notches.append(cell)

    return {
        "removed_solid_tips": removed_solid_tips,
        "filled_open_notches": filled_open_notches,
        "pass_08_route_extension": pass_08_route_extension,
        "issue_829_current_pocket_extension": current_pocket_extension,
    }


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
    entry = (
        BOAT_ENTRY_SOURCE[0] - SLICE_BOUNDS["x"],
        BOAT_ENTRY_SOURCE[1] - SLICE_BOUNDS["y"],
    )
    solid = crop_solid_cells(source_map)
    before_cleanup_solid_count = len(solid)
    seal_slice_edges(solid)
    filled_open_cells = fill_unreachable_open_cells(solid, entry)
    targeted_cleanup = apply_targeted_topology_cleanup(solid)
    filled_after_targeted_cleanup = fill_unreachable_open_cells(solid, entry)

    return {
        "id": "production_slice_01",
        "version": 1,
        "purpose": (
            "Focused first production-slice map from the top-center entry hub of the supplied full cave sketch. "
            "This is the small playable source used to evaluate boat entry, route branching, salvage return, "
            "and terrain readability before accepting a production slice."
        ),
        "source": {
            "map": "maps/full_cave_sketch_01.greybox.json",
            "slice_bounds": SLICE_BOUNDS,
            "source_entry": {"x": BOAT_ENTRY_SOURCE[0], "y": BOAT_ENTRY_SOURCE[1]},
            "cleanup": {
                "sealed_edges": ["left", "right", "bottom"],
                "filled_unreachable_open_cells": filled_open_cells,
                "filled_open_cells_after_targeted_cleanup": filled_after_targeted_cleanup,
                "removed_solid_tips": [
                    {"x": x, "y": y}
                    for x, y in targeted_cleanup["removed_solid_tips"]
                ],
                "filled_open_notches": [
                    {"x": x, "y": y}
                    for x, y in targeted_cleanup["filled_open_notches"]
                ],
                "pass_08_route_extension_opened_cells": [
                    {"x": x, "y": y}
                    for x, y in targeted_cleanup["pass_08_route_extension"]
                ],
                "issue_829_current_pocket_opened_cells": [
                    {"x": x, "y": y}
                    for x, y in targeted_cleanup["issue_829_current_pocket_extension"]
                ],
                "notes": [
                    "The top edge remains open around the source's water-surface shaft for boat entry.",
                    "Left, right, and bottom crop edges are sealed so the player cannot leave the focused slice.",
                    "Unreachable open pockets from the high-fidelity sketch conversion are filled as solid terrain.",
                    "Targeted cleanup removes isolated one-cell solid tips and fills one-cell open notches visible in the production-slice source/render review.",
                    "Pass 08 opens a tiny alcove in the southwest return pocket without changing the main lower-loop or deep-cache route.",
                    "Issue 829 opens a compact east-current chamber so its cache, surveys, and biological sample do not overlap.",
                    "The original full sketch map is left untouched for comparison.",
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
            "boat_spawn": "Top-water boat entry and extraction marker",
            "salvage": "Collectible objective",
            "hazard": "Avoidance pressure marker",
            "marker": "Non-gameplay annotation",
        },
        "terrain": row_run_terrain(solid),
        **gameplay_sections(entry, SLICE_BOUNDS, BOAT_WIDTH),
    }


def main() -> int:
    with SOURCE_MAP_PATH.open("r", encoding="utf-8") as handle:
        source_map = json.load(handle)

    map_data = build_map_data(source_map)
    OUTPUT_MAP_PATH.write_text(
        json.dumps(map_data, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    print(
        f"Wrote {OUTPUT_MAP_PATH.relative_to(ROOT)} with "
        f"{len(map_data['terrain'])} solid row runs."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
