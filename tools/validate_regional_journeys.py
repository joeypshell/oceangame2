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
SUPPORTED_CAPABILITY_IDS = {"propulsion_fins"}
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
ALLOWED_FIELDS = set(REQUIRED_FIELDS)
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
            and int(inner["x"]) + int(inner["w"]) <= int(outer["x"]) + int(outer["w"])
            and int(inner["y"]) + int(inner["h"]) <= int(outer["y"]) + int(outer["h"])
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
        for field in id_fields:
            if not _valid_id(journey[field]):
                failures.append(f"{label} {field} must use lower_snake_case.")
        if journey["required_capability_id"] not in SUPPORTED_CAPABILITY_IDS:
            failures.append(f"{label} required_capability_id must be propulsion_fins.")
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
        for gate_id in [journey["promise_gate_id"], *gate_ids]:
            gate = zones.get(str(gate_id))
            if gate is None or gate.get("current_gate") is not True:
                failures.append(f"{label} current gate reference {gate_id!r} is unresolved.")
                continue
            if gate.get("required_capability_id") != journey["required_capability_id"]:
                failures.append(f"{label} gate {gate_id!r} must use the journey capability.")
            if gate_id in gate_ids and gate.get("route_context") != journey["id"]:
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
