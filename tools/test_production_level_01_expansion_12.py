#!/usr/bin/env python3
"""Focused source tests for the Expansion 12 production-level records."""

from __future__ import annotations

import json
import unittest

from create_production_level_01_map import OUTPUT_MAP_PATH, SOURCE_MAP_PATH, build_map_data
from production_level_01_expansion_12 import (
    BOAT_ID,
    LANDMARK_ID,
    PROJECT_ID,
    ROUTE_ID,
    SURVEY_ID,
    ZONE_ID,
)
from validate_pressure_return import validate_pressure_return_routes, validate_pressure_return_schema


def _rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(item["y"], item["y"] + item.get("h", 1))
        for x in range(item["x"], item["x"] + item.get("w", 1))
    }


class ProductionLevelExpansion12Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(source)

    def test_exact_pressure_contract_and_route_budget_pass(self) -> None:
        self.assertEqual([], validate_pressure_return_schema(OUTPUT_MAP_PATH, self.map_data))
        self.assertEqual([], validate_pressure_return_routes(self.map_data))

    def test_survey_is_open_and_inside_the_authored_regions(self) -> None:
        pressure = next(item for item in self.map_data["zones"] if item["id"] == ZONE_ID)
        landmark = next(item for item in self.map_data["zones"] if item["id"] == LANDMARK_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        solid = {
            cell
            for terrain in self.map_data["terrain"]
            if terrain.get("type") == "solid"
            for cell in _rect_cells(terrain)
        }
        self.assertFalse(_rect_cells(survey) & solid)
        self.assertTrue(_rect_cells(survey).issubset(_rect_cells(pressure)))
        self.assertTrue(_rect_cells(survey).issubset(_rect_cells(landmark)))

    def test_project_and_route_commit_at_the_canonical_boat(self) -> None:
        project_ids = [item["id"] for item in self.map_data["material_projects"]]
        self.assertGreater(project_ids.index(PROJECT_ID), project_ids.index("dive_light_1_project"))
        project = next(item for item in self.map_data["material_projects"] if item["id"] == PROJECT_ID)
        route = next(item for item in self.map_data["regional_journeys"] if item["id"] == ROUTE_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        self.assertNotIn("required_project_id", project)
        self.assertEqual(BOAT_ID, route["commit_entry_id"])
        self.assertEqual(BOAT_ID, survey["commit_entry_id"])

    def test_provenance_and_review_records_are_focused(self) -> None:
        provenance = self.map_data["source"]["expansion_12"]
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual([PROJECT_ID], provenance["project_ids"])
        self.assertEqual([SURVEY_ID], provenance["survey_target_ids"])
        self.assertEqual(
            {
                "expansion_12_pre_suit_pressure_warning",
                "expansion_12_pressure_suit_project",
                "expansion_12_protected_crossing",
                "expansion_12_abyssal_survey",
                "expansion_12_pending_boat_return",
            },
            set(provenance["camera_test_ids"]),
        )


if __name__ == "__main__":
    unittest.main()
