#!/usr/bin/env python3
"""Source-owned Signal Reef nursery journey records."""

from __future__ import annotations

from typing import Any, Callable

from living_expedition_06_contract import (
    ACCESS_IDS,
    ANCHOR_ACTION_ID,
    ANCHOR_ADAPTATION_ID,
    ANCHOR_CONTEXT_ID,
    AVAILABILITY,
    BOAT_ENTRY_ID,
    CAMERA_IDS,
    COMMITMENT_EVENT_ID,
    DARK_ZONE_ID,
    EAST_GATE_ID,
    GUARDIAN_ACTION_ID,
    GUARDIAN_ADAPTATION_ID,
    GUARDIAN_CONTEXT_ID,
    INDIVIDUAL_ID,
    JOURNEY_ID,
    LANDMARK_ID,
    NURSERY_ID,
    PRESSURE_ID,
    ROUTE_ID,
    SCHOOL_ID,
    SOURCE_KEY,
    SPECIES_ID,
    WEST_GATE_ID,
)


SCHOOL_POINT = (134, 104)
SCHOOL_PATH = ((134, 104), (136, 106), (138, 108), (140, 111))
NURSERY_RECT = (139, 110, 3, 3)
PRESSURE_RECT = (126, 102, 6, 5)
PRESSURE_PATH = ((127, 104), (130, 104), (131, 105))


def regional_creature_journeys() -> list[dict]:
    return [{
        "id": JOURNEY_ID,
        "journey_kind": "regional_habitat_restoration",
        "species_id": SPECIES_ID,
        "individual_id": INDIVIDUAL_ID,
        "school_id": SCHOOL_ID,
        "nursery_id": NURSERY_ID,
        "pressure_id": PRESSURE_ID,
        "adaptation_context_ids": [ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID],
        "route_id": ROUTE_ID,
        "gate_ids": [WEST_GATE_ID, EAST_GATE_ID],
        "landmark_zone_id": LANDMARK_ID,
        "dark_zone_id": DARK_ZONE_ID,
        "commit_map_id": "production_level_01",
        "commit_entry_id": BOAT_ENTRY_ID,
        "commitment_event_id": COMMITMENT_EVENT_ID,
        "review_camera_ids": CAMERA_IDS,
        "required_access_ids": ACCESS_IDS,
        "optional": True,
        "reward_ids": [],
        "progression_effect": "none",
        "availability": AVAILABILITY,
        "intent": (
            "Return to Signal Reef with adapted Kite, shelter one guaranteed "
            "filter-skate school, and commit the shared history at the boat."
        ),
    }]


def passive_wildlife_groups() -> list[dict]:
    return [{
        "id": SCHOOL_ID,
        "wildlife_kind": "juvenile_filter_skate_school",
        "x": SCHOOL_POINT[0],
        "y": SCHOOL_POINT[1],
        "path": [{"x": x, "y": y} for x, y in SCHOOL_PATH],
        "nursery_id": NURSERY_ID,
        "pressure_id": PRESSURE_ID,
        "bondable": False,
        "harvestable": False,
        "collectible": False,
        "reward_ids": [],
        "availability": AVAILABILITY,
        "intent": (
            "A passive, uncollectible school crosses the existing western approach "
            "and settles in the Signal Reef nursery pocket."
        ),
    }]


def creature_nurseries() -> list[dict]:
    x, y, w, h = NURSERY_RECT
    return [{
        "id": NURSERY_ID,
        "nursery_kind": "filter_skate_nursery",
        "x": x,
        "y": y,
        "w": w,
        "h": h,
        "school_id": SCHOOL_ID,
        "landmark_zone_id": LANDMARK_ID,
        "availability": AVAILABILITY,
        "intent": (
            "Existing open water inside the Signal Reef landmark becomes the "
            "school's visible next-day nursery destination."
        ),
    }]


def ecological_pressures() -> list[dict]:
    x, y, w, h = PRESSURE_RECT
    return [{
        "id": PRESSURE_ID,
        "pressure_kind": "jellyfish_displacement_cycle",
        "x": x,
        "y": y,
        "w": w,
        "h": h,
        "path": [{"x": px, "y": py} for px, py in PRESSURE_PATH],
        "school_id": SCHOOL_ID,
        "damaging": False,
        "reward_ids": [],
        "availability": AVAILABILITY,
        "intent": (
            "A non-damaging jellyfish drift displaces the school on Signal Reef's "
            "western approach without blocking either current gate."
        ),
    }]


