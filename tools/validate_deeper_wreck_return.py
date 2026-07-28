#!/usr/bin/env python3
"""Validate the bounded Expansion 16 deeper-wreck oxygen return."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

from progression_contract import load_contract
from validate_full_level_traversal import (
    CollisionField,
    PathResult,
    load_player_body,
    load_runtime_budgets,
    map_point,
    shortest_path,
    solid_cells,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "maps" / "production_level_01.greybox.json"
MAP_ID = "production_level_01"
KNOWLEDGE_ID = "upper_left_wreck_relay_discovery"
PROMISE_ID = "upper_left_wreck_relay_landmark"
PROJECT_ID = "closed_circuit_rebreather_project"
CAPABILITY_ID = "closed_circuit_rebreather"
ROUTE_ID = "far_west_deeper_wreck_route"
ZONE_ID = "far_west_confined_wreck_oxygen_zone"
LANDMARK_ID = "far_west_deeper_wreck_landmark"
BACKGROUND_ID = "far_west_deeper_wreck_backdrop"
TOOL_TARGET_ID = "far_west_wreck_data_recorder"
SURVEY_ID = "far_west_deeper_wreck_survey"
DISCOVERY_ID = "far_west_deeper_wreck_discovery"
BOAT_ID = "surface_boat_entry"
RECIPE = {
    "titanium_scrap": 1,
    "rubber_sheet": 1,
    "conductive_coil": 1,
    "insulating_gel": 1,
}
REVIEW_BOUNDS = {"x": 12, "y": 90, "w": 21, "h": 32}
RETURN_RESERVE_SECONDS = 12.0
PROJECT_VALUES = {
    "required_discovery_id": KNOWLEDGE_ID,
    "required_materials": RECIPE,
    "unlocks_capability_id": CAPABILITY_ID,
    "target_id": ZONE_ID,
    "build_phase": "night_debrief",
    "project_label": "Closed-circuit rebreather",
    "completion_label": "Rebreather built",
}
ZONE_VALUES = {
    "type": "marker",
    "oxygen_consumption_zone": True,
    "oxygen_consumption_label": "Confined wreck air",
    "required_capability_id": CAPABILITY_ID,
    "warning_grace_seconds": 1.0,
    "unprotected_oxygen_drain_multiplier": 8.0,
    "route_context": ROUTE_ID,
}
ROUTE_VALUES = {
    "route_label": "Far-west deeper wreck route",
    "promise_gate_id": PROMISE_ID,
    "entry_gate_ids": [ZONE_ID],
    "required_capability_id": CAPABILITY_ID,
    "required_discovery_id": KNOWLEDGE_ID,
    "landmark_zone_id": LANDMARK_ID,
    "tool_target_id": TOOL_TARGET_ID,
    "survey_target_id": SURVEY_ID,
    "commit_entry_id": BOAT_ID,
    "route_context": ROUTE_ID,
}
TOOL_TARGET_VALUES = {
    "type": "tool_target",
    "kind": "crate",
    "tier": "valuable",
    "interaction": "cutter_salvage",
    "interaction_seconds": 2.0,
    "interaction_label": "wreck data recorder",
    "required_tool_id": "salvage_cutter",
    "tool_project_id": "salvage_cutter_project",
    "unlocks_survey_target_id": SURVEY_ID,
    "durable_clearance": True,
}
SURVEY_VALUES = {
    "target_type": "regional",
    "required_capability_id": "survey_scanner_1",
    "required_route_id": ROUTE_ID,
    "route_context": ROUTE_ID,
    "interaction": "survey",
    "interaction_seconds": 3.0,
    "interaction_label": "Survey deeper wreck recorder",
    "clue_label": "Deeper wreck recorder | Cutter access required",
    "finding_label": "Discovery logged: Far-west wreck network",
    "next_lead_label": "Next lead: deeper wreck network unresolved",
    "discovery_id": DISCOVERY_ID,
    "commit_map_id": MAP_ID,
    "commit_map_path": "res://maps/production_level_01.greybox.json",
    "commit_entry_id": BOAT_ID,
}
FORBIDDEN_ZONE_FIELDS = {
    "collision", "damage", "destination_map_id", "health_damage", "solid",
    "teleport", "world_connector",
}
FORBIDDEN_STATE_FIELDS = {
    "active", "banked", "capability_owned", "completed", "oxygen", "pending",
    "profile_state", "progress", "save_path", "selected",
}
EPSILON = 1.0e-6


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records(map_data: dict[str, Any], field: str, item_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(map_data, field) if item.get("id") == item_id]


def _triggered(map_data: dict[str, Any]) -> bool:
    records = (
        ("material_projects", PROJECT_ID),
        ("zones", ZONE_ID),
        ("zones", LANDMARK_ID),
        ("background", BACKGROUND_ID),
        ("entities", TOOL_TARGET_ID),
        ("regional_journeys", ROUTE_ID),
        ("survey_targets", SURVEY_ID),
    )
    return any(_records(map_data, field, item_id) for field, item_id in records) or any(
        item.get("oxygen_consumption_zone") is True for item in _items(map_data, "zones")
    )


def _one(
    map_data: dict[str, Any],
    field: str,
    item_id: str,
    failures: list[str],
) -> dict[str, Any]:
    matches = _records(map_data, field, item_id)
    if len(matches) != 1:
        failures.append(
            f"Expansion 16 requires exactly one {field} record {item_id!r}; found {len(matches)}."
        )
        return {}
    return matches[0]


def _check_values(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [
        f"{label} {field} must be exactly {value!r}."
        for field, value in expected.items()
        if item.get(field) != value
    ]


def _rect_contains(outer: dict[str, Any], inner: dict[str, Any]) -> bool:
    try:
        return (
            int(outer["x"]) <= int(inner["x"])
            and int(outer["y"]) <= int(inner["y"])
            and int(inner["x"]) + int(inner.get("w", 1))
            <= int(outer["x"]) + int(outer["w"])
            and int(inner["y"]) + int(inner.get("h", 1))
            <= int(outer["y"]) + int(outer["h"])
        )
    except (KeyError, TypeError, ValueError):
        return False


def _guaranteed_materials(map_data: dict[str, Any]) -> dict[str, int]:
    quantities: dict[str, int] = {}
    for pool in _items(map_data, "material_candidate_pools"):
        if pool.get("pool_role") == "optional_bonus":
            continue
        material_id = str(pool.get("material_id", ""))
        count = pool.get("select_count", 0)
        quantities[material_id] = quantities.get(material_id, 0) + (
            max(0, count) if isinstance(count, int) and not isinstance(count, bool) else 0
        )
    for source in _items(map_data, "biological_resource_sources"):
        material_id = str(source.get("material_id", ""))
        count = source.get("material_quantity", 0)
        quantities[material_id] = quantities.get(material_id, 0) + (
            max(0, count) if isinstance(count, int) and not isinstance(count, bool) else 0
        )
    return quantities


def validate_deeper_wreck_schema(
    map_path: Path,
    map_data: dict[str, Any],
    contract: dict[str, Any] | None = None,
) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    if map_data.get("id") != MAP_ID:
        failures.append(f"Expansion 16 deeper-wreck records are supported only on {MAP_ID}.")
    project = _one(map_data, "material_projects", PROJECT_ID, failures)
    zone = _one(map_data, "zones", ZONE_ID, failures)
    landmark = _one(map_data, "zones", LANDMARK_ID, failures)
    backdrop = _one(map_data, "background", BACKGROUND_ID, failures)
    target = _one(map_data, "entities", TOOL_TARGET_ID, failures)
    route = _one(map_data, "regional_journeys", ROUTE_ID, failures)
    survey = _one(map_data, "survey_targets", SURVEY_ID, failures)
    boat = _one(map_data, "entities", BOAT_ID, failures)

    failures.extend(_check_values(project, PROJECT_VALUES, PROJECT_ID))
    if "required_project_id" in project:
        failures.append(f"{PROJECT_ID} must omit required_project_id.")
    failures.extend(_check_values(zone, ZONE_VALUES, ZONE_ID))
    failures.extend(_check_values(route, ROUTE_VALUES, ROUTE_ID))
    failures.extend(_check_values(target, TOOL_TARGET_VALUES, TOOL_TARGET_ID))
    failures.extend(_check_values(survey, SURVEY_VALUES, SURVEY_ID))
    if landmark.get("type") != "marker" or landmark.get("regional_landmark") is not True:
        failures.append(f"{LANDMARK_ID} must be one regional_landmark marker.")
    if (
        landmark.get("regional_journey_id") != ROUTE_ID
        or landmark.get("landmark_label") != "Far-West Deeper Wreck"
    ):
        failures.append(f"{LANDMARK_ID} must link to {ROUTE_ID} with the locked label.")
    if (
        backdrop.get("type") != "background"
        or backdrop.get("regional_journey_id") != ROUTE_ID
        or any(backdrop.get(field) != landmark.get(field) for field in ("x", "y", "w", "h"))
    ):
        failures.append(f"{BACKGROUND_ID} must match the landmark rectangle and route.")
    for item, label in ((zone, ZONE_ID), (landmark, LANDMARK_ID), (target, TOOL_TARGET_ID), (survey, SURVEY_ID)):
        if not _rect_contains(REVIEW_BOUNDS, item):
            failures.append(f"{label} must stay inside the locked far-west review bounds.")
    if not _rect_contains(zone, target) or not _rect_contains(zone, survey):
        failures.append(f"{TOOL_TARGET_ID} and {SURVEY_ID} must sit inside {ZONE_ID}.")
    if not _rect_contains(landmark, target) or not _rect_contains(landmark, survey):
        failures.append(f"{TOOL_TARGET_ID} and {SURVEY_ID} must sit inside {LANDMARK_ID}.")
    if boat.get("type") != "boat_spawn":
        failures.append(f"{BOAT_ID} must remain the canonical boat_spawn.")

    forbidden_zone = sorted(FORBIDDEN_ZONE_FIELDS & set(zone))
    if forbidden_zone:
        failures.append(f"{ZONE_ID} must not author collision, travel, or damage fields: {forbidden_zone}.")
    state_fields = sorted(
        FORBIDDEN_STATE_FIELDS
        & (set(project) | set(zone) | set(route) | set(target) | set(survey))
    )
    if state_fields:
        failures.append(f"Expansion 16 source must not author runtime state fields: {state_fields}.")
    for field in ("required_pressure_capability_id", "required_light_capability_id", "required_oxygen_capability_id"):
        if field in survey:
            failures.append(f"{SURVEY_ID} must not add explicit interaction gate {field}.")

    owners = [
        str(item.get("id", ""))
        for item in _items(map_data, "material_projects")
        if item.get("unlocks_capability_id") == CAPABILITY_ID
    ]
    if owners != [PROJECT_ID]:
        failures.append(f"{CAPABILITY_ID} must be owned only by {PROJECT_ID}; found {owners}.")
    resolved_contract = contract if contract is not None else load_contract()
    purchase_ids = {
        str(item.get("id", ""))
        for field in ("session_upgrades", "durable_purchases")
        for item in _items(resolved_contract, field)
    }
    if CAPABILITY_ID in purchase_ids:
        failures.append(f"{CAPABILITY_ID} must not have score/session purchase ownership.")
    declarations = [
        item for item in _items(resolved_contract, "durable_capabilities")
        if item.get("id") == CAPABILITY_ID
    ]
    if len(declarations) != 1:
        failures.append(f"{CAPABILITY_ID} requires exactly one durable capability declaration.")

    knowledge_sources = [
        item for item in _items(map_data, "survey_targets")
        if item.get("discovery_id") == KNOWLEDGE_ID
    ]
    if len(knowledge_sources) != 1:
        failures.append(f"{PROJECT_ID} requires exactly one source survey for {KNOWLEDGE_ID}.")
    elif any(
        knowledge_sources[0].get(field) == CAPABILITY_ID
        for field in (
            "required_capability_id",
            "required_pressure_capability_id",
            "required_light_capability_id",
        )
    ):
        failures.append(f"{KNOWLEDGE_ID} must not require the rebreather it reveals.")
    if DISCOVERY_ID == KNOWLEDGE_ID:
        failures.append("Expansion 16 prerequisite and result discoveries must remain distinct.")

    guaranteed = _guaranteed_materials(map_data)
    for material_id, quantity in RECIPE.items():
        if guaranteed.get(material_id, 0) < quantity:
            failures.append(
                f"{PROJECT_ID} requires {quantity} {material_id}, but guaranteed sources provide "
                f"{guaranteed.get(material_id, 0)}."
            )
    relevant_sources = [
        item
        for field in ("entities", "biological_resource_sources")
        for item in _items(map_data, field)
        if item.get("material_id") in RECIPE
    ]
    if any(item.get("required_capability_id") == CAPABILITY_ID for item in relevant_sources):
        failures.append(f"{PROJECT_ID} ingredients must not be gated by {CAPABILITY_ID}.")
    if not isinstance(route.get("intent"), str) or not route["intent"].strip():
        failures.append(f"{ROUTE_ID} intent must be non-empty text.")
    return failures


def _pixel_rect(zone: dict[str, Any], tile_size: int) -> tuple[float, float, float, float]:
    return (
        float(zone["x"]) * tile_size,
        float(zone["y"]) * tile_size,
        float(int(zone["x"]) + int(zone["w"])) * tile_size,
        float(int(zone["y"]) + int(zone["h"])) * tile_size,
    )


def _inside(point: tuple[float, float], rect: tuple[float, float, float, float]) -> bool:
    return rect[0] <= point[0] < rect[2] and rect[1] <= point[1] < rect[3]


def _path_exposure(
    path: PathResult,
    rect: tuple[float, float, float, float],
    speed: float,
) -> tuple[float, float]:
    exposure = 0.0
    distance_to_entry = math.inf
    distance = 0.0
    for start, end in zip(path.points, path.points[1:]):
        segment = math.dist(start, end)
        midpoint = ((start[0] + end[0]) * 0.5, (start[1] + end[1]) * 0.5)
        if _inside(midpoint, rect):
            if not math.isfinite(distance_to_entry):
                distance_to_entry = distance
            exposure += segment / speed
        distance += segment
    return exposure, distance_to_entry


def deeper_wreck_route_budget(map_data: dict[str, Any]) -> dict[str, float | str]:
    units = map_data.get("units", {})
    tile_size = int(units.get("tile_size_px", 0))
    zone = _records(map_data, "zones", ZONE_ID)[0]
    target = _records(map_data, "entities", TOOL_TARGET_ID)[0]
    survey = _records(map_data, "survey_targets", SURVEY_ID)[0]
    boat = _records(map_data, "entities", BOAT_ID)[0]
    field = CollisionField(
        int(units.get("width_tiles", 0)),
        int(units.get("height_tiles", 0)),
        tile_size,
        solid_cells(map_data),
        load_player_body(),
    )
    budgets = load_runtime_budgets()
    start = map_point(boat, tile_size, entry=True)
    target_point = map_point(target, tile_size)
    survey_point = map_point(survey, tile_size)
    if not field.center_is_clear(target_point) or shortest_path(field, start, target_point) is None:
        return {"error": "cutter target has no collision-clear route from the boat"}
    outbound = shortest_path(field, start, survey_point)
    return_path = shortest_path(field, survey_point, start)
    if outbound is None or return_path is None:
        return {"error": "survey has no collision-clear boat route and return"}
    speed = budgets.swim_speed_px_per_second
    zone_rect = _pixel_rect(zone, tile_size)
    outbound_exposure, entry_distance = _path_exposure(outbound, zone_rect, speed)
    return_exposure, _ = _path_exposure(return_path, zone_rect, speed)
    if not math.isfinite(entry_distance):
        return {"error": "collision-clear survey route never enters the oxygen zone"}
    grace = float(zone["warning_grace_seconds"])
    multiplier = float(zone["unprotected_oxygen_drain_multiplier"])
    critical = max(0.0, outbound_exposure - grace) + max(0.0, return_exposure - grace)
    normal_round_trip = (outbound.distance_px + return_path.distance_px) / speed
    cutter_seconds = float(target["interaction_seconds"])
    scanner_seconds = float(survey["interaction_seconds"])
    protected = normal_round_trip + cutter_seconds + scanner_seconds
    unprotected = protected + critical * (multiplier - 1.0)
    scout = entry_distance * 2.0 / speed + min(grace, outbound_exposure)
    return {
        "normal_round_trip_seconds": normal_round_trip,
        "zone_warning_seconds": min(grace, outbound_exposure) + min(grace, return_exposure),
        "zone_critical_seconds": critical,
        "cutter_seconds": cutter_seconds,
        "scanner_seconds": scanner_seconds,
        "return_reserve_seconds": RETURN_RESERVE_SECONDS,
        "protected_demand_seconds": protected,
        "unprotected_demand_seconds": unprotected,
        "scout_demand_seconds": scout,
        "protected_margin_seconds": budgets.base_oxygen_seconds - protected,
        "optional_shortfall_seconds": unprotected + RETURN_RESERVE_SECONDS - budgets.upgraded_oxygen_seconds,
    }


def validate_deeper_wreck_routes(map_data: dict[str, Any]) -> list[str]:
    if not _triggered(map_data):
        return []
    try:
        budget = deeper_wreck_route_budget(map_data)
    except (IndexError, KeyError, TypeError, ValueError) as exc:
        return [f"Expansion 16 route budget could not be evaluated: {exc}"]
    if "error" in budget:
        return [str(budget["error"])]
    budgets = load_runtime_budgets()
    failures: list[str] = []
    protected = float(budget["protected_demand_seconds"])
    unprotected = float(budget["unprotected_demand_seconds"])
    scout = float(budget["scout_demand_seconds"])
    if protected + RETURN_RESERVE_SECONDS > budgets.base_oxygen_seconds + EPSILON:
        failures.append(
            f"Rebreather route must retain {RETURN_RESERVE_SECONDS:g}s on the base tank; "
            f"demand={protected:.1f}s."
        )
    if unprotected + RETURN_RESERVE_SECONDS <= budgets.upgraded_oxygen_seconds + EPSILON:
        failures.append(
            "Unprotected deeper-wreck operation can be completed with oxygen_tank_1; "
            f"demand_with_reserve={unprotected + RETURN_RESERVE_SECONDS:.1f}s."
        )
    if scout + RETURN_RESERVE_SECONDS > budgets.base_oxygen_seconds + EPSILON:
        failures.append(
            f"A fresh base-tank player cannot scout the oxygen threshold and retreat; "
            f"demand_with_reserve={scout + RETURN_RESERVE_SECONDS:.1f}s."
        )
    if float(budget["zone_critical_seconds"]) <= 0.0:
        failures.append("The complete route must include critical oxygen-zone exposure.")
    return failures


def validate_deeper_wreck_return(
    map_path: Path,
    map_data: dict[str, Any],
    contract: dict[str, Any] | None = None,
) -> list[str]:
    failures = validate_deeper_wreck_schema(map_path, map_data, contract)
    if not failures:
        failures.extend(validate_deeper_wreck_routes(map_data))
    return failures


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    failures = validate_deeper_wreck_return(map_path, map_data)
    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1
    if not _triggered(map_data):
        print(f"{map_data.get('id')} deeper-wreck return PASS: contract not authored on this map.")
        return 0
    budget = deeper_wreck_route_budget(map_data)
    print(
        f"{map_data.get('id')} deeper-wreck return PASS: "
        f"normal={float(budget['normal_round_trip_seconds']):.1f}s "
        f"critical={float(budget['zone_critical_seconds']):.1f}s "
        f"protected={float(budget['protected_demand_seconds']):.1f}s "
        f"base_margin={float(budget['protected_margin_seconds']):.1f}s "
        f"unprotected={float(budget['unprotected_demand_seconds']):.1f}s "
        f"optional_shortfall={float(budget['optional_shortfall_seconds']):.1f}s "
        f"scout={float(budget['scout_demand_seconds']):.1f}s."
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", nargs="?", type=Path, default=DEFAULT_MAP)
    args = parser.parse_args()
    path = args.map_json if args.map_json.is_absolute() else ROOT / args.map_json
    return run_validation(path)


if __name__ == "__main__":
    raise SystemExit(main())
