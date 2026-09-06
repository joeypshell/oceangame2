#!/usr/bin/env python3
"""Validate immutable creature definitions and optional Living Expedition map records."""

from __future__ import annotations

import re
from typing import Any
import living_expedition_07_contract as marl_growth

from creature_catalog_contract import STATE_FIELDS, load_creature_catalog, validate_creature_catalog
from living_expedition_03_contract import (
    expected_memory_records,
    expected_payoff_records,
    expected_trace_id,
    validate_living_expedition_03_relationship,
)
from living_expedition_04_contract import validate_living_expedition_04_relationship
from living_expedition_05_contract import (
    CANDIDATE_ID as SILT_CANDIDATE_ID,
    CONTEXT_KIND as SILT_CONTEXT_KIND,
    INDIVIDUAL_ID as SILT_INDIVIDUAL_ID,
    RESCUE_ID as SILT_RESCUE_ID,
    SPECIES_ID as SILT_SPECIES_ID,
    uses_living_expedition_05,
    validate_living_expedition_05_relationship,
)
from living_expedition_06_contract import (
    uses_living_expedition_06,
    validate_living_expedition_06_reachability,
    validate_living_expedition_06_relationship,
)
from validate_full_level_traversal import CollisionField, PlayerBody, map_point, rect_cells, solid_cells

ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
COLLECTIONS = (
    "creature_rescues",
    "companion_habitats",
    "ecological_traces",
    "companion_contexts",
    "creature_memory_opportunities",
    "creature_adaptation_payoffs",
    "companion_hostile_responses",
    "burrow_refuges",
)
CONTEXT_KINDS = {
    "mounted_route_review", "independent_action_review", "mounted_action_review", SILT_CONTEXT_KIND, "regional_journey_action",
}
GUARANTEED = "all_supported_seeds"
SPECIES_ID = "spark_ray"
INDIVIDUAL_ID = "spark_ray_juvenile_01"
RESCUE_ID = "spark_ray_rescue_01"
RIDING_REVIEW_ID = "spark_ray_riding_review_01"
VEIL_SPECIES_ID = "veil_cuttle"
VEIL_INDIVIDUAL_ID = "veil_cuttle_juvenile_01"
VEIL_RESCUE_ID = "veil_cuttle_rescue_01"
HABITAT_ID = "companion_habitat_01"
VEIL_REVIEW_CAMERA_ID = "veil_cuttle_review_01"
RESCUE_IDENTITIES = {
    RESCUE_ID: (SPECIES_ID, INDIVIDUAL_ID),
    VEIL_RESCUE_ID: (VEIL_SPECIES_ID, VEIL_INDIVIDUAL_ID),
}
SEED_FIELDS = {"day_seed", "seed", "spawn_chance", "spawn_weight"}
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
    fields = (
        "entities",
        "zones",
        "hostile_encounters",
        "survey_targets",
        "regional_journeys",
        "daily_conditions",
        "moving_hazards",
        "ecological_pressures",
        "burrow_refuges",
    )
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
    if not any(field in map_data for field in COLLECTIONS) and not uses_living_expedition_05(map_data) and not uses_living_expedition_06(map_data) and not marl_growth.uses_living_expedition_07(map_data):
        return failures
    records, shape_failures = _validate_collection_shapes(map_data)
    failures.extend(shape_failures)
    species = _catalog_index(catalog, "species")
    individuals = _catalog_index(catalog, "individuals")
    actions = _catalog_index(catalog, "actions")
    memories = _catalog_index(catalog, "memories")
    adaptations = _catalog_index(catalog, "adaptations")
    map_items = _map_index(map_data)
    rescues = _items(map_data, "creature_rescues")
    habitats = _items(map_data, "companion_habitats")
    traces = _items(map_data, "ecological_traces")
    contexts = _items(map_data, "companion_contexts")
    opportunities = _items(map_data, "creature_memory_opportunities")
    payoffs = _items(map_data, "creature_adaptation_payoffs")
    trace_id = expected_trace_id(map_data)
    memory_records = expected_memory_records(map_data)
    payoff_records = expected_payoff_records(map_data)
    memory_records.update(marl_growth.expected_memory_records(map_data))
    payoff_records.update(marl_growth.expected_payoff_records(map_data))
    includes_silt_hound = uses_living_expedition_05(map_data)
    expected_rescues = dict(RESCUE_IDENTITIES)
    if includes_silt_hound:
        expected_rescues[SILT_RESCUE_ID] = (SILT_SPECIES_ID, SILT_INDIVIDUAL_ID)
    if [item.get("id") for item in rescues] != list(expected_rescues):
        failures.append(
            f"Living Expedition requires ordered rescues {list(expected_rescues)!r}."
        )
    if [item.get("id") for item in habitats] != [HABITAT_ID]:
        failures.append(f"Second proof requires exactly one habitat {HABITAT_ID!r}.")
    if [item.get("id") for item in traces] != [trace_id]:
        failures.append(f"Living Expedition requires exactly one current trace {trace_id!r}.")
    if {item.get("id") for item in opportunities} != set(memory_records):
        failures.append(f"Memory records must be exactly {sorted(memory_records)}.")
    if {item.get("id") for item in payoffs} != set(payoff_records):
        failures.append(f"Payoff records must be exactly {sorted(payoff_records)}.")
    for rescue in rescues:
        label = str(rescue.get("id", "creature rescue"))
        required = ("species_id", "individual_id", "x", "y", "rescue_kind", "required_capability_id", "commit_map_id", "commit_entry_id")
        for field in required:
            if field not in rescue:
                failures.append(f"{label} is missing required field {field}.")
        expected_identity = expected_rescues.get(label)
        actual_identity = (rescue.get("species_id"), rescue.get("individual_id"))
        if expected_identity != actual_identity:
            failures.append(f"{label} has unsupported species/individual identity {actual_identity!r}.")
        individual = individuals.get(str(rescue.get("individual_id", "")), {})
        if individual.get("species_id") != rescue.get("species_id"):
            failures.append(f"{label} species/individual relationship does not match the catalog.")
        if rescue.get("rescue_kind") != "physical_aid":
            failures.append(f"{label}.rescue_kind must be 'physical_aid'.")
        if rescue.get("commit_map_id") != map_data.get("id"):
            failures.append(f"{label} must commit on its source map.")
        entry = map_items.get(str(rescue.get("commit_entry_id", "")), {})
        if entry.get("type") != "boat_spawn":
            failures.append(f"{label}.commit_entry_id must reference the canonical boat_spawn.")
        failures.extend(_id_failure(rescue.get("required_capability_id"), f"{label}.required_capability_id"))
        if label == RESCUE_ID:
            riding = records.get(str(rescue.get("riding_review_context_id", "")), {})
            if rescue.get("riding_review_context_id") != RIDING_REVIEW_ID:
                failures.append(f"{label}.riding_review_context_id must be {RIDING_REVIEW_ID!r}.")
            if riding.get("context_kind") != "mounted_route_review":
                failures.append(f"{label}.riding_review_context_id must reference a mounted_route_review.")
        elif label == VEIL_RESCUE_ID:
            if rescue.get("optional") is not True:
                failures.append(f"{label} must remain optional progression.")
            expected_links = {
                "habitat_id": HABITAT_ID,
                "trace_id": trace_id,
                "review_camera_id": VEIL_REVIEW_CAMERA_ID,
            }
            for field, expected in expected_links.items():
                if rescue.get(field) != expected:
                    failures.append(f"{label}.{field} must be {expected!r}.")
            camera_ids = {item.get("id") for item in _items(map_data, "camera_tests")}
            if rescue.get("review_camera_id") not in camera_ids:
                failures.append(f"{label}.review_camera_id does not resolve to camera_tests.")
    for habitat in habitats:
        label = str(habitat.get("id", "companion habitat"))
        if habitat.get("habitat_kind") != "canonical_boat":
            failures.append(f"{label}.habitat_kind must be 'canonical_boat'.")
        entry = map_items.get(str(habitat.get("entry_id", "")), {})
        if entry.get("type") != "boat_spawn":
            failures.append(f"{label}.entry_id must reference the canonical boat_spawn.")
        individual_ids, item_failures = _id_list(
            habitat.get("individual_ids"), f"{label}.individual_ids", allow_empty=False
        )
        failures.extend(item_failures)
        expected_individual_ids = [INDIVIDUAL_ID, VEIL_INDIVIDUAL_ID]
        if includes_silt_hound:
            expected_individual_ids.append(SILT_INDIVIDUAL_ID)
        if individual_ids != expected_individual_ids:
            failures.append(f"{label}.individual_ids must preserve the active catalog proof order.")
        for field in ("x", "y"):
            if not isinstance(habitat.get(field), int):
                failures.append(f"{label}.{field} must be an integer tile coordinate.")
    for trace in traces:
        label = str(trace.get("id", "ecological trace"))
        if trace.get("trace_kind") != "concealed_ecological_trace":
            failures.append(f"{label}.trace_kind must be 'concealed_ecological_trace'.")
        if (trace.get("species_id"), trace.get("individual_id")) != (
            VEIL_SPECIES_ID,
            VEIL_INDIVIDUAL_ID,
        ):
            failures.append(f"{label} must belong to Mica.")
        action = actions.get(str(trace.get("action_id", "")), {})
        if trace.get("action_id") != "reveal_trace" or "independent" not in action.get("roles", []):
            failures.append(f"{label}.action_id must be the Veil Cuttle independent Reveal Trace action.")
        if not isinstance(trace.get("reveal_radius_tiles"), (int, float)) or trace.get("reveal_radius_tiles", 0) <= 0:
            failures.append(f"{label}.reveal_radius_tiles must be positive.")
        if trace.get("scanner_capability_id") != "survey_scanner_1":
            failures.append(f"{label}.scanner_capability_id must remain 'survey_scanner_1'.")
        access_ids, item_failures = _id_list(trace.get("required_access_ids"), f"{label}.required_access_ids")
        failures.extend(item_failures)
        if access_ids:
            failures.append(f"{label} must stay in already accessible terrain.")
        if trace.get("optional") is not True or trace.get("reward_ids") != [] or trace.get("progression_effect") != "none":
            failures.append(f"{label} must remain optional, rewardless, and non-progression.")
    for context in contexts:
        label = str(context.get("id", "companion context"))
        context_species = species.get(str(context.get("species_id", "")), {})
        if not context_species:
            failures.append(f"{label}.species_id must reference a catalog species.")
        kind = context.get("context_kind")
        if kind not in CONTEXT_KINDS:
            failures.append(f"{label}.context_kind must be one of {sorted(CONTEXT_KINDS)}.")
        action_id = context.get("action_id")
        if action_id not in actions:
            failures.append(f"{label}.action_id references unknown action {action_id!r}.")
            continue
        role = "independent" if kind in {"independent_action_review", SILT_CONTEXT_KIND} else "mounted"
        if role not in actions[action_id].get("roles", []):
            failures.append(f"{label} action {action_id!r} does not support role {role!r}.")
        if kind == "mounted_route_review":
            if action_id not in context_species.get("base_action_ids", []):
                failures.append(f"{label} must review a base mounted action.")
            failures.extend(_validate_mounted_route(map_data, context, context_species))
            continue
        if kind == SILT_CONTEXT_KIND:
            if action_id not in context_species.get("base_action_ids", []):
                failures.append(f"{label} must review a base independent action.")
            if str(context.get("target_id", "")) not in map_items:
                failures.append(f"{label}.target_id does not resolve to a map source record.")
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
        if memory_records.get(label) != memory_id or memory_id not in memories:
            failures.append(f"{label}.memory_id is not the contracted memory relationship.")
            continue
        opportunity_species = species.get(str(opportunity.get("species_id", "")), {})
        opportunity_individual = individuals.get(str(opportunity.get("individual_id", "")), {})
        if (
            memory_id not in opportunity_species.get("memory_ids", [])
            or opportunity_individual.get("species_id") != opportunity.get("species_id")
        ):
            failures.append(f"{label} must belong to a catalog individual eligible for {memory_id!r}.")
        if opportunity.get("event_kind") != memories[memory_id].get("event_kind"):
            failures.append(f"{label}.event_kind does not match memory {memory_id!r}.")
        adaptation_ids, item_failures = _id_list(opportunity.get("adaptation_ids"), f"{label}.adaptation_ids", allow_empty=False)
        failures.extend(item_failures)
        if adaptation_ids != memories[memory_id].get("adaptation_ids"):
            failures.append(f"{label} has an unsupported memory/adaptation pair.")
        if opportunity.get("required_adaptation_id") in adaptation_ids:
            failures.append(f"{label} circularly requires the adaptation it awards.")
        target = map_items.get(str(opportunity.get("target_id", "")), records.get(str(opportunity.get("target_id", "")), {}))
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
        if payoff_records.get(label) != adaptation_id or adaptation_id not in adaptations:
            failures.append(f"{label}.adaptation_id is not the contracted payoff relationship.")
            continue
        payoff_species = species.get(str(payoff.get("species_id", "")), {})
        if adaptation_id not in payoff_species.get("adaptation_ids", []):
            failures.append(f"{label}.species_id is not eligible for {adaptation_id!r}.")
        target = map_items.get(str(payoff.get("target_id", "")), {})
        if not target:
            failures.append(f"{label}.target_id does not resolve to a map source record.")
        access_ids, item_failures = _validate_access_ids(payoff.get("required_access_ids", []), f"{label}.required_access_ids")
        failures.extend(item_failures)
        missing = _target_requirements(target) - set(access_ids)
        if missing:
            failures.append(f"{label} would bypass target equipment requirements {sorted(missing)}.")
        expected_contexts = {
            f"{role}_context_id": f"{role}_action_review"
            for role in ("independent", "mounted")
            if f"{role}_action_id" in adaptations[adaptation_id]
        }
        for field, expected_kind in expected_contexts.items():
            context = records.get(str(payoff.get(field, "")), {})
            if context.get("context_kind") != expected_kind or context.get("required_adaptation_id") != adaptation_id:
                failures.append(f"{label}.{field} must reference its {expected_kind} for {adaptation_id!r}.")
            elif context.get("target_id") != payoff.get("target_id"):
                failures.append(f"{label}.{field} and payoff target_id must agree.")
            elif context.get("species_id") != payoff.get("species_id"):
                failures.append(f"{label}.{field} and payoff species_id must agree.")
    failures.extend(validate_living_expedition_03_relationship(map_data))
    failures.extend(validate_living_expedition_04_relationship(map_data, catalog))
    failures.extend(validate_living_expedition_05_relationship(map_data, catalog))
    failures.extend(validate_living_expedition_06_relationship(map_data, catalog))
    failures.extend(marl_growth.validate_living_expedition_07_relationship(map_data, catalog))
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
    if not any(field in map_data for field in COLLECTIONS) and not uses_living_expedition_05(map_data) and not uses_living_expedition_06(map_data) and not marl_growth.uses_living_expedition_07(map_data):
        return []
    failures: list[str] = []
    map_items = _map_index(map_data)
    for rescue in _items(map_data, "creature_rescues"):
        if not (_record_cells(rescue) & reachable):
            failures.append(f"{rescue.get('id')} rescue site is unreachable.")
    for field, label in (
        ("companion_habitats", "habitat"),
        ("ecological_traces", "trace"),
    ):
        for item in _items(map_data, field):
            if not (_record_cells(item) & reachable):
                failures.append(f"{item.get('id')} {label} is unreachable.")
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
    if uses_living_expedition_05(map_data):
        candidate = map_items.get(SILT_CANDIDATE_ID, {})
        boat = map_items.get("surface_boat_entry", {})
        if not candidate or not (_record_cells(candidate) & reachable):
            failures.append("Living Expedition 05 excavation deposit is unreachable.")
        boat_point = (boat.get("entry_x", boat.get("x")), boat.get("entry_y", boat.get("y")))
        if not boat or boat_point not in reachable:
            failures.append("Living Expedition 05 canonical boat return is unreachable.")
    failures.extend(validate_living_expedition_06_reachability(map_data, reachable))
    failures.extend(marl_growth.validate_living_expedition_07_reachability(map_data, reachable))
    return failures
