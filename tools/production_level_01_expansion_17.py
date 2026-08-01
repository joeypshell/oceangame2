#!/usr/bin/env python3
"""Source-owned wreck-network triangulation records for Expansion 17."""

from __future__ import annotations

from typing import Any, Callable


INVESTIGATION_ID = "wreck_network_triangulation"
PREREQUISITE_ID = "far_west_deeper_wreck_discovery"
FINAL_DISCOVERY_ID = "wreck_network_triangulation_discovery"
PROMISE_ID = "far_west_deeper_wreck_landmark"
BOAT_ID = "surface_boat_entry"

WEST_JOURNEY_ID = "western_chasm_wreck_fragment_journey"
WEST_GATE_ID = "western_chasm_relay_current"
WEST_LANDMARK_ID = "western_chasm_relay_landmark"
WEST_BACKGROUND_ID = "western_chasm_relay_backdrop"
WEST_ARTIFACT_ID = "western_chasm_relay_artifact"
WEST_SURVEY_ID = "western_chasm_wreck_fragment_survey"
WEST_DISCOVERY_ID = "western_chasm_wreck_fragment_discovery"

ABYSS_JOURNEY_ID = "abyssal_shelf_wreck_fragment_journey"
ABYSS_GATE_ID = "abyssal_shelf_pressure_seam"
ABYSS_LANDMARK_ID = "abyssal_shelf_relay_landmark"
ABYSS_BACKGROUND_ID = "abyssal_shelf_relay_backdrop"
ABYSS_ARTIFACT_ID = "abyssal_shelf_relay_artifact"
ABYSS_SURVEY_ID = "abyssal_shelf_wreck_fragment_survey"
ABYSS_DISCOVERY_ID = "abyssal_shelf_wreck_fragment_discovery"


def investigations() -> list[dict]:
    return [{
        "id": INVESTIGATION_ID,
        "required_discovery_id": PREREQUISITE_ID,
        "fragment_discovery_ids": [WEST_DISCOVERY_ID, ABYSS_DISCOVERY_ID],
        "analysis_discovery_id": FINAL_DISCOVERY_ID,
        "analysis_phase": "night_debrief",
        "analysis_label": "Triangulate wreck network",
        "analysis_result_label": "Wreck network triangulated",
        "next_lead_label": "Next lead: transfer hub beyond mapped cave",
        "commit_map_id": "production_level_01",
        "commit_entry_id": BOAT_ID,
    }]


def zones() -> list[dict]:
    return [
        {
            "id": WEST_GATE_ID,
            "type": "marker",
            "x": 24,
            "y": 119,
            "w": 1,
            "h": 3,
            "current_gate": True,
            "current_direction": "right",
            "current_strength": 3.2,
            "required_capability_id": "current_stabilizer",
            "current_gate_label": "Western chasm current",
            "current_affordance_role": "relay",
            "route_context": WEST_JOURNEY_ID,
            "intent": "Close the sole player-footprint seam into the lower-left relay pocket.",
        },
        {
            "id": WEST_LANDMARK_ID,
            "type": "marker",
            "x": 19,
            "y": 119,
            "w": 5,
            "h": 2,
            "regional_landmark": True,
            "regional_journey_id": WEST_JOURNEY_ID,
            "landmark_label": "Western Chasm Relay",
        },
        {
            "id": ABYSS_GATE_ID,
            "type": "marker",
            "x": 114,
            "y": 147,
            "w": 1,
            "h": 3,
            "pressure_zone": True,
            "pressure_level": "abyssal",
            "pressure_label": "Abyssal shelf pressure",
            "required_capability_id": "pressure_suit_1",
            "warning_grace_seconds": 1.0,
            "unprotected_oxygen_drain_multiplier": 8.0,
            "route_context": ABYSS_JOURNEY_ID,
            "intent": "Name the existing pressure-basin seam into the eastern abyssal shelf.",
        },
        {
            "id": ABYSS_LANDMARK_ID,
            "type": "marker",
            "x": 120,
            "y": 147,
            "w": 8,
            "h": 3,
            "regional_landmark": True,
            "regional_journey_id": ABYSS_JOURNEY_ID,
            "landmark_label": "Abyssal Shelf Relay",
        },
    ]


