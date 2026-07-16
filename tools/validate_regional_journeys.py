#!/usr/bin/env python3
"""Validate source-authored regional journey relationships and traversal seams."""

from __future__ import annotations

import argparse
import json
import re
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
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,47}$")
GATE_FIELD_BY_CAPABILITY = {
    "propulsion_fins": "current_gate",
    "pressure_suit_1": "pressure_zone",
}
REQUIRED_FIELDS = (
    "id",
    "route_label",
    "promise_gate_id",
    "entry_gate_ids",
    "required_capability_id",
    "landmark_zone_id",
    "survey_target_id",
    "commit_entry_id",
    "route_context",
    "intent",
)
OPTIONAL_FIELDS = {"required_discovery_id", "tool_target_id"}
ALLOWED_FIELDS = set(REQUIRED_FIELDS) | OPTIONAL_FIELDS
FORBIDDEN_STATE_FIELDS = {
    "active",
    "completed",
    "owned",
    "pending",
    "player_position",
    "profile_state",
}


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _valid_id(value: Any) -> bool:
    return isinstance(value, str) and ID_PATTERN.fullmatch(value) is not None


def _valid_label(value: Any) -> bool:
    return isinstance(value, str) and DISPLAY_PATTERN.fullmatch(value) is not None


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


def validate_regional_journey_schema(map_data: dict[str, Any]) -> list[str]:
    journeys = map_data.get("regional_journeys", [])
    if journeys == []:
        return []
    if not isinstance(journeys, list):
        return ["regional_journeys must be a list when present."]

    zones = {str(item.get("id", "")): item for item in _items(map_data, "zones")}
    backgrounds = _items(map_data, "background")
    surveys = {str(item.get("id", "")): item for item in _items(map_data, "survey_targets")}
    entities = {str(item.get("id", "")): item for item in _items(map_data, "entities")}
    failures: list[str] = []
    seen_ids: set[str] = set()
    for index, journey in enumerate(journeys):
        if not isinstance(journey, dict):
            failures.append(f"regional_journeys[{index}] must be an object.")
            continue
        label = str(journey.get("id", f"regional_journeys[{index}]"))
        missing = [field for field in REQUIRED_FIELDS if field not in journey]
        if missing:
            failures.append(f"{label} is missing required fields: {', '.join(missing)}.")
            continue
        if not _valid_id(journey["id"]):
            failures.append(f"{label} id must use lower_snake_case.")
        elif label in seen_ids:
            failures.append(f"duplicate regional journey id {label!r}.")
        seen_ids.add(label)
        if not _valid_label(journey["route_label"]):
            failures.append(f"{label} route_label must be short display-safe text.")
        if not isinstance(journey["intent"], str) or not journey["intent"].strip():
            failures.append(f"{label} intent must be non-empty text.")
        present_state = sorted(FORBIDDEN_STATE_FIELDS & set(journey))
        if present_state:
            failures.append(f"{label} contains runtime state fields: {present_state}.")
        unknown_fields = sorted(set(journey) - ALLOWED_FIELDS)
        if unknown_fields:
            failures.append(f"{label} contains unsupported fields: {unknown_fields}.")

        id_fields = (
            "promise_gate_id",
            "required_capability_id",
            "landmark_zone_id",
            "survey_target_id",
            "commit_entry_id",
            "route_context",
        )
        id_fields += tuple(field for field in sorted(OPTIONAL_FIELDS) if field in journey)
        for field in id_fields:
            if not _valid_id(journey[field]):
                failures.append(f"{label} {field} must use lower_snake_case.")
        capability_id = journey["required_capability_id"]
        if capability_id not in GATE_FIELD_BY_CAPABILITY:
            failures.append(
                f"{label} required_capability_id must be one of: "
                f"{', '.join(sorted(GATE_FIELD_BY_CAPABILITY))}."
            )
        if journey["route_context"] != journey["id"]:
            failures.append(f"{label} route_context must equal its journey id.")

        gate_ids = journey["entry_gate_ids"]
        if not isinstance(gate_ids, list) or not gate_ids:
            failures.append(f"{label} entry_gate_ids must be a non-empty unique id list.")
            gate_ids = []
        elif any(not _valid_id(gate_id) for gate_id in gate_ids):
            failures.append(f"{label} entry_gate_ids must contain lower_snake_case ids.")
            gate_ids = []
        elif len(gate_ids) != len(set(gate_ids)):
            failures.append(f"{label} entry_gate_ids must be a non-empty unique id list.")
            gate_ids = []
        if journey["promise_gate_id"] in gate_ids:
            failures.append(f"{label} promise gate must remain distinct from its regional entry gates.")
        required_discovery_id = str(journey.get("required_discovery_id", ""))
        discovery_sources = [
            survey for survey in surveys.values()
            if survey.get("discovery_id") == required_discovery_id
        ] if required_discovery_id else []
        promise = zones.get(str(journey["promise_gate_id"]))
        if required_discovery_id:
            if len(discovery_sources) != 1:
                failures.append(f"{label} required_discovery_id must resolve to exactly one survey result.")
            elif discovery_sources[0].get("required_route_id") == journey["id"]:
                failures.append(f"{label} required discovery must not depend on the journey it unlocks.")
            promise_route_id = str(promise.get("regional_journey_id", "")) if promise else ""
            if (
                promise is None
                or promise.get("regional_landmark") is not True
                or not discovery_sources
                or discovery_sources[0].get("required_route_id") != promise_route_id
            ):
                failures.append(f"{label} discovery promise landmark is unresolved.")
        elif capability_id == "pressure_suit_1":
            if promise is None or promise.get("visibility_zone") is not True:
                failures.append(f"{label} pressure promise reference is unresolved.")
        elif promise is None or promise.get("current_gate") is not True:
            failures.append(f"{label} current promise gate reference is unresolved.")
        elif promise.get("required_capability_id") != capability_id:
            failures.append(f"{label} promise gate must use the journey capability.")

        expected_gate_field = GATE_FIELD_BY_CAPABILITY.get(str(capability_id), "")
        for gate_id in gate_ids:
            gate = zones.get(str(gate_id))
            if gate is None or not expected_gate_field or gate.get(expected_gate_field) is not True:
                failures.append(f"{label} entry gate reference {gate_id!r} is unresolved.")
                continue
            if gate.get("required_capability_id") != capability_id:
                failures.append(f"{label} gate {gate_id!r} must use the journey capability.")
            allowed_gate_contexts = {str(journey["id"])}
            if discovery_sources:
                allowed_gate_contexts.add(str(discovery_sources[0].get("required_route_id", "")))
            if gate.get("route_context") not in allowed_gate_contexts:
                failures.append(f"{label} entry gate {gate_id!r} must use the journey route_context.")

        landmark = zones.get(str(journey["landmark_zone_id"]))
        if landmark is None or landmark.get("regional_landmark") is not True:
            failures.append(f"{label} landmark zone reference is unresolved.")
        elif landmark.get("regional_journey_id") != journey["id"] or not _valid_label(landmark.get("landmark_label")):
            failures.append(f"{label} landmark zone must link back with a display-safe label.")
        backdrops = [item for item in backgrounds if item.get("regional_journey_id") == journey["id"]]
        if landmark is not None and (
            len(backdrops) != 1
            or backdrops[0].get("type") != "background"
            or any(backdrops[0].get(field) != landmark.get(field) for field in ("x", "y", "w", "h"))
        ):
            failures.append(f"{label} must have one non-collision backdrop matching its landmark rectangle.")

        survey = surveys.get(str(journey["survey_target_id"]))
        if survey is None or survey.get("required_route_id") != journey["id"]:
            failures.append(f"{label} survey_target_id must resolve to a target requiring this route.")
        elif landmark is not None and not _rect_contains(landmark, survey):
            failures.append(f"{label} survey target must sit inside its landmark rectangle.")
        tool_target_id = str(journey.get("tool_target_id", ""))
        if tool_target_id:
            tool_target = entities.get(tool_target_id)
            if tool_target is None or tool_target.get("type") != "tool_target":
                failures.append(f"{label} tool_target_id must resolve to a tool_target entity.")
            elif tool_target.get("unlocks_survey_target_id") != journey["survey_target_id"]:
                failures.append(f"{label} tool target must unlock the journey survey target.")
            elif landmark is not None and not _rect_contains(landmark, tool_target):
                failures.append(f"{label} tool target must sit inside its landmark rectangle.")
        if entities.get(str(journey["commit_entry_id"]), {}).get("type") != "boat_spawn":
            failures.append(f"{label} commit_entry_id must resolve to the canonical boat.")
    return failures


