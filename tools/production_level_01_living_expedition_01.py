#!/usr/bin/env python3
"""Source-owned Spark Ray proof records for Living Expedition 01."""

from __future__ import annotations

from typing import Any, Callable


SPECIES_ID = "spark_ray"
INDIVIDUAL_ID = "spark_ray_juvenile_01"
RESCUE_ID = "spark_ray_rescue_01"
RIDING_REVIEW_ID = "spark_ray_riding_review_01"
CURRENT_MEMORY_ID = "spark_ray_current_memory_01"
EEL_MEMORY_ID = "spark_ray_eel_memory_01"
ANCHOR_PAYOFF_ID = "spark_ray_anchor_current_01"
GUARDIAN_PAYOFF_ID = "spark_ray_guardian_eel_01"
CURRENT_MEMORY_TARGET_ID = "lower_right_west_current_gate"
ANCHOR_PAYOFF_TARGET_ID = "lower_right_east_current_gate"
EEL_TARGET_ID = "deep_cache_territorial_eel"
AVAILABILITY = "all_supported_seeds"


def creature_rescues() -> list[dict]:
    return [
        {
            "id": RESCUE_ID,
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "x": 118,
            "y": 41,
            "rescue_kind": "physical_aid",
            "required_capability_id": "salvage_cutter",
            "commit_map_id": "production_level_01",
            "commit_entry_id": "surface_boat_entry",
            "riding_review_context_id": RIDING_REVIEW_ID,
            "availability": AVAILABILITY,
            "intent": (
                "Free the juvenile Spark Ray from loose maintenance cable beside "
                "the upper wreck, then return together to the surface boat."
            ),
        }
    ]


def companion_contexts() -> list[dict]:
    return [
        {
            "id": RIDING_REVIEW_ID,
            "context_kind": "mounted_route_review",
            "species_id": SPECIES_ID,
            "action_id": "glide_surge",
            "route_points": [
                {"x": 95, "y": 8},
                {"x": 98, "y": 14},
                {"x": 102, "y": 19},
                {"x": 108, "y": 22},
            ],
            "required_access_ids": [],
            "dismount": {"outcome": "clear", "x": 108, "y": 22},
            "availability": AVAILABILITY,
            "intent": (
                "Review follow, mount, Glide Surge, and a clear dismount through "
                "the broad entry shaft without crossing an equipment gate."
            ),
        },
        {
            "id": "spark_ray_anchor_independent_review_01",
            "context_kind": "independent_action_review",
            "species_id": SPECIES_ID,
            "action_id": "anchor_brace",
            "required_adaptation_id": "anchor_fins",
            "target_id": ANCHOR_PAYOFF_TARGET_ID,
            "availability": AVAILABILITY,
        },
        {
            "id": "spark_ray_anchor_mounted_review_01",
            "context_kind": "mounted_action_review",
            "species_id": SPECIES_ID,
            "action_id": "anchor_brace",
            "required_adaptation_id": "anchor_fins",
            "target_id": ANCHOR_PAYOFF_TARGET_ID,
            "availability": AVAILABILITY,
        },
        {
            "id": "spark_ray_guardian_independent_review_01",
            "context_kind": "independent_action_review",
            "species_id": SPECIES_ID,
            "action_id": "guardian_pulse_action",
            "required_adaptation_id": "guardian_pulse",
            "target_id": EEL_TARGET_ID,
            "availability": AVAILABILITY,
        },
        {
            "id": "spark_ray_guardian_mounted_review_01",
            "context_kind": "mounted_action_review",
            "species_id": SPECIES_ID,
            "action_id": "guardian_pulse_action",
            "required_adaptation_id": "guardian_pulse",
            "target_id": EEL_TARGET_ID,
            "availability": AVAILABILITY,
        },
    ]


def creature_memory_opportunities() -> list[dict]:
    return [
        {
            "id": CURRENT_MEMORY_ID,
            "memory_id": "held_the_flow",
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "event_kind": "current_cycle_completed",
            "target_id": CURRENT_MEMORY_TARGET_ID,
            "adaptation_ids": ["anchor_fins"],
            "payoff_id": ANCHOR_PAYOFF_ID,
            "required_access_ids": ["propulsion_fins"],
            "availability": AVAILABILITY,
            "intent": (
                "Complete the established west Signal Reef current route together "
                "after the diver has propulsion fins."
            ),
        },
        {
            "id": EEL_MEMORY_ID,
            "memory_id": "stood_ground",
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "event_kind": "territorial_threat_cycle_resolved",
            "target_id": EEL_TARGET_ID,
            "adaptation_ids": ["guardian_pulse"],
            "payoff_id": GUARDIAN_PAYOFF_ID,
            "required_access_ids": ["shock_prod"],
            "availability": AVAILABILITY,
            "intent": (
                "Resolve one existing territorial eel threat cycle together while "
                "retaining the diver's shock-prod requirement."
            ),
        },
    ]