def regional_journeys() -> list[dict]:
    return [
        {
            "id": WEST_JOURNEY_ID,
            "route_label": "Western chasm relay route",
            "promise_gate_id": PROMISE_ID,
            "entry_gate_ids": [WEST_GATE_ID],
            "required_capability_id": "current_stabilizer",
            "required_discovery_id": PREREQUISITE_ID,
            "landmark_zone_id": WEST_LANDMARK_ID,
            "survey_target_id": WEST_SURVEY_ID,
            "commit_entry_id": BOAT_ID,
            "route_context": WEST_JOURNEY_ID,
            "approach_guidance": "Western chasm | Search the lower-left rock loop",
            "expedition_lead": {
                "lead_type": "regional_journey",
                "label": "Western Chasm Relay",
                "summary": "MAIN INVESTIGATION | Stabilizer route | Relay fragment",
                "active_guidance": "Plan: Trace the western chasm relay",
                "order": 30,
            },
            "intent": "Use the existing stabilizer to reach one physical relay fragment.",
        },
        {
            "id": ABYSS_JOURNEY_ID,
            "route_label": "Abyssal shelf relay route",
            "promise_gate_id": PROMISE_ID,
            "entry_gate_ids": [ABYSS_GATE_ID],
            "required_capability_id": "pressure_suit_1",
            "required_discovery_id": PREREQUISITE_ID,
            "landmark_zone_id": ABYSS_LANDMARK_ID,
            "survey_target_id": ABYSS_SURVEY_ID,
            "commit_entry_id": BOAT_ID,
            "route_context": ABYSS_JOURNEY_ID,
            "approach_guidance": "Abyssal shelf | Search east through the pressure basin",
            "expedition_lead": {
                "lead_type": "regional_journey",
                "label": "Abyssal Shelf Relay",
                "summary": "MAIN INVESTIGATION | Pressure suit route | Relay fragment",
                "active_guidance": "Plan: Search the abyssal shelf wreckage",
                "order": 40,
            },
            "intent": "Use the existing pressure suit to reach the second physical relay fragment.",
        },
    ]


def survey_targets() -> list[dict]:
    return [
        {
            "id": WEST_SURVEY_ID,
            "investigation_id": INVESTIGATION_ID,
            "target_type": "regional",
            "x": 20,
            "y": 119,
            "w": 2,
            "h": 2,
            "required_capability_id": "survey_scanner_1",
            "required_route_id": WEST_JOURNEY_ID,
            "route_context": WEST_JOURNEY_ID,
            "interaction": "survey",
            "interaction_seconds": 3.0,
            "interaction_label": "Survey western relay",
            "clue_label": "Western relay | Fragment signal detected",
            "finding_label": "Discovery logged: Western wreck fragment",
            "next_lead_label": "Wreck network | Second fragment unresolved",
            "discovery_id": WEST_DISCOVERY_ID,
            "commit_map_id": "production_level_01",
            "commit_map_path": "res://maps/production_level_01.greybox.json",
            "commit_entry_id": BOAT_ID,
            "scan_subject_kind": "artifact",
            "scan_subject_id": WEST_ARTIFACT_ID,
            "scan_subject_label": "Western wreck relay",
            "scan_subject_description": "Current-worn network fragment",
            "scan_presentation_id": "northwest_wreck_relay_console",
            "scan_anchor": {"x": 21, "y": 120},
            "scan_reward_kind": "discovery",
            "scan_reward_id": WEST_DISCOVERY_ID,
            "intent": "Create one pending fragment without depending on selected-lead state.",
        },
        {
            "id": ABYSS_SURVEY_ID,
            "investigation_id": INVESTIGATION_ID,
            "target_type": "regional",
            "x": 124,
            "y": 147,
            "w": 2,
            "h": 2,
            "required_capability_id": "survey_scanner_1",
            "required_pressure_capability_id": "pressure_suit_1",
            "required_route_id": ABYSS_JOURNEY_ID,
            "route_context": ABYSS_JOURNEY_ID,
            "interaction": "survey",
            "interaction_seconds": 3.0,
            "interaction_label": "Survey abyssal relay",
            "clue_label": "Abyssal relay | Fragment signal detected",
            "finding_label": "Discovery logged: Abyssal wreck fragment",
            "next_lead_label": "Wreck network | Second fragment unresolved",
            "discovery_id": ABYSS_DISCOVERY_ID,
            "commit_map_id": "production_level_01",
            "commit_map_path": "res://maps/production_level_01.greybox.json",
            "commit_entry_id": BOAT_ID,
            "scan_subject_kind": "artifact",
            "scan_subject_id": ABYSS_ARTIFACT_ID,
            "scan_subject_label": "Abyssal wreck relay",
            "scan_subject_description": "Pressure-scored network fragment",
            "scan_presentation_id": "northwest_wreck_relay_console",
            "scan_anchor": {"x": 125, "y": 148},
            "scan_reward_kind": "discovery",
            "scan_reward_id": ABYSS_DISCOVERY_ID,
            "intent": "Create the parallel pending fragment regardless of lead selection.",
        },
    ]


