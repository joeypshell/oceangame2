#!/usr/bin/env python3
"""Source-owned Archive Current Return records for Expansion 14."""

from __future__ import annotations


PROJECT_ID = "current_stabilizer_project"
ARCHIVE_DISCOVERY_ID = "southeast_wreck_archive_discovery"
CAPABILITY_ID = "current_stabilizer"
ROUTE_ID = "upper_left_wreck_relay_route"
GATE_ID = "upper_left_wreck_relay_current"
PROMISE_ID = "southeast_wreck_archive_landmark"
LANDMARK_ID = "upper_left_wreck_relay_landmark"
BACKGROUND_ID = "upper_left_wreck_relay_backdrop"
CORE_ID = "upper_left_wreck_relay_core"
SURVEY_ID = "upper_left_wreck_relay_survey"
DISCOVERY_ID = "upper_left_wreck_relay_discovery"
BOAT_ID = "surface_boat_entry"


def material_projects() -> list[dict]:
    return [{
        "id": PROJECT_ID,
        "required_project_id": "salvage_cutter_project",
        "required_discovery_id": ARCHIVE_DISCOVERY_ID,
        "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
        "unlocks_capability_id": CAPABILITY_ID,
        "target_gate_id": GATE_ID,
        "build_phase": "night_debrief",
    }]


def zones() -> list[dict]:
    return [
        {
            "id": GATE_ID,
            "type": "marker",
            "x": 53,
            "y": 57,
            "w": 3,
            "h": 4,
            "current_gate": True,
            "current_direction": "left",
            "current_strength": 3.2,
            "required_capability_id": CAPABILITY_ID,
            "current_gate_label": "Ripping relay current",
            "current_affordance_role": "relay",
            "route_context": ROUTE_ID,
        },
        {
            "id": LANDMARK_ID,
            "type": "marker",
            "x": 56,
            "y": 57,
            "w": 5,
            "h": 4,
            "regional_landmark": True,
            "regional_journey_id": ROUTE_ID,
            "landmark_label": "Northwest Wreck Relay",
        },
    ]


def regional_journeys() -> list[dict]:
    return [{
        "id": ROUTE_ID,
        "route_label": "Northwest wreck relay route",
        "promise_gate_id": PROMISE_ID,
        "entry_gate_ids": [GATE_ID],
        "required_capability_id": CAPABILITY_ID,
        "required_discovery_id": ARCHIVE_DISCOVERY_ID,
        "landmark_zone_id": LANDMARK_ID,
        "payoff_target_id": CORE_ID,
        "survey_target_id": SURVEY_ID,
        "commit_entry_id": BOAT_ID,
        "route_context": ROUTE_ID,
        "intent": "Turn the archive clue and night-built stabilizer into one return journey.",
    }]


def entities() -> list[dict]:
    return [{
        "id": CORE_ID,
        "type": "salvage",
        "x": 58,
        "y": 60,
        "kind": "relic",
        "tier": "valuable",
        "route_context": ROUTE_ID,
        "intent": "Normal valuable cargo payoff inside the earned relay pocket.",
    }]


def survey_targets() -> list[dict]:
    return [{
        "id": SURVEY_ID,
        "target_type": "regional",
        "x": 59,
        "y": 58,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "required_route_id": ROUTE_ID,
        "route_context": ROUTE_ID,
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey wreck relay",
        "clue_label": "Relay signal | Scanner survey available",
        "finding_label": "Discovery logged: Northwest wreck relay",
        "next_lead_label": "Next lead: deeper wreck relay still transmitting",
        "scan_subject_kind": "environment",
        "scan_subject_id": "northwest_wreck_relay_console",
        "scan_subject_label": "Wreck relay console",
        "scan_subject_description": "Damaged relay still transmitting",
        "scan_presentation_id": "northwest_wreck_relay_console",
        "scan_anchor": {"x": 59, "y": 58},
        "scan_reward_kind": "discovery",
        "scan_reward_id": DISCOVERY_ID,
        "discovery_id": DISCOVERY_ID,
        "commit_map_id": "production_level_01",
        "commit_map_path": "res://maps/production_level_01.greybox.json",
        "commit_entry_id": BOAT_ID,
        "intent": "Keep the relay finding pending until canonical boat return.",
    }]


def background() -> list[dict]:
    return [{
        "id": BACKGROUND_ID,
        "type": "background",
        "x": 56,
        "y": 57,
        "w": 5,
        "h": 4,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
        "intent": "Non-collision silhouette for the isolated relay pocket.",
    }]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_14_archive_project_promise",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Archive result and Current Stabilizer night-project promise at the boat.",
        },
        {
            "id": "expansion_14_pre_stabilizer_current",
            "center_x": 54.5,
            "center_y": 59.0,
            "zoom": 0.72,
            "intent": "Visible upper-left relay current blocking an unequipped diver.",
        },
        {
            "id": "expansion_14_post_stabilizer_current",
            "center_x": 54.5,
            "center_y": 59.0,
            "zoom": 0.72,
            "intent": "The same current boundary during passive equipped traversal.",
        },
        {
            "id": "expansion_14_wreck_relay_arrival",
            "center_x": 58.5,
            "center_y": 59.0,
            "zoom": 0.72,
            "intent": "Relay landmark, valuable core, survey, and held-cargo context.",
        },
        {
            "id": "expansion_14_relay_survey",
            "center_x": 59.5,
            "center_y": 59.0,
            "zoom": 0.78,
            "intent": "Explicit scanner progress at the Northwest Wreck Relay.",
        },
        {
            "id": "expansion_14_pending_boat_return",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Held relay cargo and pending discovery returning to the canonical boat.",
        },
    ]


def review_questions() -> list[str]:
    return [
        "Does the archive clearly promise one night-built Current Stabilizer return?",
        "Does the same visible current read as blocked before and swimmable after ownership?",
        "Is the Northwest Wreck Relay recognizable without terrain or collision changes?",
        "Do the valuable core and scanner finding justify the direct return to the boat?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_14.py",
        "project_ids": [PROJECT_ID],
        "journey_ids": [ROUTE_ID],
        "zone_ids": [GATE_ID, LANDMARK_ID],
        "entity_ids": [CORE_ID],
        "survey_target_ids": [SURVEY_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "intent": "Source-authored archive-current return metadata in existing open water.",
    }
