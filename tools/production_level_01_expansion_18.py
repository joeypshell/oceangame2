#!/usr/bin/env python3
"""Source-owned Transfer Hub exterior records for Expansion 18."""

from __future__ import annotations

from typing import Any, Callable


PREREQUISITE_ID = "wreck_network_triangulation_discovery"
EXTERIOR_ENTRANCE_ID = "transfer_hub_exterior_entrance"
EXTERIOR_RETURN_ID = "transfer_hub_exterior_return"
INTERIOR_MAP_ID = "transfer_hub_interior_01"
INTERIOR_ENTRY_ID = "transfer_hub_interior_entry"
INTERIOR_RETURN_ID = "transfer_hub_interior_return"
LANDMARK_ID = "transfer_hub_exterior_bulkhead"


def zones() -> list[dict]:
    return [
        {
            "id": EXTERIOR_ENTRANCE_ID,
            "type": "marker",
            "x": 92,
            "y": 151,
            "w": 3,
            "h": 3,
            "world_connector": True,
            "connector_kind": "exceptional_interior",
            "connector_label": "Transfer Hub",
            "destination_map_id": INTERIOR_MAP_ID,
            "destination_map_path": f"res://maps/{INTERIOR_MAP_ID}.greybox.json",
            "destination_entry_id": INTERIOR_ENTRY_ID,
            "connector_direction": "forward",
            "paired_connector_id": INTERIOR_RETURN_ID,
            "required_discovery_id": PREREQUISITE_ID,
            "intent": (
                "Physically scoutable lower-chamber doorway whose interaction is "
                "unlocked by the recovered transfer-hub coordinates."
            ),
        }
    ]


def entities() -> list[dict]:
    return [
        {
            "id": EXTERIOR_RETURN_ID,
            "type": "spawn",
            "x": 88,
            "y": 152,
            "intent": (
                "Paired return entry beside the original doorway; never an extraction, "
                "oxygen-refill, banking, or night owner."
            ),
        }
    ]


def background() -> list[dict]:
    return [
        {
            "id": LANDMARK_ID,
            "type": "background",
            "x": 89,
            "y": 148,
            "w": 9,
            "h": 8,
            "intent": (
                "Non-collision bulkhead silhouette identifying the one exceptional "
                "interior entrance in the existing lower chamber."
            ),
        }
    ]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_18_transfer_hub_approach",
            "center_x": 92.0,
            "center_y": 151.5,
            "zoom": 0.50,
            "intent": (
                "Continuous lower-chamber approach, scoutable bulkhead, entrance, "
                "and paired exterior return entry."
            ),
        }
    ]


def review_questions() -> list[str]:
    return [
        "Does the lower-chamber bulkhead read as one physically reached destination rather than normal fast travel?",
        "Can the unchanged route from the canonical boat reach the entrance and return entry with the player footprint?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_18.py",
        "prerequisite_discovery_id": PREREQUISITE_ID,
        "connector_ids": [EXTERIOR_ENTRANCE_ID],
        "entry_ids": [EXTERIOR_RETURN_ID],
        "background_ids": [LANDMARK_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "review_bounds": {"x": 84, "y": 146, "w": 16, "h": 10},
        "intent": (
            "One source-authored exceptional-interior entrance in existing open water; "
            "production topology remains byte-for-byte stable."
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
        raise ValueError(f"Expansion 18 duplicate {collection} ids: {duplicate_ids}.")
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append the exterior records without touching topology or prior sources."""
    for collection, factory in (
        ("zones", zones),
        ("entities", entities),
        ("background", background),
        ("camera_tests", camera_tests),
    ):
        _append_unique(map_data, collection, factory)
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "expansion_18" in source:
        raise ValueError("Expected source without existing expansion_18 provenance.")
    source["expansion_18"] = source_provenance()
    return map_data
