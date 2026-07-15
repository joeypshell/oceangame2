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

    def test_survey_must_require_route_and_remain_inside_landmark(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        journey = candidate["regional_journeys"][0]
        survey = next(
            item
            for item in candidate["survey_targets"]
            if item["id"] == journey["survey_target_id"]
        )
        survey["required_route_id"] = "wrong_route"
        survey["x"] -= 20
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("target requiring this route" in failure for failure in failures), failures)

        survey["required_route_id"] = journey["id"]
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("inside its landmark" in failure for failure in failures), failures)

    def test_payoff_requires_source_target_and_canonical_boat(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        journey = candidate["regional_journeys"][0]
        journey["survey_target_id"] = "missing_survey"
        journey["commit_entry_id"] = "missing_boat"
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("survey_target_id" in failure for failure in failures), failures)
        self.assertTrue(any("canonical boat" in failure for failure in failures), failures)

    def test_runtime_state_and_malformed_gate_ids_fail_cleanly(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        journey = candidate["regional_journeys"][0]
        journey["pending"] = True
        journey["required_capability_id"] = "current_stabilizer"
        journey["entry_gate_ids"] = [{"id": "not_an_id"}]
        failures = validate_regional_journey_schema(candidate)
        self.assertTrue(any("runtime state" in failure for failure in failures), failures)
        self.assertTrue(any("required_capability_id must be one of" in failure for failure in failures), failures)
        self.assertTrue(any("lower_snake_case" in failure for failure in failures), failures)

    def test_accepts_pressure_journey_with_visibility_promise_and_pressure_entry(self) -> None:
        candidate = copy.deepcopy(self.map_data)
        candidate["zones"].extend([
            {
                "id": "abyssal_basin_pressure_zone",
                "type": "marker",
                "x": 81,
                "y": 141,
                "w": 33,
                "h": 15,
                "pressure_zone": True,
                "required_capability_id": "pressure_suit_1",
                "route_context": "deep_harmonic_abyssal_basin_route",
            },
            {
                "id": "abyssal_basin_landmark",
                "type": "marker",
                "x": 81,
                "y": 141,
                "w": 33,
                "h": 15,
                "regional_landmark": True,
                "regional_journey_id": "deep_harmonic_abyssal_basin_route",
                "landmark_label": "Abyssal Basin",
            },
        ])
        candidate["background"].append({
            "id": "abyssal_basin_harmonic_source_backdrop",
            "type": "background",
            "x": 81,
            "y": 141,
            "w": 33,
            "h": 15,
            "regional_journey_id": "deep_harmonic_abyssal_basin_route",
        })
        candidate["survey_targets"].append({
            "id": "abyssal_basin_harmonic_source_survey",
            "x": 95,
            "y": 149,
            "w": 2,
            "h": 2,
            "required_route_id": "deep_harmonic_abyssal_basin_route",
        })
        candidate["regional_journeys"].append({
            "id": "deep_harmonic_abyssal_basin_route",
            "route_label": "Abyssal basin route",
            "promise_gate_id": "signal_reef_deep_harmonic_dark_zone",
            "entry_gate_ids": ["abyssal_basin_pressure_zone"],
            "required_capability_id": "pressure_suit_1",
            "landmark_zone_id": "abyssal_basin_landmark",
            "survey_target_id": "abyssal_basin_harmonic_source_survey",
            "commit_entry_id": "surface_boat_entry",
            "route_context": "deep_harmonic_abyssal_basin_route",
            "intent": "Use the existing lower-central basin.",
        })
        self.assertEqual([], validate_regional_journey_schema(candidate))


if __name__ == "__main__":
    unittest.main()
