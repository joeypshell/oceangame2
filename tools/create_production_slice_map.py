#!/usr/bin/env python3
"""Create the first focused production-slice greybox map."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path
from production_slice_01_expansions import biological_resource_sources, expansion_entities, expansion_survey_targets, expansion_zones, hostile_encounters, material_candidate_pools, material_projects, progression_containers
from production_slice_01_player_gate_correction import behavioral_guarded_cache

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
ISSUE_829_CURRENT_POCKET_REMOVE_SOLID_CELLS = {(x, y) for y in range(43, 47) for x in range(67, 71)}
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
PASS_13_ROUTE_OBJECTIVES = [{"id": "deep_cache_route_objective", "route_context": "deep_cache_commitment", "label": "Relay trail", "required_banked_targets": ["salvage_lower_loop", "salvage_southwest_return_cache"], "supporting_marker_ids": ["lower_loop_route", "deep_cache_first_step_cue", "southwest_return_pocket_extension", "southwest_pocket_pre_pickup_cue", "lower_loop_oxygen_rest_pocket", "return_pressure_to_boat"], "intent": "Opening objective banks two non-eel lower-loop payoffs and points toward the lower-left relay before the shock-prod-gated deep-right cache."}]
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
def reachable_open_cells(solid: set[tuple[int, int]], entry: tuple[int, int]) -> set[tuple[int, int]]:
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


def fill_unreachable_open_cells(solid: set[tuple[int, int]], entry: tuple[int, int]) -> int:
    width = SLICE_BOUNDS["w"]
    height = SLICE_BOUNDS["h"]
    reachable = reachable_open_cells(solid, entry)
    open_cells = {(x, y) for y in range(height) for x in range(width) if (x, y) not in solid}
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
    entry = (BOAT_ENTRY_SOURCE[0] - SLICE_BOUNDS["x"], BOAT_ENTRY_SOURCE[1] - SLICE_BOUNDS["y"])
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
                    {"x": x, "y": y} for x, y in targeted_cleanup["removed_solid_tips"]
                ],
                "filled_open_notches": [
                    {"x": x, "y": y} for x, y in targeted_cleanup["filled_open_notches"]
                ],
                "pass_08_route_extension_opened_cells": [
                    {"x": x, "y": y} for x, y in targeted_cleanup["pass_08_route_extension"]
                ],
                "issue_829_current_pocket_opened_cells": [
                    {"x": x, "y": y} for x, y in targeted_cleanup["issue_829_current_pocket_extension"]
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
        "zones": [
            {
                "id": "production_slice_bounds",
                "type": "marker",
                "x": 0,
                "y": 0,
                "w": SLICE_BOUNDS["w"],
                "h": SLICE_BOUNDS["h"],
                "intent": "Full extent of the first production slice crop.",
            },
            {
                "id": "entry_shaft_route",
                "type": "marker",
                "x": 28,
                "y": 0,
                "w": 24,
                "h": 25,
                "intent": "Top-water descent from boat entry into the first branch.",
            },
            {
                "id": "central_crossing_route",
                "type": "marker",
                "x": 24,
                "y": 22,
                "w": 37,
                "h": 22,
                "intent": "Primary branching hub with a return route toward the boat.",
            },
            {
                "id": "lower_loop_route",
                "type": "marker",
                "x": 12,
                "y": 55,
                "w": 52,
                "h": 24,
                "intent": "Lower optional loop for a longer salvage return test.",
            },
            {"id": "lower_left_loop_connector", "type": "marker", "x": 2, "y": 74, "w": 4, "h": 4, "world_connector": True, "connector_label": "Lower-left relay", "destination_map_id": "production_slice_04", "destination_map_path": "res://maps/production_slice_04.greybox.json", "destination_entry_id": "relay_sub_entry", "connector_direction": "forward", "intent": "Optional advanced-current entrance; not part of the fins, scanner, or weapon progression chain."},
            *expansion_zones(),
            {"id": "deep_cache_first_step_cue", "type": "marker", "x": 28, "y": 58, "w": 4, "h": 3, "objective_step_cue": True, "objective_id": "deep_cache_route_objective", "target_id": "salvage_lower_loop", "route_context": "deep_cache_commitment", "objective_step_label": "Lower loop", "intent": "Opening relay-trail objective cue for its first required target."},
            {
                "id": "return_pressure_to_boat",
                "type": "marker",
                "x": 12,
                "y": 50,
                "w": 28,
                "h": 18,
                "intent": (
                    "Pass 10 return-pressure segment around salvage_return_branch "
                    "where full cargo should prompt banking at the boat."
                ),
            },
            {"id": "lower_loop_oxygen_rest_pocket", "type": "marker", "x": 27, "y": 60, "w": 8, "h": 5, "route_context": "oxygen_rest_pressure", "oxygen_rest": True, "oxygen_rest_label": "Rest pocket", "oxygen_rest_cap_seconds": 45, "oxygen_rest_refill_per_second": 8, "intent": "Pass 12 limited oxygen rest pocket in the lower-loop return corridor; supports a brief in-cave oxygen decision without changing extraction, cargo, salvage, hazards, or terrain topology."},
            {
                "id": "southwest_return_pocket_extension",
                "type": "marker",
                "x": 1,
                "y": 67,
                "w": 27,
                "h": 16,
                "intent": (
                    "Pass 08/09 route segment marking the lower-left return pocket "
                    "near salvage_return_branch for a small optional detour decision."
                ),
            },
            {
                "id": "southwest_pocket_pre_pickup_cue",
                "type": "marker",
                "x": 12,
                "y": 65,
                "w": 16,
                "h": 9,
                "route_cue_id": "southwest_pocket_pre_pickup_cue",
                "cue_target_id": "salvage_southwest_return_cache",
                "cue_text": "Relay trail cache ahead",
                "cue_condition": "target_uncollected",
                "intent": (
                    "Pre-pickup route cue for the required non-eel relay-trail payoff."
                ),
            },
            {
                "id": "lower_loop_to_deep_cache_pressure",
                "type": "marker",
                "x": 54,
                "y": 64,
                "w": 13,
                "h": 13,
                "intent": (
                    "Pass 07 hazard/navigation pressure segment covering the hazard_right_branch "
                    "warning corridor and approach to timed salvage_deep_right_cache."
                ),
            },
            {"id": "deep_cache_dark_pocket", "type": "marker", "x": 50, "y": 68, "w": 16, "h": 11, "visibility_zone": True, "visibility_level": "dark", "visibility_label": "Dark pocket", "route_context": "deep_cache_pressure", "required_upgrade_id": "dive_light_1", "visual_only": True, "intent": "First visual-only darkness pressure zone around the lower-loop-to-deep-cache route."},
        ],
        "progression_containers": progression_containers(),
        "moving_hazards": [{"id": "deep_route_jellyfish_patrol", "kind": "jellyfish", "x": 54, "y": 68, "movement": "linear_patrol", "path": [{"x": 54, "y": 68}, {"x": 64, "y": 68}], "speed_tiles_per_second": 1.0, "route_context": "deep_cache_pressure", "display_label": "Jellyfish patrol", "intent": "First deterministic moving hazard on the lower-loop to deep-cache route."}],
        "hostile_encounters": hostile_encounters(),
        "biological_resource_sources": biological_resource_sources(),
        "route_objectives": PASS_13_ROUTE_OBJECTIVES,
        "primary_route_objective_id": "deep_cache_route_objective",
        "next_dive_objective_prompts": [{"id": "deep_cache_next_dive_prompt", "trigger": "primary_objective_complete", "objective_id": "deep_cache_route_objective", "target_id": "upper_right_current_pocket_gate", "label": "Next dive: Investigate east current", "route_context": "upper_right_current_pocket", "intent": "Result prompt pointing the next dive toward the standard current crossed passively with propulsion fins."}],
        "survey_targets": expansion_survey_targets(),
        "material_candidate_pools": material_candidate_pools(),
        "material_projects": material_projects(),
        "background": [
            {"id": "distant_entry_wall", "type": "background", "x": 30, "y": 6, "w": 18, "h": 22},
            {"id": "distant_crossing_mass", "type": "background", "x": 28, "y": 24, "w": 30, "h": 24},
            {"id": "distant_lower_loop", "type": "background", "x": 14, "y": 58, "w": 44, "h": 18},
        ],
        "entities": [
            {
                "id": "surface_boat_entry",
                "type": "boat_spawn",
                "x": entry[0],
                "y": entry[1],
                "w": BOAT_WIDTH,
                "h": 1,
                "entry_x": entry[0],
                "entry_y": entry[1],
                "facing": "right",
                "intent": "Top-water boat entry and extraction marker for the first production slice.",
            },
            {
                "id": "salvage_entry_shaft",
                "type": "salvage",
                "x": 38,
                "y": 18,
                "kind": "crate",
                "route_choice_id": "safe_entry_pickup",
                "validation_route": "safe_route_choice",
                "route_order": 0,
                "intent": "Safe route target near the entry shaft for short collect-return comparison.",
            },
            {"id": "salvage_center_crossing", "type": "salvage", "x": 46, "y": 30, "kind": "wreck_fragment"},
            {"id": "salvage_right_branch", "type": "salvage", "x": 64, "y": 24, "kind": "crate"},
            {
                "id": "salvage_lower_loop",
                "type": "salvage",
                "x": 30,
                "y": 67,
                "kind": "relic",
                "tier": "valuable",
                "route_choice_id": "lower_loop_payoff",
                "validation_route": "expanded_route_choice",
                "route_order": 0,
                "intent": "Route-choice payoff target for the lower optional loop.",
            },
            {"id": "salvage_pry_locker", "type": "salvage", "x": 36, "y": 64, "kind": "crate", "tier": "valuable", "interaction": "pry_salvage", "interaction_seconds": 1.2, "pry_stages": 3, "interaction_label": "sealed cache", "route_choice_id": "lower_bend_pry_detour", "validation_route": "pry_salvage_detour", "route_order": 0, "intent": "Pass 17 optional pry target near the lower-bend hazard, adding a deliberate oxygen-time spend without changing topology."},
            behavioral_guarded_cache(),
            {
                "id": "salvage_southwest_return_cache",
                "type": "salvage",
                "x": 25,
                "y": 76,
                "kind": "crate",
                "tier": "valuable",
                "route_choice_id": "southwest_pocket_detour",
                "validation_route": "southwest_pocket_decision",
                "route_order": 0,
                "intent": (
                    "Non-eel valuable payoff completing the opening relay trail; keeps instant collection "
                    "while the separate material route supplies the propulsion-fins recipe."
                ),
            },
            {
                "id": "salvage_return_branch",
                "type": "salvage",
                "x": 17,
                "y": 58,
                "kind": "crate",
                "route_choice_id": "return_branch_bank_prompt",
                "validation_route": "return_pressure_decision",
                "route_order": 0,
                "intent": "Pass 10 return-pressure pickup that should remain available while full cargo returns to the boat.",
            },
            {"id": "hazard_shaft_choke", "type": "hazard", "x": 34, "y": 20, "kind": "jellyfish"},
            {"id": "hazard_crossing_choke", "type": "hazard", "x": 52, "y": 34, "kind": "mine"},
            {"id": "hazard_lower_bend", "type": "hazard", "x": 36, "y": 61, "kind": "jellyfish"},
            {"id": "hazard_right_branch", "type": "hazard", "x": 57, "y": 66, "kind": "mine"},
            *expansion_entities(),
        ],
        "camera_tests": [
            {
                "id": "production_slice_overview",
                "center_x": 36,
                "center_y": 42,
                "zoom": 0.36,
                "intent": "Broad production-slice context with reduced side border.",
            },
            {
                "id": "production_slice_entry_shaft",
                "center_x": 39,
                "center_y": 11,
                "zoom": 0.66,
                "intent": "Boat entry, surface opening, and first descent read.",
            },
            {
                "id": "production_slice_first_route_choice",
                "center_x": 42,
                "center_y": 25,
                "zoom": 0.60,
                "intent": "First route choice after the entry shaft, with nearby salvage and hazard.",
            },
            {
                "id": "production_slice_central_crossing",
                "center_x": 48,
                "center_y": 43,
                "zoom": 0.58,
                "intent": "Central branching, nearby salvage, and hazard pressure review.",
            },
            {
                "id": "production_slice_lower_loop",
                "center_x": 36,
                "center_y": 66,
                "zoom": 0.58,
                "intent": "Lower optional route and return-path readability review.",
            },
            {
                "id": "production_slice_return_to_boat",
                "center_x": 36,
                "center_y": 18,
                "zoom": 0.46,
                "intent": "Return path context from first branch back to boat extraction.",
            },
        ],
        "review_questions": [
            "Does the top-water boat entry read as the start and extraction point?",
            "Do the central crossing and lower loop feel like meaningful route choices?",
            "Are salvage and hazard markers placed where they create pressure without clutter?",
            "Do sealed slice edges feel like natural cave boundaries rather than arbitrary cutoffs?",
        ],
    }


def main() -> int:
    with SOURCE_MAP_PATH.open("r", encoding="utf-8") as handle:
        source_map = json.load(handle)

    map_data = build_map_data(source_map)
    OUTPUT_MAP_PATH.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT_MAP_PATH.relative_to(ROOT)} with {len(map_data['terrain'])} solid row runs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
