#!/usr/bin/env python3
"""Validate the bounded Expansion 07 biological resource source contract."""

from __future__ import annotations

import math
import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,47}$")
PASSIVE_SOURCE_ID = "upper_right_glow_anemone_sample"
HOSTILE_SOURCE_ID = "deep_cache_eel_electrocyte_harvest"
HOSTILE_ID = "deep_cache_territorial_eel"
PASSIVE_MATERIAL_ID = "insulating_gel"
HOSTILE_MATERIAL_ID = "eel_electrocyte"
CAPACITOR_PROJECT_ID = "shock_prod_capacitor_project"
CAPACITOR_CAPABILITY_ID = "shock_prod_capacitor"
BASE_PROJECT_ID = "shock_prod_project"
BASE_CAPABILITY_ID = "shock_prod"
PASSIVE_ROUTE_CONTEXT = "upper_right_current_pocket"
HOSTILE_ROUTE_CONTEXT = "deep_cache_pressure"
COMMON_FIELDS = {
    "id",
    "source_role",
    "organism_kind",
    "interaction",
    "interaction_seconds",
    "material_id",
    "material_quantity",
    "replenishment",
    "display_label",
    "interaction_label",
    "collected_label",
    "route_context",
    "intent",
}
PASSIVE_FIELDS = COMMON_FIELDS | {"x", "y", "required_capability_id"}
HOSTILE_FIELDS = COMMON_FIELDS | {"hostile_id"}
REQUIRED_PASSIVE_FIELDS = PASSIVE_FIELDS - {"intent"}
REQUIRED_HOSTILE_FIELDS = HOSTILE_FIELDS - {"intent"}
LABEL_FIELDS = {"display_label", "interaction_label", "collected_label"}
FORBIDDEN_FIELDS = {
    "available",
    "cargo",
    "collected",
    "current_health",
    "current_position",
    "defeated",
    "drop_chance",
    "drops",
    "inventory",
    "loot",
    "progress",
    "reward",
    "runtime_state",
    "score",
    "seed",
    "spawn_chance",
    "wallet",
}
ID_COLLECTIONS = (
    "entities",
    "zones",
    "progression_containers",
    "moving_hazards",
    "route_objectives",
    "survey_targets",
    "material_candidate_pools",
    "material_projects",
    "hostile_encounters",
)
EXPECTED_RECIPE = {
    "conductive_coil": 1,
    PASSIVE_MATERIAL_ID: 1,
    HOSTILE_MATERIAL_ID: 1,
}


def _items(map_data: dict[str, Any], collection: str) -> list[dict[str, Any]]:
    value = map_data.get(collection, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_positive_number(value: Any) -> bool:
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(float(value))
        and float(value) > 0.0
    )


