#!/usr/bin/env python3
"""Source-owned Silt Hound rescue and excavation records."""

from __future__ import annotations

from typing import Any, Callable


SPECIES_ID = "silt_hound"
INDIVIDUAL_ID = "silt_hound_juvenile_01"
RESCUE_ID = "silt_hound_rescue_01"
HABITAT_ID = "companion_habitat_01"
ACTION_ID = "excavate"
CONTEXT_ID = "silt_hound_excavate_context_01"
CANDIDATE_ID = "silt_hound_buried_titanium_01"
POOL_ID = "silt_hound_excavation_pool"
RESCUE_CAMERA_ID = "living_expedition_05_rescue_review_01"
EXCAVATE_CAMERA_ID = "living_expedition_05_excavate_review_01"
AVAILABILITY = "all_supported_seeds"

RESCUE_POINT = (52, 75)
DEPOSIT_POINT = (97, 80)


def creature_rescues() -> list[dict]:
    return [
        {
            "id": RESCUE_ID,
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "x": RESCUE_POINT[0],
            "y": RESCUE_POINT[1],
            "rescue_kind": "physical_aid",
            "required_capability_id": "salvage_cutter",
            "commit_map_id": "production_level_01",
            "commit_entry_id": "surface_boat_entry",
            "habitat_id": HABITAT_ID,
            "excavation_context_id": CONTEXT_ID,
            "buried_candidate_id": CANDIDATE_ID,
            "review_camera_id": RESCUE_CAMERA_ID,
            "optional": True,
            "availability": AVAILABILITY,
            "intent": (
                "Cut Marl free from discarded dredge cable beside a disturbed "
                "brood stone, then return together to the surface boat."
            ),
        }
    ]


def companion_contexts() -> list[dict]:
    return [
        {
            "id": CONTEXT_ID,
            "context_kind": "material_excavation_review",
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "action_id": ACTION_ID,
            "target_id": CANDIDATE_ID,
            "commit_entry_id": "surface_boat_entry",
            "required_access_ids": [],
            "availability": AVAILABILITY,
            "intent": (
                "Return with active Marl to deliberately excavate the visible "
                "lower-loop mound."
            ),
        }
    ]


def entities() -> list[dict]:
    return [
        {
            "id": CANDIDATE_ID,
            "type": "material_candidate",
            "x": DEPOSIT_POINT[0],
            "y": DEPOSIT_POINT[1],
            "kind": "buried_titanium",
            "interaction": "material_collect",
            "material_id": "titanium_scrap",
            "material_quantity": 1,
            "candidate_pool_id": POOL_ID,
            "buried_deposit": True,
            "required_companion_action_id": ACTION_ID,
            "companion_context_id": CONTEXT_ID,
            "presentation_kind": "buried_mineral_mound",
            "intent": (
                "Visible optional mound revisited with Marl; excavation exposes "
                "one normal titanium pickup."
            ),
        }
    ]


def material_candidate_pools() -> list[dict]:
    return [
        {
            "id": POOL_ID,
            "material_id": "titanium_scrap",
            "selection_strategy": "day_rotation_v1",
            "select_count": 1,
            "candidate_ids": [CANDIDATE_ID],
            "guaranteed_candidate_ids": [CANDIDATE_ID],
            "pool_role": "optional_bonus",
            "intent": (
                "Keep Marl's proof available every day while excluding it from "
                "mandatory recipe guarantees."
            ),
        }
    ]


def camera_tests() -> list[dict]:
    return [
        {
            "id": RESCUE_CAMERA_ID,
            "center_x": RESCUE_POINT[0],
            "center_y": RESCUE_POINT[1] - 1,
            "zoom": 0.62,
            "intent": "Marl's physical cable rescue and lower-loop approach review.",
        },
        {
            "id": EXCAVATE_CAMERA_ID,
            "center_x": DEPOSIT_POINT[0],
            "center_y": DEPOSIT_POINT[1] - 2,
            "zoom": 0.62,
            "intent": "Closed mound, deliberate excavation, and exposed pickup review.",
        },
    ]


def review_questions() -> list[str]:
    return [
        "Does Marl's cable rescue read as physical aid rather than collection?",
        "Is the buried mound visible before excavation and clearly optional afterward?",
        "Does returning with Marl make this lower-loop revisit feel intentional?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_living_expedition_05.py",
        "rescue_ids": [RESCUE_ID],
        "habitat_ids": [HABITAT_ID],
        "companion_context_ids": [CONTEXT_ID],
        "material_candidate_ids": [CANDIDATE_ID],
        "material_pool_ids": [POOL_ID],
        "camera_test_ids": [RESCUE_CAMERA_ID, EXCAVATE_CAMERA_ID],
        "target_ids": ["surface_boat_entry", RESCUE_ID, CANDIDATE_ID],
        "availability": AVAILABILITY,
        "terrain_changes": [],
        "intent": (
            "One Silt Hound rescue and one optional authored excavation payoff "
            "in existing lower-loop topology."
        ),
    }


def _by_id(map_data: dict[str, Any], collection: str, record_id: str) -> dict[str, Any]:
    matches = [
        item
        for item in map_data.get(collection, [])
        if isinstance(item, dict) and item.get("id") == record_id
    ]
    if len(matches) != 1:
        raise ValueError(
            f"Expected one {collection} record {record_id!r}; found {len(matches)}."
        )
    return matches[0]


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
            f"Living Expedition 05 duplicate {collection} ids: {duplicate_ids}."
        )
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append one rescue and excavation relationship without terrain edits."""
    habitat = _by_id(map_data, "companion_habitats", HABITAT_ID)
    expected_individuals = ["spark_ray_juvenile_01", "veil_cuttle_juvenile_01"]
    if habitat.get("individual_ids") != expected_individuals:
        raise ValueError(
            f"Expected {HABITAT_ID} individuals {expected_individuals!r}."
        )
    habitat["individual_ids"].append(INDIVIDUAL_ID)
    habitat["intent"] = (
        "Project up to three committed individuals beside the canonical boat; "
        "the active choice remains profile-owned."
    )

    for collection, factory in (
        ("creature_rescues", creature_rescues),
        ("companion_contexts", companion_contexts),
        ("entities", entities),
        ("material_candidate_pools", material_candidate_pools),
        ("camera_tests", camera_tests),
    ):
        _append_unique(map_data, collection, factory)
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "living_expedition_05" in source:
        raise ValueError("Expected source without existing living_expedition_05 provenance.")
    source["living_expedition_05"] = source_provenance()
    return map_data
