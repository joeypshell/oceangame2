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
from production_slice_01_expansion_07 import expansion_07_biological_resource_sources, expansion_07_projects
from production_slice_01_player_gate_correction import (
    lower_left_current_gate,
    propulsion_blueprint_container,
    propulsion_material_entities,
    propulsion_material_pool,
    propulsion_project,
)


def progression_containers() -> list[dict]:
    return [propulsion_blueprint_container()]


def material_candidate_pools() -> list[dict]:
    pools = [*expansion_03_material_candidate_pools(), propulsion_material_pool()]
    return apply_expansion_05_material_research(pools)


def material_projects() -> list[dict]:
    return [
        propulsion_project(),
        *expansion_03_projects(),
        *expansion_06_projects(),
        *expansion_07_projects(),
        *expansion_04_projects(),
    ]


def biological_resource_sources() -> list[dict]:
    return expansion_07_biological_resource_sources()


def hostile_encounters() -> list[dict]:
    return expansion_06_hostile_encounters()


def expansion_entities() -> list[dict]:
    return [*expansion_03_entities(), *propulsion_material_entities(), *expansion_04_entities()]


def expansion_zones() -> list[dict]:
    return [lower_left_current_gate(), *expansion_04_zones()]


def expansion_survey_targets() -> list[dict]:
    return expansion_05_survey_targets()
