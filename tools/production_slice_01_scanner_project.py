#!/usr/bin/env python3
"""Scanner blueprint and night-project source records for production slice 01."""

from __future__ import annotations


SCANNER_BLUEPRINT_ID = "survey_scanner_blueprint"


def scanner_blueprint_container() -> dict:
    return {
        "id": "east_current_scanner_blueprint_chest",
        "container_type": "upgrade_chest",
        "x": 67,
        "y": 40,
        "w": 2,
        "h": 2,
        "display_label": "Scanner blueprint chest",
        "interaction": "interact",
        "reward_type": "blueprint",
        "reward_id": SCANNER_BLUEPRINT_ID,
        "reward_label": "Survey scanner",
        "route_context": "upper_right_current_pocket",
        "intent": "Guaranteed post-fins plan that reveals the survey-scanner recipe.",
    }


def scanner_project() -> dict:
    return {
        "id": "survey_scanner_project",
        "required_discovery_id": SCANNER_BLUEPRINT_ID,
        "required_materials": {
            "titanium_scrap": 1,
            "conductive_coil": 1,
        },
        "unlocks_capability_id": "survey_scanner_1",
        "target_id": "lower_right_anomaly_survey",
        "build_phase": "night_debrief",
        "project_label": "Survey scanner project",
        "completion_label": "Survey scanner built",
    }
