#!/usr/bin/env python3
"""Focused source tests for the Expansion 13 production-level records."""

from __future__ import annotations

import hashlib
import json
import unittest

from create_production_level_01_map import OUTPUT_MAP_PATH, SOURCE_MAP_PATH, build_map_data
from production_level_01_expansion_13 import (
    BACKGROUND_ID,
    BOAT_ID,
    DISCOVERY_ID,
    LANDMARK_ID,
    NAVIGATION_DATA_ID,
    RECORDER_ID,
    ROUTE_ID,
    SURVEY_ID,
)
from production_level_01_scanner_artifact import PAYOFF_TARGET_ID
from validate_regional_journeys import validate_regional_journey_schema
from validate_southeast_wreck_return import (
    TERRAIN_SHA256,
    southeast_wreck_route_budget,
    validate_southeast_wreck_routes,
    validate_southeast_wreck_schema,
)
from validate_survey_targets import validate_survey_target_schema


def _rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(item["y"], item["y"] + item.get("h", 1))
        for x in range(item["x"], item["x"] + item.get("w", 1))
    }


def _terrain_hash(map_data: dict) -> str:
    payload = json.dumps(map_data["terrain"], sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


class ProductionLevelExpansion13Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(source)

    def test_exact_source_contract_and_generic_schema_pass(self) -> None:
        self.assertEqual([], validate_southeast_wreck_schema(self.map_data))
        self.assertEqual([], validate_southeast_wreck_routes(self.map_data))
        self.assertEqual([], validate_regional_journey_schema(self.map_data))
        self.assertEqual([], validate_survey_target_schema(OUTPUT_MAP_PATH, self.map_data))

    def test_records_are_open_colocated_and_return_budgeted(self) -> None:
        landmark = next(item for item in self.map_data["zones"] if item["id"] == LANDMARK_ID)
        recorder = next(item for item in self.map_data["entities"] if item["id"] == RECORDER_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        solid = {
            cell
            for terrain in self.map_data["terrain"]
            if terrain.get("type") == "solid"
            for cell in _rect_cells(terrain)
        }
        self.assertFalse(_rect_cells(landmark) & solid)
        self.assertTrue(_rect_cells(recorder).issubset(_rect_cells(landmark)))
        self.assertTrue(_rect_cells(survey).issubset(_rect_cells(landmark)))
        budget = southeast_wreck_route_budget(self.map_data)
        self.assertGreater(float(budget["base_margin"]), 0.0)
        self.assertLess(float(budget["base_margin"]), 20.0)
        self.assertGreater(float(budget["upgraded_margin"]), 25.0)

    def test_route_uses_existing_prerequisites_and_canonical_boat(self) -> None:
        route = next(item for item in self.map_data["regional_journeys"] if item["id"] == ROUTE_ID)
        recorder = next(item for item in self.map_data["entities"] if item["id"] == RECORDER_ID)
        payoff = next(item for item in self.map_data["entities"] if item["id"] == PAYOFF_TARGET_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        self.assertEqual(NAVIGATION_DATA_ID, route["required_discovery_id"])
        self.assertEqual("discovery", payoff["reward_kind"])
        self.assertEqual(NAVIGATION_DATA_ID, payoff["reward_id"])
        self.assertEqual(BOAT_ID, payoff["reward_commit_entry_id"])
        self.assertEqual("pressure_suit_1", route["required_capability_id"])
        self.assertEqual("salvage_cutter", recorder["required_tool_id"])
        self.assertEqual("salvage_cutter_project", recorder["tool_project_id"])
        self.assertEqual(SURVEY_ID, recorder["unlocks_survey_target_id"])
        self.assertEqual("survey_scanner_1", survey["required_capability_id"])
        self.assertEqual(DISCOVERY_ID, survey["discovery_id"])
        self.assertEqual(BOAT_ID, route["commit_entry_id"])
        self.assertEqual(BOAT_ID, survey["commit_entry_id"])
        self.assertFalse(any(item.get("id", "").startswith("southeast_wreck") for item in self.map_data["material_projects"]))

    def test_terrain_and_provenance_remain_focused(self) -> None:
        self.assertEqual(TERRAIN_SHA256, _terrain_hash(self.map_data))
        provenance = self.map_data["source"]["expansion_13"]
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual([ROUTE_ID], provenance["journey_ids"])
        self.assertEqual([LANDMARK_ID], provenance["zone_ids"])
        self.assertEqual([RECORDER_ID], provenance["entity_ids"])
        self.assertEqual([SURVEY_ID], provenance["survey_target_ids"])
        self.assertEqual(
            {
                "expansion_13_wreck_promise",
                "expansion_13_wreck_arrival",
                "expansion_13_recorder_cut",
                "expansion_13_archive_survey",
                "expansion_13_pending_boat_return",
            },
            set(provenance["camera_test_ids"]),
        )
        backdrop = next(item for item in self.map_data["background"] if item["id"] == BACKGROUND_ID)
        self.assertEqual(ROUTE_ID, backdrop["regional_journey_id"])


if __name__ == "__main__":
    unittest.main()
