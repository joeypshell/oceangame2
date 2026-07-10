#!/usr/bin/env python3
"""Validate basic greybox map reachability from the player entry cell."""

from __future__ import annotations

import argparse
import json
import re
from collections import deque
from pathlib import Path
from validate_current_gates import validate_current_gate_reachability, validate_current_gate_schema
from validate_destination_payoffs import validate_destination_payoff_schema
from validate_final_dive_objective_seeds import validate_final_dive_objective_seed_reachability, validate_final_dive_objective_seed_schema
from validate_material_sources import validate_material_source_reachability, validate_material_source_schema
from validate_moving_hazards import validate_moving_hazard_reachability, validate_moving_hazard_schema
from validate_next_dive_prompts import validate_next_dive_prompt_schema
from validate_progression_containers import validate_progression_container_reachability, validate_progression_container_schema
from validate_relay_follow_through_objectives import validate_relay_follow_through_objective_reachability, validate_relay_follow_through_objective_schema
from validate_route_objectives import (
    validate_objective_step_cue_reachability,
    validate_objective_step_cue_schema,
    validate_primary_route_objective_schema,
    validate_route_objective_reachability,
    validate_route_objective_schema,
)
from validate_survey_targets import validate_survey_target_reachability, validate_survey_target_schema
from validate_visibility_zones import validate_visibility_zone_reachability, validate_visibility_zone_schema
from validate_world_connectors import validate_world_connector_reachability, validate_world_connector_schema

ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
ENTITY_TYPES = {"spawn", "boat_spawn", "salvage", "hazard", "material_candidate", "tool_target"}
POINT_ENTITY_TYPES = {"spawn", "salvage", "hazard", "material_candidate", "tool_target"}
KIND_ENTITY_TYPES = {"salvage", "hazard", "material_candidate", "tool_target"}
SALVAGE_VALUE_TIERS = {"common", "valuable"}
ROUTE_CHOICE_METADATA_FIELDS = {"route_choice_id", "validation_route", "route_order"}
SALVAGE_INTERACTIONS = {"instant", "timed_salvage", "pry_salvage"}
SALVAGE_INTERACTION_METADATA_FIELDS = {"interaction", "interaction_seconds", "interaction_label", "pry_stages"}
OXYGEN_MAX_SECONDS = 90.0
OXYGEN_REST_METADATA_FIELDS = {
    "oxygen_rest",
    "oxygen_rest_label",
    "oxygen_rest_cap_seconds",
    "oxygen_rest_refill_per_second",
    "route_context",
}
OXYGEN_REST_TRIGGER_FIELDS = OXYGEN_REST_METADATA_FIELDS - {"route_context"}
def rect_cells(item: dict) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells

def neighbors(x: int, y: int) -> tuple[tuple[int, int], ...]:
    return ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))

def spawn_cell(entity: dict) -> tuple[int, int]:
    if entity.get("type") == "boat_spawn":
        return (int(entity["entry_x"]), int(entity["entry_y"]))
    return (int(entity["x"]), int(entity["y"]))

def is_int_value(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)

def is_number_value(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def validate_required_fields(item: dict, item_label: str, required_fields: tuple[str, ...]) -> list[str]:
    failures: list[str] = []
    for field in required_fields:
        if field not in item:
            failures.append(f"{item_label} is missing required field {field}.")
    return failures

def validate_id(value, item_label: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} id must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} id {value!r} must use lower_snake_case."]
    return []


def validate_kind(value, item_label: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} kind must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} kind {value!r} must use lower_snake_case."]
    return []


def validate_salvage_tier(value, item_label: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} tier must be a non-empty string."]
    if value not in SALVAGE_VALUE_TIERS:
        allowed = ", ".join(sorted(SALVAGE_VALUE_TIERS))
        return [f"{item_label} tier {value!r} must be one of: {allowed}."]
    return []


