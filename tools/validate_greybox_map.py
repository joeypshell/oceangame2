#!/usr/bin/env python3
"""Validate basic greybox map reachability from the player entry cell."""

from __future__ import annotations

import argparse
import json
import re
from collections import deque
from pathlib import Path


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
ENTITY_TYPES = {"spawn", "boat_spawn", "salvage", "hazard"}
POINT_ENTITY_TYPES = {"spawn", "salvage", "hazard"}
KIND_ENTITY_TYPES = {"salvage", "hazard"}


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
        if entity_type == "salvage" and entity.get("kind") != "stress_marker":
            has_gameplay_salvage = True

    if has_gameplay_salvage and not has_boat_spawn and not base_zones:
        failures.append("Playable salvage maps must define a base extraction zone or use boat_spawn extraction.")

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
    failures.extend(validate_entity_schema(entities, width, height, base_zones))
    if failures:
        for failure in failures:
            print(failure)
        return 1

    spawn_entities = [
        entity for entity in entities if entity.get("type") in ("spawn", "boat_spawn")
    ]
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
            failures.append(f"{entity['id']} is unreachable at {point}.")

    for zone in map_data.get("zones", []):
        if zone.get("type") == "marker":
            continue
        cells = rect_cells(zone)
        if not cells - solid:
            failures.append(f"{zone['id']} has no open cells.")
        elif not (cells & reachable):
            failures.append(f"{zone['id']} is unreachable.")

    if failures:
        for failure in failures:
            print(failure)
        return 1

    print(f"{map_data['id']} passed reachability validation from entry {spawn}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
