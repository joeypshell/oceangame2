#!/usr/bin/env python3
"""Validate optional pending discoveries authored on cutter tool targets."""

from __future__ import annotations

import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
REWARD_FIELDS = {
    "reward_kind",
    "reward_id",
    "reward_pending_label",
    "reward_commit_label",
    "reward_next_lead_label",
    "reward_commit_map_id",
    "reward_commit_map_path",
    "reward_commit_entry_id",
}
REQUIRED_REWARD_FIELDS = tuple(sorted(REWARD_FIELDS))
RUNTIME_FIELDS = {"committed", "pending", "profile_state", "reward_claimed"}


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _valid_id(value: Any) -> bool:
    return isinstance(value, str) and ID_PATTERN.fullmatch(value) is not None


def _valid_label(value: Any) -> bool:
    return isinstance(value, str) and 0 < len(value) <= 96 and "\n" not in value and "\r" not in value


def discovery_reward_sources(map_data: dict[str, Any], reward_id: str) -> list[dict[str, Any]]:
    return [
        entity
        for entity in _items(map_data, "entities")
        if entity.get("reward_kind") == "discovery" and entity.get("reward_id") == reward_id
    ]


def validate_tool_target_reward_schema(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    boats = {
        str(entity.get("id", "")): entity
        for entity in _items(map_data, "entities")
        if entity.get("type") == "boat_spawn"
    }
    journeys = _items(map_data, "regional_journeys")
    survey_reward_ids = {
        str(target.get(field, ""))
        for target in _items(map_data, "survey_targets")
        for field in ("discovery_id", "scan_reward_id")
        if target.get(field)
    }
    seen_reward_ids: set[str] = set()
    for index, entity in enumerate(_items(map_data, "entities")):
        present = REWARD_FIELDS & set(entity)
        if not present:
            continue
        label = str(entity.get("id", f"entities[{index}]"))
        missing = [field for field in REQUIRED_REWARD_FIELDS if field not in entity]
        if missing:
            failures.append(f"{label} discovery reward is missing required fields: {', '.join(missing)}.")
        if entity.get("type") != "tool_target" or entity.get("interaction") != "cutter_salvage":
            failures.append(f"{label} discovery reward metadata is supported only on cutter tool_target entities.")
        if entity.get("tier") != "valuable":
            failures.append(f"{label} discovery reward must retain valuable salvage value.")
        if entity.get("reward_kind") != "discovery":
            failures.append(f"{label} reward_kind must be 'discovery'.")

        reward_id = entity.get("reward_id")
        if not _valid_id(reward_id):
            failures.append(f"{label} reward_id must use lower_snake_case.")
        elif reward_id in seen_reward_ids or reward_id in survey_reward_ids:
            failures.append(f"{label} reward_id {reward_id!r} must have exactly one source owner.")
        else:
            seen_reward_ids.add(reward_id)
        for field in ("reward_pending_label", "reward_commit_label", "reward_next_lead_label"):
            if not _valid_label(entity.get(field)):
                failures.append(f"{label} {field} must be non-empty display-safe text up to 96 characters.")

        map_id = str(map_data.get("id", ""))
        commit_map_id = entity.get("reward_commit_map_id")
        if not _valid_id(commit_map_id) or commit_map_id != map_id:
            failures.append(f"{label} reward_commit_map_id must equal the source map id {map_id!r}.")
        expected_path = f"res://maps/{map_id}.greybox.json"
        if entity.get("reward_commit_map_path") != expected_path:
            failures.append(f"{label} reward_commit_map_path must be {expected_path!r}.")
        entry_id = entity.get("reward_commit_entry_id")
        if not _valid_id(entry_id) or entry_id not in boats:
            failures.append(f"{label} reward_commit_entry_id must reference the canonical boat_spawn.")

        for journey in journeys:
            if journey.get("required_discovery_id") != reward_id:
                continue
            route_id = str(journey.get("id", ""))
            if (
                journey.get("tool_target_id") == entity.get("id")
                or entity.get("required_route_id") == route_id
                or entity.get("route_context") == route_id
            ):
                failures.append(f"{label} discovery reward must not depend on the journey it unlocks.")
        forbidden = sorted(RUNTIME_FIELDS & set(entity))
        if forbidden:
            failures.append(f"{label} discovery reward must not author runtime state fields: {forbidden}.")
    return failures
