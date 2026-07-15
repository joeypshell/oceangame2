#!/usr/bin/env python3
"""Focused positive and negative tests for the Expansion 12 pressure chain."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from progression_contract import load_contract
from validate_pressure_return import (
    BACKGROUND_ID,
    BACKGROUND_VALUES,
    BOAT_ID,
    CAPABILITY_ID,
    DISCOVERY_ID,
    KNOWLEDGE_ID,
    LANDMARK_ID,
    LANDMARK_VALUES,
    PROJECT_ID,
    PROJECT_VALUES,
    ROUTE_ID,
    ROUTE_VALUES,
    SURVEY_ID,
    SURVEY_VALUES,
    ZONE_ID,
    ZONE_VALUES,
    pressure_route_budget,
    validate_pressure_return_routes,
    validate_pressure_return_schema,
)


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "production_level_01.greybox.json"


def authored_map() -> dict:
    map_data = json.loads(MAP_PATH.read_text(encoding="utf-8"))
    map_data["material_projects"].append({"id": PROJECT_ID, **copy.deepcopy(PROJECT_VALUES)})
    map_data["zones"].extend([
        {"id": ZONE_ID, **copy.deepcopy(ZONE_VALUES), "intent": "Pressure threshold for the existing basin."},
        {"id": LANDMARK_ID, **copy.deepcopy(LANDMARK_VALUES)},
    ])
    map_data["background"].append({"id": BACKGROUND_ID, **copy.deepcopy(BACKGROUND_VALUES)})
    map_data["regional_journeys"].append({
        "id": ROUTE_ID,
        **copy.deepcopy(ROUTE_VALUES),
        "intent": "Return through continuous geography to the lower-central basin.",
    })
    map_data["survey_targets"].append({"id": SURVEY_ID, **copy.deepcopy(SURVEY_VALUES)})
    return map_data


class PressureReturnValidationTests(unittest.TestCase):
    def test_accepts_exact_chain_and_route_budgets(self) -> None:
        map_data = authored_map()
        self.assertEqual([], validate_pressure_return_schema(MAP_PATH, map_data, load_contract()))
        self.assertEqual([], validate_pressure_return_routes(map_data))
        budget = pressure_route_budget(map_data)
        self.assertGreater(float(budget["protected_margin"]), 15.0)
        self.assertGreater(float(budget["optional_shortfall"]), 0.0)
        self.assertGreater(float(budget["rest_escape_cost"]), float(budget["target_remaining"]))

    def test_rejects_drifted_recipe_zone_survey_and_runtime_state(self) -> None:
        map_data = authored_map()
        project = next(item for item in map_data["material_projects"] if item["id"] == PROJECT_ID)
        zone = next(item for item in map_data["zones"] if item["id"] == ZONE_ID)
        survey = next(item for item in map_data["survey_targets"] if item["id"] == SURVEY_ID)
        project["required_materials"]["titanium_scrap"] = 1
        zone["unprotected_oxygen_drain_multiplier"] = 2.0
        zone["health_damage"] = 1
        survey["required_pressure_capability_id"] = "wrong_suit"
        survey["pending"] = True
        failures = validate_pressure_return_schema(MAP_PATH, map_data, load_contract())
        for expected in (
            "required_materials must be exactly",
            "unprotected_oxygen_drain_multiplier must be exactly 8.0",
            "must not author collision, travel, or damage fields",
            "required_pressure_capability_id must be exactly 'pressure_suit_1'",
            "must not author runtime state fields",
        ):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_purchase_owner_circular_knowledge_and_missing_floor(self) -> None:
        map_data = authored_map()
        deep_harmonic = next(
            item for item in map_data["survey_targets"] if item.get("discovery_id") == KNOWLEDGE_ID
        )
        deep_harmonic["required_pressure_capability_id"] = CAPABILITY_ID
        rubber_pool = next(
            item for item in map_data["material_candidate_pools"] if item["material_id"] == "rubber_sheet"
        )
        rubber_pool["select_count"] = 0
        contract = copy.deepcopy(load_contract())
        contract["session_upgrades"].append({"id": CAPABILITY_ID})
        contract["durable_capabilities"] = [
            item for item in contract["durable_capabilities"] if item["id"] != CAPABILITY_ID
        ]
        failures = validate_pressure_return_schema(MAP_PATH, map_data, contract)
        self.assertTrue(any("score/session purchase ownership" in failure for failure in failures), failures)
        self.assertTrue(any("durable capability declaration" in failure for failure in failures), failures)
        self.assertTrue(any("must not require the pressure suit" in failure for failure in failures), failures)
        self.assertTrue(any("rubber_sheet" in failure and "provide 0" in failure for failure in failures), failures)

    def test_route_budget_rejects_optional_tank_bypass(self) -> None:
        map_data = authored_map()
        zone = next(item for item in map_data["zones"] if item["id"] == ZONE_ID)
        zone["unprotected_oxygen_drain_multiplier"] = 1.0
        failures = validate_pressure_return_routes(map_data)
        self.assertTrue(any("can be completed with oxygen_tank_1" in failure for failure in failures), failures)

    def test_partial_pressure_records_activate_the_complete_contract(self) -> None:
        current = json.loads(MAP_PATH.read_text(encoding="utf-8"))
        self.assertEqual([], validate_pressure_return_schema(MAP_PATH, current, load_contract()))
        current["regional_journeys"].append({"id": ROUTE_ID})
        failures = validate_pressure_return_schema(MAP_PATH, current, load_contract())
        self.assertTrue(any("requires exactly one material_projects" in failure for failure in failures), failures)
        self.assertTrue(any("requires exactly one survey_targets" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
