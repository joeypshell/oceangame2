#!/usr/bin/env python3
"""Validate source-authored material pools, ordered projects, and capability targets."""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path
from typing import Any

from material_source_contract import (
    DISPLAY_LABEL_PATTERN,
    EXPECTED_RECIPES,
    ID_PATTERN,
    MATERIAL_FIELDS,
    MINIMUM_CANDIDATES,
    PROJECT_FIELDS,
    PROJECT_RULES,
    RUNTIME_FIELDS,
    SUPPORTED_BUILD_PHASES,
    SUPPORTED_CAPABILITIES,
    SUPPORTED_MATERIALS,
    SUPPORTED_PROJECTS,
    SUPPORTED_STRATEGIES,
    TOOL_FIELDS,
)
from validate_research_sources import validate_research_source_schema


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _validate_id(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{label} {field} must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{label} {field} {value!r} must use lower_snake_case."]
    return []


def _items(map_data: dict[str, Any], collection: str) -> list[dict[str, Any]]:
    value = map_data.get(collection, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _reserved_ids(map_data: dict[str, Any]) -> set[str]:
    return {
        item["id"]
        for collection in (
            "entities", "zones", "progression_containers", "moving_hazards", "hostile_encounters",
            "survey_targets", "biological_resource_sources",
        )
        for item in _items(map_data, collection)
        if isinstance(item.get("id"), str)
    }


def _validate_entity_metadata(
    entities: list[dict[str, Any]],
) -> tuple[list[str], dict[str, dict[str, Any]], dict[str, dict[str, Any]]]:
    failures: list[str] = []
    material_entities: dict[str, dict[str, Any]] = {}
    tool_entities: dict[str, dict[str, Any]] = {}
    for index, entity in enumerate(entities):
        label = str(entity.get("id", f"entities[{index}]"))
        material_fields = MATERIAL_FIELDS & set(entity)
        tool_fields = TOOL_FIELDS & set(entity)
        is_cutter_target = entity.get("interaction") == "cutter_salvage" or bool(tool_fields)
        if material_fields:
            if entity.get("type") != "material_candidate":
                failures.append(f"{label} material metadata is only supported on material_candidate entities.")
                continue
            for field in MATERIAL_FIELDS:
                if field not in entity:
                    failures.append(f"{label} material candidate is missing required field {field}.")
            failures.extend(_validate_id(entity.get("material_id"), label, "material_id"))
            if entity.get("material_id") not in SUPPORTED_MATERIALS:
                failures.append(f"{label} material_id must be one of: {', '.join(sorted(SUPPORTED_MATERIALS))}.")
            if entity.get("material_quantity") != 1 or not _is_int(entity.get("material_quantity")):
                failures.append(f"{label} material_quantity must be exactly 1.")
            failures.extend(_validate_id(entity.get("candidate_pool_id"), label, "candidate_pool_id"))
            if entity.get("interaction") != "material_collect":
                failures.append(f"{label} material candidate interaction must be 'material_collect'.")
            if isinstance(entity.get("id"), str):
                material_entities[entity["id"]] = entity
        if is_cutter_target:
            if entity.get("type") != "tool_target":
                failures.append(f"{label} cutter metadata is only supported on tool_target entities.")
                continue
            if entity.get("interaction") != "cutter_salvage":
                failures.append(f"{label} required tool metadata requires interaction 'cutter_salvage'.")
            for field in TOOL_FIELDS:
                if field not in entity:
                    failures.append(f"{label} cutter target is missing required field {field}.")
            if entity.get("required_tool_id") != "salvage_cutter":
                failures.append(f"{label} required_tool_id must be salvage_cutter.")
            if entity.get("tool_project_id") not in SUPPORTED_PROJECTS:
                failures.append(f"{label} tool_project_id must be one of: {', '.join(sorted(SUPPORTED_PROJECTS))}.")
            if entity.get("tier") != "valuable":
                failures.append(f"{label} cutter target must use tier 'valuable' for a valid payoff.")
            if not _is_number(entity.get("interaction_seconds")) or float(entity["interaction_seconds"]) <= 0.0:
                failures.append(f"{label} cutter target interaction_seconds must be a positive number.")
            if material_fields:
                failures.append(f"{label} cutter target must not also be a material candidate.")
            if isinstance(entity.get("id"), str):
                tool_entities[entity["id"]] = entity
        runtime_fields = RUNTIME_FIELDS & set(entity)
        if (material_fields or is_cutter_target) and runtime_fields:
            failures.append(f"{label} must not author runtime/profile state fields: {', '.join(sorted(runtime_fields))}.")
    return failures, material_entities, tool_entities


def _validate_pools(
    map_data: dict[str, Any],
    material_entities: dict[str, dict[str, Any]],
) -> tuple[list[str], dict[str, dict[str, Any]], dict[str, int]]:
    failures: list[str] = []
    raw_pools = map_data.get("material_candidate_pools", [])
    if not isinstance(raw_pools, list):
        return ["material_candidate_pools must be a list when present."], {}, {}
    pools: dict[str, dict[str, Any]] = {}
    selected_yields = {material_id: 0 for material_id in SUPPORTED_MATERIALS}
    referenced_candidates: set[str] = set()
    reserved = _reserved_ids(map_data)
    for index, pool in enumerate(raw_pools):
        if not isinstance(pool, dict):
            failures.append(f"material_candidate_pools[{index}] must be an object.")
            continue
        label = str(pool.get("id", f"material_candidate_pools[{index}]"))
        for field in ("id", "material_id", "selection_strategy", "select_count", "candidate_ids"):
            if field not in pool:
                failures.append(f"{label} material pool is missing required field {field}.")
        failures.extend(_validate_id(pool.get("id"), label, "id"))
        pool_id = pool.get("id")
        if isinstance(pool_id, str):
            if pool_id in pools or pool_id in reserved:
                failures.append(f"Duplicate material pool id {pool_id!r}.")
            pools[pool_id] = pool
        material_id = pool.get("material_id")
        if material_id not in SUPPORTED_MATERIALS:
            failures.append(f"{label} material_id must be one of: {', '.join(sorted(SUPPORTED_MATERIALS))}.")
        if pool.get("selection_strategy") not in SUPPORTED_STRATEGIES:
            failures.append(f"{label} selection_strategy must be one of: {', '.join(sorted(SUPPORTED_STRATEGIES))}.")
        select_count = pool.get("select_count")
        if not _is_int(select_count) or int(select_count) <= 0:
            failures.append(f"{label} select_count must be a positive integer.")
        candidate_ids = pool.get("candidate_ids")
        if not isinstance(candidate_ids, list) or not candidate_ids:
            failures.append(f"{label} candidate_ids must be a non-empty list.")
            continue
        seen_in_pool: set[str] = set()
        for candidate_id in candidate_ids:
            failures.extend(_validate_id(candidate_id, label, "candidate id"))
            if not isinstance(candidate_id, str):
                continue
            if candidate_id in seen_in_pool or candidate_id in referenced_candidates:
                failures.append(f"Duplicate material candidate id {candidate_id!r} in candidate pools.")
            seen_in_pool.add(candidate_id)
            referenced_candidates.add(candidate_id)
            entity = material_entities.get(candidate_id)
            if entity is None:
                failures.append(f"{label} candidate id {candidate_id!r} does not reference a material_candidate entity.")
            elif entity.get("candidate_pool_id") != pool_id or entity.get("material_id") != material_id:
                failures.append(f"{label} candidate {candidate_id!r} metadata does not match its pool/material.")
        guaranteed_ids = pool.get("guaranteed_candidate_ids", [])
        if not isinstance(guaranteed_ids, list):
            failures.append(f"{label} guaranteed_candidate_ids must be a list when present.")
        else:
            seen_guaranteed: set[str] = set()
            has_duplicate = False
            for candidate_id in guaranteed_ids:
                failures.extend(_validate_id(candidate_id, label, "guaranteed candidate id"))
                if not isinstance(candidate_id, str):
                    continue
                if candidate_id in seen_guaranteed:
                    has_duplicate = True
                seen_guaranteed.add(candidate_id)
                if candidate_id not in candidate_ids:
                    failures.append(f"{label} guaranteed candidate {candidate_id!r} must belong to candidate_ids.")
            if has_duplicate:
                failures.append(f"{label} guaranteed_candidate_ids must not contain duplicates.")
            if _is_int(select_count) and len(guaranteed_ids) > int(select_count):
                failures.append(f"{label} guaranteed candidate count must not exceed select_count.")
        if _is_int(select_count) and int(select_count) > len(candidate_ids):
            failures.append(f"{label} select_count exceeds its candidate count.")
        is_optional_bonus = pool.get("pool_role") == "optional_bonus"
        minimum = 0 if is_optional_bonus else MINIMUM_CANDIDATES.get(str(material_id), 0)
        if minimum and len(candidate_ids) < minimum:
            failures.append(f"{label} requires at least {minimum} authored candidates for {material_id}.")
        if not is_optional_bonus and material_id in selected_yields and _is_int(select_count) and int(select_count) > 0:
            selected_yields[str(material_id)] += int(select_count)
        runtime_fields = RUNTIME_FIELDS & set(pool)
        if runtime_fields:
            failures.append(f"{label} must not author runtime/profile state fields: {', '.join(sorted(runtime_fields))}.")
    for candidate_id in sorted(set(material_entities) - referenced_candidates):
        failures.append(f"Material candidate {candidate_id!r} is not referenced by a candidate pool.")
    return failures, pools, selected_yields


def _validate_projects(
    map_data: dict[str, Any],
    pools: dict[str, dict[str, Any]],
    selected_yields: dict[str, int],
    tool_entities: dict[str, dict[str, Any]],
) -> list[str]:
    failures: list[str] = []
    raw_projects = map_data.get("material_projects", [])
    if not isinstance(raw_projects, list):
        return ["material_projects must be a list when present."]
    if (pools or tool_entities) and not raw_projects:
        failures.append("Material source requires at least one material project.")
    seen_ids: set[str] = set()
    reserved = _reserved_ids(map_data) | set(pools)
    referenced_targets: set[str] = set()
    referenced_gates: set[str] = set()
    referenced_hostiles: set[str] = set()
    projects: dict[str, dict[str, Any]] = {}
    project_order: list[str] = []
    guaranteed_yields = selected_yields.copy()
    for source in _items(map_data, "biological_resource_sources"):
        material_id = source.get("material_id")
        quantity = source.get("material_quantity")
        if material_id in SUPPORTED_MATERIALS and _is_int(quantity) and int(quantity) > 0:
            guaranteed_yields[str(material_id)] = guaranteed_yields.get(str(material_id), 0) + int(quantity)
    current_gates = {
        str(zone.get("id")): zone
        for zone in _items(map_data, "zones")
        if zone.get("current_gate") is True and isinstance(zone.get("id"), str)
    }
    hostile_encounters = {
        str(hostile.get("id")): hostile
        for hostile in _items(map_data, "hostile_encounters")
        if isinstance(hostile.get("id"), str)
    }
    survey_targets = {
        str(target.get("id")): target
        for target in _items(map_data, "survey_targets")
        if isinstance(target.get("id"), str)
    }
    for index, project in enumerate(raw_projects):
        if not isinstance(project, dict):
            failures.append(f"material_projects[{index}] must be an object.")
            continue
        label = str(project.get("id", f"material_projects[{index}]"))
        for field in ("id", "required_materials", "unlocks_capability_id", "build_phase"):
            if field not in project:
                failures.append(f"{label} material project is missing required field {field}.")
        failures.extend(_validate_id(project.get("id"), label, "id"))
        project_id = project.get("id")
        if isinstance(project_id, str):
            if project_id in seen_ids or project_id in reserved:
                failures.append(f"Duplicate material project id {project_id!r}.")
            seen_ids.add(project_id)
            projects[project_id] = project
            project_order.append(project_id)

    for index, project in enumerate(raw_projects):
        if not isinstance(project, dict):
            continue
        label = str(project.get("id", f"material_projects[{index}]"))
        project_id = project.get("id")
        unknown_fields = set(project) - PROJECT_FIELDS - RUNTIME_FIELDS
        if unknown_fields:
            failures.append(f"{label} has unsupported project fields: {', '.join(sorted(unknown_fields))}.")
        if project_id not in SUPPORTED_PROJECTS:
            failures.append(f"{label} id must be one of: {', '.join(sorted(SUPPORTED_PROJECTS))}.")
        if project.get("unlocks_capability_id") not in SUPPORTED_CAPABILITIES:
            failures.append(
                f"{label} unlocks_capability_id must be one of: {', '.join(sorted(SUPPORTED_CAPABILITIES))}."
            )
        if project.get("build_phase") not in SUPPORTED_BUILD_PHASES:
            failures.append(f"{label} build_phase must be one of: {', '.join(sorted(SUPPORTED_BUILD_PHASES))}.")
        for label_field in ("project_label", "completion_label"):
            if project_id in {"propulsion_fins_project", "survey_scanner_project", "shock_prod_project", "shock_prod_capacitor_project", "dive_light_1_project"} and label_field not in project:
                failures.append(f"{label} requires {label_field}.")
            elif label_field in project:
                value = project[label_field]
                if not isinstance(value, str) or not DISPLAY_LABEL_PATTERN.match(value):
                    failures.append(f"{label} {label_field} must be short display-safe text.")

        rules = PROJECT_RULES.get(str(project_id))
        if rules is not None:
            expected_discovery = rules.get("required_discovery_id")
            legacy_discovery = rules.get("legacy_required_discovery_id")
            if legacy_discovery is not None and not any(
                target.get("scan_reward_id") == expected_discovery for target in survey_targets.values()
            ):
                expected_discovery = legacy_discovery
            authored_discovery = project.get("required_discovery_id")
            if expected_discovery is None:
                if "required_discovery_id" in project:
                    failures.append(f"{label} must omit required_discovery_id for a known recipe.")
            elif authored_discovery != expected_discovery:
                failures.append(f"{label} required_discovery_id must be {expected_discovery!r}.")
            if project.get("unlocks_capability_id") != rules["capability_id"]:
                failures.append(f"{label} must unlock capability {rules['capability_id']}.")
            expected_prerequisite = rules["required_project_id"]
            authored_prerequisite = project.get("required_project_id")
            if authored_prerequisite != expected_prerequisite:
                failures.append(f"{label} required_project_id must be {expected_prerequisite!r}.")
            if isinstance(authored_prerequisite, str):
                failures.extend(_validate_id(authored_prerequisite, label, "required_project_id"))
                prerequisite_index = project_order.index(authored_prerequisite) if authored_prerequisite in project_order else -1
                if prerequisite_index < 0:
                    failures.append(f"{label} required_project_id {authored_prerequisite!r} does not exist.")
                elif prerequisite_index >= index:
                    failures.append(f"{label} required_project_id must reference an earlier project.")
            expected_effect = rules.get("capability_effect")
            if project.get("capability_effect") != expected_effect:
                failures.append(f"{label} capability_effect must be {expected_effect!r}.")

        recipe = project.get("required_materials")
        expected_recipe = EXPECTED_RECIPES.get(str(project_id))
        if recipe != expected_recipe:
            failures.append(f"{label} required_materials must be exactly {expected_recipe}.")
        else:
            for material_id, required in recipe.items():
                if guaranteed_yields.get(material_id, 0) < required:
                    failures.append(
                        f"{label} requires {required} {material_id}, but daily sources guarantee "
                        f"only {guaranteed_yields.get(material_id, 0)}."
                    )
        target_fields = [field for field in ("target_id", "target_gate_id", "target_hostile_id") if field in project]
        if len(target_fields) != 1:
            failures.append(f"{label} must define exactly one supported project target field.")
        else:
            target_field = target_fields[0]
            target_id = project[target_field]
            failures.extend(_validate_id(target_id, label, target_field))
            if rules is not None and target_field != rules["target_field"]:
                failures.append(f"{label} must use {rules['target_field']}.")
            if target_field == "target_id" and isinstance(target_id, str):
                referenced_targets.add(target_id)
                if rules is not None and rules.get("target_collection") == "survey_targets":
                    target = survey_targets.get(target_id)
                    capability_field = str(rules.get("target_capability_field", "required_capability_id"))
                    if target is None:
                        failures.append(f"{label} target_id {target_id!r} does not reference a survey target.")
                    elif target.get(capability_field) != project.get("unlocks_capability_id"):
                        failures.append(f"{label} target survey does not link back to the project capability.")
                else:
                    target = tool_entities.get(target_id)
                    if target is None:
                        failures.append(f"{label} target_id {target_id!r} does not reference a cutter salvage target.")
                    elif target.get("tool_project_id") != project_id or target.get("required_tool_id") != project.get("unlocks_capability_id"):
                        failures.append(f"{label} target {target_id!r} does not link back to the project/tool.")
            elif target_field == "target_gate_id" and isinstance(target_id, str):
                referenced_gates.add(target_id)
                gate = current_gates.get(target_id)
                if gate is None:
                    failures.append(f"{label} target_gate_id {target_id!r} does not reference a current gate.")
                elif gate.get("required_capability_id") != project.get("unlocks_capability_id"):
                    failures.append(f"{label} target gate does not link back to the project capability.")
            elif target_field == "target_hostile_id" and isinstance(target_id, str):
                referenced_hostiles.add(target_id)
                hostile = hostile_encounters.get(target_id)
                expected_hostile_capability = (
                    rules.get("hostile_required_capability_id", project.get("unlocks_capability_id"))
                    if rules is not None
                    else project.get("unlocks_capability_id")
                )
                if hostile is None:
                    failures.append(f"{label} target_hostile_id {target_id!r} does not reference a hostile encounter.")
                elif hostile.get("required_weapon_capability_id") != expected_hostile_capability:
                    failures.append(f"{label} target hostile does not link back to the project capability.")
        runtime_fields = RUNTIME_FIELDS & set(project)
        if runtime_fields:
            failures.append(f"{label} must not author runtime/profile state fields: {', '.join(sorted(runtime_fields))}.")
    for journey in _items(map_data, "regional_journeys"):
        promise_id = str(journey.get("promise_gate_id", ""))
        capability_id = str(journey.get("required_capability_id", ""))
        promise = current_gates.get(promise_id)
        if promise_id not in referenced_gates or promise is None or promise.get("required_capability_id") != capability_id:
            continue
        for gate_id in journey.get("entry_gate_ids", []):
            gate = current_gates.get(str(gate_id))
            if gate is not None and gate.get("required_capability_id") == capability_id:
                referenced_gates.add(str(gate_id))
    for target_id, target in tool_entities.items():
        project = projects.get(str(target.get("tool_project_id", "")))
        if (
            target.get("durable_clearance") is True
            and isinstance(target.get("unlocks_survey_target_id"), str)
            and project is not None
            and target.get("required_tool_id") == project.get("unlocks_capability_id")
        ):
            referenced_targets.add(target_id)
    for target_id in sorted(set(tool_entities) - referenced_targets):
        failures.append(f"Cutter target {target_id!r} is not referenced by a material project.")
    durable_gates = {
        gate_id for gate_id, gate in current_gates.items() if isinstance(gate.get("required_capability_id"), str)
    }
    for gate_id in sorted(durable_gates - referenced_gates):
        failures.append(f"Durable current gate {gate_id!r} is not referenced by a material project.")
    for hostile_id in sorted(set(hostile_encounters) - referenced_hostiles):
        failures.append(f"Hostile encounter {hostile_id!r} is not referenced by a material project.")
    return failures


def validate_material_source_schema(map_data: dict[str, Any]) -> list[str]:
    entities = _items(map_data, "entities")
    failures, material_entities, tool_entities = _validate_entity_metadata(entities)
    pool_failures, pools, selected_yields = _validate_pools(map_data, material_entities)
    failures.extend(pool_failures)
    failures.extend(_validate_projects(map_data, pools, selected_yields, tool_entities))
    failures.extend(validate_research_source_schema(map_data))
    return failures


def validate_material_source_reachability(
    entities: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    for entity in entities:
        if not isinstance(entity, dict):
            continue
        if not (MATERIAL_FIELDS & set(entity) or entity.get("interaction") == "cutter_salvage"):
            continue
        if not all(field in entity and _is_int(entity[field]) for field in ("x", "y")):
            continue
        point = (int(entity["x"]), int(entity["y"]))
        label = str(entity.get("id", "material_source"))
        if point in solid:
            failures.append(f"{label} material/tool source is inside solid terrain at {point}.")
        elif point not in reachable:
            failures.append(f"{label} material/tool source is unreachable at {point}.")
    return failures


def _rect_cells(item: dict[str, Any]) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
    }


def _reachable_cells(map_data: dict[str, Any]) -> tuple[set[tuple[int, int]], set[tuple[int, int]]]:
    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))
    solid: set[tuple[int, int]] = set()
    for terrain in _items(map_data, "terrain"):
        if terrain.get("type") == "solid" and all(field in terrain for field in ("x", "y", "w", "h")):
            solid.update(_rect_cells(terrain))
    spawn = next((entity for entity in _items(map_data, "entities") if entity.get("type") in {"spawn", "boat_spawn"}), None)
    if spawn is None:
        return solid, set()
    start = (
        int(spawn.get("entry_x", spawn.get("x", -1))),
        int(spawn.get("entry_y", spawn.get("y", -1))),
    )
    if start in solid or start[0] < 0 or start[1] < 0 or start[0] >= width or start[1] >= height:
        return solid, set()
    reachable = {start}
    queue: deque[tuple[int, int]] = deque([start])
    while queue:
        x, y = queue.popleft()
        for cell in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if cell[0] < 0 or cell[1] < 0 or cell[0] >= width or cell[1] >= height:
                continue
            if cell in solid or cell in reachable:
                continue
            reachable.add(cell)
            queue.append(cell)
    return solid, reachable


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path)
    args = parser.parse_args()
    with args.map_json.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)
    failures = validate_material_source_schema(map_data)
    solid, reachable = _reachable_cells(map_data)
    failures.extend(validate_material_source_reachability(_items(map_data, "entities"), solid, reachable))
    if failures:
        for failure in failures:
            print(failure)
        return 1
    print(f"{map_data.get('id', args.map_json.stem)} passed material source validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
