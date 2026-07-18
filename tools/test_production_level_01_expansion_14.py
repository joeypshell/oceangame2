#!/usr/bin/env python3
"""Focused source tests for the Expansion 14 production-level records."""

from __future__ import annotations

import hashlib
import json
import unittest

from create_production_level_01_map import OUTPUT_MAP_PATH, SOURCE_MAP_PATH, build_map_data
from production_level_01_expansion_14 import (
    ARCHIVE_DISCOVERY_ID,
    BACKGROUND_ID,
    BOAT_ID,
    CAPABILITY_ID,
    CORE_ID,
    GATE_ID,
    LANDMARK_ID,
    PROJECT_ID,
    ROUTE_ID,
    SURVEY_ID,
)
from validate_expansion_14_contract import TERRAIN_SHA256, validate_expansion_14_contract
from validate_material_sources import validate_material_source_schema
from validate_regional_journeys import validate_regional_journey_schema
from validate_survey_targets import validate_survey_target_schema


def _terrain_hash(map_data: dict) -> str:
    payload = json.dumps(map_data["terrain"], sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


class ProductionLevelExpansion14Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(source)

    def test_exact_contract_and_generic_schemas_pass(self) -> None:
        self.assertEqual([], validate_expansion_14_contract(self.map_data))
        self.assertEqual([], validate_material_source_schema(self.map_data))
        self.assertEqual([], validate_regional_journey_schema(self.map_data))
        self.assertEqual([], validate_survey_target_schema(OUTPUT_MAP_PATH, self.map_data))

    def test_project_route_and_boat_relationships_are_canonical(self) -> None:
        project = next(item for item in self.map_data["material_projects"] if item["id"] == PROJECT_ID)
        route = next(item for item in self.map_data["regional_journeys"] if item["id"] == ROUTE_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        self.assertEqual(ARCHIVE_DISCOVERY_ID, project["required_discovery_id"])
        self.assertEqual({"titanium_scrap": 2, "conductive_coil": 1}, project["required_materials"])
        self.assertEqual(CAPABILITY_ID, project["unlocks_capability_id"])
        self.assertEqual(GATE_ID, project["target_gate_id"])
        self.assertEqual([GATE_ID], route["entry_gate_ids"])
        self.assertEqual(CORE_ID, route["payoff_target_id"])
        self.assertEqual(BOAT_ID, route["commit_entry_id"])
        self.assertEqual(BOAT_ID, survey["commit_entry_id"])

    def test_relay_records_are_distinct_and_source_owned(self) -> None:
        gate = next(item for item in self.map_data["zones"] if item["id"] == GATE_ID)
        landmark = next(item for item in self.map_data["zones"] if item["id"] == LANDMARK_ID)
        core = next(item for item in self.map_data["entities"] if item["id"] == CORE_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        backdrop = next(item for item in self.map_data["background"] if item["id"] == BACKGROUND_ID)
        self.assertEqual((53, 57, 3, 4), tuple(gate[field] for field in ("x", "y", "w", "h")))
        self.assertEqual((56, 57, 5, 4), tuple(landmark[field] for field in ("x", "y", "w", "h")))
        self.assertEqual((58, 60), (core["x"], core["y"]))
        self.assertEqual((59, 58, 2, 2), tuple(survey[field] for field in ("x", "y", "w", "h")))
        self.assertEqual(
            tuple(landmark[field] for field in ("x", "y", "w", "h")),
            tuple(backdrop[field] for field in ("x", "y", "w", "h")),
        )

    def test_terrain_provenance_and_review_records_remain_focused(self) -> None:
        self.assertEqual(TERRAIN_SHA256, _terrain_hash(self.map_data))
        provenance = self.map_data["source"]["expansion_14"]
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual([PROJECT_ID], provenance["project_ids"])
        self.assertEqual([ROUTE_ID], provenance["journey_ids"])
        self.assertEqual([GATE_ID, LANDMARK_ID], provenance["zone_ids"])
        self.assertEqual([CORE_ID], provenance["entity_ids"])
        self.assertEqual([SURVEY_ID], provenance["survey_target_ids"])
        self.assertEqual({
            "expansion_14_archive_project_promise",
            "expansion_14_pre_stabilizer_current",
            "expansion_14_post_stabilizer_current",
            "expansion_14_wreck_relay_arrival",
            "expansion_14_relay_survey",
            "expansion_14_pending_boat_return",
        }, set(provenance["camera_test_ids"]))
        self.assertTrue(any("Current Stabilizer" in question for question in self.map_data["review_questions"]))


if __name__ == "__main__":
    unittest.main()
