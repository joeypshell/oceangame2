#!/usr/bin/env python3
"""Validate the bounded Expansion 11 durable-light progression chain."""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PROJECT_ID = "dive_light_1_project"
CAPABILITY_ID = "dive_light_1"
KNOWLEDGE_ID = "lower_right_signal_reef_discovery"
SIGNAL_REEF_SURVEY_ID = "lower_right_signal_reef_survey"
DARK_ZONE_ID = "signal_reef_deep_harmonic_dark_zone"
SURVEY_ID = "signal_reef_deep_harmonic_survey"
DISCOVERY_ID = "signal_reef_deep_harmonic_discovery"
ROUTE_ID = "east_current_signal_reef_route"
BOAT_ID = "surface_boat_entry"
RECIPE = {"titanium_scrap": 1, "conductive_coil": 1, "insulating_gel": 1}
PROJECT_VALUES = {
    "required_discovery_id": KNOWLEDGE_ID,
    "required_materials": RECIPE,
    "unlocks_capability_id": CAPABILITY_ID,
    "target_id": SURVEY_ID,
    "build_phase": "night_debrief",
    "project_label": "Dive light project",
    "completion_label": "Dive light built",
}
ZONE_VALUES = {
    "type": "marker",
    "visibility_zone": True,
    "visibility_level": "dark",
    "visibility_label": "Deep harmonic dark water",
    "required_upgrade_id": CAPABILITY_ID,
    "visual_only": True,
    "route_context": ROUTE_ID,
}
SURVEY_VALUES = {
    "target_type": "regional",
    "required_capability_id": "survey_scanner_1",
    "required_light_capability_id": CAPABILITY_ID,
    "required_route_id": ROUTE_ID,
    "route_context": ROUTE_ID,
    "interaction": "survey",
    "interaction_seconds": 3.0,
    "interaction_label": "Survey deep harmonic",
    "clue_label": "Deep harmonic | Stronger light required",
    "finding_label": "Discovery logged: Deep harmonic chart",
    "next_lead_label": "Next lead: signal descends into deeper water",
    "discovery_id": DISCOVERY_ID,
    "commit_map_id": "production_level_01",
    "commit_map_path": "res://maps/production_level_01.greybox.json",
    "commit_entry_id": BOAT_ID,
}
FORBIDDEN_PRELIGHT_FIELDS = {
    "blocked",
    "collision",
    "hidden_until_capability",
    "remove_without_capability",
    "solid",
    "teleport",
    "world_connector",
}


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records(map_data: dict[str, Any], field: str, item_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(map_data, field) if item.get("id") == item_id]


def _triggered(map_data: dict[str, Any]) -> bool:
    if _records(map_data, "material_projects", PROJECT_ID):
        return True
    if _records(map_data, "zones", DARK_ZONE_ID) or _records(map_data, "survey_targets", SURVEY_ID):
        return True
    return any(target.get("discovery_id") == DISCOVERY_ID for target in _items(map_data, "survey_targets"))


def _one(map_data: dict[str, Any], field: str, item_id: str, failures: list[str]) -> dict[str, Any]:
    matches = _records(map_data, field, item_id)
    if len(matches) != 1:
        failures.append(f"Expansion 11 requires exactly one {field} record {item_id!r}; found {len(matches)}.")
        return {}
    return matches[0]


def _check_values(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [
        f"{label} {field} must be exactly {value!r}."
        for field, value in expected.items()
        if item.get(field) != value
    ]


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    if not all(isinstance(item.get(field), int) and not isinstance(item.get(field), bool) for field in ("x", "y", "w", "h")):
        return set()
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
    }


