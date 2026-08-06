#!/usr/bin/env python3
"""Source-owned Veil Cuttle records for Living Expedition 02."""

from __future__ import annotations

from typing import Any, Callable


SPECIES_ID = "veil_cuttle"
INDIVIDUAL_ID = "veil_cuttle_juvenile_01"
RESCUE_ID = "veil_cuttle_rescue_01"
HABITAT_ID = "companion_habitat_01"
TRACE_ID = "veil_cuttle_trace_01"
REVIEW_CAMERA_ID = "veil_cuttle_review_01"
ACTION_ID = "reveal_trace"
AVAILABILITY = "all_supported_seeds"


def creature_rescues() -> list[dict]:
    return [
        {
            "id": RESCUE_ID,
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "x": 38,
            "y": 49,
            "rescue_kind": "physical_aid",
            "required_capability_id": "salvage_cutter",
            "commit_map_id": "production_level_01",
            "commit_entry_id": "surface_boat_entry",
            "habitat_id": HABITAT_ID,
            "trace_id": TRACE_ID,
            "review_camera_id": REVIEW_CAMERA_ID,
            "availability": AVAILABILITY,
            "intent": (
                "Cut Mica free from a discarded survey net in the accessible "
                "upper-west chamber, then return together to the surface boat."
            ),
        }
    ]


def companion_habitats() -> list[dict]:
    return [
        {
            "id": HABITAT_ID,
            "habitat_kind": "canonical_boat",
            "x": 95,
            "y": 4,
            "entry_id": "surface_boat_entry",
            "individual_ids": ["spark_ray_juvenile_01", INDIVIDUAL_ID],
            "availability": AVAILABILITY,
            "intent": (
                "Project both committed individuals beside the canonical boat; "
                "the active choice remains profile-owned."
            ),
        }
    ]


def ecological_traces() -> list[dict]:
    return [
        {
            "id": TRACE_ID,
            "trace_kind": "concealed_ecological_trace",
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "x": 52,
            "y": 54,
            "action_id": ACTION_ID,
            "reveal_radius_tiles": 6,
            "scanner_capability_id": "survey_scanner_1",
            "required_access_ids": [],
            "optional": True,
            "reward_ids": [],
            "progression_effect": "none",
            "availability": AVAILABILITY,
            "intent": (
                "Mica may reveal this concealed environmental trace in already "
                "accessible water; the diver must still scan it to identify it."
            ),
        }
    ]


def camera_tests() -> list[dict]:
    return [
        {
            "id": REVIEW_CAMERA_ID,
            "center_x": 45,
            "center_y": 52,
            "zoom": 0.58,
            "intent": "Mica rescue, close-follow identity, and optional Reveal Trace review.",
        }
    ]


def review_questions() -> list[str]:
    return [
        "Does Mica's rescue read as physical aid in a reachable existing chamber?",
        "Does the optional trace remain clearly separate from scanner identification and progression?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_living_expedition_02.py",
        "rescue_ids": [RESCUE_ID],
        "habitat_ids": [HABITAT_ID],
        "trace_ids": [TRACE_ID],
        "camera_test_ids": [REVIEW_CAMERA_ID],
        "target_ids": ["surface_boat_entry", RESCUE_ID, TRACE_ID],
        "availability": AVAILABILITY,
        "terrain_changes": [],
        "intent": (
            "One guaranteed second-individual rescue, canonical-boat habitat "
            "relationship, and optional no-reward trace in existing topology."
        ),
    }


def _append_unique(
    map_data: dict[str, Any],
    collection: str,
    factory: Callable[[], list[dict]],
) -> None:
    records = map_data.get(collection)
    if not isinstance(records, list):
        raise ValueError(f"Expected {collection} to be a list.")
    additions = factory()
    existing_ids = {
        str(item.get("id", "")) for item in records if isinstance(item, dict)
    }
    duplicate_ids = sorted(
        str(item.get("id", ""))
        for item in additions
        if item.get("id") in existing_ids
    )
    if duplicate_ids:
        raise ValueError(
            f"Living Expedition 02 duplicate {collection} ids: {duplicate_ids}."
        )
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append second-individual source records without changing terrain."""
    _append_unique(map_data, "creature_rescues", creature_rescues)
    for collection, factory in (
        ("companion_habitats", companion_habitats),
        ("ecological_traces", ecological_traces),
    ):
        if collection in map_data:
            raise ValueError(f"Expected map without existing {collection} records.")
        map_data[collection] = factory()
    _append_unique(map_data, "camera_tests", camera_tests)
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "living_expedition_02" in source:
        raise ValueError(
            "Expected source without existing living_expedition_02 provenance."
        )
    source["living_expedition_02"] = source_provenance()
    return map_data
