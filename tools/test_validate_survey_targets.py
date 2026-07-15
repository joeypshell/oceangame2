#!/usr/bin/env python3
"""Focused positive and negative tests for survey target validation."""

from __future__ import annotations

import copy
import unittest
from pathlib import Path

from validate_survey_targets import validate_survey_target_reachability, validate_survey_target_schema


ROOT = Path(__file__).resolve().parents[1]
SOURCE_MAP = ROOT / "maps" / "production_slice_02.greybox.json"


def valid_target() -> dict:
    return {
        "id": "lower_right_anomaly_survey",
        "target_type": "anomaly",
        "x": 1,
        "y": 1,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey anomaly",
        "discovery_id": "lower_right_anomaly_discovery",
        "route_context": "lower_right_anomaly_route",
        "commit_map_id": "production_slice_01",
        "commit_map_path": "res://maps/production_slice_01.greybox.json",
        "commit_entry_id": "surface_boat_entry",
    }


def valid_map() -> dict:
    return {
        "id": "survey_fixture",
        "units": {"width_tiles": 8, "height_tiles": 8},
        "entities": [],
        "zones": [],
        "survey_targets": [valid_target()],
    }


def valid_regional_target() -> dict:
    target = valid_target()
    target.update({
        "id": "lower_right_signal_reef_survey",
        "target_type": "regional",
        "interaction_label": "Survey Signal Reef",
        "clue_label": "Signal Reef | Harmonic pattern unresolved",
        "finding_label": "Discovery logged: Signal Reef chart",
        "next_lead_label": "Next lead: deeper harmonic below reef",
        "discovery_id": "lower_right_signal_reef_discovery",
        "required_route_id": "east_current_signal_reef_route",
        "route_context": "east_current_signal_reef_route",
    })
    return target


def valid_deep_harmonic_target() -> dict:
    target = valid_regional_target()
    target.update({
        "id": "signal_reef_deep_harmonic_survey",
        "interaction_label": "Survey deep harmonic",
        "clue_label": "Deep harmonic | Stronger light required",
        "finding_label": "Discovery logged: Deep harmonic chart",
        "next_lead_label": "Next lead: signal descends into deeper water",
        "discovery_id": "signal_reef_deep_harmonic_discovery",
        "required_light_capability_id": "dive_light_1",
    })
    return target


def valid_abyssal_target() -> dict:
    target = valid_regional_target()
    target.update({
        "id": "abyssal_basin_harmonic_source_survey",
        "interaction_label": "Survey abyssal source",
        "clue_label": "Abyssal signal | Pressure suit required",
        "finding_label": "Discovery logged: Abyssal harmonic source",
        "next_lead_label": "Abyssal source charted | Further descent unresolved",
        "discovery_id": "abyssal_basin_harmonic_source_discovery",
        "required_pressure_capability_id": "pressure_suit_1",
        "required_route_id": "deep_harmonic_abyssal_basin_route",
        "route_context": "deep_harmonic_abyssal_basin_route",
    })
    return target


