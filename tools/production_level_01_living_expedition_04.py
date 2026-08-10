#!/usr/bin/env python3
"""Source-owned companion responses for Living Expedition 04's existing eel."""

from __future__ import annotations

from typing import Any


RELATIONSHIP_ID = "deep_cache_eel_companion_response"
HOSTILE_ID = "deep_cache_territorial_eel"
SALVAGE_ID = "salvage_deep_right_cache"
HARVEST_ID = "deep_cache_eel_electrocyte_harvest"
REVIEW_CONTEXT_ID = "living_expedition_04_eel_review_01"
REVIEW_CAMERA_ID = "living_expedition_04_eel_review_camera_01"
AVAILABILITY = "all_supported_seeds"


def _by_id(map_data: dict[str, Any], collection: str, record_id: str) -> dict[str, Any]:
    matches = [
        item for item in map_data.get(collection, [])
        if isinstance(item, dict) and item.get("id") == record_id
    ]
    if len(matches) != 1:
        raise ValueError(f"Expected one {collection} record {record_id!r}; found {len(matches)}.")
    return matches[0]


def relationship() -> dict[str, Any]:
    return {
        "id": RELATIONSHIP_ID,
        "kind": "companion_hostile_response",
        "hostile_id": HOSTILE_ID,
        "guarded_salvage_id": SALVAGE_ID,
        "hostile_harvest_id": HARVEST_ID,
        "review_context_id": REVIEW_CONTEXT_ID,
        "responses": [
            {
                "species_id": "spark_ray",
                "individual_id": "spark_ray_juvenile_01",
                "required_adaptation_id": "guardian_pulse",
                "action_id": "guardian_pulse_action",
                "effect_kind": "support_interrupt",
                "damage": 0,
                "required_access_ids": ["shock_prod"],
            },
        ],
        "availability": AVAILABILITY,
        "intent": (
            "Guardian-Pulse Kite may create a zero-damage opening while Shock Prod "
            "remains defeat authority."
        ),
    }


def _review_anchor(hostile: dict[str, Any]) -> tuple[float, float]:
    territory = hostile.get("territory")
    if not isinstance(territory, dict):
        raise ValueError(f"{HOSTILE_ID} requires its existing territory rectangle.")
    try:
        return (
            float(territory["x"]) + float(territory["w"]) / 2.0,
            float(territory["y"]) + float(territory["h"]) / 2.0,
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError(f"{HOSTILE_ID} territory is malformed: {exc}") from exc


def camera_test(anchor: tuple[float, float]) -> dict[str, Any]:
    return {
        "id": REVIEW_CAMERA_ID,
        "center_x": anchor[0],
        "center_y": anchor[1],
        "zoom": 0.64,
        "intent": "Existing eel, guarded cache, diver, and active companion response review.",
    }


def review_questions() -> list[str]:
    return [
        "Does Guardian Pulse create a clear zero-damage opening while Shock Prod remains defeat authority?",
        "Can the player still evade, attempt the cache, and understand that harvest requires defeat?",
    ]


def source_provenance(anchor: tuple[float, float]) -> dict[str, Any]:
    return {
        "source": "tools/production_level_01_living_expedition_04.py",
        "relationship_ids": [RELATIONSHIP_ID],
        "hostile_ids": [HOSTILE_ID],
        "guarded_salvage_ids": [SALVAGE_ID],
        "hostile_harvest_ids": [HARVEST_ID],
        "companion_action_ids": ["guardian_pulse_action"],
        "review_context_ids": [REVIEW_CONTEXT_ID],
        "camera_test_ids": [REVIEW_CAMERA_ID],
        "derived_review_anchor": {"x": anchor[0], "y": anchor[1]},
        "availability": AVAILABILITY,
        "terrain_changes": [],
        "intent": "Reference existing encounter owners without copying geometry or mutable state.",
    }


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append one relationship and review metadata without terrain edits."""
    hostile = _by_id(map_data, "hostile_encounters", HOSTILE_ID)
    salvage = _by_id(map_data, "entities", SALVAGE_ID)
    harvest = _by_id(map_data, "biological_resource_sources", HARVEST_ID)
    if hostile.get("required_weapon_capability_id") != "shock_prod":
        raise ValueError(f"{HOSTILE_ID} must remain Shock-Prod-gated.")
    if salvage.get("guarded_by_hostile_id") != HOSTILE_ID:
        raise ValueError(f"{SALVAGE_ID} must remain guarded by {HOSTILE_ID}.")
    if harvest.get("hostile_id") != HOSTILE_ID or harvest.get("interaction") != "post_defeat_harvest":
        raise ValueError(f"{HARVEST_ID} must remain an explicit post-defeat harvest.")
    if "companion_hostile_responses" in map_data:
        raise ValueError("Expected no pre-existing companion_hostile_responses collection.")
    map_data["companion_hostile_responses"] = [relationship()]

    anchor = _review_anchor(hostile)
    cameras = map_data.get("camera_tests")
    if not isinstance(cameras, list) or any(
        isinstance(item, dict) and item.get("id") == REVIEW_CAMERA_ID for item in cameras
    ):
        raise ValueError(f"Expected camera_tests without {REVIEW_CAMERA_ID!r}.")
    cameras.append(camera_test(anchor))
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "living_expedition_04" in source:
        raise ValueError("Expected source without existing living_expedition_04 provenance.")
    source["living_expedition_04"] = source_provenance(anchor)
    return map_data