def validate_route_choice_metadata(entity: dict, item_label: str) -> list[str]:
    failures: list[str] = []
    route_fields = ROUTE_CHOICE_METADATA_FIELDS & set(entity.keys())
    if not route_fields:
        return failures

    if entity.get("type") != "salvage":
        fields = ", ".join(sorted(route_fields))
        return [f"{item_label} route-choice metadata ({fields}) is only supported on salvage entities."]

    if "route_choice_id" in entity:
        value = entity["route_choice_id"]
        if not isinstance(value, str) or not value:
            failures.append(f"{item_label} route_choice_id must be a non-empty string.")
        elif not ID_PATTERN.match(value):
            failures.append(f"{item_label} route_choice_id {value!r} must use lower_snake_case.")

    if "validation_route" in entity:
        value = entity["validation_route"]
        if not isinstance(value, str) or not value:
            failures.append(f"{item_label} validation_route must be a non-empty string.")
        elif not ID_PATTERN.match(value):
            failures.append(f"{item_label} validation_route {value!r} must use lower_snake_case.")

    if "route_order" in entity:
        value = entity["route_order"]
        if not is_int_value(value):
            failures.append(f"{item_label} route_order must be an integer.")
        elif int(value) < 0:
            failures.append(f"{item_label} route_order must be zero or greater.")

    return failures


def validate_salvage_interaction_metadata(entity: dict, item_label: str) -> list[str]:
    failures: list[str] = []
    interaction_fields = SALVAGE_INTERACTION_METADATA_FIELDS & set(entity.keys())
    if not interaction_fields:
        return failures
    if entity.get("type") in {"material_candidate", "tool_target"}:
        return failures
    if entity.get("type") != "salvage":
        fields = ", ".join(sorted(interaction_fields))
        return [f"{item_label} interaction metadata ({fields}) is only supported on salvage entities."]

    interaction = entity.get("interaction", "instant")
    if not isinstance(interaction, str) or not interaction:
        failures.append(f"{item_label} interaction must be a non-empty string.")
    elif interaction not in SALVAGE_INTERACTIONS:
        allowed = ", ".join(sorted(SALVAGE_INTERACTIONS))
        failures.append(f"{item_label} interaction {interaction!r} must be one of: {allowed}.")

    if interaction in {"timed_salvage", "pry_salvage"}:
        if "interaction_seconds" not in entity:
            failures.append(f"{item_label} {interaction} requires interaction_seconds.")
        elif not is_number_value(entity["interaction_seconds"]):
            failures.append(f"{item_label} interaction_seconds must be a positive number.")
        elif float(entity["interaction_seconds"]) <= 0.0:
            failures.append(f"{item_label} interaction_seconds must be greater than 0.")
    elif "interaction_seconds" in entity:
        failures.append(f"{item_label} interaction_seconds is only supported for timed_salvage or pry_salvage.")

    if interaction == "pry_salvage":
        if "pry_stages" not in entity:
            failures.append(f"{item_label} pry_salvage requires pry_stages.")
        elif not is_int_value(entity["pry_stages"]):
            failures.append(f"{item_label} pry_stages must be a positive integer.")
        elif int(entity["pry_stages"]) <= 0:
            failures.append(f"{item_label} pry_stages must be greater than 0.")
    elif "pry_stages" in entity:
        failures.append(f"{item_label} pry_stages is only supported for pry_salvage.")

    if "interaction_label" in entity:
        label = entity["interaction_label"]
        if not isinstance(label, str) or not label:
            failures.append(f"{item_label} interaction_label must be a non-empty string.")
        elif "\n" in label or "\r" in label or not (ID_PATTERN.match(label) or DISPLAY_LABEL_PATTERN.match(label)):
            failures.append(
                f"{item_label} interaction_label must be lower_snake_case or short display-safe text."
            )

    return failures


def validate_oxygen_rest_forbidden(item: dict, item_label: str, owner_label: str) -> list[str]:
    rest_fields = OXYGEN_REST_TRIGGER_FIELDS & set(item.keys())
    if not rest_fields:
        return []
    fields = ", ".join(sorted(rest_fields))
    return [f"{item_label} oxygen-rest metadata ({fields}) is only supported on marker zones, not {owner_label}."]


