#!/usr/bin/env python3
"""Compose bounded expansion source records for production slice 01."""

from __future__ import annotations

from production_slice_01_expansion_03 import (
    expansion_03_entities,
    material_candidate_pools as expansion_03_material_candidate_pools,
    material_projects as expansion_03_projects,
)
from production_slice_01_expansion_04 import expansion_04_entities, expansion_04_projects, expansion_04_zones
from production_slice_01_expansion_05 import apply_expansion_05_material_research, expansion_05_survey_targets
from production_slice_01_expansion_06 import expansion_06_hostile_encounters, expansion_06_projects


def material_candidate_pools() -> list[dict]:
    return apply_expansion_05_material_research(expansion_03_material_candidate_pools())


def material_projects() -> list[dict]:
    return [*expansion_03_projects(), *expansion_04_projects(), *expansion_06_projects()]


def hostile_encounters() -> list[dict]:
    return expansion_06_hostile_encounters()


def expansion_entities() -> list[dict]:
    return [*expansion_03_entities(), *expansion_04_entities()]


def expansion_zones() -> list[dict]:
    return [_legacy_lower_left_current_gate(), *expansion_04_zones()]


def expansion_survey_targets() -> list[dict]:
    return expansion_05_survey_targets()


def _legacy_lower_left_current_gate() -> dict:
    return {
        "id": "lower_left_loop_current",
        "type": "marker",
        "x": 2,
        "y": 74,
        "w": 4,
        "h": 4,
        "current_gate": True,
        "current_direction": "right",
        "current_strength": 2.2,
        "required_upgrade_id": "propulsion_fins",
        "current_gate_label": "Strong current",
        "route_context": "lower_left_loop",
        "intent": (
            "Progression-gate soft-push current on the lower-left connector until the propulsion fins session upgrade is owned."
        ),
    }
