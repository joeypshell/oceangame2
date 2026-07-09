#!/usr/bin/env python3
"""Validation helpers for source-authored world connector marker zones."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
CONNECTOR_DIRECTIONS = {"forward", "return", "bidirectional"}
CONNECTOR_FIELDS = {
    "world_connector",
    "connector_label",
    "destination_map_id",
    "destination_map_path",
    "destination_entry_id",
    "connector_direction",
}


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells


def _is_int_value(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _repo_root_for_map(map_path: Path) -> Path:
    if map_path.parent.name == "maps":
        return map_path.parent.parent
    return Path.cwd()


def _resource_path_to_file(map_path: Path, resource_path: str) -> Path | None:
    prefix = "res://"
    if not resource_path.startswith(prefix):
        return None
    relative = resource_path[len(prefix) :]
    if ".." in Path(relative).parts:
        return None
    return _repo_root_for_map(map_path) / relative


def _load_destination_map(map_path: Path, resource_path: str) -> tuple[dict[str, Any] | None, str | None]:
    destination_file = _resource_path_to_file(map_path, resource_path)
    if destination_file is None:
        return None, f"destination_map_path {resource_path!r} must start with res:// and stay inside the project."
    if destination_file.suffix != ".json" or not destination_file.name.endswith(".greybox.json"):
        return None, f"destination_map_path {resource_path!r} must point to a .greybox.json map."
    if not destination_file.exists():
        return None, f"destination_map_path {resource_path!r} does not exist."
    with destination_file.open("r", encoding="utf-8") as handle:
        loaded = json.load(handle)
    if not isinstance(loaded, dict):
        return None, f"destination_map_path {resource_path!r} did not parse as a map object."
    return loaded, None


def _validate_rect_fields(zone: dict[str, Any], item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    for field in ("x", "y", "w", "h"):
        if field not in zone:
            failures.append(f"{item_label} connector marker is missing required field {field}.")
        elif not _is_int_value(zone[field]):
            failures.append(f"{item_label} connector field {field} must be an integer.")
    if failures:
        return failures
    if int(zone["w"]) <= 0 or int(zone["h"]) <= 0:
        failures.append(f"{item_label} connector width and height must be positive.")
    if int(zone["x"]) < 0 or int(zone["y"]) < 0:
        failures.append(f"{item_label} connector rectangle origin must be inside map bounds.")
    if int(zone["x"]) + int(zone["w"]) > width or int(zone["y"]) + int(zone["h"]) > height:
        failures.append(f"{item_label} connector rectangle extends outside map bounds.")
    return failures


def validate_world_connector_schema(map_path: Path, map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))
    connector_ids: set[str] = set()

    for entity in map_data.get("entities", []):
        fields = CONNECTOR_FIELDS & set(entity.keys())
        if fields:
            failures.append(
                f"{entity.get('id', 'entity')} connector metadata ({', '.join(sorted(fields))}) "
                "is only supported on marker zones."
            )

    for index, zone in enumerate(map_data.get("zones", [])):
        fields = CONNECTOR_FIELDS & set(zone.keys())
        if not fields:
            continue
        item_label = str(zone.get("id", f"zone[{index}]"))
        if zone.get("type") != "marker":
            failures.append(f"{item_label} connector metadata is only supported on marker zones.")
            continue
        if zone.get("world_connector") is not True:
            failures.append(f"{item_label} world_connector must be true when connector metadata is present.")
        if not ID_PATTERN.match(item_label):
            failures.append(f"{item_label} connector id must use lower_snake_case.")
        if item_label in connector_ids:
            failures.append(f"Duplicate connector id {item_label!r}.")
        connector_ids.add(item_label)

        failures.extend(_validate_rect_fields(zone, item_label, width, height))

        label = zone.get("connector_label")
        if not isinstance(label, str) or not label:
            failures.append(f"{item_label} connector_label must be a non-empty string.")
        elif "\n" in label or "\r" in label or not (ID_PATTERN.match(label) or DISPLAY_LABEL_PATTERN.match(label)):
            failures.append(f"{item_label} connector_label must be lower_snake_case or short display-safe text.")

        destination_map_id = zone.get("destination_map_id")
        if not isinstance(destination_map_id, str) or not destination_map_id:
            failures.append(f"{item_label} destination_map_id must be a non-empty string.")
        elif not ID_PATTERN.match(destination_map_id):
            failures.append(f"{item_label} destination_map_id {destination_map_id!r} must use lower_snake_case.")

        destination_map_path = zone.get("destination_map_path")
        destination_data: dict[str, Any] | None = None
        if not isinstance(destination_map_path, str) or not destination_map_path:
            failures.append(f"{item_label} destination_map_path must be a non-empty string.")
        else:
            destination_data, load_error = _load_destination_map(map_path, destination_map_path)
            if load_error is not None:
                failures.append(f"{item_label} {load_error}")
            elif destination_map_id and destination_data.get("id") != destination_map_id:
                failures.append(
                    f"{item_label} destination_map_id {destination_map_id!r} does not match "
                    f"{destination_map_path} id {destination_data.get('id')!r}."
                )

        destination_entry_id = zone.get("destination_entry_id")
        if not isinstance(destination_entry_id, str) or not destination_entry_id:
            failures.append(f"{item_label} destination_entry_id must be a non-empty string.")
        elif not ID_PATTERN.match(destination_entry_id):
            failures.append(f"{item_label} destination_entry_id {destination_entry_id!r} must use lower_snake_case.")
        elif destination_data is not None:
            entries = {
                entity.get("id")
                for entity in destination_data.get("entities", [])
                if entity.get("type") in {"spawn", "boat_spawn"}
            }
            if destination_entry_id not in entries:
                failures.append(
                    f"{item_label} destination_entry_id {destination_entry_id!r} does not reference a "
                    f"spawn or boat_spawn in {destination_map_path}."
                )

        direction = zone.get("connector_direction", "forward")
        if not isinstance(direction, str) or direction not in CONNECTOR_DIRECTIONS:
            allowed = ", ".join(sorted(CONNECTOR_DIRECTIONS))
            failures.append(f"{item_label} connector_direction must be one of: {allowed}.")

    return failures


def validate_world_connector_reachability(
    zones: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    for zone in zones:
        if not (CONNECTOR_FIELDS & set(zone.keys())):
            continue
        item_label = str(zone.get("id", "connector"))
        if not all(field in zone and _is_int_value(zone[field]) for field in ("x", "y", "w", "h")):
            continue
        cells = _rect_cells(zone)
        solid_cells = sorted(cells & solid)
        unreachable_cells = sorted(cell for cell in cells if cell not in reachable)
        if solid_cells:
            failures.append(f"{item_label} connector rectangle contains solid cells. Sample: {solid_cells[:4]}")
        if unreachable_cells:
            failures.append(f"{item_label} connector rectangle contains unreachable cells. Sample: {unreachable_cells[:4]}")
    return failures
