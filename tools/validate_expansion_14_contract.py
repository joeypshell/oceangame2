#!/usr/bin/env python3
"""Validate the bounded Expansion 14 archive-current source contract."""

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
    map_point,
    rect_cells,
    shortest_path,
    solid_cells,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "maps" / "production_level_01.greybox.json"
MAP_ID = "production_level_01"
BOAT_ID = "surface_boat_entry"
ARCHIVE_DISCOVERY_ID = "southeast_wreck_archive_discovery"
ARCHIVE_SURVEY_ID = "southeast_wreck_archive_survey"
PROJECT_ID = "current_stabilizer_project"
CAPABILITY_ID = "current_stabilizer"
PREREQUISITE_PROJECT_ID = "salvage_cutter_project"
ROUTE_ID = "upper_left_wreck_relay_route"
GATE_ID = "upper_left_wreck_relay_current"
PROMISE_ID = "southeast_wreck_archive_landmark"
LANDMARK_ID = "upper_left_wreck_relay_landmark"
CORE_ID = "upper_left_wreck_relay_core"
SURVEY_ID = "upper_left_wreck_relay_survey"
DISCOVERY_ID = "upper_left_wreck_relay_discovery"
NEXT_LEAD = "Next lead: deeper wreck relay still transmitting"
TERRAIN_SHA256 = "5f01b2cb2ad2cb7729cd980dfba5bd960c0b9cbeb1b034e6bf29558162364c72"
POCKET_CELLS = {(x, y) for y in range(57, 61) for x in range(56, 61)}
RUNTIME_FIELDS = {"active", "collected", "committed", "owned", "pending", "profile_state", "progress"}

PROJECT_VALUES = {
    "required_project_id": PREREQUISITE_PROJECT_ID,
    "required_discovery_id": ARCHIVE_DISCOVERY_ID,
    "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
    "unlocks_capability_id": CAPABILITY_ID,
    "target_gate_id": GATE_ID,
    "build_phase": "night_debrief",
}
GATE_VALUES = {
    "type": "marker",
    "x": 53,
    "y": 57,
    "w": 3,
    "h": 4,
    "current_gate": True,
    "current_direction": "left",
    "current_strength": 3.2,
    "required_capability_id": CAPABILITY_ID,
    "route_context": ROUTE_ID,
}
ROUTE_VALUES = {
    "promise_gate_id": PROMISE_ID,
    "entry_gate_ids": [GATE_ID],
    "required_capability_id": CAPABILITY_ID,
    "required_discovery_id": ARCHIVE_DISCOVERY_ID,
    "landmark_zone_id": LANDMARK_ID,
    "payoff_target_id": CORE_ID,
    "survey_target_id": SURVEY_ID,
    "commit_entry_id": BOAT_ID,
    "route_context": ROUTE_ID,
}
SURVEY_VALUES = {
    "target_type": "regional",
    "required_capability_id": "survey_scanner_1",
    "required_route_id": ROUTE_ID,
    "route_context": ROUTE_ID,
    "interaction": "survey",
    "next_lead_label": NEXT_LEAD,
    "discovery_id": DISCOVERY_ID,
    "commit_map_id": MAP_ID,
    "commit_map_path": "res://maps/production_level_01.greybox.json",
    "commit_entry_id": BOAT_ID,
}


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records(map_data: dict[str, Any], field: str, item_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(map_data, field) if item.get("id") == item_id]


def _triggered(map_data: dict[str, Any]) -> bool:
    unique_ids = {ROUTE_ID, GATE_ID, LANDMARK_ID, CORE_ID, SURVEY_ID, DISCOVERY_ID}
    authored_ids = {
        str(item.get("id", ""))
        for field in ("regional_journeys", "zones", "entities", "survey_targets")
        for item in _items(map_data, field)
    }
    canonical_project = any(
        item.get("id") == PROJECT_ID and item.get("required_discovery_id") == ARCHIVE_DISCOVERY_ID
        for item in _items(map_data, "material_projects")
    )
    return canonical_project or bool(unique_ids & authored_ids)


def _one(map_data: dict[str, Any], field: str, item_id: str, failures: list[str]) -> dict[str, Any]:
    matches = _records(map_data, field, item_id)
    if len(matches) != 1:
        failures.append(f"Expansion 14 requires exactly one {field} record {item_id!r}; found {len(matches)}.")
        return {}
    return matches[0]


