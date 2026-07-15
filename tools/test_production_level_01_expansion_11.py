#!/usr/bin/env python3
"""Focused source tests for the Expansion 11 production-level records."""

from __future__ import annotations

import json
import unittest

from create_production_level_01_map import (
    OUTPUT_MAP_PATH,
    SOURCE_MAP_PATH,
    build_map_data,
)
from production_level_01_expansion_11 import (
    DARK_ZONE_ID,
    PROJECT_ID,
    SURVEY_ID,
)
from validate_light_return import validate_light_return_schema


def _rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(item["y"], item["y"] + item.get("h", 1))
        for x in range(item["x"], item["x"] + item.get("w", 1))
    }


class ProductionLevelExpansion11Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(cls.source)

    def test_exact_light_return_contract_passes(self) -> None:
        self.assertEqual([], validate_light_return_schema(OUTPUT_MAP_PATH, self.map_data))

    def test_zone_and_survey_use_existing_open_water(self) -> None:
        zone = next(item for item in self.map_data["zones"] if item["id"] == DARK_ZONE_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        solid = {
            cell
            for terrain in self.map_data["terrain"]
            if terrain.get("type") == "solid"
            for cell in _rect_cells(terrain)
        }
        self.assertFalse(_rect_cells(zone) & solid)
        self.assertTrue(_rect_cells(survey).issubset(_rect_cells(zone)))
        old_survey = next(item for item in self.map_data["survey_targets"] if item["id"] == "lower_right_signal_reef_survey")
        self.assertFalse(_rect_cells(survey) & _rect_cells(old_survey))

    def test_source_order_does_not_author_project_dependency(self) -> None:
        project = next(item for item in self.map_data["material_projects"] if item["id"] == PROJECT_ID)
        self.assertNotIn("required_project_id", project)
        project_ids = [item["id"] for item in self.map_data["material_projects"]]
        self.assertLess(project_ids.index(PROJECT_ID), project_ids.index("pressure_suit_1_project"))

    def test_provenance_and_camera_records_are_focused(self) -> None:
        source = self.map_data["source"]["expansion_11"]
        self.assertEqual([], source["terrain_changes"])
        self.assertEqual(
            {
                "expansion_11_pre_light_route_context",
                "expansion_11_upgraded_harmonic_survey",
                "expansion_11_pending_boat_return",
            },
            set(source["camera_test_ids"]),
        )


if __name__ == "__main__":
    unittest.main()
