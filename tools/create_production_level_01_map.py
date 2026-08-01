#!/usr/bin/env python3
"""Generate the contiguous production-level topology candidate."""

from __future__ import annotations

import json
from pathlib import Path

import production_level_01_expansion_12 as expansion_12
import production_level_01_expansion_13 as expansion_13
import production_level_01_expansion_14 as expansion_14
import production_level_01_expansion_16 as expansion_16
import production_level_01_expansion_17 as expansion_17
from production_level_01_expansion_15 import author_expedition_leads
from production_level_01_gameplay_transform import (
    LOCAL_TO_GLOBAL_OFFSET,
    transform_gameplay_sections,
)
from production_level_01_expansion_10 import (
    background as expansion_10_background,
    camera_tests as expansion_10_camera_tests,
    regional_journeys as expansion_10_regional_journeys,
    source_provenance as expansion_10_source_provenance,
    survey_targets as expansion_10_survey_targets,
    zones as expansion_10_zones,
)
from production_level_01_expansion_11 import (
    camera_tests as expansion_11_camera_tests,
    material_projects as expansion_11_material_projects,
    source_provenance as expansion_11_source_provenance,
    survey_targets as expansion_11_survey_targets,
    zones as expansion_11_zones,
)

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

GAMEPLAY_CLEARANCE_OPEN_LOCAL_CELLS = {
    "southwest_return_pocket": {
        (x, y) for y in range(75, 78) for x in range(23, 27)
    },
    "east_current_pocket": {
        (x, y) for y in range(43, 47) for x in range(67, 71)
    },
    "deep_cache_evade_lane": {(60, 78)},
}

GAMEPLAY_CLEARANCE_INTENTS = {
    "southwest_return_pocket": (
        "Preserve the proven southwest cache approach and Pass 08 migration lane."
    ),
    "east_current_pocket": (
        "Preserve non-overlapping current-pocket cache, survey, and biological targets."
    ),
    "deep_cache_evade_lane": (
        "Keep the eel territory lower-edge evade lane and visibility zone fully open."
    ),
}

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


def global_gameplay_clearance_cells() -> set[tuple[int, int]]:
    return {
        (
            x + int(LOCAL_TO_GLOBAL_OFFSET["x"]),
            y + int(LOCAL_TO_GLOBAL_OFFSET["y"]),
        )
        for cells in GAMEPLAY_CLEARANCE_OPEN_LOCAL_CELLS.values()
        for x, y in cells
    }


def _terrain_without_cells(
    terrain: list[dict], open_cells: set[tuple[int, int]]
) -> list[dict]:
    result: list[dict] = []
    for item in terrain:
        if item.get("type") != "solid" or not (rect_cells(item) & open_cells):
            result.append(dict(item))
            continue

        remaining = rect_cells(item) - open_cells
        part_index = 0
        for y in range(int(item["y"]), int(item["y"]) + int(item.get("h", 1))):
            row_x = sorted(x for x, cell_y in remaining if cell_y == y)
            run_start: int | None = None
            previous_x: int | None = None
            for x in [*row_x, None]:
                if run_start is None:
                    run_start = x
                elif x is None or x != previous_x + 1:
                    part_index += 1
                    result.append(
                        {
                            **item,
                            "id": f"{item['id']}_gameplay_clearance_{part_index:02d}",
                            "x": run_start,
                            "y": y,
                            "w": previous_x - run_start + 1,
                            "h": 1,
                        }
                    )
                    run_start = x
                previous_x = x
    return result