def creature_adaptation_payoffs() -> list[dict]:
    return [
        {
            "id": ANCHOR_PAYOFF_ID,
            "species_id": SPECIES_ID,
            "adaptation_id": "anchor_fins",
            "target_id": ANCHOR_PAYOFF_TARGET_ID,
            "required_access_ids": ["propulsion_fins"],
            "independent_context_id": "spark_ray_anchor_independent_review_01",
            "mounted_context_id": "spark_ray_anchor_mounted_review_01",
            "availability": AVAILABILITY,
            "intent": (
                "Review Anchor Fins in both roles at the downstream east current "
                "without replacing the diver's propulsion-fins gate."
            ),
        },
        {
            "id": GUARDIAN_PAYOFF_ID,
            "species_id": SPECIES_ID,
            "adaptation_id": "guardian_pulse",
            "target_id": EEL_TARGET_ID,
            "required_access_ids": ["shock_prod"],
            "independent_context_id": "spark_ray_guardian_independent_review_01",
            "mounted_context_id": "spark_ray_guardian_mounted_review_01",
            "availability": AVAILABILITY,
            "intent": (
                "Review Guardian Pulse as a deliberate interruption in both roles; "
                "the shock prod remains the required weapon."
            ),
        },
    ]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "living_expedition_01_rescue",
            "center_x": 119,
            "center_y": 41,
            "zoom": 0.68,
            "intent": "Physical cable rescue beside recognizable upper-wreck debris.",
        },
        {
            "id": "living_expedition_01_follow",
            "center_x": 98,
            "center_y": 15,
            "zoom": 0.55,
            "intent": "Day-2 follow and separation review in the broad entry shaft.",
        },
        {
            "id": "living_expedition_01_mounted_route",
            "center_x": 104,
            "center_y": 20,
            "zoom": 0.55,
            "intent": "Mount, Glide Surge, rider clearance, and clear dismount review.",
        },
        {
            "id": "living_expedition_01_held_the_flow",
            "center_x": 111,
            "center_y": 82,
            "zoom": 0.58,
            "intent": "Held-the-flow event at the west Signal Reef current.",
        },
        {
            "id": "living_expedition_01_stood_ground",
            "center_x": 123,
            "center_y": 74,
            "zoom": 0.62,
            "intent": "Stood-ground event inside the existing eel territory.",
        },
        {
            "id": "living_expedition_01_night_choice",
            "center_x": 95,
            "center_y": 12,
            "zoom": 0.55,
            "intent": "Night-2 adaptation choice after canonical-boat commitment.",
        },
        {
            "id": "living_expedition_01_anchor_payoff",
            "center_x": 146,
            "center_y": 77,
            "zoom": 0.62,
            "intent": "Anchor Fins payoff at the downstream east current.",
        },
        {
            "id": "living_expedition_01_guardian_payoff",
            "center_x": 123,
            "center_y": 74,
            "zoom": 0.62,
            "intent": "Guardian Pulse payoff against the same resettable eel threat.",
        },
    ]


def review_questions() -> list[str]:
    return [
        "Does the cable rescue read as physical aid rather than a pickup or generic scan?",
        "Can the rider complete the entry-shaft route and dismount without clipping, bypass, or stranding?",
        "Do both memory events retain their diver-equipment requirements and lead to distinct day-3 payoffs?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_living_expedition_01.py",
        "rescue_ids": [RESCUE_ID],
        "companion_context_ids": [item["id"] for item in companion_contexts()],
        "memory_opportunity_ids": [CURRENT_MEMORY_ID, EEL_MEMORY_ID],
        "adaptation_payoff_ids": [ANCHOR_PAYOFF_ID, GUARDIAN_PAYOFF_ID],
        "target_ids": [
            CURRENT_MEMORY_TARGET_ID,
            ANCHOR_PAYOFF_TARGET_ID,
            EEL_TARGET_ID,
        ],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "availability": AVAILABILITY,
        "terrain_changes": [],
        "intent": (
            "Guaranteed one-individual rescue, riding review, memory, and payoff "
            "records layered onto existing topology and equipment-gated routes."
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
            f"Living Expedition 01 duplicate {collection} ids: {duplicate_ids}."
        )
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append immutable proof records without touching topology or runtime state."""
    for collection, factory in (
        ("creature_rescues", creature_rescues),
        ("companion_contexts", companion_contexts),
        ("creature_memory_opportunities", creature_memory_opportunities),
        ("creature_adaptation_payoffs", creature_adaptation_payoffs),
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
    if not isinstance(source, dict) or "living_expedition_01" in source:
        raise ValueError(
            "Expected source without existing living_expedition_01 provenance."
        )
    source["living_expedition_01"] = source_provenance()
    return map_data
