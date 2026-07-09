#!/usr/bin/env python3
"""Validation helpers for source-authored visibility marker zones."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
VISIBILITY_LEVELS = {"dim", "dark"}
VISIBILITY_ZONE_FIELDS = {
    "visibility_zone",
    "visibility_level",
    "visibility_label",
    "required_upgrade_id",
    "visual_only",
    "route_context",
}
VISIBILITY_TRIGGER_FIELDS = {"visibility_zone", "visibility_level", "visibility_label", "visual_only"}


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells


def _is_int_value(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _validate_rect_fields(zone: dict[str, Any], item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    for field in ("x", "y", "w", "h"):
        if field not in zone:
            failures.append(f"{item_label} visibility marker is missing required field {field}.")
        elif not _is_int_value(zone[field]):
            failures.append(f"{item_label} visibility field {field} must be an integer.")
    if failures:
        return failures
    if int(zone["w"]) <= 0 or int(zone["h"]) <= 0:
        failures.append(f"{item_label} visibility rectangle width and height must be positive.")
    if int(zone["x"]) < 0 or int(zone["y"]) < 0:
        failures.append(f"{item_label} visibility rectangle origin must be inside map bounds.")
    if int(zone["x"]) + int(zone["w"]) > width or int(zone["y"]) + int(zone["h"]) > height:
        failures.append(f"{item_label} visibility rectangle extends outside map bounds.")
    return failures


def _validate_id(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} {field} {value!r} must use lower_snake_case."]
    return []


def _validate_label(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if "\n" in value or "\r" in value or not (ID_PATTERN.match(value) or DISPLAY_LABEL_PATTERN.match(value)):
        return [f"{item_label} {field} must be lower_snake_case or short display-safe text."]
    return []


def validate_visibility_zone_schema(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))

    for entity in map_data.get("entities", []):
        fields = VISIBILITY_TRIGGER_FIELDS & set(entity.keys())
        if fields:
            failures.append(
                f"{entity.get('id', 'entity')} visibility metadata ({', '.join(sorted(fields))}) "
                "is only supported on marker zones."
            )

    for index, zone in enumerate(map_data.get("zones", [])):
        fields = VISIBILITY_TRIGGER_FIELDS & set(zone.keys())
        if not fields:
            continue
        item_label = str(zone.get("id", f"zone[{index}]"))
        if zone.get("type") != "marker":
            failures.append(f"{item_label} visibility metadata is only supported on marker zones.")
            continue
        if zone.get("visibility_zone") is not True:
            failures.append(f"{item_label} visibility_zone must be true when visibility metadata is present.")
        if not ID_PATTERN.match(item_label):
            failures.append(f"{item_label} visibility marker id must use lower_snake_case.")

        failures.extend(_validate_rect_fields(zone, item_label, width, height))

        visibility_level = zone.get("visibility_level")
        if not isinstance(visibility_level, str) or visibility_level not in VISIBILITY_LEVELS:
            allowed = ", ".join(sorted(VISIBILITY_LEVELS))
            failures.append(f"{item_label} visibility_level must be one of: {allowed}.")

        if "visibility_label" in zone:
            failures.extend(_validate_label(zone["visibility_label"], item_label, "visibility_label"))
        if "required_upgrade_id" in zone:
            failures.extend(_validate_id(zone["required_upgrade_id"], item_label, "required_upgrade_id"))
        if "route_context" in zone:
            failures.extend(_validate_id(zone["route_context"], item_label, "route_context"))
        if "visual_only" in zone and not isinstance(zone["visual_only"], bool):
            failures.append(f"{item_label} visual_only must be a boolean when present.")

    return failures


def validate_visibility_zone_reachability(
    zones: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    for zone in zones:
        if not (VISIBILITY_TRIGGER_FIELDS & set(zone.keys())):
            continue
        item_label = str(zone.get("id", "visibility_zone"))
        if not all(field in zone and _is_int_value(zone[field]) for field in ("x", "y", "w", "h")):
            continue
        cells = _rect_cells(zone)
        solid_cells = sorted(cells & solid)
        unreachable_cells = sorted(cell for cell in cells if cell not in reachable)
        if solid_cells:
            failures.append(f"{item_label} visibility rectangle contains solid cells. Sample: {solid_cells[:4]}")
        if unreachable_cells:
            failures.append(
                f"{item_label} visibility rectangle contains unreachable cells. Sample: {unreachable_cells[:4]}"
            )
    return failures
