#!/usr/bin/env python3
"""Expansion 03 source records for the first production slice."""

from __future__ import annotations


def material_candidate_pools() -> list[dict]:
    return [
        {
            "id": "titanium_scrap_pool",
            "material_id": "titanium_scrap",
            "selection_strategy": "day_rotation_v1",
            "select_count": 2,
            "candidate_ids": [
                "material_titanium_entry",
                "material_titanium_crossing",
                "material_titanium_return",
                "material_titanium_lower_loop",
            ],
        },
        {
            "id": "conductive_coil_pool",
            "material_id": "conductive_coil",
            "selection_strategy": "day_rotation_v1",
            "select_count": 1,
            "candidate_ids": [
                "material_coil_deep_approach",
                "material_coil_deep_cache",
            ],
        },
    ]


def material_projects() -> list[dict]:
    return [
        {
            "id": "salvage_cutter_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {
                "titanium_scrap": 2,
                "conductive_coil": 1,
            },
            "unlocks_capability_id": "salvage_cutter",
            "target_id": "salvage_sealed_wreck_cache",
            "build_phase": "night_debrief",
        }
    ]


def expansion_03_entities() -> list[dict]:
    return [
        _material_candidate(
            "material_titanium_entry",
            44,
            20,
            "titanium_scrap",
            "titanium_scrap_pool",
            "Safe entry-shaft titanium candidate encountered on the first descent.",
        ),
        _material_candidate(
            "material_titanium_crossing",
            48,
            31,
            "titanium_scrap",
            "titanium_scrap_pool",
            "Central-crossing titanium candidate supporting the short route.",
        ),
        _material_candidate(
            "material_titanium_return",
            27,
            58,
            "titanium_scrap",
            "titanium_scrap_pool",
            "Return-pressure titanium candidate near the southwest branch decision.",
        ),
        _material_candidate(
            "material_titanium_lower_loop",
            40,
            66,
            "titanium_scrap",
            "titanium_scrap_pool",
            "Lower-loop titanium candidate rewarding the longer known route.",
        ),
        _material_candidate(
            "material_coil_deep_approach",
            55,
            68,
            "conductive_coil",
            "conductive_coil_pool",
            "Special component candidate on the moving-hazard deep approach.",
        ),
        _material_candidate(
            "material_coil_deep_cache",
            61,
            73,
            "conductive_coil",
            "conductive_coil_pool",
            "Special component candidate in the deep-cache branch.",
        ),
        {
            "id": "salvage_sealed_wreck_cache",
            "type": "tool_target",
            "x": 61,
            "y": 40,
            "kind": "crate",
            "tier": "valuable",
            "interaction": "cutter_salvage",
            "interaction_seconds": 2.0,
            "interaction_label": "sealed wreck",
            "required_tool_id": "salvage_cutter",
            "tool_project_id": "salvage_cutter_project",
            "intent": (
                "Expansion 03 remembered upper-right alcove payoff, visible before the cutter exists "
                "and collectable only after the night project."
            ),
        },
    ]


def _material_candidate(
    entity_id: str,
    x: int,
    y: int,
    material_id: str,
    pool_id: str,
    intent: str,
) -> dict:
    return {
        "id": entity_id,
        "type": "material_candidate",
        "x": x,
        "y": y,
        "kind": "wreck_fragment" if material_id == "titanium_scrap" else "crate",
        "interaction": "material_collect",
        "material_id": material_id,
        "material_quantity": 1,
        "candidate_pool_id": pool_id,
        "intent": intent,
    }
