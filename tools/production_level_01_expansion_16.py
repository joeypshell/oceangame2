#!/usr/bin/env python3
"""Source-owned deeper-wreck oxygen return records for Expansion 16."""

from __future__ import annotations

from typing import Any, Callable


KNOWLEDGE_ID = "upper_left_wreck_relay_discovery"
PROMISE_ID = "upper_left_wreck_relay_landmark"
PROJECT_ID = "closed_circuit_rebreather_project"
CAPABILITY_ID = "closed_circuit_rebreather"
ROUTE_ID = "far_west_deeper_wreck_route"
ZONE_ID = "far_west_confined_wreck_oxygen_zone"
LANDMARK_ID = "far_west_deeper_wreck_landmark"
BACKGROUND_ID = "far_west_deeper_wreck_backdrop"
TOOL_TARGET_ID = "far_west_wreck_data_recorder"
SURVEY_ID = "far_west_deeper_wreck_survey"
DISCOVERY_ID = "far_west_deeper_wreck_discovery"
BOAT_ID = "surface_boat_entry"


def material_projects() -> list[dict]:
    return [{
        "id": PROJECT_ID,
        "required_discovery_id": KNOWLEDGE_ID,
        "required_materials": {
            "titanium_scrap": 1,
            "rubber_sheet": 1,
            "conductive_coil": 1,
            "insulating_gel": 1,
        },
        "unlocks_capability_id": CAPABILITY_ID,
        "target_id": ZONE_ID,
        "build_phase": "night_debrief",
        "project_label": "Closed-circuit rebreather",
        "completion_label": "Rebreather built",
    }]


def zones() -> list[dict]:
    return [
        {
            "id": ZONE_ID,
            "type": "marker",
            "x": 12,
            "y": 90,
            "w": 21,
            "h": 16,
            "oxygen_consumption_zone": True,
            "oxygen_consumption_label": "Confined wreck air",
            "required_capability_id": CAPABILITY_ID,
            "warning_grace_seconds": 1.0,
            "unprotected_oxygen_drain_multiplier": 8.0,
            "route_context": ROUTE_ID,
            "intent": (
                "Accelerate oxygen only inside the far-west confined-wreck approach "
                "while preserving ordinary swimming and retreat."
            ),
        },
        {
            "id": LANDMARK_ID,
            "type": "marker",
            "x": 15,
            "y": 93,
            "w": 7,
            "h": 5,
            "regional_landmark": True,
            "regional_journey_id": ROUTE_ID,
            "landmark_label": "Far-West Deeper Wreck",
        },
    ]


def entities() -> list[dict]:
    return [{
        "id": TOOL_TARGET_ID,
        "type": "tool_target",
        "x": 16,
        "y": 96,
        "kind": "crate",
        "tier": "valuable",
        "interaction": "cutter_salvage",
        "interaction_seconds": 2.0,
        "interaction_label": "wreck data recorder",
        "required_tool_id": "salvage_cutter",
        "tool_project_id": "salvage_cutter_project",
        "unlocks_survey_target_id": SURVEY_ID,
        "durable_clearance": True,
        "intent": "Cutter-opened recorder whose clearance exposes the deeper-wreck survey.",
    }]


def regional_journeys() -> list[dict]:
    return [{
        "id": ROUTE_ID,
        "route_label": "Far-west deeper wreck route",
        "promise_gate_id": PROMISE_ID,
        "entry_gate_ids": [ZONE_ID],
        "required_capability_id": CAPABILITY_ID,
        "required_discovery_id": KNOWLEDGE_ID,
        "landmark_zone_id": LANDMARK_ID,
        "tool_target_id": TOOL_TARGET_ID,
        "survey_target_id": SURVEY_ID,
        "commit_entry_id": BOAT_ID,
        "route_context": ROUTE_ID,
        "intent": (
            "Turn the committed relay signal and night-built rebreather into one "
            "continuous far-west wreck operation and canonical-boat return."
        ),
    }]


