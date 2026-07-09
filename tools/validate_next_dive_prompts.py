"""Validation helpers for source-authored next-dive objective prompts."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _':-]{0,47}$")
SUPPORTED_TRIGGERS = {"primary_objective_complete"}
FORBIDDEN_FIELDS = {
    "x",
    "y",
    "w",
    "h",
    "score",
    "score_value",
    "oxygen",
    "oxygen_bonus",
    "cargo",
    "cargo_capacity",
    "wallet",
    "reward",
    "upgrade",
    "completed",
    "complete",
    "failed",
    "visible",
    "state",
    "save_state",
}


def _validate_id(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty lower_snake_case string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} {field} {value!r} must use lower_snake_case."]
    return []


def _validate_label(value: Any, item_label: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} label must be a non-empty string."]
    if "\n" in value or "\r" in value or not DISPLAY_LABEL_PATTERN.match(value):
        return [f"{item_label} label must be short display-safe text."]
    return []


def _validate_prompt(
    prompt: dict[str, Any],
    item_label: str,
    objective_ids: set[str],
    primary_objective_id: str,
    authored_ids: set[str],
) -> list[str]:
    failures: list[str] = []
    for field in ("id", "trigger", "objective_id", "label"):
        if field not in prompt:
            failures.append(f"{item_label} is missing required field {field}.")

    if "id" in prompt:
        failures.extend(_validate_id(prompt["id"], item_label, "id"))

    trigger = prompt.get("trigger")
    if "trigger" in prompt:
        if not isinstance(trigger, str) or trigger not in SUPPORTED_TRIGGERS:
            allowed = ", ".join(sorted(SUPPORTED_TRIGGERS))
            failures.append(f"{item_label} trigger {trigger!r} must be one of: {allowed}.")

    objective_id = prompt.get("objective_id")
    if "objective_id" in prompt:
        failures.extend(_validate_id(objective_id, item_label, "objective_id"))
        if isinstance(objective_id, str) and objective_id not in objective_ids:
            failures.append(f"{item_label} objective_id {objective_id!r} does not exist in route_objectives.")
        if trigger == "primary_objective_complete":
            if not primary_objective_id:
                failures.append(f"{item_label} requires primary_route_objective_id for primary_objective_complete.")
            elif objective_id != primary_objective_id:
                failures.append(
                    f"{item_label} objective_id {objective_id!r} must match primary_route_objective_id "
                    f"{primary_objective_id!r} for primary_objective_complete."
                )

    if "target_id" in prompt:
        target_id = prompt["target_id"]
        failures.extend(_validate_id(target_id, item_label, "target_id"))
        if isinstance(target_id, str) and target_id not in authored_ids:
            failures.append(f"{item_label} target_id {target_id!r} does not exist in entities or zones.")

    if "route_context" in prompt:
        failures.extend(_validate_id(prompt["route_context"], item_label, "route_context"))

    if "label" in prompt:
        failures.extend(_validate_label(prompt["label"], item_label))

    if "intent" in prompt and (not isinstance(prompt["intent"], str) or not prompt["intent"]):
        failures.append(f"{item_label} intent must be a non-empty string when present.")

    forbidden_fields = FORBIDDEN_FIELDS & set(prompt.keys())
    if forbidden_fields:
        fields = ", ".join(sorted(forbidden_fields))
        failures.append(f"{item_label} must not author runtime/placement fields: {fields}.")

    return failures


def validate_next_dive_prompt_schema(map_data: dict[str, Any], entities: list[dict], zones: list[dict]) -> list[str]:
    if "next_dive_objective_prompts" not in map_data:
        return []

    prompts = map_data["next_dive_objective_prompts"]
    if not isinstance(prompts, list):
        return ["next_dive_objective_prompts must be a list."]

    failures: list[str] = []
    if len(prompts) > 1:
        failures.append("Only one next-dive objective prompt is currently supported.")

    objectives = map_data.get("route_objectives", [])
    objective_ids = {
        objective.get("id")
        for objective in objectives
        if isinstance(objective, dict) and isinstance(objective.get("id"), str)
    }
    primary_objective_id = map_data.get("primary_route_objective_id", "")
    if not isinstance(primary_objective_id, str):
        primary_objective_id = ""
    authored_ids = {
        item.get("id")
        for item in [*entities, *zones]
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }

    seen_ids: set[str] = set()
    for index, prompt in enumerate(prompts):
        item_label = f"next_dive_objective_prompts[{index}]"
        if not isinstance(prompt, dict):
            failures.append(f"{item_label} must be an object.")
            continue
        prompt_id = prompt.get("id")
        if isinstance(prompt_id, str):
            if prompt_id in seen_ids:
                failures.append(f"Duplicate next-dive objective prompt id {prompt_id!r}.")
            seen_ids.add(prompt_id)
        failures.extend(_validate_prompt(prompt, item_label, objective_ids, primary_objective_id, authored_ids))

    return failures
