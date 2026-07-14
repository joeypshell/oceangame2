#!/usr/bin/env python3
"""Validation helpers for source-authored non-salvage survey targets."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
COMPACT_TEXT_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|:.-]{0,63}$")
COORDINATE_PATTERN = re.compile(r"(?:\b[xy]\s*=?\s*\d+\b|\b\d+\s*,\s*\d+\b)", re.IGNORECASE)
SUPPORTED_TARGET_TYPES = {"anomaly", "regional", "resource"}
SUPPORTED_CAPABILITIES = {"survey_scanner_1"}
SUPPORTED_INTERACTIONS = {"survey"}
TARGET_DISCOVERIES = {
    "anomaly": {"lower_right_anomaly_discovery"},
    "regional": {"lower_right_signal_reef_discovery", "signal_reef_deep_harmonic_discovery"},
    "resource": {"upper_right_mineral_trace_research"},
}
LIGHT_GATED_TARGETS = {"signal_reef_deep_harmonic_survey": "dive_light_1"}
FINDING_FIELDS = {"clue_label", "finding_label"}
RESOURCE_FIELDS = {*FINDING_FIELDS, "research_material_pool_id"}
REGIONAL_FIELDS = {*FINDING_FIELDS, "next_lead_label", "required_route_id"}
SURVEY_SPECIFIC_FIELDS = {
    "target_type",
    "required_capability_id",
    "required_light_capability_id",
    "discovery_id",
    "commit_map_id",
    "commit_map_path",
    "commit_entry_id",
    *RESOURCE_FIELDS,
    *REGIONAL_FIELDS,
}
RUNTIME_STATE_FIELDS = {
    "active",
    "capability_owned",
    "cargo",
    "committed",
    "completed",
    "current_map_id",
    "oxygen",
    "payout",
    "pending",
    "price",
    "profile_state",
    "progress",
    "result_text",
    "save_path",
    "score",
    "wallet",
}
REQUIRED_FIELDS = (
    "id",
    "target_type",
    "x",
    "y",
    "w",
    "h",
    "required_capability_id",
    "interaction",
    "interaction_seconds",
    "interaction_label",
    "discovery_id",
    "route_context",
    "commit_map_id",
    "commit_map_path",
    "commit_entry_id",
)


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
    }


def _validate_id(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} {field} {value!r} must use lower_snake_case."]
    return []


def _validate_compact_text(value: Any, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    failures: list[str] = []
    if "\n" in value or "\r" in value or not COMPACT_TEXT_PATTERN.match(value):
        failures.append(f"{item_label} {field} must be compact single-line display-safe text.")
    if COORDINATE_PATTERN.search(value):
        failures.append(f"{item_label} {field} must not contain coordinates.")
    return failures


def _validate_rect(target: dict[str, Any], item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    for field in ("x", "y", "w", "h"):
        if field not in target:
            failures.append(f"{item_label} survey target is missing required field {field}.")
        elif not _is_int(target[field]):
            failures.append(f"{item_label} survey target field {field} must be an integer.")
    if failures:
        return failures
    if int(target["w"]) <= 0 or int(target["h"]) <= 0:
        failures.append(f"{item_label} survey target width and height must be positive.")
    if int(target["x"]) < 0 or int(target["y"]) < 0:
        failures.append(f"{item_label} survey target origin must be inside map bounds.")
    if int(target["x"]) + int(target["w"]) > width or int(target["y"]) + int(target["h"]) > height:
        failures.append(f"{item_label} survey target rectangle extends outside map bounds.")
    return failures


def _repo_root_for_map(map_path: Path) -> Path:
    return map_path.parent.parent if map_path.parent.name == "maps" else Path.cwd()


def _load_commit_map(map_path: Path, resource_path: Any) -> tuple[dict[str, Any] | None, str | None]:
    if not isinstance(resource_path, str) or not resource_path:
        return None, "commit_map_path must be a non-empty string."
    if not resource_path.startswith("res://"):
        return None, f"commit_map_path {resource_path!r} must start with res://."
    relative = Path(resource_path.removeprefix("res://"))
    if ".." in relative.parts:
        return None, f"commit_map_path {resource_path!r} must stay inside the project."
    commit_file = _repo_root_for_map(map_path) / relative
    if commit_file.suffix != ".json" or not commit_file.name.endswith(".greybox.json"):
        return None, f"commit_map_path {resource_path!r} must point to a .greybox.json map."
    if not commit_file.exists():
        return None, f"commit_map_path {resource_path!r} does not exist."
    with commit_file.open("r", encoding="utf-8") as handle:
        loaded = json.load(handle)
    if not isinstance(loaded, dict):
        return None, f"commit_map_path {resource_path!r} did not parse as a map object."
    return loaded, None


def _validate_commit_reference(map_path: Path, target: dict[str, Any], item_label: str) -> list[str]:
    failures: list[str] = []
    failures.extend(_validate_id(target.get("commit_map_id"), item_label, "commit_map_id"))
    failures.extend(_validate_id(target.get("commit_entry_id"), item_label, "commit_entry_id"))
    commit_map, load_error = _load_commit_map(map_path, target.get("commit_map_path"))
    if load_error:
        failures.append(f"{item_label} {load_error}")
        return failures
    if commit_map.get("id") != target.get("commit_map_id"):
        failures.append(
            f"{item_label} commit_map_id {target.get('commit_map_id')!r} does not match "
            f"{target.get('commit_map_path')} id {commit_map.get('id')!r}."
        )
    entries = {
        entity.get("id"): entity.get("type")
        for entity in commit_map.get("entities", [])
        if isinstance(entity, dict) and entity.get("type") in {"spawn", "boat_spawn"}
    }
    entry_id = target.get("commit_entry_id")
    if entry_id not in entries:
        failures.append(f"{item_label} commit_entry_id {entry_id!r} does not reference an entry in the commit map.")
    elif entries[entry_id] != "boat_spawn":
        failures.append(f"{item_label} commit_entry_id {entry_id!r} must reference a boat_spawn.")
    return failures


def validate_survey_target_schema(map_path: Path, map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    targets = map_data.get("survey_targets", [])
    if not isinstance(targets, list):
        return ["survey_targets must be a list when present."]

    for collection_name in (
        "entities",
        "zones",
        "progression_containers",
        "moving_hazards",
        "material_candidate_pools",
        "material_projects",
    ):
        for index, item in enumerate(map_data.get(collection_name, [])):
            if not isinstance(item, dict):
                continue
            fields = SURVEY_SPECIFIC_FIELDS & set(item)
            if collection_name == "zones" and item.get("type") == "marker" and item.get("current_gate") is True:
                fields.discard("required_capability_id")
            if collection_name == "entities" and item.get("type") == "salvage" and isinstance(item.get("guarded_by_hostile_id"), str):
                fields.discard("required_capability_id")
            if item.get("interaction") == "survey":
                fields.add("interaction")
            if fields:
                failures.append(
                    f"{collection_name}[{index}] survey metadata ({', '.join(sorted(fields))}) "
                    "is only supported in survey_targets."
                )

    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))
    reserved_ids = {
        item.get("id")
        for collection_name in ("entities", "zones", "progression_containers", "moving_hazards")
        for item in map_data.get(collection_name, [])
        if isinstance(item, dict) and isinstance(item.get("id"), str)
    }
    seen_target_ids: set[str] = set()
    seen_discovery_ids: set[str] = set()

    for index, target in enumerate(targets):
        if not isinstance(target, dict):
            failures.append(f"survey_targets[{index}] must be an object.")
            continue
        item_label = str(target.get("id", f"survey_targets[{index}]"))
        for field in REQUIRED_FIELDS:
            if field not in target:
                failures.append(f"{item_label} survey target is missing required field {field}.")
        failures.extend(_validate_id(target.get("id"), item_label, "id"))
        target_id = target.get("id")
        if isinstance(target_id, str):
            if target_id in seen_target_ids or target_id in reserved_ids:
                failures.append(f"Duplicate survey target id {target_id!r}.")
            seen_target_ids.add(target_id)
        failures.extend(_validate_rect(target, item_label, width, height))

        target_type = target.get("target_type")
        if target_type not in SUPPORTED_TARGET_TYPES:
            failures.append(f"{item_label} target_type must be one of: {', '.join(sorted(SUPPORTED_TARGET_TYPES))}.")
        if target.get("required_capability_id") not in SUPPORTED_CAPABILITIES:
            failures.append(
                f"{item_label} required_capability_id must be one of: {', '.join(sorted(SUPPORTED_CAPABILITIES))}."
            )
        if target.get("interaction") not in SUPPORTED_INTERACTIONS:
            failures.append(f"{item_label} interaction must be one of: {', '.join(sorted(SUPPORTED_INTERACTIONS))}.")
        if not _is_number(target.get("interaction_seconds")) or float(target["interaction_seconds"]) <= 0.0:
            failures.append(f"{item_label} interaction_seconds must be a positive number.")

        label = target.get("interaction_label")
        if not isinstance(label, str) or not label:
            failures.append(f"{item_label} interaction_label must be a non-empty string.")
        elif "\n" in label or "\r" in label or not (ID_PATTERN.match(label) or DISPLAY_LABEL_PATTERN.match(label)):
            failures.append(f"{item_label} interaction_label must be lower_snake_case or short display-safe text.")

        failures.extend(_validate_id(target.get("discovery_id"), item_label, "discovery_id"))
        discovery_id = target.get("discovery_id")
        if isinstance(discovery_id, str):
            if discovery_id in seen_discovery_ids:
                failures.append(f"Duplicate survey discovery id {discovery_id!r}.")
            seen_discovery_ids.add(discovery_id)
        expected_discoveries = TARGET_DISCOVERIES.get(str(target_type))
        if expected_discoveries is not None and discovery_id not in expected_discoveries:
            allowed = ", ".join(sorted(expected_discoveries))
            failures.append(f"{item_label} {target_type} discovery_id must be one of: {allowed}.")
        expected_light = LIGHT_GATED_TARGETS.get(str(target_id))
        if expected_light is not None and target.get("required_light_capability_id") != expected_light:
            failures.append(f"{item_label} required_light_capability_id must be {expected_light!r}.")
        elif expected_light is None and "required_light_capability_id" in target:
            failures.append(f"{item_label} required_light_capability_id is only supported on a light-gated target.")
        if target_type in {"regional", "resource"}:
            type_fields = REGIONAL_FIELDS if target_type == "regional" else RESOURCE_FIELDS
            for field in sorted(type_fields):
                if field not in target:
                    failures.append(f"{item_label} {target_type} survey target is missing required field {field}.")
            failures.extend(_validate_compact_text(target.get("clue_label"), item_label, "clue_label"))
            failures.extend(_validate_compact_text(target.get("finding_label"), item_label, "finding_label"))
            if target_type == "resource":
                failures.extend(_validate_id(target.get("research_material_pool_id"), item_label, "research_material_pool_id"))
                unexpected_fields = (REGIONAL_FIELDS - FINDING_FIELDS) & set(target)
            else:
                failures.extend(_validate_compact_text(target.get("next_lead_label"), item_label, "next_lead_label"))
                failures.extend(_validate_id(target.get("required_route_id"), item_label, "required_route_id"))
                if target.get("required_route_id") != target.get("route_context"):
                    failures.append(f"{item_label} required_route_id must equal route_context.")
                unexpected_fields = (RESOURCE_FIELDS - FINDING_FIELDS) & set(target)
            if unexpected_fields:
                failures.append(
                    f"{item_label} unsupported {target_type} metadata: {', '.join(sorted(unexpected_fields))}."
                )
        else:
            unexpected_resource_fields = RESOURCE_FIELDS & set(target)
            if unexpected_resource_fields:
                failures.append(
                    f"{item_label} resource metadata ({', '.join(sorted(unexpected_resource_fields))}) "
                    "is only supported on resource survey targets."
                )
            unexpected_regional_fields = (REGIONAL_FIELDS - FINDING_FIELDS) & set(target)
            if unexpected_regional_fields:
                failures.append(
                    f"{item_label} regional metadata ({', '.join(sorted(unexpected_regional_fields))}) "
                    "is only supported on regional survey targets."
                )
        failures.extend(_validate_id(target.get("route_context"), item_label, "route_context"))
        failures.extend(_validate_commit_reference(map_path, target, item_label))

        runtime_fields = RUNTIME_STATE_FIELDS & set(target)
        if runtime_fields:
            failures.append(
                f"{item_label} must not author runtime/profile state fields: {', '.join(sorted(runtime_fields))}."
            )

    return failures


def validate_survey_target_reachability(
    targets: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    if not isinstance(targets, list):
        return failures
    for target in targets:
        if not isinstance(target, dict):
            continue
        item_label = str(target.get("id", "survey_target"))
        if not all(field in target and _is_int(target[field]) for field in ("x", "y", "w", "h")):
            continue
        cells = _rect_cells(target)
        solid_cells = sorted(cells & solid)
        unreachable_cells = sorted(cell for cell in cells if cell not in reachable)
        if solid_cells:
            failures.append(f"{item_label} survey target contains solid cells. Sample: {solid_cells[:4]}")
        if unreachable_cells:
            failures.append(f"{item_label} survey target contains unreachable cells. Sample: {unreachable_cells[:4]}")
    return failures