def background() -> list[dict]:
    return [
        {
            "id": WEST_BACKGROUND_ID,
            "type": "background",
            "x": 19,
            "y": 119,
            "w": 5,
            "h": 2,
            "regional_landmark": True,
            "regional_journey_id": WEST_JOURNEY_ID,
            "intent": "Non-collision wreckage silhouette around the western relay artifact.",
        },
        {
            "id": ABYSS_BACKGROUND_ID,
            "type": "background",
            "x": 120,
            "y": 147,
            "w": 8,
            "h": 3,
            "regional_landmark": True,
            "regional_journey_id": ABYSS_JOURNEY_ID,
            "intent": "Non-collision wreckage silhouette around the abyssal relay artifact.",
        },
    ]


def camera_tests() -> list[dict]:
    return [
        {"id": "expansion_17_parallel_leads", "center_x": 95.0, "center_y": 12.0, "zoom": 0.55, "intent": "Two broad unresolved fragment leads after the far-west boat commit."},
        {"id": "expansion_17_western_approach", "center_x": 27.0, "center_y": 120.0, "zoom": 0.48, "intent": "Stabilizer seam and recognizable lower-left relay pocket."},
        {"id": "expansion_17_western_scan", "center_x": 21.0, "center_y": 120.0, "zoom": 0.72, "intent": "Held scanner progress on the western physical relay."},
        {"id": "expansion_17_abyssal_approach", "center_x": 117.0, "center_y": 148.0, "zoom": 0.45, "intent": "Pressure-basin shelf seam and continuous return context."},
        {"id": "expansion_17_abyssal_scan", "center_x": 125.0, "center_y": 148.0, "zoom": 0.72, "intent": "Held scanner progress on the abyssal physical relay."},
        {"id": "expansion_17_analysis_ready", "center_x": 95.0, "center_y": 12.0, "zoom": 0.55, "intent": "Both committed fragments and explicit night-analysis prompt."},
    ]


def review_questions() -> list[str]:
    return [
        "Do the western-current and abyssal-pressure routes feel physically different?",
        "Are both relay artifacts recognizable without exact route-line guidance?",
        "Can either lead be followed first without hiding or invalidating the other target?",
        "Do both fragment routes preserve a collision-active return to the canonical boat?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_17.py",
        "investigation_ids": [INVESTIGATION_ID],
        "journey_ids": [WEST_JOURNEY_ID, ABYSS_JOURNEY_ID],
        "zone_ids": [WEST_GATE_ID, WEST_LANDMARK_ID, ABYSS_GATE_ID, ABYSS_LANDMARK_ID],
        "artifact_ids": [WEST_ARTIFACT_ID, ABYSS_ARTIFACT_ID],
        "survey_target_ids": [WEST_SURVEY_ID, ABYSS_SURVEY_ID],
        "background_ids": [WEST_BACKGROUND_ID, ABYSS_BACKGROUND_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "review_bounds": {"x": 19, "y": 119, "w": 109, "h": 31},
        "intent": "Two source-authored physical relay leads in existing continuous water.",
    }


def _append_unique(map_data: dict[str, Any], collection: str, factory: Callable[[], list[dict]]) -> None:
    records = map_data.get(collection)
    if not isinstance(records, list):
        raise ValueError(f"Expected {collection} to be a list.")
    additions = factory()
    existing_ids = {str(item.get("id", "")) for item in records if isinstance(item, dict)}
    duplicate_ids = sorted(str(item.get("id", "")) for item in additions if item.get("id") in existing_ids)
    if duplicate_ids:
        raise ValueError(f"Expansion 17 duplicate {collection} ids: {duplicate_ids}.")
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append the bounded records without touching topology or prior sources."""
    if "wreck_network_investigations" in map_data:
        raise ValueError("Expected map without existing wreck_network_investigations.")
    map_data["wreck_network_investigations"] = investigations()
    for collection, factory in (
        ("zones", zones),
        ("regional_journeys", regional_journeys),
        ("survey_targets", survey_targets),
        ("background", background),
        ("camera_tests", camera_tests),
    ):
        _append_unique(map_data, collection, factory)
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "expansion_17" in source:
        raise ValueError("Expected source without existing expansion_17 provenance.")
    source["expansion_17"] = source_provenance()
    return map_data
