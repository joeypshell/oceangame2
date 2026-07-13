#!/usr/bin/env python3
"""Focused fixtures for regional journey source relationships."""

from __future__ import annotations

import copy
import json
import unittest

from create_production_level_01_map import SOURCE_MAP_PATH, build_map_data
from validate_regional_journeys import validate_regional_journey_schema


class RegionalJourneyValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        self.map_data = build_map_data(source)

    def test_generated_route_relationships_are_valid(self) -> None:
        self.assertEqual([], validate_regional_journey_schema(self.map_data))

    def test_missing_entry_gate_reference_fails(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        candidate["regional_journeys"][0]["entry_gate_ids"][0] = "missing_gate"
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("missing_gate" in failure and "unresolved" in failure for failure in failures), failures)

    def test_landmark_backdrop_must_match_source_rectangle(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        candidate["background"][-1]["x"] += 1
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("backdrop" in failure for failure in failures), failures)

    def test_runtime_state_and_malformed_gate_ids_fail_cleanly(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        journey = candidate["regional_journeys"][0]
        journey["pending"] = True
        journey["entry_gate_ids"] = [{"id": "not_an_id"}]
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("runtime state" in failure for failure in failures), failures)
        self.assertTrue(any("lower_snake_case" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