def validate_rect_fields(item: dict, item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    failures.extend(validate_required_fields(item, item_label, ("x", "y", "w", "h")))
    if failures:
        return failures

    for field in ("x", "y", "w", "h"):
        if not is_int_value(item[field]):
            failures.append(f"{item_label} field {field} must be an integer tile coordinate or size.")
    if failures:
        return failures

    if int(item["w"]) <= 0 or int(item["h"]) <= 0:
        failures.append(f"{item_label} width and height must be positive.")
    if int(item["x"]) < 0 or int(item["y"]) < 0:
        failures.append(f"{item_label} rectangle origin must be inside map bounds.")
    if int(item["x"]) + int(item["w"]) > width or int(item["y"]) + int(item["h"]) > height:
        failures.append(f"{item_label} rectangle extends outside map bounds.")
    return failures


def validate_oxygen_rest_metadata(zone: dict, item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    rest_fields = OXYGEN_REST_TRIGGER_FIELDS & set(zone.keys())
    if not rest_fields:
        return failures

    if zone.get("type") != "marker":
        fields = ", ".join(sorted(rest_fields))
        return [f"{item_label} oxygen-rest metadata ({fields}) is only supported on marker zones."]

    if zone.get("oxygen_rest") is not True:
        failures.append(f"{item_label} oxygen_rest must be true when oxygen-rest metadata is present.")
    for field in ("oxygen_rest_cap_seconds", "oxygen_rest_refill_per_second"):
        if field not in zone:
            failures.append(f"{item_label} oxygen-rest metadata requires {field}.")
        elif not is_number_value(zone[field]) or float(zone[field]) <= 0.0:
            failures.append(f"{item_label} {field} must be a positive number.")

    if "oxygen_rest_cap_seconds" in zone and is_number_value(zone["oxygen_rest_cap_seconds"]):
        if float(zone["oxygen_rest_cap_seconds"]) > OXYGEN_MAX_SECONDS:
            failures.append(f"{item_label} oxygen_rest_cap_seconds must not exceed {OXYGEN_MAX_SECONDS:.0f}.")

    if "oxygen_rest_label" in zone:
        label = zone["oxygen_rest_label"]
        if not isinstance(label, str) or not label:
            failures.append(f"{item_label} oxygen_rest_label must be a non-empty string.")
        elif "\n" in label or "\r" in label or not (ID_PATTERN.match(label) or DISPLAY_LABEL_PATTERN.match(label)):
            failures.append(
                f"{item_label} oxygen_rest_label must be lower_snake_case or short display-safe text."
            )

    if "route_context" in zone:
        route_context = zone["route_context"]
        if not isinstance(route_context, str) or not route_context:
            failures.append(f"{item_label} route_context must be a non-empty string.")
        elif not ID_PATTERN.match(route_context):
            failures.append(f"{item_label} route_context {route_context!r} must use lower_snake_case.")

    failures.extend(validate_rect_fields(zone, item_label, width, height))
    return failures


def validate_tile_coordinate(entity: dict, field: str, width: int, height: int) -> list[str]:
    item_label = str(entity.get("id", entity.get("type", "entity")))
    if field not in entity:
        return [f"{item_label} is missing required coordinate field {field}."]
    if not is_int_value(entity[field]):
        return [f"{item_label} field {field} must be an integer tile coordinate."]

    limit = width if field.endswith("x") or field == "x" else height
    if int(entity[field]) < 0 or int(entity[field]) >= limit:
        return [f"{item_label} field {field} is outside map bounds: {entity[field]}."]
    return []


def validate_route_target_reachability(
    entity: dict,
    validation_route: str,
    point: tuple[int, int],
    reachable: set[tuple[int, int]],
) -> list[str]:
    if point in reachable:
        return []
    route_id = str(entity.get("route_choice_id", entity.get("id", "route_choice_target")))
    entity_id = str(entity.get("id", "salvage"))
    return [
        f"Route-choice target {entity_id} for validation_route {validation_route!r} "
        f"route_choice_id {route_id!r} is unreachable at {point}."
    ]


def validate_entity_schema(entities: list[dict], width: int, height: int, base_zones: list[dict]) -> list[str]:
    failures: list[str] = []
    seen_ids: set[str] = set()
    has_boat_spawn = any(entity.get("type") == "boat_spawn" for entity in entities)
    has_gameplay_salvage = False

    for index, entity in enumerate(entities):
        item_label = str(entity.get("id", f"entity[{index}]"))
        failures.extend(validate_required_fields(entity, item_label, ("id", "type")))
        if "id" in entity:
            failures.extend(validate_id(entity["id"], item_label))
            if entity["id"] in seen_ids:
                failures.append(f"Duplicate entity id {entity['id']!r}.")
            seen_ids.add(entity["id"])
        if "type" in entity and entity["type"] not in ENTITY_TYPES:
            failures.append(f"{item_label} has unsupported entity type {entity['type']!r}.")

        entity_type = entity.get("type")
        if entity_type in POINT_ENTITY_TYPES:
            failures.extend(validate_required_fields(entity, item_label, ("x", "y")))
            failures.extend(validate_tile_coordinate(entity, "x", width, height))
            failures.extend(validate_tile_coordinate(entity, "y", width, height))
        if entity_type in KIND_ENTITY_TYPES:
            failures.extend(validate_required_fields(entity, item_label, ("kind",)))
            if "kind" in entity:
                failures.extend(validate_kind(entity["kind"], item_label))
        if entity_type == "salvage" and "tier" in entity:
            failures.extend(validate_salvage_tier(entity["tier"], item_label))
        failures.extend(validate_route_choice_metadata(entity, item_label))
        failures.extend(validate_salvage_interaction_metadata(entity, item_label))
        failures.extend(validate_oxygen_rest_forbidden(entity, item_label, "entities"))
        if entity_type == "salvage" and entity.get("kind") != "stress_marker":
            has_gameplay_salvage = True

    if has_gameplay_salvage and not has_boat_spawn and not base_zones:
        failures.append("Playable salvage maps must define a base extraction zone or use boat_spawn extraction.")

    return failures


def validate_zone_schema(zones: list[dict], width: int, height: int) -> list[str]:
    failures: list[str] = []
    oxygen_rest_zone_ids: list[str] = []
    for index, zone in enumerate(zones):
        item_label = str(zone.get("id", f"zone[{index}]"))
        failures.extend(validate_oxygen_rest_metadata(zone, item_label, width, height))
        if OXYGEN_REST_TRIGGER_FIELDS & set(zone.keys()):
            oxygen_rest_zone_ids.append(item_label)

    if len(oxygen_rest_zone_ids) > 1:
        failures.append(f"Only one oxygen-rest marker is currently supported. Found: {oxygen_rest_zone_ids}.")
    return failures

def validate_boat_spawn(entity: dict, solid: set[tuple[int, int]], width: int, height: int) -> list[str]:
    failures: list[str] = []
    required_fields = ("x", "y", "w", "h", "entry_x", "entry_y")
    failures.extend(validate_required_fields(entity, str(entity.get("id", "boat_spawn")), required_fields))
    if failures:
        return failures

    for field in required_fields:
        if not is_int_value(entity[field]):
            failures.append(f"{entity['id']} field {field} must be an integer tile coordinate or size.")
    if failures:
        return failures

    entry = spawn_cell(entity)
    if entry[0] < 0 or entry[1] < 0 or entry[0] >= width or entry[1] >= height:
        failures.append(f"{entity['id']} entry is outside map bounds at {entry}.")
        return failures
    if entry in solid:
        failures.append(f"{entity['id']} entry is inside solid terrain at {entry}.")

    boat_cells = rect_cells(entity)
    out_of_bounds = [
        cell for cell in boat_cells if cell[0] < 0 or cell[1] < 0 or cell[0] >= width or cell[1] >= height
    ]
    if out_of_bounds:
        failures.append(f"{entity['id']} boat extraction rectangle extends outside map bounds. Sample: {out_of_bounds[:4]}")
    if entry not in boat_cells:
        failures.append(f"{entity['id']} entry {entry} is outside the boat extraction rectangle.")
    if not boat_cells - solid:
        failures.append(f"{entity['id']} boat extraction rectangle has no open cells.")
    return failures

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path)
    args = parser.parse_args()

    with args.map_json.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)

    width = int(map_data["units"]["width_tiles"])
    height = int(map_data["units"]["height_tiles"])

    solid: set[tuple[int, int]] = set()
    for terrain in map_data.get("terrain", []):
        if terrain.get("type") == "solid":
            solid.update(rect_cells(terrain))

    entities = map_data.get("entities", [])
    base_zones = [zone for zone in map_data.get("zones", []) if zone.get("type") == "base"]

    failures: list[str] = []
    zones = map_data.get("zones", [])
    failures.extend(validate_entity_schema(entities, width, height, base_zones))
    failures.extend(validate_zone_schema(zones, width, height))
    failures.extend(validate_current_gate_schema(map_data))
    failures.extend(validate_destination_payoff_schema(args.map_json, map_data))
    failures.extend(validate_final_dive_objective_seed_schema(map_data, entities))
    failures.extend(validate_material_source_schema(map_data))
    failures.extend(validate_moving_hazard_schema(map_data))
    failures.extend(validate_next_dive_prompt_schema(map_data, entities, zones))
    failures.extend(validate_progression_container_schema(map_data))
    failures.extend(validate_relay_follow_through_objective_schema(map_data, entities))
    failures.extend(validate_survey_target_schema(args.map_json, map_data))
    failures.extend(validate_visibility_zone_schema(map_data))
    failures.extend(validate_world_connector_schema(args.map_json, map_data))
    failures.extend(validate_route_objective_schema(map_data, entities, zones))
    failures.extend(validate_primary_route_objective_schema(map_data))
    failures.extend(validate_objective_step_cue_schema(map_data, entities, zones))
    if failures:
        for failure in failures:
            print(failure)
        return 1

    spawn_entities = [entity for entity in entities if entity.get("type") in ("spawn", "boat_spawn")]
    if len(spawn_entities) != 1:
        print(f"Expected exactly one spawn or boat_spawn entity, found {len(spawn_entities)}.")
        return 1

    if spawn_entities[0].get("type") == "boat_spawn":
        failures.extend(validate_boat_spawn(spawn_entities[0], solid, width, height))
    if failures:
        for failure in failures:
            print(failure)
        return 1

    spawn = spawn_cell(spawn_entities[0])
    if spawn in solid:
        print(f"Spawn {spawn_entities[0]['id']} is inside solid terrain at {spawn}.")
        return 1

    reachable: set[tuple[int, int]] = {spawn}
    queue: deque[tuple[int, int]] = deque([spawn])

    while queue:
        x, y = queue.popleft()
        for nx, ny in neighbors(x, y):
            if nx < 0 or ny < 0 or nx >= width or ny >= height:
                continue
            cell = (nx, ny)
            if cell in solid or cell in reachable:
                continue
            reachable.add(cell)
            queue.append(cell)

    open_cells = {(x, y) for y in range(height) for x in range(width) if (x, y) not in solid}
    unreachable = open_cells - reachable
    if unreachable:
        sample = sorted(unreachable)[:12]
        print(f"Found {len(unreachable)} unreachable open tiles. Sample: {sample}")
        return 1

    for entity in entities:
        point = spawn_cell(entity) if entity.get("type") == "boat_spawn" else (int(entity["x"]), int(entity["y"]))
        if point in solid:
            failures.append(f"{entity['id']} is inside solid terrain at {point}.")
        elif point not in reachable:
            if ROUTE_CHOICE_METADATA_FIELDS & set(entity.keys()) and entity.get("type") == "salvage":
                validation_route = entity.get("validation_route", entity.get("route_choice_id", "route_choice"))
                failures.extend(validate_route_target_reachability(entity, str(validation_route), point, reachable))
            else:
                failures.append(f"{entity['id']} is unreachable at {point}.")

    for zone in zones:
        if OXYGEN_REST_TRIGGER_FIELDS & set(zone.keys()):
            cells = rect_cells(zone)
            solid_cells = sorted(cells & solid)
            unreachable_cells = sorted(cell for cell in cells if cell not in reachable)
            if solid_cells:
                failures.append(f"{zone['id']} oxygen-rest rectangle contains solid cells. Sample: {solid_cells[:4]}")
            if unreachable_cells:
                failures.append(f"{zone['id']} oxygen-rest rectangle contains unreachable cells. Sample: {unreachable_cells[:4]}")
        if zone.get("type") == "marker":
            continue
        cells = rect_cells(zone)
        if not cells - solid:
            failures.append(f"{zone['id']} has no open cells.")
        elif not (cells & reachable):
            failures.append(f"{zone['id']} is unreachable.")

    failures.extend(validate_route_objective_reachability(map_data, entities, zones, solid, reachable))
    failures.extend(validate_objective_step_cue_reachability(map_data, entities, zones, solid, reachable))
    failures.extend(validate_current_gate_reachability(zones, solid, reachable))
    failures.extend(validate_final_dive_objective_seed_reachability(map_data, entities, solid, reachable))
    failures.extend(validate_material_source_reachability(entities, solid, reachable))
    failures.extend(validate_moving_hazard_reachability(map_data.get("moving_hazards", []), solid, reachable))
    failures.extend(validate_progression_container_reachability(map_data.get("progression_containers", []), solid, reachable))
    failures.extend(validate_relay_follow_through_objective_reachability(map_data, entities, solid, reachable))
    failures.extend(validate_survey_target_reachability(map_data.get("survey_targets", []), solid, reachable))
    failures.extend(validate_visibility_zone_reachability(zones, solid, reachable))
    failures.extend(validate_world_connector_reachability(zones, solid, reachable))

    if failures:
        for failure in failures:
            print(failure)
        return 1

    print(f"{map_data['id']} passed reachability validation from entry {spawn}.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