def candidate_terrain(
    source_map: dict, gameplay_clearance_cells: set[tuple[int, int]]
) -> list[dict]:
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
    return _terrain_without_cells(terrain, gameplay_clearance_cells)


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
            "id": "production_level_opening_gameplay",
            "center_x": 100,
            "center_y": 25,
            "zoom": 0.60,
            "intent": "Transformed opening route, nearby salvage, and hazard review.",
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
        {
            "id": "production_level_return_to_boat",
            "center_x": 94,
            "center_y": 18,
            "zoom": 0.46,
            "intent": "Continuous return context from the opening route to the canonical boat.",
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
    gameplay_clearance_cells = global_gameplay_clearance_cells()
    missing_clearance_source = gameplay_clearance_cells - draft_solid
    if missing_clearance_source:
        raise ValueError(
            "Gameplay-clearance source signature changed; expected solid cells are already open: "
            f"{sorted(missing_clearance_source)}"
        )
    candidate_solid = set(draft_solid)
    candidate_solid.update(SEALED_BOUNDARY_CELLS)
    candidate_solid.difference_update(gameplay_clearance_cells)
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

    gameplay, gameplay_provenance = transform_gameplay_sections()

    return expansion_17.author(expansion_16.author(author_expedition_leads({
        "id": "production_level_01",
        "version": 1,
        "purpose": (
            "Contiguous full-level topology candidate generated from the complete full cave sketch. "
            "The proven slice-01 gameplay overlay is transformed into global coordinates through "
            "a source-owned, inspectable pass."
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
                "gameplay_clearance_openings": [
                    {
                        "id": cleanup_id,
                        "intent": GAMEPLAY_CLEARANCE_INTENTS[cleanup_id],
                        "slice_local": [
                            {"x": x, "y": y}
                            for x, y in sorted(local_cells)
                        ],
                        "full_global": [
                            {
                                "x": x + int(LOCAL_TO_GLOBAL_OFFSET["x"]),
                                "y": y + int(LOCAL_TO_GLOBAL_OFFSET["y"]),
                            }
                            for x, y in sorted(local_cells)
                        ],
                    }
                    for cleanup_id, local_cells in GAMEPLAY_CLEARANCE_OPEN_LOCAL_CELLS.items()
                ],
                "notes": [
                    "The canonical surface_boat_entry opening at top x=91..98 remains open.",
                    "Nine adjacent top cells and the separate ten-cell top-right opening are sealed in global source coordinates.",
                    "No crop seal, stitched slice terrain, connector, teleport, or stabilizer-entry metadata is imported.",
                    "Expansion 12-14 records come only from their focused source helpers.",
                    "Twenty-nine named source-owned cells are opened only where reused gameplay requires its proven clearance.",
                    "The full-sketch draft remains unchanged as conversion and provenance evidence.",
                ],
            },
            "stats": {
                "draft_solid_cells": len(draft_solid),
                "candidate_solid_cells": len(candidate_solid),
                "draft_open_boundary_cells": len(BOAT_OPENING_CELLS)
                + len(SEALED_BOUNDARY_CELLS),
                "candidate_open_boundary_cells": len(BOAT_OPENING_CELLS),
                "gameplay_clearance_opened_cells": len(gameplay_clearance_cells),
            },
            "gameplay_overlay": gameplay_provenance,
            "expansion_10": expansion_10_source_provenance(),
            "expansion_11": expansion_11_source_provenance(),
            "expansion_12": expansion_12.source_provenance(),
            "expansion_13": expansion_13.source_provenance(),
            "expansion_14": expansion_14.source_provenance(),
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
            "salvage": "Collectible objective reused from the proven opening region",
            "hazard": "Avoidance pressure reused from the proven opening region",
        },
        "terrain": candidate_terrain(source_map, gameplay_clearance_cells),
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
            *gameplay["zones"],
            *expansion_10_zones(),
            *expansion_11_zones(),
            *expansion_12.zones(),
            *expansion_13.zones(),
            *expansion_14.zones(),
        ],
        "regional_journeys": [
            *expansion_10_regional_journeys(),
            *expansion_12.regional_journeys(),
            *expansion_13.regional_journeys(),
            *expansion_14.regional_journeys(),
        ],
        "daily_conditions": gameplay["daily_conditions"],
        "progression_containers": gameplay["progression_containers"],
        "moving_hazards": gameplay["moving_hazards"],
        "hostile_encounters": gameplay["hostile_encounters"],
        "biological_resource_sources": gameplay["biological_resource_sources"],
        "route_objectives": gameplay["route_objectives"],
        "primary_route_objective_id": gameplay["primary_route_objective_id"],
        "next_dive_objective_prompts": gameplay["next_dive_objective_prompts"],
        "survey_targets": [
            *gameplay["survey_targets"],
            *expansion_10_survey_targets(),
            *expansion_11_survey_targets(),
            *expansion_12.survey_targets(),
            *expansion_13.survey_targets(),
            *expansion_14.survey_targets(),
        ],
        "material_candidate_pools": gameplay["material_candidate_pools"],
        "material_projects": [
            *gameplay["material_projects"],
            *expansion_11_material_projects(),
            *expansion_12.material_projects(),
            *expansion_14.material_projects(),
        ],
        "background": [
            *gameplay["background"],
            *expansion_10_background(),
            *expansion_12.background(),
            *expansion_13.background(),
            *expansion_14.background(),
        ],
        "entities": [canonical_boat(source_map), *gameplay["entities"], *expansion_13.entities(), *expansion_14.entities()],
        "camera_tests": [
            *camera_tests(),
            *gameplay["camera_tests"],
            *expansion_10_camera_tests(),
            *expansion_11_camera_tests(),
            *expansion_12.camera_tests(),
            *expansion_13.camera_tests(),
            *expansion_14.camera_tests(),
        ],
        "review_questions": [
            "Does the candidate preserve the complete supplied cave silhouette?",
            "Is the canonical boat opening the only visible route out of the outer boundary?",
            "Do the upper-left, lower-left, and lower-right anchors sit in recognizable open sectors?",
            "Does transformed opening gameplay retain its source-local relationships without a crop seam?",
            "Do source, render, and collision evidence agree after gameplay transformation?",
            *expansion_12.review_questions(),
            *expansion_13.review_questions(),
            *expansion_14.review_questions(),
        ],
    })))


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