def companion_contexts() -> list[dict]:
    shared = {
        "context_kind": "regional_journey_action",
        "species_id": SPECIES_ID,
        "individual_id": INDIVIDUAL_ID,
        "journey_id": JOURNEY_ID,
        "school_id": SCHOOL_ID,
        "nursery_id": NURSERY_ID,
        "required_access_ids": ACCESS_IDS,
        "availability": AVAILABILITY,
    }
    return [
        {
            "id": ANCHOR_CONTEXT_ID,
            **shared,
            "branch_kind": "current_lee",
            "action_id": ANCHOR_ACTION_ID,
            "required_adaptation_id": ANCHOR_ADAPTATION_ID,
            "target_id": EAST_GATE_ID,
            "intent": (
                "Anchor-adapted Kite braces beside the existing east current gate "
                "to form a temporary lee for the school."
            ),
        },
        {
            "id": GUARDIAN_CONTEXT_ID,
            **shared,
            "branch_kind": "pressure_interrupt",
            "action_id": GUARDIAN_ACTION_ID,
            "required_adaptation_id": GUARDIAN_ADAPTATION_ID,
            "target_id": PRESSURE_ID,
            "intent": (
                "Guardian-adapted Kite deliberately interrupts the western "
                "jellyfish displacement cycle without damaging wildlife."
            ),
        },
    ]


def camera_tests() -> list[dict]:
    values = (
        (132, 104, 0.45, "School, pressure, and nursery approach relationship."),
        (146, 82, 0.52, "Anchor Fins action beside the existing east current gate."),
        (130, 104, 0.54, "Guardian Pulse interruption on the western approach."),
        (140, 111, 0.58, "Pending nursery state before canonical boat return."),
        (140, 111, 0.58, "Visible restored nursery state on the next day."),
    )
    return [
        {
            "id": camera_id,
            "center_x": center_x,
            "center_y": center_y,
            "zoom": zoom,
            "intent": intent,
        }
        for camera_id, (center_x, center_y, zoom, intent) in zip(CAMERA_IDS, values)
    ]


def review_questions() -> list[str]:
    return [
        "Does the passive filter-skate school read as wildlife rather than loot?",
        "Do both Kite adaptations offer distinct optional responses in existing water?",
        "Does the next-day nursery change make Signal Reef worth revisiting?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_living_expedition_06.py",
        "journey_ids": [JOURNEY_ID],
        "passive_wildlife_ids": [SCHOOL_ID],
        "nursery_ids": [NURSERY_ID],
        "ecological_pressure_ids": [PRESSURE_ID],
        "companion_context_ids": [ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID],
        "camera_test_ids": CAMERA_IDS,
        "availability": AVAILABILITY,
        "terrain_changes": [],
        "intent": (
            "One guaranteed optional Signal Reef nursery journey using existing "
            "topology, access gates, Kite adaptations, and canonical boat return."
        ),
    }


def _by_id(map_data: dict[str, Any], collection: str, record_id: str) -> dict[str, Any]:
    matches = [
        item for item in map_data.get(collection, [])
        if isinstance(item, dict) and item.get("id") == record_id
    ]
    if len(matches) != 1:
        raise ValueError(
            f"Expected one {collection} record {record_id!r}; found {len(matches)}."
        )
    return matches[0]


def _append_unique(
    map_data: dict[str, Any], collection: str, factory: Callable[[], list[dict]]
) -> None:
    records = map_data.get(collection)
    if not isinstance(records, list):
        raise ValueError(f"Expected {collection} to be a list.")
    additions = factory()
    existing_ids = {str(item.get("id", "")) for item in records if isinstance(item, dict)}
    duplicates = sorted(str(item["id"]) for item in additions if item.get("id") in existing_ids)
    if duplicates:
        raise ValueError(f"Living Expedition 06 duplicate {collection} ids: {duplicates}.")
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append the optional nursery relationship without changing terrain."""
    terrain = list(map_data.get("terrain", []))
    for collection, factory in (
        ("regional_creature_journeys", regional_creature_journeys),
        ("passive_wildlife_groups", passive_wildlife_groups),
        ("creature_nurseries", creature_nurseries),
        ("ecological_pressures", ecological_pressures),
    ):
        if collection in map_data:
            raise ValueError(f"Expected source without existing {collection} collection.")
        map_data[collection] = factory()

    for collection, factory in (
        ("companion_contexts", companion_contexts),
        ("camera_tests", camera_tests),
    ):
        _append_unique(map_data, collection, factory)

    for collection, record_id in (
        ("regional_journeys", ROUTE_ID),
        ("zones", WEST_GATE_ID),
        ("zones", EAST_GATE_ID),
        ("zones", LANDMARK_ID),
        ("zones", DARK_ZONE_ID),
        ("entities", BOAT_ENTRY_ID),
    ):
        _by_id(map_data, collection, record_id)

    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or SOURCE_KEY in source:
        raise ValueError(f"Expected source without existing {SOURCE_KEY} provenance.")
    source[SOURCE_KEY] = source_provenance()
    if map_data.get("terrain") != terrain:
        raise ValueError("Living Expedition 06 must not change terrain topology.")
    return map_data
