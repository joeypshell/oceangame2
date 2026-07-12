#!/usr/bin/env python3
"""Player-gate correction source records for production slice 01."""

from __future__ import annotations


PROPULSION_BLUEPRINT_ID = "propulsion_fins_blueprint"


def propulsion_blueprint_container() -> dict:
    return {
        "id": "lower_loop_upgrade_chest",
        "container_type": "upgrade_chest",
        "x": 18,
        "y": 72,
        "w": 2,
        "h": 2,
        "display_label": "Fins blueprint chest",
        "interaction": "instant",
        "reward_type": "blueprint",
        "reward_id": PROPULSION_BLUEPRINT_ID,
        "route_context": "lower_loop_reward",
        "intent": "Guaranteed pre-gate recovered plan that reveals the propulsion-fins recipe.",
    }


def propulsion_material_pool() -> dict:
    return {
        "id": "rubber_sheet_pool",
        "material_id": "rubber_sheet",
        "selection_strategy": "day_rotation_v1",
        "select_count": 1,
        "candidate_ids": [
            "material_rubber_entry",
            "material_rubber_lower_loop",
        ],
    }


def propulsion_project() -> dict:
    return {
        "id": "propulsion_fins_project",
        "required_discovery_id": PROPULSION_BLUEPRINT_ID,
        "required_materials": {
            "titanium_scrap": 2,
            "rubber_sheet": 1,
        },
        "unlocks_capability_id": "propulsion_fins",
        "target_gate_id": "lower_left_loop_current",
        "build_phase": "night_debrief",
        "project_label": "Propulsion fins project",
        "completion_label": "Propulsion fins built",
    }


def propulsion_material_entities() -> list[dict]:
    return [
        _rubber_candidate(
            "material_rubber_entry",
            43,
            22,
            "Entry-shaft rubber candidate beside the first titanium route.",
        ),
        _rubber_candidate(
            "material_rubber_lower_loop",
            16,
            69,
            "Lower-loop rubber candidate on the non-eel relay approach.",
        ),
    ]


def lower_left_current_gate() -> dict:
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
        "required_capability_id": "propulsion_fins",
        "current_gate_label": "Lower-left relay current",
        "route_context": "lower_left_loop",
        "intent": "Visible relay current blocked until recipe-built propulsion fins are owned.",
    }


def behavioral_guarded_cache() -> dict:
    return {
        "id": "salvage_deep_right_cache",
        "type": "salvage",
        "x": 64,
        "y": 75,
        "kind": "relic",
        "tier": "valuable",
        "route_choice_id": "deep_right_cache_payoff",
        "validation_route": "expanded_route_choice",
        "route_order": 1,
        "interaction": "timed_salvage",
        "interaction_seconds": 2.5,
        "interaction_label": "deep cache",
        "guarded_by_hostile_id": "deep_cache_territorial_eel",
        "intent": "Timed cache that may be attempted immediately; the active eel interrupts collection through combat behavior.",
    }


def _rubber_candidate(entity_id: str, x: int, y: int, intent: str) -> dict:
    return {
        "id": entity_id,
        "type": "material_candidate",
        "x": x,
        "y": y,
        "kind": "wreck_fragment",
        "interaction": "material_collect",
        "material_id": "rubber_sheet",
        "material_quantity": 1,
        "candidate_pool_id": "rubber_sheet_pool",
        "intent": intent,
    }
