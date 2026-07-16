#!/usr/bin/env python3
"""Validate the bounded Expansion 13 Southeast Wreck Return contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

from validate_full_level_traversal import (
    CollisionField,
    load_player_body,
    load_runtime_budgets,
    map_point,
    rect_cells,
    shortest_path,
    solid_cells,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "maps" / "production_level_01.greybox.json"
MAP_ID = "production_level_01"
BOAT_ID = "surface_boat_entry"
KNOWLEDGE_ID = "abyssal_basin_harmonic_source_discovery"
PRESSURE_ZONE_ID = "abyssal_basin_pressure_zone"
PROMISE_LANDMARK_ID = "abyssal_basin_landmark"
ROUTE_ID = "southeast_wreck_archive_route"
LANDMARK_ID = "southeast_wreck_archive_landmark"
BACKGROUND_ID = "southeast_wreck_archive_backdrop"
RECORDER_ID = "southeast_wreck_recorder"
SURVEY_ID = "southeast_wreck_archive_survey"
DISCOVERY_ID = "southeast_wreck_archive_discovery"
TERRAIN_SHA256 = "5f01b2cb2ad2cb7729cd980dfba5bd960c0b9cbeb1b034e6bf29558162364c72"
MAX_BASE_MARGIN_SECONDS = 20.0
MIN_UPGRADE_GAIN_SECONDS = 14.0
RUNTIME_STATE_FIELDS = {
    "active",
    "cleared",
    "collected",
    "committed",
    "pending",
    "profile_state",
    "progress",
}
RECORDER_VALUES = {
    "type": "tool_target",
    "kind": "crate",
    "tier": "valuable",
    "interaction": "cutter_salvage",
    "interaction_seconds": 2.0,
    "interaction_label": "wreck recorder",
    "required_tool_id": "salvage_cutter",
    "unlocks_survey_target_id": SURVEY_ID,
    "durable_clearance": True,
}
SURVEY_VALUES = {
    "target_type": "regional",
    "required_capability_id": "survey_scanner_1",
    "required_pressure_capability_id": "pressure_suit_1",
    "required_route_id": ROUTE_ID,
    "route_context": ROUTE_ID,
    "interaction": "survey",
    "interaction_seconds": 3.0,
    "interaction_label": "Survey wreck archive",
    "clue_label": "Wreck archive | Recorder access required",
    "finding_label": "Discovery logged: Southeast wreck archive",
    "next_lead_label": "Next lead: distant wreck network unresolved",
    "discovery_id": DISCOVERY_ID,
    "commit_map_id": MAP_ID,
    "commit_map_path": "res://maps/production_level_01.greybox.json",
    "commit_entry_id": BOAT_ID,
}
ROUTE_VALUES = {
    "route_label": "Southeast wreck archive route",
    "promise_gate_id": PROMISE_LANDMARK_ID,
    "entry_gate_ids": [PRESSURE_ZONE_ID],
    "required_capability_id": "pressure_suit_1",
    "required_discovery_id": KNOWLEDGE_ID,
    "landmark_zone_id": LANDMARK_ID,
    "tool_target_id": RECORDER_ID,
    "survey_target_id": SURVEY_ID,
    "commit_entry_id": BOAT_ID,
    "route_context": ROUTE_ID,
}


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records(map_data: dict[str, Any], field: str, item_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(map_data, field) if item.get("id") == item_id]


def _triggered(map_data: dict[str, Any]) -> bool:
    named = (
        ("regional_journeys", ROUTE_ID),
        ("zones", LANDMARK_ID),
        ("background", BACKGROUND_ID),
        ("entities", RECORDER_ID),
        ("survey_targets", SURVEY_ID),
    )
    return any(_records(map_data, field, item_id) for field, item_id in named) or any(
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
        failures.append(f"Expansion 13 requires exactly one {field} record {item_id!r}; found {len(matches)}.")
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
            and int(inner["x"]) + int(inner.get("w", 1)) <= int(outer["x"]) + int(outer["w"])
            and int(inner["y"]) + int(inner.get("h", 1)) <= int(outer["y"]) + int(outer["h"])
        )
    except (KeyError, TypeError, ValueError):
        return False


def _terrain_hash(map_data: dict[str, Any]) -> str:
    payload = json.dumps(map_data.get("terrain"), sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def validate_southeast_wreck_schema(map_data: dict[str, Any]) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    if map_data.get("id") != MAP_ID:
        failures.append(f"Expansion 13 records are supported only on {MAP_ID}.")
    route = _one(map_data, "regional_journeys", ROUTE_ID, failures)
    landmark = _one(map_data, "zones", LANDMARK_ID, failures)
    backdrop = _one(map_data, "background", BACKGROUND_ID, failures)
    recorder = _one(map_data, "entities", RECORDER_ID, failures)
    survey = _one(map_data, "survey_targets", SURVEY_ID, failures)
    boat = _one(map_data, "entities", BOAT_ID, failures)
    pressure_zone = _one(map_data, "zones", PRESSURE_ZONE_ID, failures)

    failures.extend(_check_values(route, ROUTE_VALUES, ROUTE_ID))
    if not isinstance(route.get("intent"), str) or not route["intent"].strip():
        failures.append(f"{ROUTE_ID} intent must be non-empty text.")
    failures.extend(_check_values(recorder, RECORDER_VALUES, RECORDER_ID))
    failures.extend(_check_values(survey, SURVEY_VALUES, SURVEY_ID))
    failures.extend(_check_values(
        landmark,
        {
            "type": "marker",
            "regional_landmark": True,
            "regional_journey_id": ROUTE_ID,
            "landmark_label": "Southeast Wreck Archive",
        },
        LANDMARK_ID,
    ))
    failures.extend(_check_values(
        backdrop,
        {"type": "background", "regional_landmark": True, "regional_journey_id": ROUTE_ID},
        BACKGROUND_ID,
    ))
    if landmark and backdrop and any(landmark.get(field) != backdrop.get(field) for field in ("x", "y", "w", "h")):
        failures.append(f"{BACKGROUND_ID} must match the {LANDMARK_ID} rectangle.")
    if landmark and recorder and not _rect_contains(landmark, recorder):
        failures.append(f"{RECORDER_ID} must sit inside {LANDMARK_ID}.")
    if landmark and survey and not _rect_contains(landmark, survey):
        failures.append(f"{SURVEY_ID} must sit inside {LANDMARK_ID}.")

    relationship_owners = [
        item for item in _items(map_data, "entities")
        if item.get("unlocks_survey_target_id") == SURVEY_ID
    ]
    if [item.get("id") for item in relationship_owners] != [RECORDER_ID]:
        failures.append(f"{SURVEY_ID} must have exactly one source unlock owner: {RECORDER_ID}.")
    for entity in _items(map_data, "entities"):
        if entity.get("id") == RECORDER_ID:
            continue
        if "unlocks_survey_target_id" in entity or "durable_clearance" in entity:
            failures.append("Expansion 13 dependency metadata is supported only on southeast_wreck_recorder.")
    if survey and ({"required_tool_target_id", "unlocks_survey_target_id"} & set(survey)):
        failures.append(f"{SURVEY_ID} must not duplicate the recorder-owned dependency.")

    producers = [
        item for item in _items(map_data, "survey_targets")
        if item.get("discovery_id") == KNOWLEDGE_ID
    ]
    if len(producers) != 1:
        failures.append(f"{ROUTE_ID} requires exactly one source survey for {KNOWLEDGE_ID}.")
    elif producers[0].get("id") == SURVEY_ID or producers[0].get("required_route_id") == ROUTE_ID:
        failures.append(f"{ROUTE_ID} prerequisite discovery must not depend on the route it unlocks.")
    if KNOWLEDGE_ID == DISCOVERY_ID:
        failures.append("Expansion 13 prerequisite and result discoveries must remain distinct.")

    if pressure_zone:
        if pressure_zone.get("pressure_zone") is not True:
            failures.append(f"{PRESSURE_ZONE_ID} must remain a pressure zone.")
        if pressure_zone.get("required_capability_id") != "pressure_suit_1":
            failures.append(f"{PRESSURE_ZONE_ID} must continue to require pressure_suit_1.")
    if boat.get("type") != "boat_spawn":
        failures.append(f"{BOAT_ID} must remain the canonical boat_spawn.")
    if _terrain_hash(map_data) != TERRAIN_SHA256:
        failures.append("Expansion 13 must not change production_level_01 terrain topology.")
    forbidden = sorted(RUNTIME_STATE_FIELDS & (set(route) | set(recorder) | set(survey)))
    if forbidden:
        failures.append(f"Expansion 13 source must not author runtime state fields: {forbidden}.")
    return failures


def southeast_wreck_route_budget(map_data: dict[str, Any]) -> dict[str, float | str]:
    units = map_data.get("units", {})
    tile_size = int(units.get("tile_size_px", 0))
    recorder = _records(map_data, "entities", RECORDER_ID)[0]
    survey = _records(map_data, "survey_targets", SURVEY_ID)[0]
    boat = _records(map_data, "entities", BOAT_ID)[0]
    field = CollisionField(
        int(units.get("width_tiles", 0)),
        int(units.get("height_tiles", 0)),
        tile_size,
        solid_cells(map_data),
        load_player_body(),
    )
    start = map_point(boat, tile_size, entry=True)
    recorder_point = map_point(recorder, tile_size)
    survey_point = map_point(survey, tile_size)
    legs = (
        shortest_path(field, start, recorder_point),
        shortest_path(field, recorder_point, survey_point),
        shortest_path(field, survey_point, start),
    )
    if any(leg is None for leg in legs):
        return {"error": "recorder/survey chain has no collision-clear canonical-boat route"}
    budgets = load_runtime_budgets()
    distance = sum(float(leg.distance_px) for leg in legs if leg is not None)
    interaction = float(recorder["interaction_seconds"]) + float(survey["interaction_seconds"])
    demand = distance / budgets.swim_speed_px_per_second + interaction
    return {
        "distance_px": distance,
        "demand_seconds": demand,
        "base_margin": budgets.base_oxygen_seconds - demand,
        "upgraded_margin": budgets.upgraded_oxygen_seconds - demand,
    }


def validate_southeast_wreck_routes(map_data: dict[str, Any]) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    try:
        budget = southeast_wreck_route_budget(map_data)
    except (IndexError, KeyError, TypeError, ValueError):
        return ["Expansion 13 route budget could not resolve the contracted records."]
    if "error" in budget:
        return [str(budget["error"])]
    base_margin = float(budget["base_margin"])
    upgraded_margin = float(budget["upgraded_margin"])
    if base_margin <= 0.0:
        failures.append(f"Southeast wreck route is not viable on the base tank; margin={base_margin:.1f}s.")
    elif base_margin > MAX_BASE_MARGIN_SECONDS:
        failures.append(f"Southeast wreck base-tank margin is not tight; margin={base_margin:.1f}s.")
    if upgraded_margin - base_margin < MIN_UPGRADE_GAIN_SECONDS:
        failures.append("oxygen_tank_1 must provide a useful optional margin without becoming mandatory.")

    units = map_data["units"]
    tile_size = int(units["tile_size_px"])
    base_solids = solid_cells(map_data)
    field = CollisionField(
        int(units["width_tiles"]),
        int(units["height_tiles"]),
        tile_size,
        base_solids,
        load_player_body(),
    )
    boat = _records(map_data, "entities", BOAT_ID)[0]
    recorder = _records(map_data, "entities", RECORDER_ID)[0]
    survey = _records(map_data, "survey_targets", SURVEY_ID)[0]
    zone = _records(map_data, "zones", PRESSURE_ZONE_ID)[0]
    start = map_point(boat, tile_size, entry=True)
    recorder_point = map_point(recorder, tile_size)
    survey_point = map_point(survey, tile_size)
    blocked = CollisionField(
        int(units["width_tiles"]),
        int(units["height_tiles"]),
        tile_size,
        base_solids | rect_cells(zone),
        load_player_body(),
    )
    if shortest_path(field, start, recorder_point) is None or shortest_path(field, survey_point, start) is None:
        failures.append("Southeast wreck recorder and survey must remain reachable and returnable.")
    if shortest_path(blocked, start, recorder_point) is not None or shortest_path(blocked, survey_point, start) is not None:
        failures.append(f"Southeast wreck route bypasses {PRESSURE_ZONE_ID}.")
    landmark = _records(map_data, "zones", LANDMARK_ID)[0]
    blocked_landmark = sorted(rect_cells(landmark) & base_solids)
    if blocked_landmark:
        failures.append(f"{LANDMARK_ID} contains solid cells. Sample: {blocked_landmark[:4]}")
    return failures


def validate_southeast_wreck_return(map_data: dict[str, Any]) -> list[str]:
    failures = validate_southeast_wreck_schema(map_data)
    if not failures:
        failures.extend(validate_southeast_wreck_routes(map_data))
    return failures


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    failures = validate_southeast_wreck_return(map_data)
    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1
    if not _triggered(map_data):
        print(f"{map_data.get('id')} southeast wreck PASS: contract not authored on this map.")
        return 0
    budget = southeast_wreck_route_budget(map_data)
    print(
        f"{map_data.get('id')} southeast wreck PASS: "
        f"distance={float(budget['distance_px']):.1f}px "
        f"demand={float(budget['demand_seconds']):.1f}s "
        f"base_margin={float(budget['base_margin']):.1f}s "
        f"upgraded_margin={float(budget['upgraded_margin']):.1f}s."
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
