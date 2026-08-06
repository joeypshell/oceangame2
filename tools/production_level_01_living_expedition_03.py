#!/usr/bin/env python3
"""Source-owned Mica migration relationship for Living Expedition 03."""

from __future__ import annotations

from typing import Any, Callable


SPECIES_ID = "veil_cuttle"
INDIVIDUAL_ID = "veil_cuttle_juvenile_01"
RESCUE_ID = "veil_cuttle_rescue_01"
LEGACY_TRACE_ID = "veil_cuttle_trace_01"
TRACE_ID = "southwest_bloom_migration_trace"
OBSERVATION_ID = "southwest_bloom_migration_observation"
MEMORY_RECORD_ID = "veil_cuttle_bloom_memory_01"
MEMORY_ID = "followed_the_bloom"
PAYOFF_ID = "veil_cuttle_drift_lens_payoff_01"
ADAPTATION_ID = "drift_lens"
CONTEXT_ID = "veil_cuttle_drift_review_01"
REVIEW_CAMERA_ID = "living_expedition_03_bloom_review_01"
CONDITION_ID = "southwest_jellyfish_bloom"
MIGRATION_HAZARD_ID = "southwest_bloom_jellyfish_patrol"
PAYOFF_HAZARD_ID = "deep_route_jellyfish_patrol"
AVAILABILITY = "all_supported_seeds"


def _by_id(map_data: dict[str, Any], collection: str, record_id: str) -> dict[str, Any]:
    matches = [
        item for item in map_data.get(collection, [])
        if isinstance(item, dict) and item.get("id") == record_id
    ]
    if len(matches) != 1:
        raise ValueError(f"Expected one {collection} record {record_id!r}; found {len(matches)}.")
    return matches[0]


