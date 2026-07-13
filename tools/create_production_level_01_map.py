#!/usr/bin/env python3
"""Generate the contiguous production-level topology candidate."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP_PATH = ROOT / "maps" / "full_cave_sketch_01.greybox.json"
OUTPUT_MAP_PATH = ROOT / "maps" / "production_level_01.greybox.json"

EXPECTED_WIDTH = 158
EXPECTED_HEIGHT = 161
BOAT_ID = "surface_boat_entry"
BOAT_OPENING_CELLS = tuple((x, 0) for x in range(91, 99))
SEALED_BOUNDARY_CELLS = tuple(
    [(x, 0) for x in range(99, 108)] + [(x, 0) for x in range(141, 151)]
)

SECTOR_ANCHORS = (
    {
        "id": "full_level_upper_left_anchor",
        "type": "marker",
        "x": 38,
        "y": 49,
        "w": 1,
        "h": 1,
        "validation_anchor": True,
        "sector": "upper_left",
        "intent": "Representative upper-left traversal and return anchor.",
    },
    {
        "id": "full_level_lower_left_anchor",
        "type": "marker",
        "x": 44,
        "y": 112,
        "w": 1,
        "h": 1,
        "validation_anchor": True,
        "sector": "lower_left",
        "intent": "Representative lower-left traversal and return anchor.",
    },
    {
        "id": "full_level_lower_right_anchor",
        "type": "marker",
        "x": 121,
        "y": 115,
        "w": 1,
        "h": 1,
        "validation_anchor": True,
        "sector": "lower_right",
        "intent": "Representative lower-right traversal and return anchor.",
    },
)


def rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item.get("h", 1)))
        for x in range(int(item["x"]), int(item["x"]) + int(item.get("w", 1)))
    }


def solid_cells(source_map: dict) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for item in source_map.get("terrain", []):
        if item.get("type") == "solid":
            cells.update(rect_cells(item))
    return cells


def boundary_cells(width: int, height: int) -> set[tuple[int, int]]:
    return (
        {(x, 0) for x in range(width)}
        | {(x, height - 1) for x in range(width)}
        | {(0, y) for y in range(height)}
        | {(width - 1, y) for y in range(height)}
    )


def assert_expected_boundary_source(
    solid: set[tuple[int, int]], width: int, height: int
) -> None:
    observed_open = boundary_cells(width, height) - solid
    expected_open = set(BOAT_OPENING_CELLS) | set(SEALED_BOUNDARY_CELLS)
    if observed_open != expected_open:
        missing = sorted(expected_open - observed_open)
        unexpected = sorted(observed_open - expected_open)
        raise ValueError(
            "Full-sketch boundary signature changed; review source cleanup "
            f"before generating. missing={missing} unexpected={unexpected}"
        )


def candidate_terrain(source_map: dict) -> list[dict]:
    terrain = [dict(item) for item in source_map.get("terrain", [])]
    terrain.extend(
        [
            {
                "id": "solid_boundary_cleanup_top_adjacent",
                "type": "solid",
                "x": 99,
                "y": 0,
                "w": 9,
                "h": 1,
            },
            {
                "id": "solid_boundary_cleanup_top_right",
                "type": "solid",
                "x": 141,
                "y": 0,
                "w": 10,
                "h": 1,
            },
        ]
    )
    return terrain


def canonical_boat(source_map: dict) -> dict:
    matches = [
        entity for entity in source_map.get("entities", []) if entity.get("id") == BOAT_ID
    ]
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one {BOAT_ID}; found {len(matches)}.")
    source_boat = matches[0]
    expected = (91, 0, 8, 1, 91, 0)
    observed = (
        source_boat.get("x"),
        source_boat.get("y"),
        source_boat.get("w"),
        source_boat.get("h"),
        source_boat.get("entry_x"),
        source_boat.get("entry_y"),
    )
    if observed != expected:
        raise ValueError(f"Canonical boat signature changed: {observed} != {expected}.")
    return {
        **source_boat,
        "intent": "Canonical top-water boat entry and extraction for the contiguous production candidate.",
    }


def camera_tests() -> list[dict]:
    return [
        {
            "id": "production_level_overview",
            "center_x": 79.0,
            "center_y": 80.5,
            "zoom": 0.13,
            "intent": "Whole-candidate topology and boundary review.",
        },
        {
            "id": "production_level_boat_entry",
            "center_x": 95,
            "center_y": 8,
            "zoom": 0.55,
            "intent": "Canonical boat and intentional top-water opening review.",
        },
        {
            "id": "production_level_upper_left",
            "center_x": 38,
            "center_y": 49,
            "zoom": 0.34,
            "intent": "Upper-left sector-anchor topology review.",
        },
        {
            "id": "production_level_lower_left",
            "center_x": 44,
            "center_y": 112,
            "zoom": 0.30,
            "intent": "Lower-left sector-anchor topology review.",
        },
        {
            "id": "production_level_lower_right",
            "center_x": 121,
            "center_y": 115,
            "zoom": 0.30,
            "intent": "Lower-right sector-anchor topology review.",
        },
    ]


def build_map_data(source_map: dict) -> dict:
    source_units = source_map.get("units", {})
    width = int(source_units.get("width_tiles", 0))
    height = int(source_units.get("height_tiles", 0))
    if (width, height) != (EXPECTED_WIDTH, EXPECTED_HEIGHT):
        raise ValueError(
            f"Expected {EXPECTED_WIDTH}x{EXPECTED_HEIGHT} full draft; got {width}x{height}."
        )

    draft_solid = solid_cells(source_map)
    assert_expected_boundary_source(draft_solid, width, height)
    candidate_solid = set(draft_solid)
    candidate_solid.update(SEALED_BOUNDARY_CELLS)
    remaining_open_boundary = boundary_cells(width, height) - candidate_solid
    if remaining_open_boundary != set(BOAT_OPENING_CELLS):
        raise ValueError(
            "Candidate boundary cleanup failed; remaining open cells are "
            f"{sorted(remaining_open_boundary)}."
        )

    for anchor in SECTOR_ANCHORS:
        point = (int(anchor["x"]), int(anchor["y"]))
        if point in candidate_solid:
            raise ValueError(f"Sector anchor {anchor['id']} is inside solid terrain at {point}.")

    return {
        "id": "production_level_01",
        "version": 1,
        "purpose": (
            "Contiguous full-level topology candidate generated from the complete full cave sketch. "
            "Gameplay transformation follows in a separate source-owned pass."
        ),
        "source": {
            "map": "maps/full_cave_sketch_01.greybox.json",
            "image": source_map.get("source", {}).get("image", ""),
            "coordinate_space": "global_full_map_tiles",
            "full_bounds": {"x": 0, "y": 0, "w": width, "h": height},
            "cleanup": {
                "intentional_top_water_opening": [
                    {"x": x, "y": y} for x, y in BOAT_OPENING_CELLS
                ],
                "sealed_unintended_boundary_openings": [
                    {"x": x, "y": y} for x, y in SEALED_BOUNDARY_CELLS
                ],
                "notes": [
                    "The canonical surface_boat_entry opening at top x=91..98 remains open.",
                    "Nine adjacent top cells and the separate ten-cell top-right opening are sealed in global source coordinates.",
                    "No crop seal, stitched slice terrain, connector, teleport, pressure, or stabilizer-entry metadata is imported.",
                    "The full-sketch draft remains unchanged as conversion and provenance evidence.",
                ],
            },
            "stats": {
                "draft_solid_cells": len(draft_solid),
                "candidate_solid_cells": len(candidate_solid),
                "draft_open_boundary_cells": len(BOAT_OPENING_CELLS)
                + len(SEALED_BOUNDARY_CELLS),
                "candidate_open_boundary_cells": len(BOAT_OPENING_CELLS),
            },
            "review_artifact": "references/greybox/production_level_01_source_render_collision_review.png",
        },
        "units": {
            "tile_size_px": int(source_units.get("tile_size_px", 32)),
            "width_tiles": width,
            "height_tiles": height,
        },
        "legend": {
            "water": "Open swimmable space from the complete full-sketch topology",
            "solid": "Collision terrain from the full sketch plus named boundary cleanup",
            "boat_spawn": "Canonical top-water boat entry and extraction marker",
            "marker": "Non-gameplay validation or review annotation",
        },
        "terrain": candidate_terrain(source_map),
        "zones": [
            {
                "id": "production_level_bounds",
                "type": "marker",
                "x": 0,
                "y": 0,
                "w": width,
                "h": height,
                "intent": "Full extent of the contiguous production candidate.",
            },
            *SECTOR_ANCHORS,
        ],
        "background": [],
        "entities": [canonical_boat(source_map)],
        "camera_tests": camera_tests(),
        "review_questions": [
            "Does the candidate preserve the complete supplied cave silhouette?",
            "Is the canonical boat opening the only visible route out of the outer boundary?",
            "Do the upper-left, lower-left, and lower-right anchors sit in recognizable open sectors?",
            "Do source, render, and collision evidence agree before gameplay is transformed?",
        ],
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
        f"{len(map_data['terrain'])} collision rectangles."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
