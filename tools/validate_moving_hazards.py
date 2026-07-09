#!/usr/bin/env python3
"""Validation helpers for source-authored moving hazards."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
HAZARD_KINDS = {"mine", "jellyfish", "stress_marker"}
MOVEMENTS = {"linear_patrol"}


def _is_int_value(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number_value(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _validate_id(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} {field} {value!r} must use lower_snake_case."]
    return []


def _validate_label(value: Any, item_label: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} display_label must be a non-empty string."]
    if "\n" in value or "\r" in value or not (ID_PATTERN.match(value) or DISPLAY_LABEL_PATTERN.match(value)):
        return [f"{item_label} display_label must be lower_snake_case or short display-safe text."]
    return []


def _validate_point(point: Any, item_label: str, field: str, width: int, height: int) -> list[str]:
    if not isinstance(point, dict):
        return [f"{item_label} {field} must be an object with x/y integer fields."]
    failures: list[str] = []
    for coord in ("x", "y"):
        if coord not in point:
            failures.append(f"{item_label} {field} is missing {coord}.")
        elif not _is_int_value(point[coord]):
            failures.append(f"{item_label} {field}.{coord} must be an integer.")
    if failures:
        return failures
    if int(point["x"]) < 0 or int(point["y"]) < 0 or int(point["x"]) >= width or int(point["y"]) >= height:
        failures.append(f"{item_label} {field} is outside map bounds.")
    return failures


def _hazard_point(hazard: dict[str, Any]) -> dict[str, int]:
    return {"x": int(hazard["x"]), "y": int(hazard["y"])}


def validate_moving_hazard_schema(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    hazards = map_data.get("moving_hazards", [])
    if not hazards:
        return failures
    if not isinstance(hazards, list):
        return ["moving_hazards must be a list when present."]

    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))
    seen_ids: set[str] = set()

    for index, hazard in enumerate(hazards):
        if not isinstance(hazard, dict):
            failures.append(f"moving_hazards[{index}] must be an object.")
            continue
        item_label = str(hazard.get("id", f"moving_hazards[{index}]"))
        failures.extend(_validate_id(hazard.get("id"), item_label, "id"))
        if item_label in seen_ids:
            failures.append(f"Duplicate moving hazard id {item_label!r}.")
        seen_ids.add(item_label)

        kind = hazard.get("kind")
        if kind not in HAZARD_KINDS:
            failures.append(f"{item_label} kind must be one of: {', '.join(sorted(HAZARD_KINDS))}.")
        movement = hazard.get("movement")
        if movement not in MOVEMENTS:
            failures.append(f"{item_label} movement must be one of: {', '.join(sorted(MOVEMENTS))}.")
        failures.extend(_validate_id(hazard.get("route_context"), item_label, "route_context"))
        failures.extend(_validate_label(hazard.get("display_label"), item_label))
        failures.extend(_validate_point(_hazard_point(hazard) if "x" in hazard and "y" in hazard else hazard, item_label, "initial point", width, height))

        path = hazard.get("path")
        if not isinstance(path, list) or len(path) < 2:
            failures.append(f"{item_label} path must contain at least two points.")
        else:
            for point_index, point in enumerate(path):
                failures.extend(_validate_point(point, item_label, f"path[{point_index}]", width, height))

        speed = hazard.get("speed_tiles_per_second")
        if not _is_number_value(speed) or float(speed) <= 0.0:
            failures.append(f"{item_label} speed_tiles_per_second must be a positive number.")
        if "phase_offset_seconds" in hazard:
            phase = hazard["phase_offset_seconds"]
            if not _is_number_value(phase) or float(phase) < 0.0:
                failures.append(f"{item_label} phase_offset_seconds must be a non-negative number.")

    return failures


def validate_moving_hazard_reachability(
    hazards: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    if not isinstance(hazards, list):
        return failures
    for hazard in hazards:
        if not isinstance(hazard, dict):
            continue
        item_label = str(hazard.get("id", "moving_hazard"))
        points: list[dict[str, Any]] = []
        if "x" in hazard and "y" in hazard:
            points.append(_hazard_point(hazard))
        if isinstance(hazard.get("path"), list):
            points.extend(point for point in hazard["path"] if isinstance(point, dict))
        for point in points:
            if not all(coord in point and _is_int_value(point[coord]) for coord in ("x", "y")):
                continue
            cell = (int(point["x"]), int(point["y"]))
            if cell in solid:
                failures.append(f"{item_label} moving hazard point {cell} is inside solid terrain.")
            elif cell not in reachable:
                failures.append(f"{item_label} moving hazard point {cell} is unreachable.")
    return failures
