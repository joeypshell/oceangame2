#!/usr/bin/env python3
"""Expansion 06 combat-foundation source records for production slice 01."""

from __future__ import annotations


def expansion_06_hostile_encounters() -> list[dict]:
    return [
        {
            "id": "deep_cache_territorial_eel",
            "kind": "territorial_eel",
            "x": 66,
            "y": 74,
            "behavior": "territorial_lunge",
            "territory": {"x": 60, "y": 71, "w": 10, "h": 8},
            "warning_radius_tiles": 4.0,
            "warning_seconds": 0.75,
            "lunge_speed_tiles_per_second": 6.0,
            "lunge_seconds": 0.45,
            "recovery_seconds": 1.25,
            "contact_radius_tiles": 0.75,
            "health": 3,
            "contact_damage": 1,
            "required_weapon_capability_id": "shock_prod",
            "warning_label": "Territorial eel - watch the lunge",
            "retreat_label": "Eel guarding cache - return with shock prod",
            "defeated_label": "Territory clear for today",
            "route_context": "deep_cache_pressure",
            "intent": (
                "One territorial encounter hard-guarding the deep-right cache; unarmed players may retreat "
                "through unchanged topology but cannot collect the payoff."
            ),
        }
    ]


def expansion_06_projects() -> list[dict]:
    return [
        {
            "id": "shock_prod_project",
            "required_project_id": "current_stabilizer_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {
                "titanium_scrap": 2,
                "conductive_coil": 1,
            },
            "unlocks_capability_id": "shock_prod",
            "target_hostile_id": "deep_cache_territorial_eel",
            "build_phase": "night_debrief",
            "project_label": "Shock prod project",
            "completion_label": "Shock prod built",
        }
    ]
