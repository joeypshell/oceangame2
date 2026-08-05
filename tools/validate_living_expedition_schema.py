#!/usr/bin/env python3
"""Validate immutable creature definitions and optional Living Expedition map records."""

from __future__ import annotations

import re
from typing import Any

from creature_catalog_contract import STATE_FIELDS, load_creature_catalog, validate_creature_catalog
from validate_full_level_traversal import CollisionField, PlayerBody, map_point, rect_cells, solid_cells

ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
COLLECTIONS = (
    "creature_rescues",
    "companion_contexts",
    "creature_memory_opportunities",
    "creature_adaptation_payoffs",
)
CONTEXT_KINDS = {"mounted_route_review", "independent_action_review", "mounted_action_review"}
GUARANTEED = "all_supported_seeds"
SPECIES_ID = "spark_ray"
INDIVIDUAL_ID = "spark_ray_juvenile_01"
RESCUE_ID = "spark_ray_rescue_01"
RIDING_REVIEW_ID = "spark_ray_riding_review_01"
MEMORY_RECORDS = {
    "spark_ray_current_memory_01": "held_the_flow",
    "spark_ray_eel_memory_01": "stood_ground",
}
PAYOFF_RECORDS = {
    "spark_ray_anchor_current_01": "anchor_fins",
    "spark_ray_guardian_eel_01": "guardian_pulse",
}
SEED_FIELDS = {"daily_condition_id", "day_seed", "seed", "spawn_chance", "spawn_weight"}
ACCESS_FIELDS = (
    "required_capability_id",
    "required_upgrade_id",
    "required_light_capability_id",
    "required_pressure_capability_id",
    "required_rebreather_capability_id",
    "required_weapon_capability_id",
)

def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _id_failure(value: Any, label: str) -> list[str]:
    if not isinstance(value, str) or not ID_PATTERN.fullmatch(value):
        return [f"{label} must be a lower_snake_case id."]
    return []


def _id_list(value: Any, label: str, *, allow_empty: bool = True) -> tuple[list[str], list[str]]:
    if not isinstance(value, list) or (not allow_empty and not value):
        return [], [f"{label} must be {'a non-empty' if not allow_empty else 'an'} id list."]
    values: list[str] = []
    failures: list[str] = []
    for index, item in enumerate(value):
        failures.extend(_id_failure(item, f"{label}[{index}]"))
        if isinstance(item, str):
            if item in values:
                failures.append(f"{label} contains duplicate id {item!r}.")
            values.append(item)
    return values, failures


def _catalog_index(catalog: dict[str, Any], field: str) -> dict[str, dict[str, Any]]:
    return {str(item.get("id", "")): item for item in _items(catalog, field)}


def _forbidden_paths(value: Any, forbidden: set[str], prefix: str = "") -> list[str]:
    paths: list[str] = []
    if isinstance(value, dict):
        for key, nested in value.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            if key in forbidden:
                paths.append(path)
            paths.extend(_forbidden_paths(nested, forbidden, path))
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            paths.extend(_forbidden_paths(nested, forbidden, f"{prefix}[{index}]"))
    return paths


def _validate_collection_shapes(map_data: dict[str, Any]) -> tuple[dict[str, dict[str, Any]], list[str]]:
    records: dict[str, dict[str, Any]] = {}
    failures: list[str] = []
    for field in COLLECTIONS:
        value = map_data.get(field, [])
        if not isinstance(value, list):
            failures.append(f"{field} must be a list when present.")
            continue
        for index, item in enumerate(value):
            label = f"{field}[{index}]"
            if not isinstance(item, dict):
                failures.append(f"{label} must be an object.")
                continue
            failures.extend(_id_failure(item.get("id"), f"{label}.id"))
            item_id = item.get("id")
            if isinstance(item_id, str):
                if item_id in records:
                    failures.append(f"Duplicate creature map id {item_id!r}.")
                records[item_id] = item
            forbidden = _forbidden_paths(item, STATE_FIELDS | SEED_FIELDS)
            if forbidden:
                failures.append(f"{label} contains mutable or seed-dependent fields: {forbidden}.")
            if item.get("availability") != GUARANTEED:
                failures.append(f"{label}.availability must be {GUARANTEED!r}.")
    return records, failures


