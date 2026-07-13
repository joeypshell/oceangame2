#!/usr/bin/env python3
"""Expansion 08 daily-condition source records for production slice 01."""

from __future__ import annotations


CONDITION_ID = "southwest_jellyfish_bloom"
BONUS_POOL_ID = "southwest_bloom_coil_bonus_pool"
BONUS_CANDIDATE_ID = "material_coil_southwest_bloom"
MIGRATION_HAZARD_ID = "southwest_bloom_jellyfish_patrol"


def daily_conditions() -> list[dict]:
    return [{
        "id": CONDITION_ID,
        "schedule": "even_days_v1",
        "forecast_label": "Tomorrow: Southwest jellyfish bloom",
        "active_label": "Southwest bloom: jellyfish + coil trace",
        "route_context": "southwest_pocket_decision",
        "intent": "Forecast one optional southwest risk-reward opportunity.",
    }]


def material_candidate_pools() -> list[dict]:
    return [{
        "id": BONUS_POOL_ID,
        "material_id": "conductive_coil",
        "selection_strategy": "day_rotation_v1",
        "select_count": 1,
        "candidate_ids": [BONUS_CANDIDATE_ID],
        "pool_role": "optional_bonus",
        "daily_condition_id": CONDITION_ID,
    }]


def expansion_entities() -> list[dict]:
    return [{
        "id": BONUS_CANDIDATE_ID,
        "type": "material_candidate",
        "x": 8,
        "y": 80,
        "kind": "crate",
        "interaction": "material_collect",
        "material_id": "conductive_coil",
        "material_quantity": 1,
        "candidate_pool_id": BONUS_POOL_ID,
        "intent": "Optional even-day coil trace below the southwest migration lane.",
    }]


def moving_hazards() -> list[dict]:
    return [{
        "id": MIGRATION_HAZARD_ID,
        "kind": "jellyfish",
        "x": 8,
        "y": 78,
        "movement": "linear_patrol",
        "path": [{"x": 8, "y": 78}, {"x": 20, "y": 78}],
        "speed_tiles_per_second": 1.0,
        "route_context": "southwest_pocket_decision",
        "display_label": "Bloom jellyfish patrol",
        "daily_condition_id": CONDITION_ID,
        "intent": "Optional even-day patrol paired with the southwest coil opportunity.",
    }]
