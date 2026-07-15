#!/usr/bin/env python3
"""Validate the bounded Expansion 12 pressure-suit return contract."""

from __future__ import annotations

import argparse
import heapq
import json
import math
import sys
from pathlib import Path
from typing import Any

from progression_contract import load_contract
from validate_full_level_traversal import (
    CollisionField,
    Point,
    load_player_body,
    load_runtime_budgets,
    map_point,
    shortest_path,
    solid_cells as map_solid_cells,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "maps" / "production_level_01.greybox.json"
MAP_ID = "production_level_01"
BOAT_ID = "surface_boat_entry"
KNOWLEDGE_ID = "signal_reef_deep_harmonic_discovery"
PROJECT_ID = "pressure_suit_1_project"
CAPABILITY_ID = "pressure_suit_1"
ROUTE_ID = "deep_harmonic_abyssal_basin_route"
ZONE_ID = "abyssal_basin_pressure_zone"
LANDMARK_ID = "abyssal_basin_landmark"
BACKGROUND_ID = "abyssal_basin_harmonic_source_backdrop"
SURVEY_ID = "abyssal_basin_harmonic_source_survey"
DISCOVERY_ID = "abyssal_basin_harmonic_source_discovery"
RECIPE = {"titanium_scrap": 2, "rubber_sheet": 1, "insulating_gel": 1}
PROJECT_VALUES = {
    "required_discovery_id": KNOWLEDGE_ID,
    "required_materials": RECIPE,
    "unlocks_capability_id": CAPABILITY_ID,
    "target_id": SURVEY_ID,
    "build_phase": "night_debrief",
    "project_label": "Pressure suit project",
    "completion_label": "Pressure suit built",
}
ZONE_VALUES = {
    "type": "marker",
    "x": 60,
    "y": 126,
    "w": 77,
    "h": 30,
    "pressure_zone": True,
    "pressure_level": "abyssal",
    "pressure_label": "Abyssal pressure",
    "required_capability_id": CAPABILITY_ID,
    "warning_grace_seconds": 1.0,
    "unprotected_oxygen_drain_multiplier": 8.0,
    "route_context": ROUTE_ID,
}
LANDMARK_VALUES = {
    "type": "marker",
    "x": 81,
    "y": 141,
    "w": 33,
    "h": 15,
    "regional_landmark": True,
    "regional_journey_id": ROUTE_ID,
    "landmark_label": "Abyssal Basin",
}
BACKGROUND_VALUES = {
    "type": "background",
    "x": 81,
    "y": 141,
    "w": 33,
    "h": 15,
    "regional_landmark": True,
    "regional_journey_id": ROUTE_ID,
}
ROUTE_VALUES = {
    "route_label": "Abyssal basin route",
    "promise_gate_id": "signal_reef_deep_harmonic_dark_zone",
    "entry_gate_ids": [ZONE_ID],
    "required_capability_id": CAPABILITY_ID,
    "landmark_zone_id": LANDMARK_ID,
    "survey_target_id": SURVEY_ID,
    "commit_entry_id": BOAT_ID,
    "route_context": ROUTE_ID,
}
SURVEY_VALUES = {
    "target_type": "regional",
    "x": 95,
    "y": 149,
    "w": 2,
    "h": 2,
    "required_capability_id": "survey_scanner_1",
    "required_pressure_capability_id": CAPABILITY_ID,
    "required_route_id": ROUTE_ID,
    "route_context": ROUTE_ID,
    "interaction": "survey",
    "interaction_seconds": 3.0,
    "interaction_label": "Survey abyssal source",
    "clue_label": "Abyssal signal | Pressure suit required",
    "finding_label": "Discovery logged: Abyssal harmonic source",
    "next_lead_label": "Abyssal source charted | Further descent unresolved",
    "discovery_id": DISCOVERY_ID,
    "commit_map_id": MAP_ID,
    "commit_map_path": "res://maps/production_level_01.greybox.json",
    "commit_entry_id": BOAT_ID,
}
FORBIDDEN_ZONE_FIELDS = {
    "collision",
    "damage",
    "health_damage",
    "solid",
    "teleport",
    "world_connector",
}
FORBIDDEN_STATE_FIELDS = {
    "active",
    "capability_owned",
    "completed",
    "oxygen",
    "pending",
    "profile_state",
    "progress",
    "save_path",
}
MIN_PROTECTED_MARGIN_SECONDS = 15.0
EPSILON = 1.0e-6


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records(map_data: dict[str, Any], field: str, item_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(map_data, field) if item.get("id") == item_id]


def _triggered(map_data: dict[str, Any]) -> bool:
    named_records = (
        ("material_projects", PROJECT_ID),
        ("zones", ZONE_ID),
        ("zones", LANDMARK_ID),
        ("background", BACKGROUND_ID),
        ("regional_journeys", ROUTE_ID),
        ("survey_targets", SURVEY_ID),
    )
    return any(_records(map_data, field, item_id) for field, item_id in named_records) or any(
        item.get("discovery_id") == DISCOVERY_ID for item in _items(map_data, "survey_targets")
    )


def _one(
    map_data: dict[str, Any],
    field: str,
    item_id: str,
    failures: list[str],
) -> dict[str, Any]:
    matches = _records(map_data, field, item_id)
    if len(matches) != 1:
        failures.append(f"Expansion 12 requires exactly one {field} record {item_id!r}; found {len(matches)}.")
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
            and int(inner["x"]) + int(inner["w"]) <= int(outer["x"]) + int(outer["w"])
            and int(inner["y"]) + int(inner["h"]) <= int(outer["y"]) + int(outer["h"])
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
        quantities[material_id] = quantities.get(material_id, 0) + max(0, count if isinstance(count, int) else 0)
    for source in _items(map_data, "biological_resource_sources"):
        material_id = str(source.get("material_id", ""))
        count = source.get("material_quantity", 0)
        quantities[material_id] = quantities.get(material_id, 0) + max(0, count if isinstance(count, int) else 0)
    return quantities


def validate_pressure_return_schema(
    map_path: Path,
    map_data: dict[str, Any],
    contract: dict[str, Any] | None = None,
) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    if map_data.get("id") != MAP_ID:
        failures.append(f"Expansion 12 pressure records are supported only on {MAP_ID}.")
    project = _one(map_data, "material_projects", PROJECT_ID, failures)
    zone = _one(map_data, "zones", ZONE_ID, failures)
    landmark = _one(map_data, "zones", LANDMARK_ID, failures)
    backdrop = _one(map_data, "background", BACKGROUND_ID, failures)
    route = _one(map_data, "regional_journeys", ROUTE_ID, failures)
    survey = _one(map_data, "survey_targets", SURVEY_ID, failures)
    boat = _one(map_data, "entities", BOAT_ID, failures)

    failures.extend(_check_values(project, PROJECT_VALUES, PROJECT_ID))
    if "required_project_id" in project:
        failures.append(f"{PROJECT_ID} must omit required_project_id.")
    project_ids = [str(item.get("id", "")) for item in _items(map_data, "material_projects")]
    if PROJECT_ID in project_ids and "dive_light_1_project" in project_ids:
        if project_ids.index(PROJECT_ID) <= project_ids.index("dive_light_1_project"):
            failures.append(f"{PROJECT_ID} must follow dive_light_1_project in source order.")

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
        failures.append(f"{CAPABILITY_ID} must have exactly one durable capability declaration.")
    owners = [
        str(item.get("id", ""))
        for item in _items(map_data, "material_projects")
        if item.get("unlocks_capability_id") == CAPABILITY_ID
    ]
    if owners != [PROJECT_ID]:
        failures.append(f"{CAPABILITY_ID} must be owned only by {PROJECT_ID}; found {owners}.")

    knowledge = [
        item for item in _items(map_data, "survey_targets")
        if item.get("discovery_id") == KNOWLEDGE_ID
    ]
    if len(knowledge) != 1:
        failures.append(f"{PROJECT_ID} requires exactly one source survey for {KNOWLEDGE_ID}.")
    elif knowledge[0].get("required_pressure_capability_id") == CAPABILITY_ID:
        failures.append(f"{KNOWLEDGE_ID} must not require the pressure suit it reveals.")

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

    failures.extend(_check_values(zone, ZONE_VALUES, ZONE_ID))
    forbidden_zone = sorted(FORBIDDEN_ZONE_FIELDS & set(zone))
    if forbidden_zone:
        failures.append(f"{ZONE_ID} must not author collision, travel, or damage fields: {forbidden_zone}.")
    failures.extend(_check_values(landmark, LANDMARK_VALUES, LANDMARK_ID))
    failures.extend(_check_values(backdrop, BACKGROUND_VALUES, BACKGROUND_ID))
    failures.extend(_check_values(route, ROUTE_VALUES, ROUTE_ID))
    if not isinstance(route.get("intent"), str) or not route["intent"].strip():
        failures.append(f"{ROUTE_ID} intent must be non-empty text.")
    failures.extend(_check_values(survey, SURVEY_VALUES, SURVEY_ID))
    if not _rect_contains(zone, survey) or not _rect_contains(landmark, survey):
        failures.append(f"{SURVEY_ID} must sit inside both the pressure zone and abyssal landmark.")
    forbidden_state = sorted(FORBIDDEN_STATE_FIELDS & (set(project) | set(zone) | set(survey)))
    if forbidden_state:
        failures.append(f"Expansion 12 source must not author runtime state fields: {forbidden_state}.")
    if boat.get("type") != "boat_spawn":
        failures.append(f"{BOAT_ID} must remain the canonical boat_spawn.")
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


def _weighted_cost(
    field: CollisionField,
    start: Point,
    target: Point,
    zone_rect: tuple[float, float, float, float],
    speed: float,
    multiplier: float,
) -> float:
    if not field.center_is_clear(start) or not field.center_is_clear(target):
        return math.inf
    frontier: list[tuple[float, float, Point]] = [(math.dist(start, target) / speed, 0.0, start)]
    distances = {start: 0.0}
    while frontier:
        _estimate, cost, point = heapq.heappop(frontier)
        if cost > distances.get(point, math.inf) + EPSILON:
            continue
        if point == target:
            return cost
        for neighbor, distance_px in field.neighbors(point):
            midpoint = ((point[0] + neighbor[0]) * 0.5, (point[1] + neighbor[1]) * 0.5)
            drain = multiplier if _inside(midpoint, zone_rect) else 1.0
            candidate = cost + distance_px / speed * drain
            if candidate + EPSILON >= distances.get(neighbor, math.inf):
                continue
            distances[neighbor] = candidate
            estimate = candidate + math.dist(neighbor, target) / speed
            heapq.heappush(frontier, (estimate, candidate, neighbor))
    return math.inf


def pressure_route_budget(map_data: dict[str, Any]) -> dict[str, float | str]:
    units = map_data.get("units", {})
    tile_size = int(units.get("tile_size_px", 0))
    zone = _records(map_data, "zones", ZONE_ID)[0]
    survey = _records(map_data, "survey_targets", SURVEY_ID)[0]
    boat = _records(map_data, "entities", BOAT_ID)[0]
    field = CollisionField(
        int(units.get("width_tiles", 0)),
        int(units.get("height_tiles", 0)),
        tile_size,
        map_solid_cells(map_data),
        load_player_body(),
    )
    budgets = load_runtime_budgets()
    start = map_point(boat, tile_size, entry=True)
    target = map_point(survey, tile_size)
    outbound = shortest_path(field, start, target)
    return_path = shortest_path(field, target, start)
    if outbound is None or return_path is None:
        return {"error": "survey has no collision-clear boat route and return"}
    zone_rect = _pixel_rect(zone, tile_size)
    multiplier = float(zone["unprotected_oxygen_drain_multiplier"])
    grace = float(zone["warning_grace_seconds"])
    interaction = float(survey["interaction_seconds"])
    weighted_one_way = _weighted_cost(
        field, start, target, zone_rect, budgets.swim_speed_px_per_second, multiplier
    )
    grace_saving = grace * (multiplier - 1.0)
    protected_demand = (
        outbound.distance_px + return_path.distance_px
    ) / budgets.swim_speed_px_per_second + interaction
    unprotected_demand = weighted_one_way * 2.0 + interaction * multiplier - grace_saving
    first_inside = next((point for point in outbound.points if _inside(point, zone_rect)), None)
    scout_demand = math.inf
    if first_inside is not None:
        scout_one_way = _weighted_cost(
            field, start, first_inside, zone_rect, budgets.swim_speed_px_per_second, multiplier
        )
        scout_demand = max(0.0, scout_one_way * 2.0 - grace_saving)
    target_remaining = budgets.upgraded_oxygen_seconds - (
        weighted_one_way + interaction * multiplier - grace_saving
    )
    rest_cost = math.inf
    for rest in _items(map_data, "zones"):
        if rest.get("oxygen_rest") is not True:
            continue
        try:
            rest_target = map_point(rest, tile_size)
        except ValueError:
            continue
        rest_cost = min(
            rest_cost,
            _weighted_cost(
                field,
                target,
                rest_target,
                zone_rect,
                budgets.swim_speed_px_per_second,
                multiplier,
            ),
        )
    return {
        "protected_demand": protected_demand,
        "protected_margin": budgets.base_oxygen_seconds - protected_demand,
        "unprotected_demand": unprotected_demand,
        "optional_shortfall": unprotected_demand - budgets.upgraded_oxygen_seconds,
        "scout_demand": scout_demand,
        "target_remaining": target_remaining,
        "rest_escape_cost": rest_cost,
    }


def validate_pressure_return_routes(map_data: dict[str, Any]) -> list[str]:
    if not _triggered(map_data):
        return []
    try:
        budget = pressure_route_budget(map_data)
    except (IndexError, KeyError, TypeError, ValueError) as exc:
        return [f"Expansion 12 route budget could not be evaluated: {exc}"]
    if "error" in budget:
        return [str(budget["error"])]
    failures: list[str] = []
    if float(budget["protected_margin"]) < MIN_PROTECTED_MARGIN_SECONDS:
        failures.append(
            f"Pressure-suit route needs at least {MIN_PROTECTED_MARGIN_SECONDS:g}s base-tank margin; "
            f"found {float(budget['protected_margin']):.1f}s."
        )
    if float(budget["optional_shortfall"]) <= 0.0:
        failures.append(
            "Unprotected pressure route can be completed with oxygen_tank_1; "
            f"demand={float(budget['unprotected_demand']):.1f}s."
        )
    if float(budget["scout_demand"]) > load_runtime_budgets().base_oxygen_seconds:
        failures.append("A fresh base-tank player cannot scout the pressure threshold and retreat.")
    rest_cost = float(budget["rest_escape_cost"])
    if math.isfinite(rest_cost) and float(budget["target_remaining"]) + EPSILON >= rest_cost:
        failures.append(
            "Unprotected optional-tank route can reach an oxygen-rest pocket after the survey; "
            f"remaining={float(budget['target_remaining']):.1f}s rest_cost={rest_cost:.1f}s."
        )
    return failures


def validate_pressure_return(map_path: Path, map_data: dict[str, Any]) -> list[str]:
    failures = validate_pressure_return_schema(map_path, map_data)
    if not failures:
        failures.extend(validate_pressure_return_routes(map_data))
    return failures


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    failures = validate_pressure_return(map_path, map_data)
    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1
    if not _triggered(map_data):
        print(f"{map_data.get('id')} pressure return PASS: contract not authored on this map.")
        return 0
    budget = pressure_route_budget(map_data)
    print(
        f"{map_data.get('id')} pressure return PASS: "
        f"protected={float(budget['protected_demand']):.1f}s "
        f"base_margin={float(budget['protected_margin']):.1f}s "
        f"unprotected={float(budget['unprotected_demand']):.1f}s "
        f"optional_shortfall={float(budget['optional_shortfall']):.1f}s "
        f"scout={float(budget['scout_demand']):.1f}s."
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
