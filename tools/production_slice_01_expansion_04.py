#!/usr/bin/env python3
"""Expansion 04 source records for the first production slice."""

from __future__ import annotations


def expansion_04_zones() -> list[dict]:
    return [
        {
            "id": "upper_right_current_pocket_gate",
            "type": "marker",
            "x": 65,
            "y": 40,
            "w": 2,
            "h": 2,
            "current_gate": True,
            "current_direction": "left",
            "current_strength": 2.2,
            "required_capability_id": "propulsion_fins",
            "current_gate_label": "Strong east current",
            "current_affordance_role": "barrier",
            "route_context": "upper_right_current_pocket",
            "intent": (
                "First standard current boundary; recipe-built propulsion fins allow normal swim-through traversal."
            ),
        }
    ]


def expansion_04_projects() -> list[dict]:
    return [
        {
            "id": "current_stabilizer_project",
            "required_project_id": "salvage_cutter_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {
                "titanium_scrap": 2,
                "conductive_coil": 1,
            },
            "unlocks_capability_id": "current_stabilizer",
            "target_gate_id": "lower_left_loop_current",
            "build_phase": "night_debrief",
        }
    ]


def expansion_04_entities() -> list[dict]:
    return [
        {
            "id": "salvage_current_pocket_cache",
            "type": "salvage",
            "x": 69,
            "y": 40,
            "kind": "relic",
            "tier": "valuable",
            "validation_route": "propulsion_fins_payoff",
            "route_context": "upper_right_current_pocket",
            "intent": (
                "Visible valuable scanner-funding payoff behind the first propulsion-fins current gate."
            ),
        }
    ]
