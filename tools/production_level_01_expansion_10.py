#!/usr/bin/env python3
"""Source-owned route and landmark records for Expansion 10."""

from __future__ import annotations


JOURNEY_ID = "east_current_signal_reef_route"
PROMISE_GATE_ID = "upper_right_current_pocket_gate"
ENTRY_GATE_IDS = (
    "lower_right_west_current_gate",
    "lower_right_east_current_gate",
)
LANDMARK_ZONE_ID = "lower_right_signal_reef_landmark"
LANDMARK_BACKGROUND_ID = "lower_right_signal_reef_backdrop"
CAPABILITY_ID = "propulsion_fins"


def regional_journeys() -> list[dict]:
    return [{
        "id": JOURNEY_ID,
        "route_label": "Signal Reef route",
        "promise_gate_id": PROMISE_GATE_ID,
        "entry_gate_ids": list(ENTRY_GATE_IDS),
        "required_capability_id": CAPABILITY_ID,
        "landmark_zone_id": LANDMARK_ZONE_ID,
        "route_context": JOURNEY_ID,
        "intent": (
            "Reuse the taught east-current language to gate one meaningful "
            "lower-right region and later boat-return discovery."
        ),
    }]


def zones() -> list[dict]:
    return [
        {
            "id": ENTRY_GATE_IDS[0],
            "type": "marker",
            "x": 109,
            "y": 81,
            "w": 3,
            "h": 6,
            "current_gate": True,
            "current_direction": "up",
            "current_strength": 2.2,
            "required_capability_id": CAPABILITY_ID,
            "current_gate_label": "Signal Reef current",
            "current_affordance_role": "barrier",
            "route_context": JOURNEY_ID,
        },
        {
            "id": ENTRY_GATE_IDS[1],
            "type": "marker",
            "x": 145,
            "y": 75,
            "w": 4,
            "h": 4,
            "current_gate": True,
            "current_direction": "up",
            "current_strength": 2.2,
            "required_capability_id": CAPABILITY_ID,
            "current_gate_label": "Signal Reef current",
            "current_affordance_role": "barrier",
            "route_context": JOURNEY_ID,
        },
        {
            "id": LANDMARK_ZONE_ID,
            "type": "marker",
            "x": 132,
            "y": 108,
            "w": 10,
            "h": 10,
            "regional_landmark": True,
            "regional_journey_id": JOURNEY_ID,
            "landmark_label": "Signal Reef",
        },
    ]


def background() -> list[dict]:
    return [{
        "id": LANDMARK_BACKGROUND_ID,
        "type": "background",
        "x": 132,
        "y": 108,
        "w": 10,
        "h": 10,
        "regional_landmark": True,
        "regional_journey_id": JOURNEY_ID,
    }]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_10_current_promise",
            "center_x": 123.5,
            "center_y": 41.0,
            "zoom": 0.55,
            "intent": "Existing east-current promise before the regional journey.",
        },
        {
            "id": "expansion_10_lower_right_entry",
            "center_x": 129.0,
            "center_y": 82.0,
            "zoom": 0.28,
            "intent": "Both passive current seams and continuous lower-right entry context.",
        },
        {
            "id": "expansion_10_signal_reef",
            "center_x": 137.0,
            "center_y": 113.0,
            "zoom": 0.45,
            "intent": "Signal Reef landmark silhouette and surrounding collision-active water.",
        },
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_10.py",
        "journey_ids": [JOURNEY_ID],
        "entry_gate_ids": list(ENTRY_GATE_IDS),
        "landmark_zone_ids": [LANDMARK_ZONE_ID],
        "terrain_changes": [],
        "intent": "Source-authored regional route metadata with no topology edits.",
    }