def _map_index(map_data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    fields = ("entities", "zones", "hostile_encounters", "survey_targets", "regional_journeys")
    return {str(item.get("id", "")): item for field in fields for item in _items(map_data, field)}


def _validate_access_ids(value: Any, label: str) -> tuple[list[str], list[str]]:
    return _id_list(value, label)


def _target_requirements(target: dict[str, Any]) -> set[str]:
    return {
        str(target[field])
        for field in ACCESS_FIELDS
        if isinstance(target.get(field), str) and target.get(field)
    }


def _validate_mounted_route(
    map_data: dict[str, Any], context: dict[str, Any], species: dict[str, Any]
) -> list[str]:
    failures: list[str] = []
    points = context.get("route_points")
    if not isinstance(points, list) or len(points) < 2 or not all(isinstance(point, dict) for point in points):
        return [f"{context.get('id')} route_points must contain at least two point objects."]
    access_ids, access_failures = _validate_access_ids(
        context.get("required_access_ids", []), f"{context.get('id')}.required_access_ids"
    )
    failures.extend(access_failures)
    try:
        units = map_data["units"]
        tile_size = int(units["tile_size_px"])
        dimensions = (int(units["width_tiles"]), int(units["height_tiles"]), tile_size)
        footprint = species["rider_footprint_px"]
        body = PlayerBody(float(footprint["width"]), float(footprint["height"]))
        base_solids = solid_cells(map_data)
        field = CollisionField(*dimensions, base_solids, body)
        route = [map_point(point, tile_size) for point in points]
    except (KeyError, TypeError, ValueError) as exc:
        return [f"{context.get('id')} mounted route is malformed: {exc}"]
    for start, end in zip(route, route[1:]):
        if not field.segment_is_clear(start, end):
            failures.append(f"{context.get('id')} rider footprint clips terrain between {start} and {end}.")
    for gate in _items(map_data, "zones"):
        requirements = _target_requirements(gate)
        if not requirements:
            continue
        blocked = CollisionField(*dimensions, base_solids | rect_cells(gate), body)
        crosses = any(field.segment_is_clear(a, b) and not blocked.segment_is_clear(a, b) for a, b in zip(route, route[1:]))
        missing = requirements - set(access_ids)
        if crosses and missing:
            failures.append(f"{context.get('id')} bypasses equipment gate {gate.get('id')!r}; missing {sorted(missing)}.")
    dismount = context.get("dismount")
    if not isinstance(dismount, dict) or dismount.get("outcome") != "clear":
        failures.append(f"{context.get('id')} requires a reviewed clear dismount outcome.")
    else:
        try:
            clearance = species["dismount_clearance_px"]
            dismount_body = PlayerBody(float(clearance["width"]), float(clearance["height"]))
            dismount_field = CollisionField(*dimensions, base_solids, dismount_body)
            if not dismount_field.center_is_clear(map_point(dismount, tile_size)):
                failures.append(f"{context.get('id')} reviewed dismount point clips terrain.")
        except (KeyError, TypeError, ValueError) as exc:
            failures.append(f"{context.get('id')} dismount point is malformed: {exc}")
    return failures


def validate_living_expedition_schema(
    map_data: dict[str, Any], catalog: dict[str, Any] | None = None
) -> list[str]:
    if catalog is None:
        catalog = load_creature_catalog()
    failures = validate_creature_catalog(catalog)
    if not any(field in map_data for field in COLLECTIONS):
        return failures
    records, shape_failures = _validate_collection_shapes(map_data)
    failures.extend(shape_failures)
    species = _catalog_index(catalog, "species")
    actions = _catalog_index(catalog, "actions")
    memories = _catalog_index(catalog, "memories")
    adaptations = _catalog_index(catalog, "adaptations")
    map_items = _map_index(map_data)
    rescues = _items(map_data, "creature_rescues")
    contexts = _items(map_data, "companion_contexts")
    opportunities = _items(map_data, "creature_memory_opportunities")
    payoffs = _items(map_data, "creature_adaptation_payoffs")
    if [item.get("id") for item in rescues] != [RESCUE_ID]:
        failures.append(f"First proof requires exactly one creature rescue {RESCUE_ID!r}.")
    if {item.get("id") for item in opportunities} != set(MEMORY_RECORDS):
        failures.append(f"First proof memory records must be exactly {sorted(MEMORY_RECORDS)}.")
    if {item.get("id") for item in payoffs} != set(PAYOFF_RECORDS):
        failures.append(f"First proof payoff records must be exactly {sorted(PAYOFF_RECORDS)}.")
    for rescue in rescues:
        label = str(rescue.get("id", "creature rescue"))
        required = ("species_id", "individual_id", "x", "y", "rescue_kind", "required_capability_id", "commit_map_id", "commit_entry_id", "riding_review_context_id")
        for field in required:
            if field not in rescue:
                failures.append(f"{label} is missing required field {field}.")
        if rescue.get("species_id") != SPECIES_ID or rescue.get("individual_id") != INDIVIDUAL_ID:
            failures.append(f"{label} must introduce {INDIVIDUAL_ID!r} as species {SPECIES_ID!r}.")
        if rescue.get("rescue_kind") != "physical_aid":
            failures.append(f"{label}.rescue_kind must be 'physical_aid'.")
        if rescue.get("commit_map_id") != map_data.get("id"):
            failures.append(f"{label} must commit on its source map.")
        entry = map_items.get(str(rescue.get("commit_entry_id", "")), {})
        if entry.get("type") != "boat_spawn":
            failures.append(f"{label}.commit_entry_id must reference the canonical boat_spawn.")
        riding = records.get(str(rescue.get("riding_review_context_id", "")), {})
        if rescue.get("riding_review_context_id") != RIDING_REVIEW_ID:
            failures.append(f"{label}.riding_review_context_id must be {RIDING_REVIEW_ID!r}.")
        if riding.get("context_kind") != "mounted_route_review":
            failures.append(f"{label}.riding_review_context_id must reference a mounted_route_review.")
        failures.extend(_id_failure(rescue.get("required_capability_id"), f"{label}.required_capability_id"))
    for context in contexts:
        label = str(context.get("id", "companion context"))
        if context.get("species_id") != SPECIES_ID or context.get("species_id") not in species:
            failures.append(f"{label}.species_id must reference {SPECIES_ID!r}.")
        kind = context.get("context_kind")
        if kind not in CONTEXT_KINDS:
            failures.append(f"{label}.context_kind must be one of {sorted(CONTEXT_KINDS)}.")
        action_id = context.get("action_id")
        if action_id not in actions:
            failures.append(f"{label}.action_id references unknown action {action_id!r}.")
            continue
        role = "independent" if kind == "independent_action_review" else "mounted"
        if role not in actions[action_id].get("roles", []):
            failures.append(f"{label} action {action_id!r} does not support role {role!r}.")
        if kind == "mounted_route_review":
            if action_id not in species[SPECIES_ID].get("base_action_ids", []):
                failures.append(f"{label} must review a base mounted action.")
            failures.extend(_validate_mounted_route(map_data, context, species[SPECIES_ID]))
            continue
        adaptation_id = context.get("required_adaptation_id")
        if adaptation_id not in adaptations:
            failures.append(f"{label}.required_adaptation_id references an unknown adaptation.")
        elif action_id != adaptations[adaptation_id].get(f"{role}_action_id"):
            failures.append(f"{label} action does not match adaptation {adaptation_id!r} for role {role!r}.")
        if str(context.get("target_id", "")) not in map_items:
            failures.append(f"{label}.target_id does not resolve to a map source record.")
    for opportunity in opportunities:
        label = str(opportunity.get("id", "memory opportunity"))
        memory_id = opportunity.get("memory_id")
        if MEMORY_RECORDS.get(label) != memory_id or memory_id not in memories:
            failures.append(f"{label}.memory_id is not the contracted memory relationship.")
            continue
        if opportunity.get("species_id") != SPECIES_ID or opportunity.get("individual_id") != INDIVIDUAL_ID:
            failures.append(f"{label} must belong to the rescued Spark Ray individual.")
        if opportunity.get("event_kind") != memories[memory_id].get("event_kind"):
            failures.append(f"{label}.event_kind does not match memory {memory_id!r}.")
        adaptation_ids, item_failures = _id_list(opportunity.get("adaptation_ids"), f"{label}.adaptation_ids", allow_empty=False)
        failures.extend(item_failures)
        if adaptation_ids != memories[memory_id].get("adaptation_ids"):
            failures.append(f"{label} has an unsupported memory/adaptation pair.")
        if opportunity.get("required_adaptation_id") in adaptation_ids:
            failures.append(f"{label} circularly requires the adaptation it awards.")
        target = map_items.get(str(opportunity.get("target_id", "")), {})
        if not target:
            failures.append(f"{label}.target_id does not resolve to a map source record.")
        if memory_id == "held_the_flow" and target.get("current_gate") is not True:
            failures.append(f"{label} must target a source-authored current gate.")
        if memory_id == "stood_ground" and target not in _items(map_data, "hostile_encounters"):
            failures.append(f"{label} must target a source-authored hostile encounter.")
        payoff = records.get(str(opportunity.get("payoff_id", "")), {})
        if payoff.get("adaptation_id") not in adaptation_ids:
            failures.append(f"{label}.payoff_id has a malformed adaptation link.")
    for payoff in payoffs:
        label = str(payoff.get("id", "adaptation payoff"))
        adaptation_id = payoff.get("adaptation_id")
        if PAYOFF_RECORDS.get(label) != adaptation_id or adaptation_id not in adaptations:
            failures.append(f"{label}.adaptation_id is not the contracted payoff relationship.")
            continue
        if payoff.get("species_id") != SPECIES_ID:
            failures.append(f"{label}.species_id must reference {SPECIES_ID!r}.")
        target = map_items.get(str(payoff.get("target_id", "")), {})
        if not target:
            failures.append(f"{label}.target_id does not resolve to a map source record.")
        access_ids, item_failures = _validate_access_ids(payoff.get("required_access_ids", []), f"{label}.required_access_ids")
        failures.extend(item_failures)
        missing = _target_requirements(target) - set(access_ids)
        if missing:
            failures.append(f"{label} would bypass target equipment requirements {sorted(missing)}.")
        expected_contexts = {
            "independent_context_id": "independent_action_review",
            "mounted_context_id": "mounted_action_review",
        }
        for field, expected_kind in expected_contexts.items():
            context = records.get(str(payoff.get(field, "")), {})
            if context.get("context_kind") != expected_kind or context.get("required_adaptation_id") != adaptation_id:
                failures.append(f"{label}.{field} must reference its {expected_kind} for {adaptation_id!r}.")
            elif context.get("target_id") != payoff.get("target_id"):
                failures.append(f"{label}.{field} and payoff target_id must agree.")
    return failures


def _record_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    try:
        if isinstance(item.get("territory"), dict):
            return rect_cells(item["territory"])
        return rect_cells(item)
    except (KeyError, TypeError, ValueError):
        return set()


def validate_living_expedition_reachability(
    map_data: dict[str, Any], _solid: set[tuple[int, int]], reachable: set[tuple[int, int]]
) -> list[str]:
    if not any(field in map_data for field in COLLECTIONS):
        return []
    failures: list[str] = []
    map_items = _map_index(map_data)
    for rescue in _items(map_data, "creature_rescues"):
        if not (_record_cells(rescue) & reachable):
            failures.append(f"{rescue.get('id')} rescue site is unreachable.")
    for context in _items(map_data, "companion_contexts"):
        for point in context.get("route_points", []) if isinstance(context.get("route_points"), list) else []:
            if isinstance(point, dict) and not (_record_cells(point) & reachable):
                failures.append(f"{context.get('id')} mounted route point is unreachable.")
        dismount = context.get("dismount")
        if isinstance(dismount, dict) and not (_record_cells(dismount) & reachable):
            failures.append(f"{context.get('id')} dismount point is unreachable.")
    for field in ("creature_memory_opportunities", "creature_adaptation_payoffs"):
        for item in _items(map_data, field):
            target = map_items.get(str(item.get("target_id", "")), {})
            if target and not (_record_cells(target) & reachable):
                failures.append(f"{item.get('id')} target {target.get('id')!r} is unreachable.")
    return failures
