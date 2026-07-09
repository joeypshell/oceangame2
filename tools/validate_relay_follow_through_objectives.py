"""Validation helpers for source-authored relay follow-through objectives."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _':-]{0,47}$")
SUPPORTED_TRIGGERS = {"destination_payoff_banked"}
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


def _validate_objective(
    objective: dict[str, Any],
    item_label: str,
    entity_by_id: dict[str, dict[str, Any]],
) -> list[str]:
    failures: list[str] = []
    for field in ("id", "trigger", "connector_id", "entry_id", "target_id", "label"):
        if field not in objective:
            failures.append(f"{item_label} is missing required field {field}.")

    if "id" in objective:
        failures.extend(_validate_id(objective["id"], item_label, "id"))

    trigger = objective.get("trigger")
    if "trigger" in objective and (not isinstance(trigger, str) or trigger not in SUPPORTED_TRIGGERS):
        allowed = ", ".join(sorted(SUPPORTED_TRIGGERS))
        failures.append(f"{item_label} trigger {trigger!r} must be one of: {allowed}.")

    for field in ("connector_id", "entry_id", "target_id", "route_context", "source_prompt_id"):
        if field in objective:
            failures.extend(_validate_id(objective[field], item_label, field))

    target = entity_by_id.get(str(objective.get("target_id", "")))
    if "target_id" in objective:
        if target is None:
            failures.append(f"{item_label} target_id {objective['target_id']!r} does not exist in entities.")
        elif target.get("type") != "salvage" or target.get("kind") == "stress_marker":
            failures.append(f"{item_label} target_id {objective['target_id']!r} must reference playable salvage.")

    entry = entity_by_id.get(str(objective.get("entry_id", "")))
    if "entry_id" in objective:
        if entry is None:
            failures.append(f"{item_label} entry_id {objective['entry_id']!r} does not exist in entities.")
        elif entry.get("type") not in {"spawn", "boat_spawn"}:
            failures.append(f"{item_label} entry_id {objective['entry_id']!r} must reference spawn or boat_spawn.")

    if target is not None:
        connector_id = objective.get("connector_id")
        payoff_connector = target.get("destination_payoff_connector_id")
        if isinstance(connector_id, str) and isinstance(payoff_connector, str) and connector_id != payoff_connector:
            failures.append(
                f"{item_label} connector_id {connector_id!r} must match target destination_payoff_connector_id "
                f"{payoff_connector!r}."
            )

    for field in ("label", "result_label"):
        if field in objective:
            failures.extend(_validate_label(objective[field], item_label, field))

    if "intent" in objective and (not isinstance(objective["intent"], str) or not objective["intent"]):
        failures.append(f"{item_label} intent must be a non-empty string when present.")

    forbidden_fields = FORBIDDEN_FIELDS & set(objective.keys())
    if forbidden_fields:
        fields = ", ".join(sorted(forbidden_fields))
        failures.append(f"{item_label} must not author runtime/placement fields: {fields}.")

    return failures


def validate_relay_follow_through_objective_schema(
    map_data: dict[str, Any],
    entities: list[dict[str, Any]],
) -> list[str]:
    if "relay_follow_through_objectives" not in map_data:
        return []

    objectives = map_data["relay_follow_through_objectives"]
    if not isinstance(objectives, list):
        return ["relay_follow_through_objectives must be a list."]

    failures: list[str] = []
    if len(objectives) > 1:
        failures.append("Only one relay follow-through objective is currently supported.")

    entity_by_id = {
        entity.get("id"): entity
        for entity in entities
        if isinstance(entity, dict) and isinstance(entity.get("id"), str)
    }
    seen_ids: set[str] = set()
    for index, objective in enumerate(objectives):
        item_label = f"relay_follow_through_objectives[{index}]"
        if not isinstance(objective, dict):
            failures.append(f"{item_label} must be an object.")
            continue
        objective_id = objective.get("id")
        if isinstance(objective_id, str):
            if objective_id in seen_ids:
                failures.append(f"Duplicate relay follow-through objective id {objective_id!r}.")
            seen_ids.add(objective_id)
        failures.extend(_validate_objective(objective, item_label, entity_by_id))

    return failures


def validate_relay_follow_through_objective_reachability(
    map_data: dict[str, Any],
    entities: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    objectives = map_data.get("relay_follow_through_objectives", [])
    if not isinstance(objectives, list):
        return []

    failures: list[str] = []
    entity_by_id = {
        entity.get("id"): entity
        for entity in entities
        if isinstance(entity, dict) and isinstance(entity.get("id"), str)
    }
    for index, objective in enumerate(objectives):
        if not isinstance(objective, dict):
            continue
        item_label = f"relay_follow_through_objectives[{index}]"
        for field in ("entry_id", "target_id"):
            entity = entity_by_id.get(str(objective.get(field, "")))
            if entity is None:
                continue
            point = _entity_point(entity)
            if point is None:
                continue
            if point in solid:
                failures.append(f"{item_label} {field} {entity['id']!r} is inside solid terrain at {point}.")
            elif point not in reachable:
                failures.append(f"{item_label} {field} {entity['id']!r} is unreachable at {point}.")
    return failures