def validate_regional_journey_reachability(
    map_data: dict[str, Any],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    zones = {str(item.get("id", "")): item for item in _items(map_data, "zones")}
    failures: list[str] = []
    for journey in _items(map_data, "regional_journeys"):
        landmark = zones.get(str(journey.get("landmark_zone_id", "")))
        if landmark is None:
            continue
        cells = rect_cells(landmark)
        blocked = sorted(cells & solid)
        if blocked:
            failures.append(f"{journey.get('id')} landmark contains solid cells. Sample: {blocked[:4]}")
        if not (cells & reachable):
            failures.append(f"{journey.get('id')} landmark is unreachable from the canonical boat.")
    return failures


def validate_regional_journey_footprint(map_data: dict[str, Any]) -> list[str]:
    units = map_data["units"]
    tile_size = int(units["tile_size_px"])
    zones = {str(item.get("id", "")): item for item in _items(map_data, "zones")}
    boats = [item for item in _items(map_data, "entities") if item.get("type") == "boat_spawn"]
    if len(boats) != 1:
        return [f"regional journey validation expected one canonical boat; found {len(boats)}."]
    start = map_point(boats[0], tile_size, entry=True)
    body = load_player_body()
    base_solids = solid_cells(map_data)
    failures: list[str] = []
    for journey in _items(map_data, "regional_journeys"):
        landmark = zones.get(str(journey.get("landmark_zone_id", "")))
        gate_items = [zones.get(str(gate_id)) for gate_id in journey.get("entry_gate_ids", [])]
        if landmark is None or any(gate is None for gate in gate_items):
            continue
        target = map_point(landmark, tile_size)
        open_field = CollisionField(
            int(units["width_tiles"]), int(units["height_tiles"]), tile_size, base_solids, body
        )
        outbound = shortest_path(open_field, start, target)
        return_path = shortest_path(open_field, target, start)
        if outbound is None or return_path is None:
            failures.append(f"{journey.get('id')} has no player-footprint route to its landmark and back.")
            continue
        blocked_solids = set(base_solids)
        for gate in gate_items:
            blocked_solids.update(rect_cells(gate))
        blocked_field = CollisionField(
            int(units["width_tiles"]), int(units["height_tiles"]), tile_size, blocked_solids, body
        )
        if shortest_path(blocked_field, start, target) is not None:
            failures.append(f"{journey.get('id')} has a no-capability bypass around its entry current seams.")
    return failures


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    failures = validate_regional_journey_schema(map_data)
    if not failures:
        failures.extend(validate_regional_journey_footprint(map_data))
    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1
    print(
        f"{map_data['id']} regional journeys PASS: schema, player-footprint return, "
        "and no-capability seam denial agree."
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
