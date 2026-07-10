#!/usr/bin/env python3
"""Focused positive and negative tests for practical research source validation."""

from __future__ import annotations

import copy
import unittest
from pathlib import Path

from test_validate_material_sources import valid_map, with_stabilizer_project
from validate_material_sources import validate_material_source_schema
from validate_research_sources import validate_research_source_schema
from validate_survey_targets import validate_survey_target_schema


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP = ROOT / "maps" / "production_slice_01.greybox.json"


def resource_target() -> dict:
    return {
        "id": "upper_right_mineral_trace_survey",
        "target_type": "resource",
        "x": 11,
        "y": 3,
        "w": 1,
        "h": 1,
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
    }


def research_map() -> dict:
    map_data = with_stabilizer_project(valid_map())
    map_data["survey_targets"] = [resource_target()]
    pool = map_data["material_candidate_pools"][1]
    pool.update(
        {
            "research_discovery_id": "upper_right_mineral_trace_research",
            "researched_candidate_ids": [pool["candidate_ids"][1]],
            "research_lead_label": "Research lead | Coils near deep-cache machinery",
        }
    )
    return map_data


class ResearchSourceValidationTests(unittest.TestCase):
    def test_accepts_linked_resource_target_and_researched_pool(self) -> None:
        map_data = research_map()
        self.assertEqual(validate_survey_target_schema(SOURCE_MAP, map_data), [])
        self.assertEqual(validate_research_source_schema(map_data), [])
        self.assertEqual(validate_material_source_schema(map_data), [])

    def test_rejects_missing_and_misplaced_research_metadata(self) -> None:
        map_data = research_map()
        del map_data["material_candidate_pools"][1]["research_lead_label"]
        map_data["entities"][0]["researched_candidate_ids"] = ["material_coil_1"]
        map_data["material_candidate_pools"][0]["clue_label"] = "Misplaced clue"
        failures = validate_research_source_schema(map_data)
        survey_failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("only supported in material_candidate_pools" in failure for failure in failures))
        self.assertTrue(any("research metadata is missing" in failure for failure in failures))
        self.assertTrue(any("only supported in survey_targets" in failure for failure in survey_failures))

    def test_rejects_dangling_link_and_invalid_candidate_subset(self) -> None:
        map_data = research_map()
        map_data["survey_targets"][0]["research_material_pool_id"] = "missing_pool"
        pool = map_data["material_candidate_pools"][1]
        pool["researched_candidate_ids"] = ["material_titanium_0", "material_titanium_0"]
        failures = validate_research_source_schema(map_data)
        self.assertTrue(any("research_material_pool_id must link" in failure for failure in failures))
        self.assertTrue(any("researched_candidate_ids must be unique" in failure for failure in failures))

    def test_rejects_mismatched_candidate_metadata_and_undersized_subset(self) -> None:
        map_data = research_map()
        pool = map_data["material_candidate_pools"][1]
        pool["select_count"] = 2
        candidate_id = pool["researched_candidate_ids"][0]
        candidate = next(entity for entity in map_data["entities"] if entity.get("id") == candidate_id)
        candidate["material_id"] = "titanium_scrap"
        failures = validate_research_source_schema(map_data)
        self.assertTrue(any("at least select_count" in failure for failure in failures))
        self.assertTrue(any("metadata does not match" in failure for failure in failures))

    def test_rejects_coordinate_text_runtime_state_and_wrong_side(self) -> None:
        map_data = research_map()
        target = map_data["survey_targets"][0]
        target["x"] = 9
        target["finding_label"] = "Coils at x=11"
        target["pending"] = True
        pool = map_data["material_candidate_pools"][1]
        pool["research_lead_label"] = "Coils at 6,2"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data) + validate_research_source_schema(map_data)
        self.assertTrue(any("must not contain coordinates" in failure for failure in failures))
        self.assertTrue(any("must be placed beyond" in failure for failure in failures))
        self.assertTrue(any("must not author runtime/profile state" in failure for failure in failures))

    def test_rejects_resource_fields_on_anomaly_and_invalid_discovery(self) -> None:
        map_data = research_map()
        target = copy.deepcopy(map_data["survey_targets"][0])
        target["target_type"] = "anomaly"
        target["discovery_id"] = "unknown_research"
        map_data["survey_targets"] = [target]
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("anomaly discovery_id must be" in failure for failure in failures))
        self.assertTrue(any("resource metadata" in failure for failure in failures))

    def test_rejects_unsupported_effect_kind(self) -> None:
        map_data = research_map()
        map_data["material_candidate_pools"][1]["research_effect_type"] = "double_yield"
        failures = validate_research_source_schema(map_data)
        self.assertTrue(any("Unsupported research effect fields" in failure for failure in failures))


if __name__ == "__main__":
    unittest.main()
