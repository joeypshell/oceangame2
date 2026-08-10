#!/usr/bin/env python3
"""Validate the bounded Expansion 08 daily-condition source contract."""

from __future__ import annotations

import re
from typing import Any


CONDITION_ID = "southwest_jellyfish_bloom"
CONDITION_SCHEDULE = "even_days_v1"
ROUTE_CONTEXT = "southwest_pocket_decision"
BONUS_POOL_ID = "southwest_bloom_coil_bonus_pool"
BONUS_CANDIDATE_ID = "material_coil_southwest_bloom"
MIGRATION_HAZARD_ID = "southwest_bloom_jellyfish_patrol"
FORECAST_LABEL = "Tomorrow: Southwest jellyfish bloom"
ACTIVE_LABEL = "Southwest bloom: jellyfish + coil trace"
REQUIRED_CONDITION_FIELDS = {"id", "schedule", "forecast_label", "active_label", "route_context", "intent"}
CONDITION_FIELDS = REQUIRED_CONDITION_FIELDS | {"expedition_lead"}
LINK_FIELDS = {"daily_condition_id", "pool_role"}
RUNTIME_FIELDS = {
    "active", "cargo", "current_day", "depleted", "next_condition", "profile_state", "selected",
    "spawned", "visible", "weights",
}
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
TEXT_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|:+.-]{0,95}$")


