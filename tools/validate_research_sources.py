#!/usr/bin/env python3
"""Cross-validate practical research targets and researched material pools."""

from __future__ import annotations

import re
from typing import Any


RESEARCH_DISCOVERY_ID = "upper_right_mineral_trace_research"
RESEARCH_POOL_ID = "conductive_coil_pool"
RESEARCH_GATE_ID = "upper_right_current_pocket_gate"
RESEARCH_ROUTE_CONTEXT = "upper_right_current_pocket"
RESEARCH_POOL_FIELDS = {"research_discovery_id", "researched_candidate_ids", "research_lead_label"}
UNSUPPORTED_EFFECT_FIELDS = {"research_effect", "research_effect_type"}
COMPACT_TEXT_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|:.-]{0,63}$")
COORDINATE_PATTERN = re.compile(r"(?:\b[xy]\s*=?\s*\d+\b|\b\d+\s*,\s*\d+\b)", re.IGNORECASE)
RUNTIME_FIELDS = {
    "active",
    "committed",
    "completed",
    "current_day",
    "day_seed",
    "depleted",
    "pending",
    "profile_state",
    "progress",
    "save_path",
    "selected",
}


def _items(map_data: dict[str, Any], collection: str) -> list[dict[str, Any]]:
    value = map_data.get(collection, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _compact_text_failures(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{label} {field} must be a non-empty string."]
    failures: list[str] = []
    if "\n" in value or "\r" in value or not COMPACT_TEXT_PATTERN.match(value):
        failures.append(f"{label} {field} must be compact single-line display-safe text.")
    if COORDINATE_PATTERN.search(value):
        failures.append(f"{label} {field} must not contain coordinates.")
    return failures


def _research_pools(map_data: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        pool
        for pool in _items(map_data, "material_candidate_pools")
        if RESEARCH_POOL_FIELDS & set(pool)
    ]


def validate_research_source_schema(map_data: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    targets = [target for target in _items(map_data, "survey_targets") if target.get("target_type") == "resource"]
    pools = _research_pools(map_data)
    if not targets and not pools:
        return failures

    for collection in ("entities", "zones", "progression_containers", "moving_hazards", "survey_targets"):
        for index, item in enumerate(_items(map_data, collection)):
            misplaced = RESEARCH_POOL_FIELDS & set(item)
            if misplaced:
                failures.append(
                    f"{collection}[{index}] research pool metadata ({', '.join(sorted(misplaced))}) "
                    "is only supported in material_candidate_pools."
                )

    if len(targets) != 1:
        failures.append("Expansion 05 practical research requires exactly one resource survey target.")
    if len(pools) != 1:
        failures.append("Expansion 05 practical research requires exactly one researched material pool.")
    if not targets or not pools:
        return failures

    target = targets[0]
    pool = pools[0]
    target_label = str(target.get("id", "resource_survey"))
    pool_label = str(pool.get("id", "research_pool"))
    unsupported_effects = UNSUPPORTED_EFFECT_FIELDS & (set(target) | set(pool))
    if unsupported_effects:
        failures.append(f"Unsupported research effect fields: {', '.join(sorted(unsupported_effects))}.")
    if target.get("discovery_id") != RESEARCH_DISCOVERY_ID:
        failures.append(f"{target_label} discovery_id must be {RESEARCH_DISCOVERY_ID!r}.")
    if target.get("research_material_pool_id") != pool.get("id"):
        failures.append(f"{target_label} research_material_pool_id must link to {pool_label!r}.")
    if target.get("research_material_pool_id") != RESEARCH_POOL_ID:
        failures.append(f"{target_label} research_material_pool_id must be {RESEARCH_POOL_ID!r}.")
    if target.get("route_context") != RESEARCH_ROUTE_CONTEXT:
        failures.append(f"{target_label} route_context must be {RESEARCH_ROUTE_CONTEXT!r}.")

    gates = {zone.get("id"): zone for zone in _items(map_data, "zones") if zone.get("current_gate") is True}
    gate = gates.get(RESEARCH_GATE_ID)
    if gate is None:
        failures.append(f"{target_label} requires current gate {RESEARCH_GATE_ID!r}.")
    elif isinstance(target.get("x"), int) and isinstance(gate.get("x"), int) and isinstance(gate.get("w"), int):
        if int(target["x"]) < int(gate["x"]) + int(gate["w"]):
            failures.append(f"{target_label} must be placed beyond {RESEARCH_GATE_ID}.")

    missing_pool_fields = RESEARCH_POOL_FIELDS - set(pool)
    if missing_pool_fields:
        failures.append(f"{pool_label} research metadata is missing: {', '.join(sorted(missing_pool_fields))}.")
    if pool.get("id") != RESEARCH_POOL_ID:
        failures.append(f"Researched material pool must be {RESEARCH_POOL_ID!r}.")
    if pool.get("material_id") != "conductive_coil":
        failures.append(f"{pool_label} researched material must be 'conductive_coil'.")
    if pool.get("research_discovery_id") != target.get("discovery_id"):
        failures.append(f"{pool_label} research_discovery_id must link back to {target_label!r}.")

    candidates = pool.get("candidate_ids")
    researched = pool.get("researched_candidate_ids")
    if not isinstance(researched, list) or not researched:
        failures.append(f"{pool_label} researched_candidate_ids must be a non-empty list.")
    elif len(researched) != len(set(researched)):
        failures.append(f"{pool_label} researched_candidate_ids must be unique.")
    elif not isinstance(candidates, list) or not set(researched).issubset(set(candidates)):
        failures.append(f"{pool_label} researched_candidate_ids must be a subset of candidate_ids.")
    else:
        select_count = pool.get("select_count")
        if not isinstance(select_count, int) or isinstance(select_count, bool) or len(researched) < select_count:
            failures.append(f"{pool_label} researched_candidate_ids must contain at least select_count candidates.")
        entities = {entity.get("id"): entity for entity in _items(map_data, "entities")}
        for candidate_id in researched:
            entity = entities.get(candidate_id)
            if entity is None:
                failures.append(f"{pool_label} researched candidate {candidate_id!r} does not exist.")
            elif entity.get("candidate_pool_id") != pool.get("id") or entity.get("material_id") != pool.get("material_id"):
                failures.append(f"{pool_label} researched candidate {candidate_id!r} metadata does not match its pool/material.")

    failures.extend(_compact_text_failures(pool.get("research_lead_label"), pool_label, "research_lead_label"))
    runtime_fields = RUNTIME_FIELDS & (set(target) | set(pool))
    if runtime_fields:
        failures.append(f"Practical research source must not author runtime/profile state: {', '.join(sorted(runtime_fields))}.")
    return failures