class SurveyTargetValidationTests(unittest.TestCase):
    def test_valid_schema_and_reachability(self) -> None:
        map_data = valid_map()
        self.assertEqual(validate_survey_target_schema(SOURCE_MAP, map_data), [])
        reachable = {(x, y) for y in range(8) for x in range(8)}
        self.assertEqual(validate_survey_target_reachability(map_data["survey_targets"], set(), reachable), [])

    def test_validates_regional_finding_and_broad_next_lead(self) -> None:
        map_data = valid_map()
        map_data["survey_targets"] = [valid_regional_target()]
        self.assertEqual(validate_survey_target_schema(SOURCE_MAP, map_data), [])

        target = map_data["survey_targets"][0]
        target.pop("next_lead_label")
        target["required_route_id"] = "wrong_route"
        target["research_material_pool_id"] = "wrong_pool"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("missing required field next_lead_label" in failure for failure in failures), failures)
        self.assertTrue(any("required_route_id must equal route_context" in failure for failure in failures), failures)
        self.assertTrue(any("unsupported regional metadata: research_material_pool_id" in failure for failure in failures), failures)

        target["next_lead_label"] = "Next lead: x=123"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("next_lead_label must not contain coordinates" in failure for failure in failures), failures)

    def test_accepts_only_the_contract_light_gated_regional_target(self) -> None:
        map_data = valid_map()
        map_data["survey_targets"] = [valid_deep_harmonic_target()]
        self.assertEqual(validate_survey_target_schema(SOURCE_MAP, map_data), [])

        map_data["survey_targets"][0]["required_light_capability_id"] = "wrong_light"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("required_light_capability_id must be 'dive_light_1'" in failure for failure in failures), failures)

        ordinary = valid_regional_target()
        ordinary["required_light_capability_id"] = "dive_light_1"
        map_data["survey_targets"] = [ordinary]
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("only supported on a light-gated target" in failure for failure in failures), failures)

    def test_accepts_only_the_contract_pressure_gated_regional_target(self) -> None:
        map_data = valid_map()
        map_data["survey_targets"] = [valid_abyssal_target()]
        self.assertEqual(validate_survey_target_schema(SOURCE_MAP, map_data), [])

        map_data["survey_targets"][0]["required_pressure_capability_id"] = "wrong_suit"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(
            any("required_pressure_capability_id must be 'pressure_suit_1'" in failure for failure in failures),
            failures,
        )

        ordinary = valid_regional_target()
        ordinary["required_pressure_capability_id"] = "pressure_suit_1"
        map_data["survey_targets"] = [ordinary]
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("only supported on a pressure-gated target" in failure for failure in failures), failures)

    def test_requires_dedicated_list_and_unique_ids(self) -> None:
        map_data = valid_map()
        map_data["entities"] = [{"id": "salvage", "required_capability_id": "survey_scanner_1"}]
        duplicate = copy.deepcopy(map_data["survey_targets"][0])
        map_data["survey_targets"].append(duplicate)
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("only supported in survey_targets" in failure for failure in failures))
        self.assertTrue(any("Duplicate survey target id" in failure for failure in failures))
        self.assertTrue(any("Duplicate survey discovery id" in failure for failure in failures))
        self.assertEqual(
            validate_survey_target_schema(SOURCE_MAP, {"units": {}, "survey_targets": {}}),
            ["survey_targets must be a list when present."],
        )

    def test_allows_durable_current_requirement_but_rejects_survey_fields_on_gate(self) -> None:
        map_data = valid_map()
        gate = {
            "id": "durable_current_gate",
            "type": "marker",
            "current_gate": True,
            "required_capability_id": "current_stabilizer",
        }
        map_data["zones"] = [gate]
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertFalse(any("zones[0] survey metadata" in failure for failure in failures), failures)

        gate["discovery_id"] = "misplaced_discovery"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("zones[0] survey metadata (discovery_id)" in failure for failure in failures), failures)

    def test_allows_required_capability_on_explicitly_guarded_salvage(self) -> None:
        map_data = valid_map()
        map_data["entities"] = [{
            "id": "guarded_cache",
            "type": "salvage",
            "required_capability_id": "shock_prod",
            "guarded_by_hostile_id": "territorial_eel",
        }]
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertFalse(any("entities[0] survey metadata" in failure for failure in failures), failures)

    def test_rejects_invalid_interaction_and_runtime_state(self) -> None:
        map_data = valid_map()
        target = map_data["survey_targets"][0]
        target.update(
            {
                "target_type": "salvage",
                "required_capability_id": "unknown_scanner",
                "interaction": "timed_salvage",
                "interaction_seconds": 0,
                "interaction_label": "bad\nlabel",
                "discovery_id": "Bad Discovery",
                "route_context": "Bad Route",
                "pending": True,
                "x": 7,
            }
        )
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        for expected in (
            "target_type must be one of",
            "required_capability_id must be one of",
            "interaction must be one of",
            "interaction_seconds must be a positive number",
            "interaction_label must be lower_snake_case or short display-safe text",
            "discovery_id 'Bad Discovery' must use lower_snake_case",
            "route_context 'Bad Route' must use lower_snake_case",
            "must not author runtime/profile state fields: pending",
            "survey target rectangle extends outside map bounds",
        ):
            self.assertTrue(any(expected in failure for failure in failures), expected)

        target["id"] = ["not", "hashable"]
        target["discovery_id"] = {"not": "hashable"}
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("id must be a non-empty string" in failure for failure in failures))
        self.assertTrue(any("discovery_id must be a non-empty string" in failure for failure in failures))

    def test_validates_commit_map_and_boat_entry(self) -> None:
        map_data = valid_map()
        target = map_data["survey_targets"][0]
        target["commit_map_id"] = "wrong_map"
        target["commit_entry_id"] = "missing_entry"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("does not match" in failure for failure in failures))
        self.assertTrue(any("does not reference an entry" in failure for failure in failures))

        target["commit_map_id"] = "production_slice_02"
        target["commit_map_path"] = "res://maps/production_slice_02.greybox.json"
        target["commit_entry_id"] = "relay_sub_entry"
        failures = validate_survey_target_schema(SOURCE_MAP, map_data)
        self.assertTrue(any("must reference a boat_spawn" in failure for failure in failures))

    def test_rejects_solid_and_unreachable_cells(self) -> None:
        target = valid_target()
        failures = validate_survey_target_reachability(
            [target],
            {(1, 1)},
            {(1, 1), (1, 2)},
        )
        self.assertTrue(any("contains solid cells" in failure for failure in failures))
        self.assertTrue(any("contains unreachable cells" in failure for failure in failures))


if __name__ == "__main__":
    unittest.main()
