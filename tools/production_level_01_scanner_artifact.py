#!/usr/bin/env python3
"""Focused full-level source override for the scanner-to-cutter journey."""

from __future__ import annotations

from copy import deepcopy


TARGET_ID = "lower_right_anomaly_survey"
PROJECT_ID = "salvage_cutter_project"
PAYOFF_TARGET_ID = "salvage_sealed_wreck_cache"
JOURNEY_ID = "scanner_cutter_first_return"

_TARGET_OVERRIDE = {
    "interaction_label": "Scan maintenance case",
    "clue_label": "Maintenance echo | Concealed wreck case",
    "finding_label": "Blueprint recovered: Salvage cutter",
    "scan_subject_kind": "artifact",
    "scan_subject_id": "salvage_cutter_maintenance_case",
    "scan_presentation_id": "salvage_cutter_blueprint_case",
    "scan_anchor": {"x": 68, "y": 44},
    "scan_reward_kind": "blueprint",
    "scan_reward_id": "salvage_cutter_blueprint",
    "journey_id": JOURNEY_ID,
    "journey_role": "blueprint_artifact",
    "journey_lead_label": "Maintenance signal | Beyond east current",
    "intent": (
        "Partially concealed wreck maintenance case beyond the existing east current; "
        "its explicit blueprint reward replaces the abstract cutter-plan signal."
    ),
}

_PAYOFF_OVERRIDE = {
    "journey_id": JOURNEY_ID,
    "journey_role": "sealed_payoff",
    "return_lead_label": "Cutter ready | Return beyond east current to sealed wreck",
    "payoff_label": "Sealed wreck opened",
    "next_mystery_label": "Faint maintenance signal continues deeper southeast",
}


def source_overrides() -> dict[tuple[str, str], dict]:
    return {
        ("survey_targets", TARGET_ID): deepcopy(_TARGET_OVERRIDE),
        ("entities", PAYOFF_TARGET_ID): deepcopy(_PAYOFF_OVERRIDE),
        ("material_projects", PROJECT_ID): {
            "required_discovery_id": "salvage_cutter_blueprint",
        },
    }