def _check_values(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [
        f"{label} {field} must be exactly {value!r}."
        for field, value in expected.items()
        if item.get(field) != value
    ]


def _terrain_hash(map_data: dict[str, Any]) -> str:
    payload = json.dumps(map_data.get("terrain"), sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def _rect_contains(outer: dict[str, Any], inner: dict[str, Any]) -> bool:
    try:
        return rect_cells(inner) <= rect_cells(outer)
    except (KeyError, TypeError, ValueError):
        return False


def _safe_rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    try:
        return rect_cells(item)
    except (KeyError, TypeError, ValueError):
        return set()


def validate_expansion_14_schema(map_data: dict[str, Any]) -> list[str]:
    if not _triggered(map_data):
        return []
    failures: list[str] = []
    if map_data.get("id") != MAP_ID:
        failures.append(f"Expansion 14 records are supported only on {MAP_ID}.")
    project = _one(map_data, "material_projects", PROJECT_ID, failures)
    gate = _one(map_data, "zones", GATE_ID, failures)
    route = _one(map_data, "regional_journeys", ROUTE_ID, failures)
    landmark = _one(map_data, "zones", LANDMARK_ID, failures)
    core = _one(map_data, "entities", CORE_ID, failures)
    survey = _one(map_data, "survey_targets", SURVEY_ID, failures)
    boat = _one(map_data, "entities", BOAT_ID, failures)

    failures.extend(_check_values(project, PROJECT_VALUES, PROJECT_ID))
    failures.extend(_check_values(gate, GATE_VALUES, GATE_ID))
    failures.extend(_check_values(route, ROUTE_VALUES, ROUTE_ID))
    failures.extend(_check_values(
        landmark,
        {"type": "marker", "regional_landmark": True, "regional_journey_id": ROUTE_ID},
        LANDMARK_ID,
    ))
    failures.extend(_check_values(
        core,
        {"type": "salvage", "tier": "valuable", "route_context": ROUTE_ID},
        CORE_ID,
    ))
    failures.extend(_check_values(survey, SURVEY_VALUES, SURVEY_ID))
    if boat.get("type") != "boat_spawn":
        failures.append(f"{BOAT_ID} must remain the canonical boat_spawn.")
    if _terrain_hash(map_data) != TERRAIN_SHA256:
        failures.append("Expansion 14 must not change production_level_01 terrain/collision topology.")

    backdrops = [item for item in _items(map_data, "background") if item.get("regional_journey_id") == ROUTE_ID]
    if len(backdrops) != 1 or backdrops[0].get("type") != "background":
        failures.append(f"{ROUTE_ID} requires exactly one non-collision background record.")
    elif landmark and any(backdrops[0].get(field) != landmark.get(field) for field in ("x", "y", "w", "h")):
        failures.append(f"{ROUTE_ID} background must match the landmark rectangle.")

    base_solids = solid_cells(map_data)
    if gate and _safe_rect_cells(gate) & base_solids:
        failures.append(f"{GATE_ID} must be entirely water-only.")
    landmark_cells = _safe_rect_cells(landmark)
    if landmark and (not landmark_cells or not landmark_cells <= POCKET_CELLS):
        failures.append(f"{LANDMARK_ID} must stay inside the locked relay pocket.")
    for item, label in ((core, CORE_ID), (survey, SURVEY_ID)):
        if landmark and item and not _rect_contains(landmark, item):
            failures.append(f"{label} must sit inside {LANDMARK_ID}.")
    if core and survey and _safe_rect_cells(core) & _safe_rect_cells(survey):
        failures.append("Relay core and survey must use distinct pocket positions.")

    project_owners = [
        item for item in _items(map_data, "material_projects")
        if item.get("unlocks_capability_id") == CAPABILITY_ID or item.get("target_gate_id") == GATE_ID
    ]
    if [item.get("id") for item in project_owners] != [PROJECT_ID]:
        failures.append(f"{CAPABILITY_ID} must have exactly one compatible project owner: {PROJECT_ID}.")
    capability_gates = [
        item.get("id") for item in _items(map_data, "zones")
        if item.get("current_gate") is True and item.get("required_capability_id") == CAPABILITY_ID
    ]
    if capability_gates != [GATE_ID]:
        failures.append(f"Canonical full-level {CAPABILITY_ID} ownership must target only {GATE_ID}.")
    archive_sources = [
        item.get("id") for item in _items(map_data, "survey_targets")
        if item.get("discovery_id") == ARCHIVE_DISCOVERY_ID
    ]
    if archive_sources != [ARCHIVE_SURVEY_ID]:
        failures.append(f"{ARCHIVE_DISCOVERY_ID} must retain exactly one source: {ARCHIVE_SURVEY_ID}.")
    for item in (project, gate, route, landmark, core, survey):
        runtime_fields = sorted(RUNTIME_FIELDS & set(item))
        if runtime_fields:
            failures.append(f"{item.get('id')} contains runtime state fields: {runtime_fields}.")
    return failures


def validate_expansion_14_routes(map_data: dict[str, Any]) -> list[str]:
    if not _triggered(map_data):
        return []
    try:
        units = map_data["units"]
        tile_size = int(units["tile_size_px"])
        boat = _records(map_data, "entities", BOAT_ID)[0]
        gate = _records(map_data, "zones", GATE_ID)[0]
        targets = [
            _records(map_data, "entities", CORE_ID)[0],
            _records(map_data, "survey_targets", SURVEY_ID)[0],
        ]
    except (IndexError, KeyError, TypeError, ValueError):
        return ["Expansion 14 route validation could not resolve the contracted records."]
    base_solids = solid_cells(map_data)
    dimensions = (int(units["width_tiles"]), int(units["height_tiles"]), tile_size)
    body = load_player_body()
    open_field = CollisionField(*dimensions, base_solids, body)
    blocked_field = CollisionField(*dimensions, base_solids | rect_cells(gate), body)
    start = map_point(boat, tile_size, entry=True)
    failures: list[str] = []
    for target in targets:
        target_point = map_point(target, tile_size)
        if shortest_path(open_field, start, target_point) is None or shortest_path(open_field, target_point, start) is None:
            failures.append(f"{target.get('id')} must have a player-footprint route to the boat and back.")
        if shortest_path(blocked_field, start, target_point) is not None:
            failures.append(f"{target.get('id')} bypasses {GATE_ID} before capability ownership.")
    return failures


def validate_expansion_14_contract(map_data: dict[str, Any]) -> list[str]:
    failures = validate_expansion_14_schema(map_data)
    if not failures:
        failures.extend(validate_expansion_14_routes(map_data))
    return failures


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    failures = validate_expansion_14_contract(map_data)
    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1
    state = "contract and footprint gate agree" if _triggered(map_data) else "contract not authored"
    print(f"{map_data.get('id')} Expansion 14 PASS: {state}.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", nargs="?", type=Path, default=DEFAULT_MAP)
    args = parser.parse_args()
    path = args.map_json if args.map_json.is_absolute() else ROOT / args.map_json
    return run_validation(path)


if __name__ == "__main__":
    raise SystemExit(main())
