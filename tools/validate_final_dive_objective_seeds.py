"""Validation helpers for source-authored final-dive objective seeds."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _':-]{0,47}$")
SUPPORTED_TRIGGERS = {"relay_follow_through_complete"}
FORBIDDEN_FIELDS = {
    "x",
    "y",
    "w",
    "h",
    "score",
    "score_value",
    "oxygen",
    "cargo",
    "wallet",
    "reward",
    "upgrade",
    "completed",
    "complete",
    "failed",
    "visible",
    "state",
    "save_state",
    "unlocked",
    "destination_map_path",
    "destination_entry_id",
}


def _is_int_value(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _validate_id(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty lower_snake_case string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} {field} {value!r} must use lower_snake_case."]
    return []


def _validate_label(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if "\n" in value or "\r" in value or not DISPLAY_LABEL_PATTERN.match(value):
        return [f"{item_label} {field} must be short display-safe text."]
    return []


def _entity_point(entity: dict[str, Any]) -> tuple[int, int] | None:
    if not (_is_int_value(entity.get("x")) and _is_int_value(entity.get("y"))):
        return None
    return (int(entity["x"]), int(entity["y"]))


def _relay_objective_ids(map_data: dict[str, Any]) -> set[str]:
    objectives = map_data.get("relay_follow_through_objectives", [])
    if not isinstance(objectives, list):
        return set()
    return {
        objective.get("id")
        for objective in objectives
        if isinstance(objective, dict) and isinstance(objective.get("id"), str)
    }


def _relay_objective_by_id(map_data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    objectives = map_data.get("relay_follow_through_objectives", [])
    if not isinstance(objectives, list):
        return {}
    return {
        objective["id"]: objective
        for objective in objectives
        if isinstance(objective, dict) and isinstance(objective.get("id"), str)
    }


def _validate_seed(
    seed: dict[str, Any],
    item_label: str,
    entity_by_id: dict[str, dict[str, Any]],
    source_objective_ids: set[str],
    source_objective_by_id: dict[str, dict[str, Any]],
) -> list[str]:
    failures: list[str] = []
    for field in ("id", "trigger", "source_objective_id", "target_id", "label"):
        if field not in seed:
            failures.append(f"{item_label} is missing required field {field}.")

    if "id" in seed:
        failures.extend(_validate_id(seed["id"], item_label, "id"))

    trigger = seed.get("trigger")
    if "trigger" in seed and (not isinstance(trigger, str) or trigger not in SUPPORTED_TRIGGERS):
        allowed = ", ".join(sorted(SUPPORTED_TRIGGERS))
        failures.append(f"{item_label} trigger {trigger!r} must be one of: {allowed}.")

    for field in ("source_objective_id", "target_id", "route_context"):
        if field in seed:
            failures.extend(_validate_id(seed[field], item_label, field))

    source_id = seed.get("source_objective_id")
    source_objective = None
    if "source_objective_id" in seed:
        if isinstance(source_id, str) and source_id in source_objective_ids:
            source_objective = source_objective_by_id.get(source_id)
        else:
            failures.append(
                f"{item_label} source_objective_id {source_id!r} does not exist in relay_follow_through_objectives."
            )

    target = entity_by_id.get(str(seed.get("target_id", "")))
    if "target_id" in seed:
        if target is None:
            failures.append(f"{item_label} target_id {seed['target_id']!r} does not exist in entities.")
        elif target.get("type") != "salvage" or target.get("kind") == "stress_marker":
            failures.append(f"{item_label} target_id {seed['target_id']!r} must reference playable salvage.")

    if source_objective is not None and isinstance(seed.get("target_id"), str):
        source_target_id = source_objective.get("target_id")
        if isinstance(source_target_id, str) and seed["target_id"] != source_target_id:
            failures.append(
                f"{item_label} target_id {seed['target_id']!r} must match source objective target_id "
                f"{source_target_id!r} for relay_follow_through_complete."
            )

    for field in ("label", "result_label"):
        if field in seed:
            failures.extend(_validate_label(seed[field], item_label, field))

    if "intent" in seed and (not isinstance(seed["intent"], str) or not seed["intent"]):
        failures.append(f"{item_label} intent must be a non-empty string when present.")

    forbidden_fields = FORBIDDEN_FIELDS & set(seed.keys())
    if forbidden_fields:
        fields = ", ".join(sorted(forbidden_fields))
        failures.append(f"{item_label} must not author runtime/placement fields: {fields}.")

    return failures


def validate_final_dive_objective_seed_schema(
    map_data: dict[str, Any],
    entities: list[dict[str, Any]],
) -> list[str]:
    if "final_dive_objective_seeds" not in map_data:
        return []

    seeds = map_data["final_dive_objective_seeds"]
    if not isinstance(seeds, list):
        return ["final_dive_objective_seeds must be a list."]

    failures: list[str] = []
    if len(seeds) > 1:
        failures.append("Only one final-dive objective seed is currently supported.")

    entity_by_id = {
        entity.get("id"): entity
        for entity in entities
        if isinstance(entity, dict) and isinstance(entity.get("id"), str)
    }
    source_objective_ids = _relay_objective_ids(map_data)
    source_objective_by_id = _relay_objective_by_id(map_data)
    seen_ids: set[str] = set()
    for index, seed in enumerate(seeds):
        item_label = f"final_dive_objective_seeds[{index}]"
        if not isinstance(seed, dict):
            failures.append(f"{item_label} must be an object.")
            continue
        seed_id = seed.get("id")
        if isinstance(seed_id, str):
            if seed_id in seen_ids:
                failures.append(f"Duplicate final-dive objective seed id {seed_id!r}.")
            seen_ids.add(seed_id)
        failures.extend(_validate_seed(seed, item_label, entity_by_id, source_objective_ids, source_objective_by_id))

    return failures


def validate_final_dive_objective_seed_reachability(
    map_data: dict[str, Any],
    entities: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    seeds = map_data.get("final_dive_objective_seeds", [])
    if not isinstance(seeds, list):
        return []

    failures: list[str] = []
    entity_by_id = {
        entity.get("id"): entity
        for entity in entities
        if isinstance(entity, dict) and isinstance(entity.get("id"), str)
    }
    for index, seed in enumerate(seeds):
        if not isinstance(seed, dict):
            continue
        item_label = f"final_dive_objective_seeds[{index}]"
        target = entity_by_id.get(str(seed.get("target_id", "")))
        if target is None:
            continue
        point = _entity_point(target)
        if point is None:
            continue
        if point in solid:
            failures.append(f"{item_label} target_id {target['id']!r} is inside solid terrain at {point}.")
        elif point not in reachable:
            failures.append(f"{item_label} target_id {target['id']!r} is unreachable at {point}.")
    return failures
