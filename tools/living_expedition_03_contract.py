"""Validate the bounded Living Expedition 03 ecological relationship."""

from __future__ import annotations

from typing import Any


LEGACY_TRACE_ID = "veil_cuttle_trace_01"
TRACE_ID = "southwest_bloom_migration_trace"
OBSERVATION_ID = "southwest_bloom_migration_observation"
MEMORY_RECORD_ID = "veil_cuttle_bloom_memory_01"
MEMORY_ID = "followed_the_bloom"
PAYOFF_ID = "veil_cuttle_drift_lens_payoff_01"
ADAPTATION_ID = "drift_lens"
CONTEXT_ID = "veil_cuttle_drift_review_01"
CONDITION_ID = "southwest_jellyfish_bloom"
MIGRATION_HAZARD_ID = "southwest_bloom_jellyfish_patrol"
PAYOFF_HAZARD_ID = "deep_route_jellyfish_patrol"
SPECIES_ID = "veil_cuttle"
INDIVIDUAL_ID = "veil_cuttle_juvenile_01"
ACTION_ID = "reveal_trace"
PAYOFF_ACTION_ID = "read_drift"
GUARANTEED = "all_supported_seeds"

BASE_MEMORY_RECORDS = {
    "spark_ray_current_memory_01": "held_the_flow",
    "spark_ray_eel_memory_01": "stood_ground",
}
BASE_PAYOFF_RECORDS = {
    "spark_ray_anchor_current_01": "anchor_fins",
    "spark_ray_guardian_eel_01": "guardian_pulse",
}

_CONTRACT_IDS = {TRACE_ID, MEMORY_RECORD_ID, PAYOFF_ID, CONTEXT_ID}
_COPIED_HAZARD_FIELDS = {
    "active",
    "current_position",
    "elapsed",
    "path",
    "phase",
    "position",
    "speed_tiles_per_second",
}


def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _index(payload: dict[str, Any], field: str) -> dict[str, dict[str, Any]]:
    return {str(item.get("id", "")): item for item in _items(payload, field)}


def uses_living_expedition_03(map_data: dict[str, Any]) -> bool:
    rescue = _index(map_data, "creature_rescues").get("veil_cuttle_rescue_01", {})
    if rescue.get("trace_id") == TRACE_ID:
        return True
    for field in (
        "ecological_traces",
        "companion_contexts",
        "creature_memory_opportunities",
        "creature_adaptation_payoffs",
    ):
        if _CONTRACT_IDS & set(_index(map_data, field)):
            return True
    return False


def expected_trace_id(map_data: dict[str, Any]) -> str:
    return TRACE_ID if uses_living_expedition_03(map_data) else LEGACY_TRACE_ID


def expected_memory_records(map_data: dict[str, Any]) -> dict[str, str]:
    records = dict(BASE_MEMORY_RECORDS)
    if uses_living_expedition_03(map_data):
        records[MEMORY_RECORD_ID] = MEMORY_ID
    return records


def expected_payoff_records(map_data: dict[str, Any]) -> dict[str, str]:
    records = dict(BASE_PAYOFF_RECORDS)
    if uses_living_expedition_03(map_data):
        records[PAYOFF_ID] = ADAPTATION_ID
    return records


def _expect_fields(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [
        f"{label}.{field} must be {value!r}."
        for field, value in expected.items()
        if item.get(field) != value
    ]


def validate_living_expedition_03_relationship(map_data: dict[str, Any]) -> list[str]:
    if not uses_living_expedition_03(map_data):
        return []
    traces = _index(map_data, "ecological_traces")
    contexts = _index(map_data, "companion_contexts")
    memories = _index(map_data, "creature_memory_opportunities")
    payoffs = _index(map_data, "creature_adaptation_payoffs")
    conditions = _index(map_data, "daily_conditions")
    hazards = _index(map_data, "moving_hazards")
    trace = traces.get(TRACE_ID, {})
    memory = memories.get(MEMORY_RECORD_ID, {})
    payoff = payoffs.get(PAYOFF_ID, {})
    context = contexts.get(CONTEXT_ID, {})
    failures: list[str] = []
    failures.extend(_expect_fields(trace, {
        "species_id": SPECIES_ID,
        "individual_id": INDIVIDUAL_ID,
        "action_id": ACTION_ID,
        "relationship_kind": "moving_hazard_migration",
        "observation_id": OBSERVATION_ID,
        "daily_condition_id": CONDITION_ID,
        "moving_hazard_id": MIGRATION_HAZARD_ID,
        "memory_opportunity_id": MEMORY_RECORD_ID,
        "adaptation_payoff_id": PAYOFF_ID,
    }, TRACE_ID))
    copied = sorted(_COPIED_HAZARD_FIELDS & set(trace))
    if copied:
        failures.append(f"{TRACE_ID} copies moving-hazard authority fields: {copied}.")
    condition = conditions.get(CONDITION_ID, {})
    migration_hazard = hazards.get(MIGRATION_HAZARD_ID, {})
    if not condition:
        failures.append(f"{TRACE_ID} requires daily condition {CONDITION_ID!r}.")
    if migration_hazard.get("daily_condition_id") != CONDITION_ID:
        failures.append(f"{TRACE_ID} requires its linked condition-owned migration hazard.")
    if migration_hazard.get("kind") != "jellyfish":
        failures.append(f"{MIGRATION_HAZARD_ID} must remain a jellyfish moving hazard.")
    failures.extend(_expect_fields(memory, {
        "memory_id": MEMORY_ID,
        "species_id": SPECIES_ID,
        "individual_id": INDIVIDUAL_ID,
        "event_kind": "ecological_observation_committed",
        "target_id": TRACE_ID,
        "adaptation_ids": [ADAPTATION_ID],
        "payoff_id": PAYOFF_ID,
        "required_access_ids": [],
        "availability": GUARANTEED,
    }, MEMORY_RECORD_ID))
    failures.extend(_expect_fields(payoff, {
        "species_id": SPECIES_ID,
        "adaptation_id": ADAPTATION_ID,
        "target_id": PAYOFF_HAZARD_ID,
        "required_access_ids": [],
        "independent_context_id": CONTEXT_ID,
        "availability": GUARANTEED,
    }, PAYOFF_ID))
    failures.extend(_expect_fields(context, {
        "context_kind": "independent_action_review",
        "species_id": SPECIES_ID,
        "action_id": PAYOFF_ACTION_ID,
        "required_adaptation_id": ADAPTATION_ID,
        "target_id": PAYOFF_HAZARD_ID,
        "availability": GUARANTEED,
    }, CONTEXT_ID))
    payoff_hazard = hazards.get(PAYOFF_HAZARD_ID, {})
    if payoff_hazard.get("kind") != "jellyfish":
        failures.append(f"{PAYOFF_HAZARD_ID} must remain a jellyfish moving hazard.")
    for label, item in ((TRACE_ID, trace), (MEMORY_RECORD_ID, memory), (PAYOFF_ID, payoff)):
        if item.get("required_access_ids", []) != []:
            failures.append(f"{label} cannot grant or require equipment access.")
        if item.get("reward_ids", []) != [] or item.get("progression_effect", "none") != "none":
            failures.append(f"{label} cannot grant score, materials, blueprints, or progression rewards.")
    return failures
