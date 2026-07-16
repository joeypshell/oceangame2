#!/usr/bin/env python3
"""Source-owned Southeast Wreck Return records for Expansion 13."""

from __future__ import annotations


KNOWLEDGE_ID = "abyssal_basin_harmonic_source_discovery"
ROUTE_ID = "southeast_wreck_archive_route"
PRESSURE_ZONE_ID = "abyssal_basin_pressure_zone"
PROMISE_LANDMARK_ID = "abyssal_basin_landmark"
LANDMARK_ID = "southeast_wreck_archive_landmark"
BACKGROUND_ID = "southeast_wreck_archive_backdrop"
RECORDER_ID = "southeast_wreck_recorder"
SURVEY_ID = "southeast_wreck_archive_survey"
DISCOVERY_ID = "southeast_wreck_archive_discovery"
BOAT_ID = "surface_boat_entry"


def zones() -> list[dict]:
    return [{
        "id": LANDMARK_ID,
        "type": "marker",
        "x": 146,
        "y": 143,
        "w": 5,
        "h": 9,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
        "landmark_label": "Southeast Wreck Archive",
    }]


def entities() -> list[dict]:
    return [{
        "id": RECORDER_ID,
        "type": "tool_target",
        "x": 147,
        "y": 149,
        "kind": "crate",
        "tier": "valuable",
        "interaction": "cutter_salvage",
        "interaction_seconds": 2.0,
        "interaction_label": "wreck recorder",
        "required_tool_id": "salvage_cutter",
        "tool_project_id": "salvage_cutter_project",
        "unlocks_survey_target_id": SURVEY_ID,
        "durable_clearance": True,
        "intent": "Cutter-opened recorder whose clearance exposes the archive survey.",
    }]


def regional_journeys() -> list[dict]:
    return [{
        "id": ROUTE_ID,
        "route_label": "Southeast wreck archive route",
        "promise_gate_id": PROMISE_LANDMARK_ID,
        "entry_gate_ids": [PRESSURE_ZONE_ID],
        "required_capability_id": "pressure_suit_1",
        "required_discovery_id": KNOWLEDGE_ID,
        "landmark_zone_id": LANDMARK_ID,
        "tool_target_id": RECORDER_ID,
        "survey_target_id": SURVEY_ID,
        "commit_entry_id": BOAT_ID,
        "route_context": ROUTE_ID,
        "intent": (
            "Reuse the pressure-protected lower route for one distant cutter and "
            "scanner chain that returns to the canonical boat."
        ),
    }]


def survey_targets() -> list[dict]:
    return [{
        "id": SURVEY_ID,
        "target_type": "regional",
        "x": 149,
        "y": 149,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "required_pressure_capability_id": "pressure_suit_1",
        "required_route_id": ROUTE_ID,
        "route_context": ROUTE_ID,
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey wreck archive",
        "clue_label": "Wreck archive | Recorder access required",
        "finding_label": "Discovery logged: Southeast wreck archive",
        "next_lead_label": "Next lead: distant wreck network unresolved",
        "discovery_id": DISCOVERY_ID,
        "commit_map_id": "production_level_01",
        "commit_map_path": "res://maps/production_level_01.greybox.json",
        "commit_entry_id": BOAT_ID,
        "intent": "Keep the archive finding pending until the canonical boat return.",
    }]


def background() -> list[dict]:
    return [{
        "id": BACKGROUND_ID,
        "type": "background",
        "x": 146,
        "y": 143,
        "w": 5,
        "h": 9,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
        "intent": "Distinct non-collision archive silhouette in the far southeast chamber.",
    }]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_13_wreck_promise",
            "center_x": 105.0,
            "center_y": 146.0,
            "zoom": 0.28,
            "intent": "Broad abyssal-to-southeast route promise without an exact path marker.",
        },
        {
            "id": "expansion_13_wreck_arrival",
            "center_x": 148.0,
            "center_y": 147.0,
            "zoom": 0.55,
            "intent": "Distinct wreck-archive arrival in unchanged continuous water.",
        },
        {
            "id": "expansion_13_recorder_cut",
            "center_x": 147.5,
            "center_y": 149.5,
            "zoom": 0.72,
            "intent": "Readable cutter interaction and recorder cargo state.",
        },
        {
            "id": "expansion_13_archive_survey",
            "center_x": 149.5,
            "center_y": 149.5,
            "zoom": 0.72,
            "intent": "Explicit scanner progress after recorder clearance.",
        },
        {
            "id": "expansion_13_pending_boat_return",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Recorder cargo and pending archive finding returning to the boat.",
        },
    ]


def review_questions() -> list[str]:
    return [
        "Does the prior abyssal finding create a broad southeast wreck promise?",
        "Is the archive a distinct destination without changing terrain?",
        "Do cutter clearance and explicit scanner activation read as one chain?",
        "Does the recorder and pending finding return feel tense but base-tank viable?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_13.py",
        "journey_ids": [ROUTE_ID],
        "zone_ids": [LANDMARK_ID],
        "entity_ids": [RECORDER_ID],
        "survey_target_ids": [SURVEY_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "intent": "Source-authored wreck return metadata in existing southeast open water.",
    }
