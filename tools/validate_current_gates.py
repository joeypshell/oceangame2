#!/usr/bin/env python3
"""Validation helpers for source-authored current gate marker zones."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
CURRENT_DIRECTIONS = {"left", "right", "up", "down"}
CURRENT_GATE_FIELDS = {
    "current_gate",
    "current_direction",
    "current_strength",
    "current_gate_label",
    "required_upgrade_id",
    "route_context",
}
CURRENT_GATE_TRIGGER_FIELDS = CURRENT_GATE_FIELDS - {"route_context"}


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells


def _is_int_value(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number_value(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _validate_rect_fields(zone: dict[str, Any], item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    for field in ("x", "y", "w", "h"):
        if field not in zone:
            failures.append(f"{item_label} current-gate marker is missing required field {field}.")
        elif not _is_int_value(zone[field]):
            failures.append(f"{item_label} current-gate field {field} must be an integer.")
    if failures:
        return failures
    if int(zone["w"]) <= 0 or int(zone["h"]) <= 0:
        failures.append(f"{item_label} current-gate width and height must be positive.")
    if int(zone["x"]) < 0 or int(zone["y"]) < 0:
        failures.append(f"{item_label} current-gate rectangle origin must be inside map bounds.")
    if int(zone["x"]) + int(zone["w"]) > width or int(zone["y"]) + int(zone["h"]) > height:
        failures.append(f"{item_label} current-gate rectangle extends outside map bounds.")
    return failures


def _validate_label(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if "\n" in value or "\r" in value or not (ID_PATTERN.match(value) or DISPLAY_LABEL_PATTERN.match(value)):
        return [f"{item_label} {field} must be lower_snake_case or short display-safe text."]
    return []


def _validate_id(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} {field} {value!r} must use lower_snake_case."]
    return []


def validate_current_gate_schema(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))

    for entity in map_data.get("entities", []):
        fields = CURRENT_GATE_TRIGGER_FIELDS & set(entity.keys())
        if fields:
            failures.append(
                f"{entity.get('id', 'entity')} current-gate metadata ({', '.join(sorted(fields))}) "
                "is only supported on marker zones."
            )

    for index, zone in enumerate(map_data.get("zones", [])):
        fields = CURRENT_GATE_TRIGGER_FIELDS & set(zone.keys())
        if not fields:
            continue
        item_label = str(zone.get("id", f"zone[{index}]"))
        if zone.get("type") != "marker":
            failures.append(f"{item_label} current-gate metadata is only supported on marker zones.")
            continue
        if zone.get("current_gate") is not True:
            failures.append(f"{item_label} current_gate must be true when current-gate metadata is present.")
        if not ID_PATTERN.match(item_label):
            failures.append(f"{item_label} current-gate id must use lower_snake_case.")

        failures.extend(_validate_rect_fields(zone, item_label, width, height))

        direction = zone.get("current_direction")
        if not isinstance(direction, str) or direction not in CURRENT_DIRECTIONS:
            allowed = ", ".join(sorted(CURRENT_DIRECTIONS))
            failures.append(f"{item_label} current_direction must be one of: {allowed}.")

        strength = zone.get("current_strength")
        if not _is_number_value(strength) or float(strength) <= 0.0:
            failures.append(f"{item_label} current_strength must be a positive number.")

        failures.extend(_validate_id(zone.get("required_upgrade_id"), item_label, "required_upgrade_id"))

        if "current_gate_label" in zone:
            failures.extend(_validate_label(zone["current_gate_label"], item_label, "current_gate_label"))
        if "route_context" in zone:
            failures.extend(_validate_id(zone["route_context"], item_label, "route_context"))

    return failures


def validate_current_gate_reachability(
    zones: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    for zone in zones:
        if not (CURRENT_GATE_TRIGGER_FIELDS & set(zone.keys())):
            continue
        item_label = str(zone.get("id", "current_gate"))
        if not all(field in zone and _is_int_value(zone[field]) for field in ("x", "y", "w", "h")):
            continue
        cells = _rect_cells(zone)
        solid_cells = sorted(cells & solid)
        unreachable_cells = sorted(cell for cell in cells if cell not in reachable)
        if solid_cells:
            failures.append(f"{item_label} current-gate rectangle contains solid cells. Sample: {solid_cells[:4]}")
        if unreachable_cells:
            failures.append(
                f"{item_label} current-gate rectangle contains unreachable cells. Sample: {unreachable_cells[:4]}"
            )
    return failures