def _validate_id(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not ID_PATTERN.match(value):
        return [f"{label} {field} must be nonempty lower_snake_case."]
    return []


def _validate_label(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not DISPLAY_LABEL_PATTERN.match(value):
        return [f"{label} {field} must be short display-safe text."]
    return []


def _reserved_ids(map_data: dict[str, Any]) -> set[str]:
    return {
        str(item["id"])
        for collection in ID_COLLECTIONS
        for item in _items(map_data, collection)
        if isinstance(item.get("id"), str)
    }


def _validate_common(source: dict[str, Any], label: str) -> list[str]:
    failures: list[str] = []
    failures.extend(_validate_id(source.get("id"), label, "id"))
    if not _is_positive_number(source.get("interaction_seconds")):
        failures.append(f"{label} interaction_seconds must be a finite positive number.")
    if source.get("material_quantity") != 1 or not _is_int(source.get("material_quantity")):
        failures.append(f"{label} material_quantity must be exactly 1.")
    if source.get("replenishment") != "new_day":
        failures.append(f"{label} replenishment must be 'new_day'.")
    for field in LABEL_FIELDS:
        failures.extend(_validate_label(source.get(field), label, field))
    forbidden = FORBIDDEN_FIELDS & set(source)
    if forbidden:
        failures.append(f"{label} must not author runtime/drop fields: {', '.join(sorted(forbidden))}.")
    return failures


def _validate_passive(source: dict[str, Any], label: str) -> list[str]:
    failures = _validate_common(source, label)
    missing = REQUIRED_PASSIVE_FIELDS - set(source)
    unknown = set(source) - PASSIVE_FIELDS - FORBIDDEN_FIELDS
    if missing:
        failures.append(f"{label} is missing fields: {', '.join(sorted(missing))}.")
    if unknown:
        failures.append(f"{label} has unsupported fields: {', '.join(sorted(unknown))}.")
    expected = {
        "id": PASSIVE_SOURCE_ID,
        "source_role": "passive_sample",
        "organism_kind": "glow_anemone",
        "required_capability_id": "survey_scanner_1",
        "interaction": "timed_sample",
        "material_id": PASSIVE_MATERIAL_ID,
        "route_context": PASSIVE_ROUTE_CONTEXT,
    }
    for field, value in expected.items():
        if source.get(field) != value:
            failures.append(f"{label} {field} must be {value!r}.")
    for field in ("x", "y"):
        if not _is_int(source.get(field)):
            failures.append(f"{label} {field} must be an integer tile coordinate.")
    return failures


def _validate_hostile(source: dict[str, Any], label: str, hostiles: dict[str, dict[str, Any]]) -> list[str]:
    failures = _validate_common(source, label)
    missing = REQUIRED_HOSTILE_FIELDS - set(source)
    unknown = set(source) - HOSTILE_FIELDS - FORBIDDEN_FIELDS
    if missing:
        failures.append(f"{label} is missing fields: {', '.join(sorted(missing))}.")
    if unknown:
        failures.append(f"{label} has unsupported fields: {', '.join(sorted(unknown))}.")
    expected = {
        "id": HOSTILE_SOURCE_ID,
        "source_role": "hostile_harvest",
        "organism_kind": "territorial_eel",
        "hostile_id": HOSTILE_ID,
        "interaction": "post_defeat_harvest",
        "material_id": HOSTILE_MATERIAL_ID,
        "route_context": HOSTILE_ROUTE_CONTEXT,
    }
    for field, value in expected.items():
        if source.get(field) != value:
            failures.append(f"{label} {field} must be {value!r}.")
    linked = hostiles.get(HOSTILE_ID)
    if linked is None:
        failures.append(f"{label} hostile_id does not reference the supported hostile.")
    elif linked.get("required_weapon_capability_id") != BASE_CAPABILITY_ID:
        failures.append(f"{label} linked hostile must remain defeatable with {BASE_CAPABILITY_ID!r}.")
    return failures


def _validate_project(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    projects = _items(map_data, "material_projects")
    project_ids = [str(project.get("id", "")) for project in projects]
    capacitor = next((project for project in projects if project.get("id") == CAPACITOR_PROJECT_ID), None)
    sources = _items(map_data, "biological_resource_sources")
    if not sources and capacitor is None:
        return failures
    if capacitor is None:
        return [f"Biological resources require {CAPACITOR_PROJECT_ID!r}."]
    expected = {
        "required_project_id": BASE_PROJECT_ID,
        "required_discovery_id": "lower_right_anomaly_discovery",
        "required_materials": EXPECTED_RECIPE,
        "unlocks_capability_id": CAPACITOR_CAPABILITY_ID,
        "target_hostile_id": HOSTILE_ID,
        "capability_effect": "interrupt_warning_lunge",
        "build_phase": "night_debrief",
        "project_label": "Shock-prod capacitor project",
        "completion_label": "Shock-prod capacitor built",
    }
    for field, value in expected.items():
        if capacitor.get(field) != value:
            failures.append(f"{CAPACITOR_PROJECT_ID} {field} must be exactly {value!r}.")
    if BASE_PROJECT_ID not in project_ids:
        failures.append(f"{CAPACITOR_PROJECT_ID} prerequisite {BASE_PROJECT_ID!r} does not exist.")
    elif project_ids.index(BASE_PROJECT_ID) >= project_ids.index(CAPACITOR_PROJECT_ID):
        failures.append(f"{CAPACITOR_PROJECT_ID} must follow {BASE_PROJECT_ID} in source order.")
    source_materials = {str(source.get("material_id", "")) for source in sources}
    if not {PASSIVE_MATERIAL_ID, HOSTILE_MATERIAL_ID}.issubset(source_materials):
        failures.append("Capacitor biological inputs must each have a guaranteed source.")
    return failures


def validate_biological_resource_schema(map_data: dict[str, Any]) -> list[str]:
    raw = map_data.get("biological_resource_sources", [])
    if not isinstance(raw, list):
        return ["biological_resource_sources must be a list when present."]
    failures: list[str] = []
    if raw and len(raw) != 2:
        failures.append(f"Expansion 07 supports exactly two biological sources, found {len(raw)}.")
    hostiles = {str(item.get("id")): item for item in _items(map_data, "hostile_encounters")}
    reserved = _reserved_ids(map_data)
    seen: set[str] = set()
    for index, source in enumerate(raw):
        if not isinstance(source, dict):
            failures.append(f"biological_resource_sources[{index}] must be an object.")
            continue
        label = str(source.get("id", f"biological_resource_sources[{index}]"))
        source_id = source.get("id")
        if isinstance(source_id, str):
            if source_id in seen or source_id in reserved:
                failures.append(f"Duplicate biological source id {source_id!r}.")
            seen.add(source_id)
        role = source.get("source_role")
        if role == "passive_sample":
            failures.extend(_validate_passive(source, label))
        elif role == "hostile_harvest":
            failures.extend(_validate_hostile(source, label, hostiles))
        else:
            failures.append(f"{label} source_role must be 'passive_sample' or 'hostile_harvest'.")
    if raw and seen != {PASSIVE_SOURCE_ID, HOSTILE_SOURCE_ID}:
        failures.append("Biological source ids must match the locked Expansion 07 pair.")
    failures.extend(_validate_project(map_data))
    return failures


def validate_biological_resource_reachability(
    map_data: dict[str, Any], solid: set[tuple[int, int]], reachable: set[tuple[int, int]]
) -> list[str]:
    failures: list[str] = []
    passive = next(
        (item for item in _items(map_data, "biological_resource_sources") if item.get("id") == PASSIVE_SOURCE_ID),
        None,
    )
    if passive is None or not _is_int(passive.get("x")) or not _is_int(passive.get("y")):
        return failures
    point = (int(passive["x"]), int(passive["y"]))
    units = map_data.get("units", {})
    width, height = int(units.get("width_tiles", 0)), int(units.get("height_tiles", 0))
    if point[0] < 0 or point[1] < 0 or point[0] >= width or point[1] >= height:
        failures.append(f"{PASSIVE_SOURCE_ID} point {point} is outside map bounds.")
    elif point in solid:
        failures.append(f"{PASSIVE_SOURCE_ID} point {point} is inside solid terrain.")
    elif point not in reachable:
        failures.append(f"{PASSIVE_SOURCE_ID} point {point} is unreachable.")
    gate = next(
        (zone for zone in _items(map_data, "zones") if zone.get("id") == "upper_right_current_pocket_gate"),
        None,
    )
    if gate is None or not all(_is_int(gate.get(field)) for field in ("x", "w")):
        failures.append(f"{PASSIVE_SOURCE_ID} requires the authored current-pocket gate.")
    elif point[0] < int(gate["x"]) + int(gate["w"]):
        failures.append(f"{PASSIVE_SOURCE_ID} must remain east of the current-pocket gate.")
    occupied = {
        (int(item["x"]), int(item["y"]))
        for collection in ("entities", "hostile_encounters")
        for item in _items(map_data, collection)
        if _is_int(item.get("x")) and _is_int(item.get("y"))
    }
    for survey in _items(map_data, "survey_targets"):
        if all(_is_int(survey.get(field)) for field in ("x", "y", "w", "h")):
            occupied.update(
                (x, y)
                for y in range(int(survey["y"]), int(survey["y"]) + int(survey["h"]))
                for x in range(int(survey["x"]), int(survey["x"]) + int(survey["w"]))
            )
    if point in occupied:
        failures.append(f"{PASSIVE_SOURCE_ID} point {point} overlaps another authored interaction center.")
    return failures
