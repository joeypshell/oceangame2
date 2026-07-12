#!/usr/bin/env python3
"""Expansion 05 practical-research source records for production slice 01."""

from __future__ import annotations


def apply_expansion_05_material_research(pools: list[dict]) -> list[dict]:
    values: list[dict] = []
    for source in pools:
        pool = source.copy()
        pool["candidate_ids"] = list(source.get("candidate_ids", []))
        if pool.get("id") == "conductive_coil_pool":
            pool.update(
                {
                    "research_discovery_id": "upper_right_mineral_trace_research",
                    "researched_candidate_ids": ["material_coil_deep_cache"],
                    "research_lead_label": "Research lead | Coils near deep-cache machinery",
                }
            )
        values.append(pool)
    return values


def expansion_05_survey_targets() -> list[dict]:
    return [
        {
            "id": "lower_right_anomaly_survey",
            "target_type": "anomaly",
            "x": 67,
            "y": 43,
            "w": 2,
            "h": 2,
            "required_capability_id": "survey_scanner_1",
            "interaction": "survey",
            "interaction_seconds": 3.0,
            "interaction_label": "Survey anomaly",
            "discovery_id": "lower_right_anomaly_discovery",
            "route_context": "upper_right_current_pocket",
            "commit_map_id": "production_slice_01",
            "commit_map_path": "res://maps/production_slice_01.greybox.json",
            "commit_entry_id": "surface_boat_entry",
            "intent": "Main anomaly survey moved into the contiguous east current pocket for the scanner journey.",
        },
        {
            "id": "upper_right_mineral_trace_survey",
            "target_type": "resource",
            "x": 69,
            "y": 43,
            "w": 2,
            "h": 2,
            "required_capability_id": "survey_scanner_1",
            "interaction": "survey",
            "interaction_seconds": 3.0,
            "interaction_label": "Survey mineral trace",
            "clue_label": "Mineral trace | Composition unknown",
            "finding_label": "Research: coils favor deep-cache machinery",
            "discovery_id": "upper_right_mineral_trace_research",
            "research_material_pool_id": "conductive_coil_pool",
            "route_context": "upper_right_current_pocket",
            "commit_map_id": "production_slice_01",
            "commit_map_path": "res://maps/production_slice_01.greybox.json",
            "commit_entry_id": "surface_boat_entry",
            "intent": (
                "Expansion 05 mineral trace beyond the durable current gate; its committed finding "
                "favors the existing deep-cache coil habitat on a fresh day."
            ),
        }
    ]