def _migration_anchor(hazard: dict[str, Any]) -> tuple[int, int]:
    path = hazard.get("path")
    if not isinstance(path, list) or len(path) < 2:
        raise ValueError(f"{MIGRATION_HAZARD_ID} requires an authored patrol path.")
    first, last = path[0], path[-1]
    if not isinstance(first, dict) or not isinstance(last, dict):
        raise ValueError(f"{MIGRATION_HAZARD_ID} patrol endpoints must be objects.")
    try:
        return (
            int(round((float(first["x"]) + float(last["x"])) / 2.0)),
            int(round((float(first["y"]) + float(last["y"])) / 2.0)),
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError(f"{MIGRATION_HAZARD_ID} patrol endpoints are malformed: {exc}") from exc


def ecological_trace(hazard: dict[str, Any]) -> dict[str, Any]:
    x, y = _migration_anchor(hazard)
    return {
        "id": TRACE_ID,
        "trace_kind": "concealed_ecological_trace",
        "species_id": SPECIES_ID,
        "individual_id": INDIVIDUAL_ID,
        "x": x,
        "y": y,
        "action_id": "reveal_trace",
        "reveal_radius_tiles": 6,
        "scanner_capability_id": "survey_scanner_1",
        "required_access_ids": [],
        "optional": True,
        "reward_ids": [],
        "progression_effect": "none",
        "relationship_kind": "moving_hazard_migration",
        "observation_id": OBSERVATION_ID,
        "daily_condition_id": CONDITION_ID,
        "moving_hazard_id": MIGRATION_HAZARD_ID,
        "memory_opportunity_id": MEMORY_RECORD_ID,
        "adaptation_payoff_id": PAYOFF_ID,
        "availability": AVAILABILITY,
        "intent": (
            "Mica reveals a migration filament derived from the linked active "
            "jellyfish patrol; the Scanner identifies the relationship."
        ),
    }


def companion_contexts() -> list[dict]:
    return [{
        "id": CONTEXT_ID,
        "context_kind": "independent_action_review",
        "species_id": SPECIES_ID,
        "action_id": "read_drift",
        "required_adaptation_id": ADAPTATION_ID,
        "target_id": PAYOFF_HAZARD_ID,
        "availability": AVAILABILITY,
        "intent": "Review deliberate Read Drift against an existing moving jellyfish patrol.",
    }]


def creature_memory_opportunities() -> list[dict]:
    return [{
        "id": MEMORY_RECORD_ID,
        "memory_id": MEMORY_ID,
        "species_id": SPECIES_ID,
        "individual_id": INDIVIDUAL_ID,
        "event_kind": "ecological_observation_committed",
        "target_id": TRACE_ID,
        "adaptation_ids": [ADAPTATION_ID],
        "payoff_id": PAYOFF_ID,
        "required_access_ids": [],
        "availability": AVAILABILITY,
        "intent": "Commit the identified bloom migration only at the canonical boat.",
    }]


def creature_adaptation_payoffs() -> list[dict]:
    return [{
        "id": PAYOFF_ID,
        "species_id": SPECIES_ID,
        "adaptation_id": ADAPTATION_ID,
        "target_id": PAYOFF_HAZARD_ID,
        "required_access_ids": [],
        "independent_context_id": CONTEXT_ID,
        "availability": AVAILABILITY,
        "intent": "Read a jellyfish patrol's existing path and direction without changing it.",
    }]


def camera_tests(anchor: tuple[int, int]) -> list[dict]:
    return [{
        "id": REVIEW_CAMERA_ID,
        "center_x": anchor[0],
        "center_y": anchor[1],
        "zoom": 0.58,
        "intent": "Southwest bloom patrol, migration filament, and Mica observation review.",
    }]


def review_questions() -> list[str]:
    return [
        "Does the migration trace read as evidence connected to the moving southwest bloom?",
        "Does the relationship remain optional, rewardless, reachable, and separate from hazard authority?",
    ]


def source_provenance(anchor: tuple[int, int]) -> dict:
    return {
        "source": "tools/production_level_01_living_expedition_03.py",
        "relationship_ids": [TRACE_ID],
        "observation_ids": [OBSERVATION_ID],
        "memory_opportunity_ids": [MEMORY_RECORD_ID],
        "adaptation_payoff_ids": [PAYOFF_ID],
        "companion_context_ids": [CONTEXT_ID],
        "camera_test_ids": [REVIEW_CAMERA_ID],
        "condition_ids": [CONDITION_ID],
        "moving_hazard_ids": [MIGRATION_HAZARD_ID, PAYOFF_HAZARD_ID],
        "retired_trace_ids": [LEGACY_TRACE_ID],
        "derived_trace_anchor": {"x": anchor[0], "y": anchor[1]},
        "availability": AVAILABILITY,
        "terrain_changes": [],
        "intent": (
            "Replace the anonymous Mica trace with one source-linked bloom "
            "migration observation and independent next-sortie field payoff."
        ),
    }


def _append_unique(
    map_data: dict[str, Any], collection: str, factory: Callable[[], list[dict]]
) -> None:
    records = map_data.get(collection)
    if not isinstance(records, list):
        raise ValueError(f"Expected {collection} to be a list.")
    additions = factory()
    existing_ids = {str(item.get("id", "")) for item in records if isinstance(item, dict)}
    duplicates = sorted(str(item.get("id", "")) for item in additions if item.get("id") in existing_ids)
    if duplicates:
        raise ValueError(f"Living Expedition 03 duplicate {collection} ids: {duplicates}.")
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Replace the legacy trace and append relationship records without terrain edits."""
    hazard = _by_id(map_data, "moving_hazards", MIGRATION_HAZARD_ID)
    if hazard.get("daily_condition_id") != CONDITION_ID:
        raise ValueError(f"{MIGRATION_HAZARD_ID} must remain linked to {CONDITION_ID}.")
    _by_id(map_data, "daily_conditions", CONDITION_ID)
    _by_id(map_data, "moving_hazards", PAYOFF_HAZARD_ID)
    anchor = _migration_anchor(hazard)
    legacy_trace = _by_id(map_data, "ecological_traces", LEGACY_TRACE_ID)
    traces = map_data["ecological_traces"]
    traces[traces.index(legacy_trace)] = ecological_trace(hazard)
    _by_id(map_data, "creature_rescues", RESCUE_ID)["trace_id"] = TRACE_ID
    _append_unique(map_data, "companion_contexts", companion_contexts)
    _append_unique(map_data, "creature_memory_opportunities", creature_memory_opportunities)
    _append_unique(map_data, "creature_adaptation_payoffs", creature_adaptation_payoffs)
    _append_unique(map_data, "camera_tests", lambda: camera_tests(anchor))
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "living_expedition_03" in source:
        raise ValueError("Expected source without existing living_expedition_03 provenance.")
    previous = source.get("living_expedition_02")
    if not isinstance(previous, dict) or previous.get("trace_ids") != [LEGACY_TRACE_ID]:
        raise ValueError("Expected the explicit Living Expedition 02 legacy trace provenance.")
    previous["trace_ids"] = []
    previous["retired_trace_ids"] = [LEGACY_TRACE_ID]
    previous["trace_transition_owner"] = "living_expedition_03"
    previous["target_ids"] = [
        record_id for record_id in previous.get("target_ids", [])
        if record_id != LEGACY_TRACE_ID
    ]
    source["living_expedition_03"] = source_provenance(anchor)
    return map_data
