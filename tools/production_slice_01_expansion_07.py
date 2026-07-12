#!/usr/bin/env python3
"""Expansion 07 biological-resource source records for production slice 01."""

from __future__ import annotations


def expansion_07_biological_resource_sources() -> list[dict]:
    return [
        {
            "id": "upper_right_glow_anemone_sample",
            "source_role": "passive_sample",
            "organism_kind": "glow_anemone",
            "x": 68,
            "y": 46,
            "required_capability_id": "survey_scanner_1",
            "interaction": "timed_sample",
            "interaction_seconds": 1.5,
            "material_id": "insulating_gel",
            "material_quantity": 1,
            "replenishment": "new_day",
            "display_label": "Glow anemone",
            "interaction_label": "Sampling glow anemone",
            "collected_label": "Insulating gel held",
            "route_context": "upper_right_current_pocket",
            "intent": "One nonlethal biological sample beyond the remembered current gate.",
        },
        {
            "id": "deep_cache_eel_electrocyte_harvest",
            "source_role": "hostile_harvest",
            "organism_kind": "territorial_eel",
            "hostile_id": "deep_cache_territorial_eel",
            "interaction": "post_defeat_harvest",
            "interaction_seconds": 1.5,
            "material_id": "eel_electrocyte",
            "material_quantity": 1,
            "replenishment": "new_day",
            "display_label": "Eel electrocyte",
            "interaction_label": "Harvesting electrocyte",
            "collected_label": "Electrocyte held",
            "route_context": "deep_cache_pressure",
            "intent": "One explicit harvest from the existing eel after current-day defeat.",
        },
    ]


def expansion_07_projects() -> list[dict]:
    return [
        {
            "id": "shock_prod_capacitor_project",
            "required_project_id": "shock_prod_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {
                "conductive_coil": 1,
                "insulating_gel": 1,
                "eel_electrocyte": 1,
            },
            "unlocks_capability_id": "shock_prod_capacitor",
            "target_hostile_id": "deep_cache_territorial_eel",
            "capability_effect": "interrupt_warning_lunge",
            "build_phase": "night_debrief",
            "project_label": "Shock-prod capacitor project",
            "completion_label": "Shock-prod capacitor built",
        }
    ]
