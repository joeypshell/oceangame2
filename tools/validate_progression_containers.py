#!/usr/bin/env python3
"""Validation helpers for source-authored progression containers."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
CONTAINER_TYPES = {"upgrade_chest", "key_chest", "locked_salvage_cache"}
INTERACTIONS = {"instant", "timed_salvage", "pry_salvage"}
REWARD_TYPES = {"wallet", "upgrade_flag", "key_flag", "salvage_unlock"}


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells


def _is_int_value(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


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


def _validate_rect(container: dict[str, Any], item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    for field in ("x", "y", "w", "h"):
        if field not in container:
            failures.append(f"{item_label} container is missing required field {field}.")
        elif not _is_int_value(container[field]):
            failures.append(f"{item_label} container field {field} must be an integer.")
    if failures:
        return failures
    if int(container["w"]) <= 0 or int(container["h"]) <= 0:
        failures.append(f"{item_label} container width and height must be positive.")
    if int(container["x"]) < 0 or int(container["y"]) < 0:
        failures.append(f"{item_label} container rectangle origin must be inside map bounds.")
    if int(container["x"]) + int(container["w"]) > width or int(container["y"]) + int(container["h"]) > height:
        failures.append(f"{item_label} container rectangle extends outside map bounds.")
    return failures


def validate_progression_container_schema(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    containers = map_data.get("progression_containers", [])
    if not containers:
        return failures
    if not isinstance(containers, list):
        return ["progression_containers must be a list when present."]

    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))
    seen_ids: set[str] = set()

    for index, container in enumerate(containers):
        if not isinstance(container, dict):
            failures.append(f"progression_containers[{index}] must be an object.")
            continue
        item_label = str(container.get("id", f"progression_containers[{index}]"))
        failures.extend(_validate_id(container.get("id"), item_label, "id"))
        if item_label in seen_ids:
            failures.append(f"Duplicate progression container id {item_label!r}.")
        seen_ids.add(item_label)
        failures.extend(_validate_rect(container, item_label, width, height))
        failures.extend(_validate_label(container.get("display_label"), item_label))

        container_type = container.get("container_type")
        if container_type not in CONTAINER_TYPES:
            failures.append(f"{item_label} container_type must be one of: {', '.join(sorted(CONTAINER_TYPES))}.")
        interaction = container.get("interaction")
        if interaction not in INTERACTIONS:
            failures.append(f"{item_label} interaction must be one of: {', '.join(sorted(INTERACTIONS))}.")
        reward_type = container.get("reward_type")
        if reward_type not in REWARD_TYPES:
            failures.append(f"{item_label} reward_type must be one of: {', '.join(sorted(REWARD_TYPES))}.")
        failures.extend(_validate_id(container.get("reward_id"), item_label, "reward_id"))

        if reward_type == "wallet":
            amount = container.get("reward_amount")
            if not _is_int_value(amount) or int(amount) <= 0:
                failures.append(f"{item_label} wallet reward_amount must be a positive integer.")
        if "required_key_id" in container:
            failures.extend(_validate_id(container["required_key_id"], item_label, "required_key_id"))
        if "lock_id" in container:
            failures.extend(_validate_id(container["lock_id"], item_label, "lock_id"))
        if "route_context" in container:
            failures.extend(_validate_id(container["route_context"], item_label, "route_context"))

    return failures


def validate_progression_container_reachability(
    containers: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    if not isinstance(containers, list):
        return failures
    for container in containers:
        if not isinstance(container, dict):
            continue
        item_label = str(container.get("id", "progression_container"))
        if not all(field in container and _is_int_value(container[field]) for field in ("x", "y", "w", "h")):
            continue
        cells = _rect_cells(container)
        solid_cells = sorted(cells & solid)
        unreachable_cells = sorted(cell for cell in cells if cell not in reachable)
        if solid_cells:
            failures.append(f"{item_label} container rectangle contains solid cells. Sample: {solid_cells[:4]}")
        if unreachable_cells:
            failures.append(f"{item_label} container rectangle contains unreachable cells. Sample: {unreachable_cells[:4]}")
    return failures
