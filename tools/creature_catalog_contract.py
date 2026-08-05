"""Validate the immutable first-proof creature catalog."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "config" / "creature_catalog.json"
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
SPECIES_ID = "spark_ray"
ROLES = {"independent", "mounted"}
CATALOG_IDS = {
    "actions": {"glide_surge", "anchor_brace", "guardian_pulse_action"},
    "memories": {"held_the_flow", "stood_ground"},
    "adaptations": {"anchor_fins", "guardian_pulse"},
}
SPECIES_VALUES = {
    "roles": ["independent", "mounted"],
    "ride_capable": True,
    "base_action_ids": ["glide_surge"],
    "memory_ids": ["held_the_flow", "stood_ground"],
    "adaptation_ids": ["anchor_fins", "guardian_pulse"],
}
ACTION_VALUES = {
    "glide_surge": {"roles": ["mounted"], "effect_kind": "movement", "damaging": False},
    "anchor_brace": {"roles": ["independent", "mounted"], "effect_kind": "current_brace", "damaging": False},
    "guardian_pulse_action": {
        "roles": ["independent", "mounted"],
        "effect_kind": "interrupt_knockback",
        "damaging": False,
    },
}
MEMORY_VALUES = {
    "held_the_flow": {"event_kind": "current_cycle_completed", "adaptation_ids": ["anchor_fins"]},
    "stood_ground": {
        "event_kind": "territorial_threat_cycle_resolved",
        "adaptation_ids": ["guardian_pulse"],
    },
}
ADAPTATION_VALUES = {
    "anchor_fins": {
        "required_memory_id": "held_the_flow",
        "independent_action_id": "anchor_brace",
        "mounted_action_id": "anchor_brace",
        "mutually_exclusive_with": ["guardian_pulse"],
    },
    "guardian_pulse": {
        "required_memory_id": "stood_ground",
        "independent_action_id": "guardian_pulse_action",
        "mounted_action_id": "guardian_pulse_action",
        "mutually_exclusive_with": ["anchor_fins"],
    },
}
STATE_FIELDS = {
    "active",
    "available",
    "bond",
    "committed",
    "completed",
    "cooldown",
    "cooldown_remaining",
    "current_position",
    "earned",
    "mounted",
    "owned",
    "pending",
    "profile_state",
    "progress",
    "rescued",
    "runtime_state",
    "selected",
}


def load_creature_catalog(path: Path = CATALOG_PATH) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return payload


def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _id_failure(value: Any, label: str) -> list[str]:
    if not isinstance(value, str) or not ID_PATTERN.fullmatch(value):
        return [f"{label} must be a lower_snake_case id."]
    return []


def _positive_size(value: Any, label: str) -> list[str]:
    if not isinstance(value, dict):
        return [f"{label} must be an object with positive width and height."]
    failures: list[str] = []
    for field in ("width", "height"):
        number = value.get(field)
        if not isinstance(number, (int, float)) or isinstance(number, bool) or number <= 0:
            failures.append(f"{label}.{field} must be a positive number.")
    return failures


def _id_list(value: Any, label: str) -> tuple[list[str], list[str]]:
    if not isinstance(value, list) or not value:
        return [], [f"{label} must be a non-empty id list."]
    values: list[str] = []
    failures: list[str] = []
    for index, item in enumerate(value):
        failures.extend(_id_failure(item, f"{label}[{index}]"))
        if isinstance(item, str):
            if item in values:
                failures.append(f"{label} contains duplicate id {item!r}.")
            values.append(item)
    return values, failures


def _index(catalog: dict[str, Any], field: str) -> dict[str, dict[str, Any]]:
    return {str(item.get("id", "")): item for item in _items(catalog, field)}


def _forbidden_paths(value: Any, prefix: str = "") -> list[str]:
    paths: list[str] = []
    if isinstance(value, dict):
        for key, nested in value.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            if key in STATE_FIELDS:
                paths.append(path)
            paths.extend(_forbidden_paths(nested, path))
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            paths.extend(_forbidden_paths(nested, f"{prefix}[{index}]"))
    return paths


def _contract_drift(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [f"{label}.{field} must remain {value!r}." for field, value in expected.items() if item.get(field) != value]


def validate_creature_catalog(catalog: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if catalog.get("version") != 1:
        failures.append("creature catalog version must be 1.")
    if catalog.get("implementation_status") != "proposed":
        failures.append("creature catalog implementation_status must remain 'proposed' until runtime support lands.")
    if forbidden := _forbidden_paths(catalog):
        failures.append(f"creature catalog contains mutable state fields: {forbidden}.")
    seen: dict[str, str] = {}
    for field in ("species", "actions", "memories", "adaptations"):
        value = catalog.get(field)
        if not isinstance(value, list):
            failures.append(f"creature catalog {field} must be a list.")
            continue
        for index, item in enumerate(value):
            label = f"creature catalog {field}[{index}]"
            if not isinstance(item, dict):
                failures.append(f"{label} must be an object.")
                continue
            failures.extend(_id_failure(item.get("id"), f"{label}.id"))
            item_id = item.get("id")
            if isinstance(item_id, str):
                if item_id in seen:
                    failures.append(f"Duplicate creature catalog id {item_id!r} in {seen[item_id]} and {field}.")
                seen[item_id] = field
    species = _index(catalog, "species")
    actions = _index(catalog, "actions")
    memories = _index(catalog, "memories")
    adaptations = _index(catalog, "adaptations")
    if set(species) != {SPECIES_ID}:
        failures.append(f"First-proof creature catalog must define only species {SPECIES_ID!r}.")
    for field, expected_ids in CATALOG_IDS.items():
        if set(_index(catalog, field)) != expected_ids:
            failures.append(f"First-proof creature catalog {field} ids must be exactly {sorted(expected_ids)}.")
    for species_id, item in species.items():
        roles, item_failures = _id_list(item.get("roles"), f"species {species_id}.roles")
        failures.extend(item_failures)
        if set(roles) - ROLES:
            failures.append(f"species {species_id} has unsupported roles {sorted(set(roles) - ROLES)}.")
        failures.extend(_positive_size(item.get("rider_footprint_px"), f"species {species_id}.rider_footprint_px"))
        failures.extend(_positive_size(item.get("dismount_clearance_px"), f"species {species_id}.dismount_clearance_px"))
        for field, known in (("base_action_ids", actions), ("memory_ids", memories), ("adaptation_ids", adaptations)):
            ids, item_failures = _id_list(item.get(field), f"species {species_id}.{field}")
            failures.extend(item_failures)
            if unknown := sorted(set(ids) - set(known)):
                failures.append(f"species {species_id}.{field} references unknown ids {unknown}.")
        failures.extend(_contract_drift(item, SPECIES_VALUES, f"species {species_id}"))
    for action_id, item in actions.items():
        roles, item_failures = _id_list(item.get("roles"), f"action {action_id}.roles")
        failures.extend(item_failures)
        if set(roles) - ROLES:
            failures.append(f"action {action_id} has unsupported roles {sorted(set(roles) - ROLES)}.")
        failures.extend(_id_failure(item.get("effect_kind"), f"action {action_id}.effect_kind"))
        if not isinstance(item.get("damaging"), bool):
            failures.append(f"action {action_id}.damaging must be boolean.")
        failures.extend(_contract_drift(item, ACTION_VALUES.get(action_id, {}), f"action {action_id}"))
    for memory_id, item in memories.items():
        failures.extend(_id_failure(item.get("event_kind"), f"memory {memory_id}.event_kind"))
        adaptation_ids, item_failures = _id_list(item.get("adaptation_ids"), f"memory {memory_id}.adaptation_ids")
        failures.extend(item_failures)
        if set(adaptation_ids) - set(adaptations):
            failures.append(f"memory {memory_id} references an unknown adaptation.")
        failures.extend(_contract_drift(item, MEMORY_VALUES.get(memory_id, {}), f"memory {memory_id}"))
    for adaptation_id, item in adaptations.items():
        memory_id = item.get("required_memory_id")
        failures.extend(_id_failure(memory_id, f"adaptation {adaptation_id}.required_memory_id"))
        if memory_id not in memories or adaptation_id not in memories.get(str(memory_id), {}).get("adaptation_ids", []):
            failures.append(f"adaptation {adaptation_id} has an unsupported memory/adaptation relationship.")
        for role in ROLES:
            action_id = item.get(f"{role}_action_id")
            failures.extend(_id_failure(action_id, f"adaptation {adaptation_id}.{role}_action_id"))
            if action_id not in actions or role not in actions.get(str(action_id), {}).get("roles", []):
                failures.append(f"adaptation {adaptation_id} references an invalid {role} action {action_id!r}.")
        exclusions, item_failures = _id_list(
            item.get("mutually_exclusive_with"), f"adaptation {adaptation_id}.mutually_exclusive_with"
        )
        failures.extend(item_failures)
        for other in exclusions:
            if other not in adaptations or adaptation_id not in adaptations.get(other, {}).get("mutually_exclusive_with", []):
                failures.append(f"adaptation exclusion {adaptation_id!r} -> {other!r} must be valid and symmetric.")
        failures.extend(_contract_drift(item, ADAPTATION_VALUES.get(adaptation_id, {}), f"adaptation {adaptation_id}"))
    return failures
