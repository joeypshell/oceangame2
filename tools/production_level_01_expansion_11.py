#!/usr/bin/env python3
"""Source-owned durable-light return records for Expansion 11."""

from __future__ import annotations


PROJECT_ID = "dive_light_1_project"
CAPABILITY_ID = "dive_light_1"
KNOWLEDGE_ID = "lower_right_signal_reef_discovery"
DARK_ZONE_ID = "signal_reef_deep_harmonic_dark_zone"
SURVEY_ID = "signal_reef_deep_harmonic_survey"
DISCOVERY_ID = "signal_reef_deep_harmonic_discovery"
ROUTE_ID = "east_current_signal_reef_route"
BOAT_ID = "surface_boat_entry"


def material_projects() -> list[dict]:
    return [{
        "id": PROJECT_ID,
        "required_discovery_id": KNOWLEDGE_ID,
        "required_materials": {
            "titanium_scrap": 1,
            "conductive_coil": 1,
            "insulating_gel": 1,
        },
        "unlocks_capability_id": CAPABILITY_ID,
        "target_id": SURVEY_ID,
        "build_phase": "night_debrief",
        "project_label": "Dive light project",
        "completion_label": "Dive light built",
    }]


def zones() -> list[dict]:
    return [{
        "id": DARK_ZONE_ID,
        "type": "marker",
        "x": 132,
        "y": 118,
        "w": 10,
        "h": 6,
        "visibility_zone": True,
        "visibility_level": "dark",
        "visibility_label": "Deep harmonic dark water",
        "required_upgrade_id": CAPABILITY_ID,
        "visual_only": True,
        "route_context": ROUTE_ID,
        "intent": (
            "Use the existing open pocket directly below Signal Reef for a "
            "scoutable dark-water return without terrain or collision changes."
        ),
    }]


def survey_targets() -> list[dict]:
    return [{
        "id": SURVEY_ID,
        "target_type": "regional",
        "x": 136,
        "y": 120,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "required_light_capability_id": CAPABILITY_ID,
        "required_route_id": ROUTE_ID,
        "route_context": ROUTE_ID,
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey deep harmonic",
        "clue_label": "Deep harmonic | Stronger light required",
        "finding_label": "Discovery logged: Deep harmonic chart",
        "next_lead_label": "Next lead: signal descends into deeper water",
        "discovery_id": DISCOVERY_ID,
        "commit_map_id": "production_level_01",
        "commit_map_path": "res://maps/production_level_01.greybox.json",
        "commit_entry_id": BOAT_ID,
        "intent": (
            "Make the deeper Signal Reef signal visible before the light while "
            "reserving timed progress for the durable capability."
        ),
    }]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_11_pre_light_route_context",
            "center_x": 137.0,
            "center_y": 116.0,
            "zoom": 0.42,
            "intent": "Known Signal Reef landmark above the scoutable dark return pocket.",
        },
        {
            "id": "expansion_11_upgraded_harmonic_survey",
            "center_x": 137.0,
            "center_y": 121.0,
            "zoom": 0.55,
            "intent": "Durable-light survey interaction inside the deep harmonic zone.",
        },
        {
            "id": "expansion_11_pending_boat_return",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Pending deep-harmonic discovery returning to the canonical boat.",
        },
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_11.py",
        "project_ids": [PROJECT_ID],
        "zone_ids": [DARK_ZONE_ID],
        "survey_target_ids": [SURVEY_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "intent": "Source-authored durable-light return metadata in existing open water.",
    }
