#!/usr/bin/env python3
"""Validation helpers for source-authored destination payoff salvage."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
PAYOFF_FIELDS = {
    "destination_payoff_id",
    "destination_payoff_label",
    "destination_payoff_connector_id",
}


def _repo_root_for_map(map_path: Path) -> Path:
    if map_path.parent.name == "maps":
        return map_path.parent.parent
    return Path.cwd()


def _resource_path_to_file(repo_root: Path, resource_path: str) -> Path | None:
    prefix = "res://"
    if not resource_path.startswith(prefix):
        return None
    relative = resource_path[len(prefix) :]
    if ".." in Path(relative).parts:
        return None
    return repo_root / relative


def _load_json(path: Path) -> dict[str, Any] | None:
    try:
        with path.open("r", encoding="utf-8") as handle:
            loaded = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return None
    return loaded if isinstance(loaded, dict) else None


def _connector_targets_map(
    repo_root: Path,
    destination_map_path: Path,
    destination_map_id: str,
    connector_id: str,
) -> bool:
    maps_dir = repo_root / "maps"
    if not maps_dir.is_dir():
        return False

    destination_path = destination_map_path.resolve()
    for map_file in maps_dir.glob("*.greybox.json"):
        map_data = _load_json(map_file)
        if map_data is None:
            continue
        for zone in map_data.get("zones", []):
            if zone.get("type") != "marker" or zone.get("world_connector") is not True:
                continue
            if zone.get("id") != connector_id:
                continue
            if zone.get("destination_map_id") == destination_map_id:
                return True
            destination_resource = zone.get("destination_map_path")
            if isinstance(destination_resource, str):
                connector_destination = _resource_path_to_file(repo_root, destination_resource)
                if connector_destination is not None and connector_destination.resolve() == destination_path:
                    return True
    return False


def _validate_payoff_record(record: dict[str, Any], item_label: str) -> list[str]:
    failures: list[str] = []
    if record.get("type") != "salvage":
        fields = ", ".join(sorted(PAYOFF_FIELDS & set(record.keys())))
        return [f"{item_label} destination payoff metadata ({fields}) is only supported on salvage entities."]

    payoff_id = record.get("destination_payoff_id")
    if not isinstance(payoff_id, str) or not payoff_id:
        failures.append(f"{item_label} destination_payoff_id must be a non-empty string.")
    elif not ID_PATTERN.match(payoff_id):
        failures.append(f"{item_label} destination_payoff_id {payoff_id!r} must use lower_snake_case.")

    connector_id = record.get("destination_payoff_connector_id")
    if not isinstance(connector_id, str) or not connector_id:
        failures.append(f"{item_label} destination_payoff_connector_id must be a non-empty string.")
    elif not ID_PATTERN.match(connector_id):
        failures.append(
            f"{item_label} destination_payoff_connector_id {connector_id!r} must use lower_snake_case."
        )

    if "destination_payoff_label" in record:
        label = record["destination_payoff_label"]
        if not isinstance(label, str) or not label:
            failures.append(f"{item_label} destination_payoff_label must be a non-empty string.")
        elif "\n" in label or "\r" in label or not (ID_PATTERN.match(label) or DISPLAY_LABEL_PATTERN.match(label)):
            failures.append(
                f"{item_label} destination_payoff_label must be lower_snake_case or short display-safe text."
            )

    if record.get("kind") == "stress_marker":
        failures.append(f"{item_label} destination payoff must be playable salvage, not stress_marker.")

    return failures


def validate_destination_payoff_schema(map_path: Path, map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    payoff_entities: list[dict[str, Any]] = []

    for entity in map_data.get("entities", []):
        if not (PAYOFF_FIELDS & set(entity.keys())):
            continue
        item_label = str(entity.get("id", "entity"))
        failures.extend(_validate_payoff_record(entity, item_label))
        if entity.get("type") == "salvage":
            payoff_entities.append(entity)

    for zone in map_data.get("zones", []):
        fields = PAYOFF_FIELDS & set(zone.keys())
        if fields:
            fields_label = ", ".join(sorted(fields))
            failures.append(
                f"{zone.get('id', 'zone')} destination payoff metadata ({fields_label}) "
                "is only supported on salvage entities."
            )

    if not payoff_entities:
        return failures
    if len(payoff_entities) > 1:
        ids = [str(entity.get("id", "salvage")) for entity in payoff_entities]
        failures.append(f"Only one destination payoff is currently supported. Found: {ids}.")

    repo_root = _repo_root_for_map(map_path)
    destination_map_id = str(map_data.get("id", ""))
    for entity in payoff_entities:
        connector_id = entity.get("destination_payoff_connector_id")
        if not isinstance(connector_id, str) or not connector_id or not ID_PATTERN.match(connector_id):
            continue
        if not _connector_targets_map(repo_root, map_path, destination_map_id, connector_id):
            failures.append(
                f"{entity.get('id', 'salvage')} destination_payoff_connector_id {connector_id!r} "
                f"does not reference a committed connector into {destination_map_id!r}."
            )

    return failures