def survey_targets() -> list[dict]:
    return [{
        "id": SURVEY_ID,
        "target_type": "regional",
        "x": 15,
        "y": 95,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "required_route_id": ROUTE_ID,
        "route_context": ROUTE_ID,
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey deeper wreck recorder",
        "clue_label": "Deeper wreck recorder | Cutter access required",
        "finding_label": "Discovery logged: Far-west wreck network",
        "next_lead_label": "Next lead: deeper wreck network unresolved",
        "discovery_id": DISCOVERY_ID,
        "commit_map_id": "production_level_01",
        "commit_map_path": "res://maps/production_level_01.greybox.json",
        "commit_entry_id": BOAT_ID,
        "scan_subject_kind": "artifact",
        "scan_subject_id": "far_west_wreck_network_recorder",
        "scan_subject_label": "Deep-wreck network recorder",
        "scan_subject_description": "Pressure-damaged route index",
        "scan_presentation_id": "far_west_wreck_data_recorder",
        "scan_anchor": {"x": 16, "y": 96},
        "scan_reward_kind": "discovery",
        "scan_reward_id": DISCOVERY_ID,
        "intent": "Keep the recorder finding pending until the canonical boat return.",
    }]


def background() -> list[dict]:
    return [{
        "id": BACKGROUND_ID,
        "type": "background",
        "x": 15,
        "y": 93,
        "w": 7,
        "h": 5,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
        "intent": "Distinct non-collision wreck silhouette in the existing far-west chamber.",
    }]


def camera_tests() -> list[dict]:
    return [
        {
            "id": "expansion_16_rebreather_project",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Canonical-boat night project and ingredient review.",
        },
        {
            "id": "expansion_16_oxygen_threshold",
            "center_x": 30.0,
            "center_y": 96.0,
            "zoom": 0.42,
            "intent": "Scoutable confined-wreck threshold and continuous retreat route.",
        },
        {
            "id": "expansion_16_unprotected_retreat",
            "center_x": 25.0,
            "center_y": 96.0,
            "zoom": 0.48,
            "intent": "Readable accelerated oxygen pressure before rebreather ownership.",
        },
        {
            "id": "expansion_16_deeper_wreck_arrival",
            "center_x": 16.0,
            "center_y": 96.0,
            "zoom": 0.55,
            "intent": "Rebreather-protected arrival at the far-west wreck landmark.",
        },
        {
            "id": "expansion_16_recorder_cut",
            "center_x": 16.0,
            "center_y": 96.0,
            "zoom": 0.72,
            "intent": "Explicit selected-cutter interaction at the data recorder.",
        },
        {
            "id": "expansion_16_recorder_survey",
            "center_x": 16.0,
            "center_y": 96.0,
            "zoom": 0.72,
            "intent": "Held scanner progress after durable recorder clearance.",
        },
        {
            "id": "expansion_16_pending_boat_return",
            "center_x": 95.0,
            "center_y": 12.0,
            "zoom": 0.55,
            "intent": "Pending far-west discovery returning to the canonical boat.",
        },
    ]


def review_questions() -> list[str]:
    return [
        "Can the confined-wreck threshold be scouted and safely retreated from before the rebreather?",
        "Does the night recipe clearly answer the relay's far-west oxygen limitation?",
        "Does protected travel preserve ordinary oxygen pressure and remembered geography?",
        "Are cutter, scanner, pending finding, and canonical-boat commitment each distinct?",
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_expansion_16.py",
        "project_ids": [PROJECT_ID],
        "journey_ids": [ROUTE_ID],
        "zone_ids": [ZONE_ID, LANDMARK_ID],
        "entity_ids": [TOOL_TARGET_ID],
        "survey_target_ids": [SURVEY_ID],
        "camera_test_ids": [item["id"] for item in camera_tests()],
        "terrain_changes": [],
        "review_bounds": {"x": 12, "y": 90, "w": 21, "h": 32},
        "intent": "Source-authored oxygen return metadata in existing continuous water.",
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
        str(item.get("id", "")) for item in additions if item.get("id") in existing_ids
    )
    if duplicate_ids:
        raise ValueError(f"Expansion 16 duplicate {collection} ids: {duplicate_ids}.")
    records.extend(additions)


def author(map_data: dict[str, Any]) -> dict[str, Any]:
    """Append the bounded records without touching topology or prior sources."""
    for collection, factory in (
        ("zones", zones),
        ("regional_journeys", regional_journeys),
        ("survey_targets", survey_targets),
        ("material_projects", material_projects),
        ("background", background),
        ("entities", entities),
        ("camera_tests", camera_tests),
    ):
        _append_unique(map_data, collection, factory)
    questions = map_data.get("review_questions")
    if not isinstance(questions, list):
        raise ValueError("Expected review_questions to be a list.")
    questions.extend(review_questions())
    source = map_data.get("source")
    if not isinstance(source, dict) or "expansion_16" in source:
        raise ValueError("Expected source without existing expansion_16 provenance.")
    source["expansion_16"] = source_provenance()
    return map_data
