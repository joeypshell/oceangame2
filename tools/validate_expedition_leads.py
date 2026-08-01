#!/usr/bin/env python3
"""Validate source-authored Expansion 15 expedition-planning leads."""

from __future__ import annotations

import re
from typing import Any

from validate_daily_conditions import validate_daily_condition_schema
from validate_wreck_network_investigations import validate_wreck_network_investigation_schema


PARENT_TYPES = {
    "regional_journeys": "regional_journey",
    "daily_conditions": "daily_condition",
}
LEAD_FIELDS = {"lead_type", "label", "summary", "active_guidance", "order"}
FORBIDDEN_LEAD_FIELDS = {
    "active",
    "completed",
    "current_day",
    "eligible",
    "highlighted",
    "profile_state",
    "readiness",
    "reward",
    "reward_id",
    "reward_kind",
    "score",
    "selected",
    "selected_lead_id",
}
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|:+.-]{0,47}$")
TEXT_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|:+.-]{0,95}$")


def _items(map_data: dict[str, Any], collection: str) -> list[dict[str, Any]]:
    value = map_data.get(collection, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records_by_id(map_data: dict[str, Any], collection: str) -> dict[str, dict[str, Any]]:
    return {
        str(item["id"]): item
        for item in _items(map_data, collection)
        if isinstance(item.get("id"), str)
    }


def _misplaced_lead_failures(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if "expedition_lead" in map_data:
        failures.append("Top-level expedition_lead metadata is unsupported.")
    for collection, value in map_data.items():
        if collection in PARENT_TYPES or not isinstance(value, list):
            continue
        for index, item in enumerate(value):
            if isinstance(item, dict) and "expedition_lead" in item:
                failures.append(
                    f"{collection}[{index}] expedition_lead is supported only on "
                    "regional_journeys and daily_conditions."
                )
    return failures


def _text_failure(value: Any, label: str, field: str, pattern: re.Pattern[str], limit: int) -> list[str]:
    if not isinstance(value, str) or not value or "\n" in value or "\r" in value:
        return [f"{label} expedition_lead {field} must be non-empty single-line display-safe text."]
    if len(value) > limit or pattern.fullmatch(value) is None:
        return [f"{label} expedition_lead {field} must be display-safe text at most {limit} characters."]
    return []


def _regional_reference_failures(map_data: dict[str, Any], parent: dict[str, Any], label: str) -> list[str]:
    failures: list[str] = []
    surveys = _records_by_id(map_data, "survey_targets")
    survey_id = str(parent.get("survey_target_id", ""))
    survey = surveys.get(survey_id)
    if survey is None:
        failures.append(f"{label} expedition lead has dangling survey_target_id {survey_id!r}.")
    elif not isinstance(survey.get("discovery_id"), str) or not ID_PATTERN.fullmatch(survey["discovery_id"]):
        failures.append(f"{label} expedition lead survey must author a valid discovery_id.")

    required_discovery_id = str(parent.get("required_discovery_id", ""))
    discovery_sources = [
        item
        for item in _items(map_data, "survey_targets")
        if item.get("discovery_id") == required_discovery_id
    ]
    discovery_sources.extend(
        item
        for item in _items(map_data, "entities")
        if (
            item.get("type") == "tool_target"
            and item.get("reward_kind") == "discovery"
            and item.get("reward_id") == required_discovery_id
        )
    )
    if not ID_PATTERN.fullmatch(required_discovery_id) or len(discovery_sources) != 1:
        failures.append(
            f"{label} expedition lead required_discovery_id must resolve to exactly one discovery source."
        )

    capability_id = str(parent.get("required_capability_id", ""))
    capability_projects = [
        project
        for project in _items(map_data, "material_projects")
        if project.get("unlocks_capability_id") == capability_id
    ]
    if not ID_PATTERN.fullmatch(capability_id) or len(capability_projects) != 1:
        failures.append(
            f"{label} expedition lead required_capability_id must resolve to exactly one material project."
        )
    return failures


def _daily_reference_failures(map_data: dict[str, Any], parent: dict[str, Any], label: str) -> list[str]:
    failures: list[str] = []
    condition_id = str(parent.get("id", ""))
    linked_pools = [
        item
        for item in _items(map_data, "material_candidate_pools")
        if item.get("daily_condition_id") == condition_id
    ]
    linked_hazards = [
        item
        for item in _items(map_data, "moving_hazards")
        if item.get("daily_condition_id") == condition_id
    ]
    if not linked_pools:
        failures.append(f"{label} expedition lead has no linked daily-condition material pool.")
    if not linked_hazards:
        failures.append(f"{label} expedition lead has no linked daily-condition moving hazard.")
    for field in ("schedule", "route_context"):
        value = parent.get(field)
        if not isinstance(value, str) or ID_PATTERN.fullmatch(value) is None:
            failures.append(f"{label} expedition lead parent {field} must use lower_snake_case.")
    return failures


def validate_expedition_lead_schema(map_data: dict[str, Any]) -> list[str]:
    failures = _misplaced_lead_failures(map_data)
    seen_ids: set[str] = set()
    seen_orders: set[int] = set()

    for collection, expected_type in PARENT_TYPES.items():
        raw_items = map_data.get(collection, [])
        if not isinstance(raw_items, list):
            continue
        for index, parent in enumerate(raw_items):
            if not isinstance(parent, dict) or "expedition_lead" not in parent:
                continue
            label = str(parent.get("id", f"{collection}[{index}]"))
            parent_id = parent.get("id")
            if not isinstance(parent_id, str) or ID_PATTERN.fullmatch(parent_id) is None:
                failures.append(f"{label} expedition lead parent id must use lower_snake_case.")
            elif parent_id in seen_ids:
                failures.append(f"Duplicate expedition lead id {parent_id!r}.")
            else:
                seen_ids.add(parent_id)

            lead = parent["expedition_lead"]
            if not isinstance(lead, dict):
                failures.append(f"{label} expedition_lead must be an object.")
                continue
            missing = LEAD_FIELDS - set(lead)
            if missing:
                failures.append(
                    f"{label} expedition_lead is missing required fields: {', '.join(sorted(missing))}."
                )
            forbidden = FORBIDDEN_LEAD_FIELDS & set(lead)
            if forbidden:
                failures.append(
                    f"{label} expedition_lead must not author runtime selection or rewards: "
                    f"{', '.join(sorted(forbidden))}."
                )
            unsupported = set(lead) - LEAD_FIELDS - FORBIDDEN_LEAD_FIELDS
            if unsupported:
                failures.append(
                    f"{label} expedition_lead contains unsupported fields: "
                    f"{', '.join(sorted(unsupported))}."
                )

            lead_type = lead.get("lead_type")
            if lead_type not in PARENT_TYPES.values():
                failures.append(f"{label} expedition_lead lead_type {lead_type!r} is unsupported.")
            elif lead_type != expected_type:
                failures.append(
                    f"{label} expedition_lead lead_type must match parent type {expected_type!r}."
                )
            failures.extend(_text_failure(lead.get("label"), label, "label", LABEL_PATTERN, 48))
            failures.extend(_text_failure(lead.get("summary"), label, "summary", TEXT_PATTERN, 96))
            failures.extend(
                _text_failure(lead.get("active_guidance"), label, "active_guidance", TEXT_PATTERN, 96)
            )

            order = lead.get("order")
            if not isinstance(order, int) or isinstance(order, bool) or order < 0:
                failures.append(f"{label} expedition_lead order must be a non-negative integer.")
            elif order in seen_orders:
                failures.append(f"Duplicate expedition lead order {order}.")
            else:
                seen_orders.add(order)

            route_context = parent.get("route_context")
            if not isinstance(route_context, str) or ID_PATTERN.fullmatch(route_context) is None:
                failures.append(f"{label} expedition lead parent route_context must use lower_snake_case.")
            if expected_type == "regional_journey":
                failures.extend(_regional_reference_failures(map_data, parent, label))
            else:
                failures.extend(_daily_reference_failures(map_data, parent, label))
    return failures


def validate_expedition_planning_schema(map_data: dict[str, Any]) -> list[str]:
    return [
        *validate_daily_condition_schema(map_data),
        *validate_expedition_lead_schema(map_data),
        *validate_wreck_network_investigation_schema(map_data),
    ]