def _reachable_from_boat(map_data: dict[str, Any], solid: set[tuple[int, int]]) -> set[tuple[int, int]]:
    boats = _records(map_data, "entities", BOAT_ID)
    if len(boats) != 1:
        return set()
    boat = boats[0]
    start = (int(boat.get("entry_x", boat.get("x", -1))), int(boat.get("entry_y", boat.get("y", -1))))
    width = int(map_data.get("units", {}).get("width_tiles", 0))
    height = int(map_data.get("units", {}).get("height_tiles", 0))
    if start in solid or not (0 <= start[0] < width and 0 <= start[1] < height):
        return set()
    reachable = {start}
    pending = deque([start])
    while pending:
        x, y = pending.popleft()
        for cell in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= cell[0] < width and 0 <= cell[1] < height and cell not in solid and cell not in reachable:
                reachable.add(cell)
                pending.append(cell)
    return reachable


def _load_contract(path: Path | None = None) -> dict[str, Any]:
    contract_path = path or ROOT / "config" / "progression_contract.json"
    with contract_path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("progression contract must be an object")
    return value


def _validate_single_owner(map_data: dict[str, Any], contract: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    session_ids = {
        str(item.get("id"))
        for field in ("session_upgrades", "durable_purchases")
        for item in _items(contract, field)
    }
    if CAPABILITY_ID in session_ids:
        failures.append(f"{CAPABILITY_ID} must not have session/purchase ownership when {PROJECT_ID} is authored.")
    owners = [
        str(project.get("id"))
        for project in _items(map_data, "material_projects")
        if project.get("unlocks_capability_id") == CAPABILITY_ID
    ]
    if owners != [PROJECT_ID]:
        failures.append(f"{CAPABILITY_ID} must be owned only by {PROJECT_ID}; found {owners}.")
    return failures


def _validate_knowledge_and_materials(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    knowledge_targets = _records(map_data, "survey_targets", SIGNAL_REEF_SURVEY_ID)
    if len(knowledge_targets) != 1 or knowledge_targets[0].get("discovery_id") != KNOWLEDGE_ID:
        failures.append(f"{PROJECT_ID} knowledge must come from {SIGNAL_REEF_SURVEY_ID} -> {KNOWLEDGE_ID}.")
    elif knowledge_targets[0].get("required_light_capability_id") == CAPABILITY_ID:
        failures.append(f"{SIGNAL_REEF_SURVEY_ID} must not require the light that its discovery unlocks.")

    pools = _items(map_data, "material_candidate_pools")
    for material_id in ("titanium_scrap", "conductive_coil"):
        guaranteed = sum(
            int(pool.get("select_count", 0))
            for pool in pools
            if pool.get("material_id") == material_id and pool.get("pool_role") != "optional_bonus"
        )
        if guaranteed < RECIPE[material_id]:
            failures.append(
                f"{PROJECT_ID} requires {RECIPE[material_id]} {material_id}, but daily pools guarantee {guaranteed}."
            )

    gel_sources = [
        source
        for source in _items(map_data, "biological_resource_sources")
        if source.get("material_id") == "insulating_gel"
    ]
    if len(gel_sources) != 1:
        failures.append(f"{PROJECT_ID} requires exactly one guaranteed insulating_gel source; found {len(gel_sources)}.")
    else:
        gel = gel_sources[0]
        expected = {
            "source_role": "passive_sample",
            "material_quantity": 1,
            "replenishment": "new_day",
            "required_capability_id": "survey_scanner_1",
        }
        failures.extend(_check_values(gel, expected, str(gel.get("id", "insulating_gel source"))))
        if "hostile_id" in gel or gel.get("required_capability_id") == CAPABILITY_ID:
            failures.append("insulating_gel must remain noncombat and obtainable before dive_light_1.")

    candidate_ids = {
        str(candidate_id)
        for pool in pools
        if pool.get("material_id") in RECIPE
        for candidate_id in pool.get("candidate_ids", [])
    }
    for entity in _items(map_data, "entities"):
        if str(entity.get("id")) in candidate_ids and CAPABILITY_ID in {
            entity.get("required_capability_id"), entity.get("required_tool_id")
        }:
            failures.append(f"{entity.get('id')} cannot require {CAPABILITY_ID} to source its own project recipe.")
    return failures


def validate_light_return_schema(
    map_path: Path,
    map_data: dict[str, Any],
    progression_contract: dict[str, Any] | None = None,
) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    project = _one(map_data, "material_projects", PROJECT_ID, failures)
    zone = _one(map_data, "zones", DARK_ZONE_ID, failures)
    survey = _one(map_data, "survey_targets", SURVEY_ID, failures)
    route = _one(map_data, "regional_journeys", ROUTE_ID, failures)
    if project:
        failures.extend(_check_values(project, PROJECT_VALUES, PROJECT_ID))
        if "required_project_id" in project:
            failures.append(f"{PROJECT_ID} must omit required_project_id; source order is not a prerequisite.")
    if zone:
        failures.extend(_check_values(zone, ZONE_VALUES, DARK_ZONE_ID))
    if survey:
        failures.extend(_check_values(survey, SURVEY_VALUES, SURVEY_ID))
    if route:
        if route.get("required_capability_id") != "propulsion_fins":
            failures.append(f"{ROUTE_ID} must preserve its propulsion_fins requirement.")
        if route.get("route_context") != ROUTE_ID:
            failures.append(f"{ROUTE_ID} route_context must remain {ROUTE_ID!r}.")
    if zone and survey and not _rect_cells(survey).issubset(_rect_cells(zone)):
        failures.append(f"{SURVEY_ID} must be contained inside {DARK_ZONE_ID}.")
    for item, label in ((zone, DARK_ZONE_ID), (survey, SURVEY_ID)):
        forbidden = FORBIDDEN_PRELIGHT_FIELDS & set(item)
        if forbidden:
            failures.append(f"{label} must not author pre-light hiding/collision fields: {', '.join(sorted(forbidden))}.")
    try:
        contract = progression_contract if progression_contract is not None else _load_contract()
        failures.extend(_validate_single_owner(map_data, contract))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        failures.append(f"Could not load progression contract for Expansion 11: {exc}")
    failures.extend(_validate_knowledge_and_materials(map_data))
    return failures


def validate_light_return_reachability(
    map_data: dict[str, Any],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    for field, item_id in (("zones", DARK_ZONE_ID), ("survey_targets", SURVEY_ID)):
        matches = _records(map_data, field, item_id)
        if len(matches) != 1:
            continue
        cells = _rect_cells(matches[0])
        if not cells:
            continue
        if cells & solid:
            failures.append(f"{item_id} must remain non-solid before and after the light capability.")
        if not cells.issubset(reachable):
            failures.append(f"{item_id} must be reachable before the light capability and returnable to the boat.")
    boats = _records(map_data, "entities", BOAT_ID)
    if len(boats) == 1:
        boat = boats[0]
        boat_cell = (int(boat.get("entry_x", boat.get("x", -1))), int(boat.get("entry_y", boat.get("y", -1))))
        if boat.get("type") != "boat_spawn" or boat_cell not in reachable:
            failures.append(f"{BOAT_ID} must remain the reachable canonical boat entry.")
    else:
        failures.append(f"Expansion 11 requires exactly one canonical boat entry {BOAT_ID!r}.")
    return failures


def validate_light_return(
    map_path: Path,
    map_data: dict[str, Any],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    return [
        *validate_light_return_schema(map_path, map_data),
        *validate_light_return_reachability(map_data, solid, reachable),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path)
    parser.add_argument("--progression-contract", type=Path)
    args = parser.parse_args()
    with args.map_json.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)
    solid = {
        cell
        for terrain in _items(map_data, "terrain")
        if terrain.get("type") == "solid"
        for cell in _rect_cells(terrain)
    }
    reachable = _reachable_from_boat(map_data, solid)
    contract = _load_contract(args.progression_contract)
    failures = [
        *validate_light_return_schema(args.map_json, map_data, contract),
        *validate_light_return_reachability(map_data, solid, reachable),
    ]
    if failures:
        print("Expansion 11 light-return validation FAIL:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"Expansion 11 light-return validation PASS: {map_data.get('id', args.map_json.name)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
