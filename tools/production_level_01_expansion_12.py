#!/usr/bin/env python3
"""Source-owned abyssal pressure-return records for Expansion 12."""

from __future__ import annotations


PROJECT_ID = "pressure_suit_1_project"
CAPABILITY_ID = "pressure_suit_1"
KNOWLEDGE_ID = "signal_reef_deep_harmonic_discovery"
ROUTE_ID = "deep_harmonic_abyssal_basin_route"
ZONE_ID = "abyssal_basin_pressure_zone"
LANDMARK_ID = "abyssal_basin_landmark"
BACKGROUND_ID = "abyssal_basin_harmonic_source_backdrop"
SURVEY_ID = "abyssal_basin_harmonic_source_survey"
DISCOVERY_ID = "abyssal_basin_harmonic_source_discovery"
BOAT_ID = "surface_boat_entry"


def material_projects() -> list[dict]:
    return [{
        "id": PROJECT_ID,
        "required_discovery_id": KNOWLEDGE_ID,
        "required_materials": {
            "titanium_scrap": 2,
            "rubber_sheet": 1,
            "insulating_gel": 1,
        },
        "unlocks_capability_id": CAPABILITY_ID,
        "target_id": SURVEY_ID,
        "build_phase": "night_debrief",
        "project_label": "Pressure suit project",
        "completion_label": "Pressure suit built",
    }]


def zones() -> list[dict]:
    return [
        {
            "id": ZONE_ID,
            "type": "marker",
            "x": 60,
            "y": 126,
            "w": 77,
            "h": 30,
            "pressure_zone": True,
            "pressure_level": "abyssal",
            "pressure_label": "Abyssal pressure",
            "required_capability_id": CAPABILITY_ID,
            "warning_grace_seconds": 1.0,
            "unprotected_oxygen_drain_multiplier": 8.0,
            "route_context": ROUTE_ID,
            "intent": (
                "Teach retreat at the existing lower-central pressure threshold "
                "without changing terrain or blocking ordinary movement."
            ),
        },
        {
            "id": LANDMARK_ID,
            "type": "marker",
            "x": 81,
            "y": 141,
            "w": 33,
            "h": 15,
            "regional_landmark": True,
            "regional_journey_id": ROUTE_ID,
            "landmark_label": "Abyssal Basin",
        },
    ]


def regional_journeys() -> list[dict]:
    return [{
        "id": ROUTE_ID,
        "route_label": "Abyssal basin route",
        "promise_gate_id": "signal_reef_deep_harmonic_dark_zone",
        "entry_gate_ids": [ZONE_ID],
        "required_capability_id": CAPABILITY_ID,
        "landmark_zone_id": LANDMARK_ID,
        "survey_target_id": SURVEY_ID,
        "commit_entry_id": BOAT_ID,
        "route_context": ROUTE_ID,
        "intent": (
            "Return through continuous lower-central geography after learning the "
            "deep harmonic, then commit the abyssal discovery at the boat."
        ),
    }]


def survey_targets() -> list[dict]:
    return [{
        "id": SURVEY_ID,
        "target_type": "regional",
        "x": 95,
        "y": 149,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "required_pressure_capability_id": CAPABILITY_ID,
        "required_route_id": ROUTE_ID,
        "route_context": ROUTE_ID,
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey abyssal source",
        "clue_label": "Abyssal signal | Pressure suit required",
        "finding_label": "Discovery logged: Abyssal harmonic source",
        "next_lead_label": "Abyssal source charted | Further descent unresolved",
        "discovery_id": DISCOVERY_ID,
        "commit_map_id": "production_level_01",
        "commit_map_path": "res://maps/production_level_01.greybox.json",
        "commit_entry_id": BOAT_ID,
        "intent": (
            "Reward one protected return to the existing basin while keeping the "
            "finding pending until the canonical boat."
        ),
    }]


def background() -> list[dict]:
    return [{
        "id": BACKGROUND_ID,
        "type": "background",
        "x": 81,
        "y": 141,
        "w": 33,
        "h": 15,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
    }]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_12_pre_suit_pressure_warning",
            "center_x": 79.0,
            "center_y": 137.0,
            "zoom": 0.38,
            "intent": "Scoutable pressure threshold and retreat route before suit ownership.",
        },
        {
            "id": "expansion_12_pressure_suit_project",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Canonical boat context for the night-built pressure suit project.",
        },
        {
            "id": "expansion_12_protected_crossing",
            "center_x": 84.0,
            "center_y": 144.0,
            "zoom": 0.34,
            "intent": "Continuous protected crossing into the existing abyssal basin.",
        },
        {
            "id": "expansion_12_abyssal_survey",
            "center_x": 96.0,
            "center_y": 150.0,
            "zoom": 0.55,
            "intent": "Pressure-suit survey interaction at the harmonic source.",
        },
        {
            "id": "expansion_12_pending_boat_return",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Pending abyssal discovery returning to the canonical boat.",
        },
    ]


def review_questions() -> list[str]:
    return [
        "Can the pressure threshold be scouted and safely retreated from before the suit?",
        "Does the pressure-suit return preserve continuous remembered geography?",
        "Is the abyssal survey clearly deeper than the known Signal Reef harmonic?",
        "Does the completed survey remain pending until the canonical boat return?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_12.py",
        "project_ids": [PROJECT_ID],
        "journey_ids": [ROUTE_ID],
        "zone_ids": [ZONE_ID, LANDMARK_ID],
        "survey_target_ids": [SURVEY_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "intent": "Source-authored pressure return metadata in existing open water.",
    }