def _items(map_data: dict[str, Any], collection: str) -> list[dict[str, Any]]:
    value = map_data.get(collection, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _id_failure(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not ID_PATTERN.match(value):
        return [f"{label} {field} must use non-empty lower_snake_case."]
    return []


def _text_failure(value: Any, label: str, field: str, *, long: bool = False) -> list[str]:
    if not isinstance(value, str) or not value or "\n" in value or "\r" in value:
        return [f"{label} {field} must be compact single-line text."]
    if long:
        return [] if len(value) <= 160 else [f"{label} {field} must be at most 160 characters."]
    return [] if TEXT_PATTERN.match(value) else [f"{label} {field} must be compact display-safe text."]


def _reserved_ids(map_data: dict[str, Any]) -> set[str]:
    collections = (
        "entities", "zones", "progression_containers", "moving_hazards", "hostile_encounters",
        "survey_targets", "material_candidate_pools", "material_projects", "biological_resource_sources",
    )
    return {
        str(item["id"])
        for collection in collections
        for item in _items(map_data, collection)
        if isinstance(item.get("id"), str)
    }


def _misplaced_link_failures(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    allowed = {"material_candidate_pools", "moving_hazards"}
    collections = (
        "entities", "zones", "progression_containers", "hostile_encounters", "survey_targets",
        "material_projects", "biological_resource_sources",
    )
    for collection in collections:
        for index, item in enumerate(_items(map_data, collection)):
            misplaced = LINK_FIELDS & set(item)
            if misplaced:
                failures.append(
                    f"{collection}[{index}] daily-condition metadata ({', '.join(sorted(misplaced))}) "
                    f"is only supported in {', '.join(sorted(allowed))}."
                )
    for index, hazard in enumerate(_items(map_data, "moving_hazards")):
        if "pool_role" in hazard:
            failures.append(f"moving_hazards[{index}] pool_role is only supported in material_candidate_pools.")
    return failures


def validate_daily_condition_schema(map_data: dict[str, Any]) -> list[str]:
    failures = _misplaced_link_failures(map_data)
    raw_conditions = map_data.get("daily_conditions", [])
    if not isinstance(raw_conditions, list):
        return [*failures, "daily_conditions must be a list when present."]

    linked_pools = [
        pool
        for pool in _items(map_data, "material_candidate_pools")
        if "daily_condition_id" in pool
    ]
    linked_hazards = [hazard for hazard in _items(map_data, "moving_hazards") if "daily_condition_id" in hazard]
    if not raw_conditions:
        if linked_pools or linked_hazards:
            failures.append("Daily-condition links require one daily_conditions definition.")
        return failures

    if len(raw_conditions) != 1 or not isinstance(raw_conditions[0], dict):
        failures.append("Expansion 08 requires exactly one daily-condition object.")
        return failures

    condition = raw_conditions[0]
    label = str(condition.get("id", "daily_conditions[0]"))
    missing = REQUIRED_CONDITION_FIELDS - set(condition)
    if missing:
        failures.append(f"{label} daily condition is missing: {', '.join(sorted(missing))}.")
    unsupported = set(condition) - CONDITION_FIELDS
    if unsupported:
        failures.append(f"{label} has unsupported daily-condition fields: {', '.join(sorted(unsupported))}.")
    runtime = RUNTIME_FIELDS & set(condition)
    if runtime:
        failures.append(f"{label} must not author runtime condition state: {', '.join(sorted(runtime))}.")
    failures.extend(_id_failure(condition.get("id"), label, "id"))
    if condition.get("id") in _reserved_ids(map_data):
        failures.append(f"Duplicate daily condition id {condition.get('id')!r}.")
    expected = {
        "id": CONDITION_ID,
        "schedule": CONDITION_SCHEDULE,
        "forecast_label": FORECAST_LABEL,
        "active_label": ACTIVE_LABEL,
        "route_context": ROUTE_CONTEXT,
    }
    for field, value in expected.items():
        if condition.get(field) != value:
            failures.append(f"{label} {field} must be {value!r}.")
    failures.extend(_text_failure(condition.get("forecast_label"), label, "forecast_label"))
    failures.extend(_text_failure(condition.get("active_label"), label, "active_label"))
    failures.extend(_text_failure(condition.get("intent"), label, "intent", long=True))

    if len(linked_pools) != 1:
        failures.append("Expansion 08 requires exactly one condition-bound material pool.")
    if len(linked_hazards) != 1:
        failures.append("Expansion 08 requires exactly one condition-bound moving hazard.")
    for item in [*linked_pools, *linked_hazards]:
        item_label = str(item.get("id", "condition_link"))
        failures.extend(_id_failure(item.get("daily_condition_id"), item_label, "daily_condition_id"))
        if item.get("daily_condition_id") != CONDITION_ID:
            failures.append(f"{item_label} daily_condition_id must be {CONDITION_ID!r}.")

    if linked_pools:
        pool = linked_pools[0]
        pool_expected = {
            "id": BONUS_POOL_ID,
            "material_id": "conductive_coil",
            "selection_strategy": "day_rotation_v1",
            "select_count": 1,
            "candidate_ids": [BONUS_CANDIDATE_ID],
            "pool_role": "optional_bonus",
        }
        for field, value in pool_expected.items():
            if pool.get(field) != value:
                failures.append(f"{pool.get('id', 'condition_pool')} {field} must be {value!r}.")
        candidates = {str(item.get("id", "")): item for item in _items(map_data, "entities")}
        candidate = candidates.get(BONUS_CANDIDATE_ID)
        if candidate is None:
            failures.append(f"Condition bonus candidate {BONUS_CANDIDATE_ID!r} does not exist.")
        elif candidate.get("candidate_pool_id") != BONUS_POOL_ID or candidate.get("material_id") != "conductive_coil":
            failures.append(f"Condition bonus candidate {BONUS_CANDIDATE_ID!r} metadata does not match its pool/material.")

    if linked_hazards:
        hazard = linked_hazards[0]
        hazard_expected = {
            "id": MIGRATION_HAZARD_ID,
            "kind": "jellyfish",
            "movement": "linear_patrol",
            "route_context": ROUTE_CONTEXT,
        }
        for field, value in hazard_expected.items():
            if hazard.get(field) != value:
                failures.append(f"{hazard.get('id', 'condition_hazard')} {field} must be {value!r}.")
    return failures
