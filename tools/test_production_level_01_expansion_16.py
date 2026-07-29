#!/usr/bin/env python3
"""Focused source tests for the Expansion 16 production-level records."""

from __future__ import annotations

import hashlib
import json
import unittest

from create_production_level_01_map import OUTPUT_MAP_PATH, SOURCE_MAP_PATH, build_map_data
from production_level_01_expansion_16 import (
    BACKGROUND_ID,
    BOAT_ID,
    CAPABILITY_ID,
    DISCOVERY_ID,
    LANDMARK_ID,
    APPROACH_GUIDANCE,
    PROJECT_ID,
    ROUTE_BEACON_IDS,
    ROUTE_ID,
    SURVEY_ID,
    TOOL_TARGET_ID,
    WARNING_ZONE_ID,
    ZONE_ID,
)
from validate_deeper_wreck_return import (
    RETURN_RESERVE_SECONDS,
    deeper_wreck_route_budget,
    validate_deeper_wreck_schema,
)
from validate_expansion_14_contract import TERRAIN_SHA256
from validate_material_sources import validate_material_source_schema
from validate_regional_journeys import validate_regional_journey_schema
from validate_survey_targets import validate_survey_target_schema


def _terrain_hash(map_data: dict) -> str:
    payload = json.dumps(map_data["terrain"], sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


class ProductionLevelExpansion16Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(source)
        cls.budget = deeper_wreck_route_budget(cls.map_data)

    def test_exact_contract_and_generic_schemas_pass(self) -> None:
        self.assertEqual([], validate_deeper_wreck_schema(OUTPUT_MAP_PATH, self.map_data))
        self.assertEqual([], validate_material_source_schema(self.map_data))
        self.assertEqual([], validate_regional_journey_schema(self.map_data))
        self.assertEqual([], validate_survey_target_schema(OUTPUT_MAP_PATH, self.map_data))

    def test_project_zone_and_interaction_chain_are_canonical(self) -> None:
        project = next(item for item in self.map_data["material_projects"] if item["id"] == PROJECT_ID)
        zone = next(item for item in self.map_data["zones"] if item["id"] == ZONE_ID)
        route = next(item for item in self.map_data["regional_journeys"] if item["id"] == ROUTE_ID)
        target = next(item for item in self.map_data["entities"] if item["id"] == TOOL_TARGET_ID)
        survey = next(item for item in self.map_data["survey_targets"] if item["id"] == SURVEY_ID)
        self.assertEqual(CAPABILITY_ID, project["unlocks_capability_id"])
        self.assertEqual(ZONE_ID, project["target_id"])
        self.assertEqual((12, 90, 21, 16), tuple(zone[field] for field in ("x", "y", "w", "h")))
        self.assertEqual(8.0, zone["unprotected_oxygen_drain_multiplier"])
        self.assertEqual(TOOL_TARGET_ID, route["tool_target_id"])
        self.assertEqual(APPROACH_GUIDANCE, route["approach_guidance"])
        self.assertEqual(SURVEY_ID, target["unlocks_survey_target_id"])
        self.assertEqual("salvage_cutter", target["required_tool_id"])
        self.assertEqual("survey_scanner_1", survey["required_capability_id"])
        self.assertNotIn("required_pressure_capability_id", survey)
        self.assertEqual(DISCOVERY_ID, survey["discovery_id"])
        self.assertEqual(BOAT_ID, survey["commit_entry_id"])

    def test_route_guidance_chain_is_source_authored_and_non_solid(self) -> None:
        zones = {item["id"]: item for item in self.map_data["zones"]}
        expected_rects = ((98, 102, 1, 2), (78, 109, 1, 2), (60, 95, 1, 2), (46, 94, 1, 2))
        solids = {
            (x, y)
            for terrain in self.map_data["terrain"]
            if terrain["type"] == "solid"
            for y in range(terrain["y"], terrain["y"] + terrain["h"])
            for x in range(terrain["x"], terrain["x"] + terrain["w"])
        }
        for beacon_id, expected_rect in zip(ROUTE_BEACON_IDS, expected_rects):
            beacon = zones[beacon_id]
            self.assertEqual(expected_rect, tuple(beacon[field] for field in ("x", "y", "w", "h")))
            self.assertEqual("relay_beacon", beacon["guidance_kind"])
            self.assertFalse({
                (x, y)
                for y in range(beacon["y"], beacon["y"] + beacon["h"])
                for x in range(beacon["x"], beacon["x"] + beacon["w"])
            } & solids)
        warning = zones[WARNING_ZONE_ID]
        self.assertEqual((33, 93, 5, 3), tuple(warning[field] for field in ("x", "y", "w", "h")))
        self.assertEqual(ZONE_ID, warning["oxygen_warning_for_zone_id"])

    def test_route_budget_distinguishes_project_from_optional_tank(self) -> None:
        protected = float(self.budget["protected_demand_seconds"])
        unprotected = float(self.budget["unprotected_demand_seconds"])
        self.assertGreaterEqual(float(self.budget["protected_margin_seconds"]), RETURN_RESERVE_SECONDS)
        self.assertGreater(float(self.budget["optional_shortfall_seconds"]), 0.0)
        self.assertGreater(float(self.budget["zone_critical_seconds"]), 0.0)
        self.assertLess(protected, unprotected)

    def test_terrain_and_provenance_remain_focused(self) -> None:
        self.assertEqual(TERRAIN_SHA256, _terrain_hash(self.map_data))
        provenance = self.map_data["source"]["expansion_16"]
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual([PROJECT_ID], provenance["project_ids"])
        self.assertEqual([ROUTE_ID], provenance["journey_ids"])
        self.assertEqual(
            [ZONE_ID, *ROUTE_BEACON_IDS, WARNING_ZONE_ID, LANDMARK_ID],
            provenance["zone_ids"],
        )
        self.assertEqual([TOOL_TARGET_ID], provenance["entity_ids"])
        self.assertEqual([SURVEY_ID], provenance["survey_target_ids"])
        backdrop = next(
            item for item in self.map_data["background"] if item["id"] == BACKGROUND_ID
        )
        landmark = next(
            item for item in self.map_data["zones"] if item["id"] == LANDMARK_ID
        )
        self.assertEqual(
            tuple(landmark[field] for field in ("x", "y", "w", "h")),
            tuple(backdrop[field] for field in ("x", "y", "w", "h")),
        )

    def test_committed_map_matches_generator(self) -> None:
        committed = json.loads(OUTPUT_MAP_PATH.read_text(encoding="utf-8"))
        self.assertEqual(self.map_data, committed)


if __name__ == "__main__":
    unittest.main()
