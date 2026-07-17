#!/usr/bin/env python3
"""Focused full-level source override for the cutter blueprint artifact."""

from __future__ import annotations

from copy import deepcopy


TARGET_ID = "lower_right_anomaly_survey"

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
    "intent": (
        "Partially concealed wreck maintenance case beyond the existing east current; "
        "its explicit blueprint reward replaces the abstract cutter-plan signal."
    ),
}


def source_overrides() -> dict[tuple[str, str], dict]:
    return {("survey_targets", TARGET_ID): deepcopy(_TARGET_OVERRIDE)}
