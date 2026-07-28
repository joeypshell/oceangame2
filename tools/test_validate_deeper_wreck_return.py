#!/usr/bin/env python3
"""Focused positive and negative tests for the Expansion 16 contract."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path
from unittest.mock import patch

from progression_contract import load_contract
from progression_graph import build_progression_graph
from validate_material_sources import validate_material_source_schema
from validate_regional_journeys import validate_regional_journey_schema
from validate_survey_targets import validate_survey_target_schema
from validate_deeper_wreck_return import (
    BACKGROUND_ID,
    BOAT_ID,
    CAPABILITY_ID,
    DISCOVERY_ID,
    KNOWLEDGE_ID,
    LANDMARK_ID,
    PROJECT_ID,
    PROJECT_VALUES,
    ROUTE_ID,
    ROUTE_VALUES,
    SURVEY_ID,
    SURVEY_VALUES,
    TOOL_TARGET_ID,
    TOOL_TARGET_VALUES,
    ZONE_ID,
    ZONE_VALUES,
    deeper_wreck_route_budget,
    validate_deeper_wreck_routes,
    validate_deeper_wreck_schema,
)


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "production_level_01.greybox.json"


def contract_with_rebreather() -> dict:
    contract = copy.deepcopy(load_contract())
    if not any(item.get("id") == CAPABILITY_ID for item in contract["durable_capabilities"]):
        contract["durable_capabilities"].append({
            "id": CAPABILITY_ID,
            "constant_name": "CLOSED_CIRCUIT_REBREATHER",
            "mandatory": False,
        })
    return contract


def map_without_records() -> dict:
    map_data = json.loads(MAP_PATH.read_text(encoding="utf-8"))
    ids_by_collection = {
        "material_projects": {PROJECT_ID},
        "zones": {ZONE_ID, LANDMARK_ID},
        "background": {BACKGROUND_ID},
        "entities": {TOOL_TARGET_ID},
        "regional_journeys": {ROUTE_ID},
        "survey_targets": {SURVEY_ID},
    }
    for collection, record_ids in ids_by_collection.items():
        map_data[collection] = [
            item for item in map_data.get(collection, [])
            if item.get("id") not in record_ids
        ]
    source = map_data.get("source")
    if isinstance(source, dict):
        source.pop("expansion_16", None)
    return map_data


def authored_fixture() -> dict:
    map_data = map_without_records()
    map_data["material_projects"].append({
        "id": PROJECT_ID,
        **copy.deepcopy(PROJECT_VALUES),
    })
    map_data["zones"].extend([
        {
            "id": ZONE_ID,
            "x": 12,
            "y": 90,
            "w": 21,
            "h": 16,
            **copy.deepcopy(ZONE_VALUES),
        },
        {
            "id": LANDMARK_ID,
            "type": "marker",
            "x": 15,
            "y": 93,
            "w": 7,
            "h": 5,
            "regional_landmark": True,
            "regional_journey_id": ROUTE_ID,
            "landmark_label": "Far-West Deeper Wreck",
        },
    ])
    map_data["background"].append({
        "id": BACKGROUND_ID,
        "type": "background",
        "x": 15,
        "y": 93,
        "w": 7,
        "h": 5,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
    })
    map_data["entities"].append({
        "id": TOOL_TARGET_ID,
        "x": 17,
        "y": 96,
        **copy.deepcopy(TOOL_TARGET_VALUES),
    })
    map_data["regional_journeys"].append({
        "id": ROUTE_ID,
        **copy.deepcopy(ROUTE_VALUES),
        "intent": "Turn the committed relay signal into one prepared far-west wreck return.",
    })
    map_data["survey_targets"].append({
        "id": SURVEY_ID,
        "x": 15,
        "y": 95,
        "w": 2,
        "h": 2,
        **copy.deepcopy(SURVEY_VALUES),
    })
    return map_data
class DeeperWreckValidationTests(unittest.TestCase):
    def test_accepts_exact_chain_and_route_equations(self) -> None:
        map_data = authored_fixture()
        self.assertEqual(
            [],
            validate_deeper_wreck_schema(MAP_PATH, map_data, contract_with_rebreather()),
        )
        budget = deeper_wreck_route_budget(map_data)
        self.assertGreaterEqual(float(budget["protected_margin_seconds"]), 12.0)
        self.assertGreater(float(budget["optional_shortfall_seconds"]), 0.0)
        self.assertGreater(float(budget["zone_critical_seconds"]), 0.0)
        self.assertEqual([], validate_material_source_schema(map_data))
        self.assertEqual([], validate_regional_journey_schema(map_data))
        self.assertEqual([], validate_survey_target_schema(MAP_PATH, map_data))

    def test_rejects_recipe_zone_chain_and_runtime_drift(self) -> None:
        map_data = authored_fixture()
        project = next(item for item in map_data["material_projects"] if item["id"] == PROJECT_ID)
        zone = next(item for item in map_data["zones"] if item["id"] == ZONE_ID)
        target = next(item for item in map_data["entities"] if item["id"] == TOOL_TARGET_ID)
        survey = next(item for item in map_data["survey_targets"] if item["id"] == SURVEY_ID)
        project["required_materials"]["titanium_scrap"] = 2
        zone["unprotected_oxygen_drain_multiplier"] = 2.0
        zone["world_connector"] = True
        target["unlocks_survey_target_id"] = "wrong_survey"
        survey["required_oxygen_capability_id"] = CAPABILITY_ID
        survey["pending"] = True
        failures = validate_deeper_wreck_schema(
            MAP_PATH, map_data, contract_with_rebreather()
        )
        expected = (
            "required_materials must be exactly",
            "unprotected_oxygen_drain_multiplier must be exactly 8.0",
            "must not author collision, travel, or damage fields",
            "unlocks_survey_target_id must be exactly",
            "must not add explicit interaction gate",
            "must not author runtime state fields",
        )
        for text in expected:
            self.assertTrue(any(text in failure for failure in failures), (text, failures))

    def test_rejects_purchase_owner_circular_knowledge_and_missing_material(self) -> None:
        map_data = authored_fixture()
        knowledge = next(
            item for item in map_data["survey_targets"]
            if item.get("discovery_id") == KNOWLEDGE_ID
        )
        knowledge["required_capability_id"] = CAPABILITY_ID
        for pool in map_data["material_candidate_pools"]:
            if pool.get("material_id") == "rubber_sheet":
                pool["select_count"] = 0
        contract = contract_with_rebreather()
        contract["session_upgrades"].append({"id": CAPABILITY_ID})
        contract["durable_capabilities"] = [
            item for item in contract["durable_capabilities"]
            if item["id"] != CAPABILITY_ID
        ]
        failures = validate_deeper_wreck_schema(MAP_PATH, map_data, contract)
        self.assertTrue(any("score/session purchase ownership" in failure for failure in failures), failures)
        self.assertTrue(any("durable capability declaration" in failure for failure in failures), failures)
        self.assertTrue(any("must not require the rebreather" in failure for failure in failures), failures)
        self.assertTrue(any("rubber_sheet" in failure and "provide 0" in failure for failure in failures), failures)

    def test_route_budget_rejects_optional_tank_substitution(self) -> None:
        bypass_budget = {
            "protected_demand_seconds": 70.0,
            "unprotected_demand_seconds": 90.0,
            "scout_demand_seconds": 50.0,
            "zone_critical_seconds": 2.0,
        }
        with patch(
            "validate_deeper_wreck_return.deeper_wreck_route_budget",
            return_value=bypass_budget,
        ):
            failures = validate_deeper_wreck_routes(authored_fixture())
        self.assertTrue(any("completed with oxygen_tank_1" in failure for failure in failures), failures)

    def test_partial_records_activate_complete_contract(self) -> None:
        map_data = map_without_records()
        self.assertEqual(
            [],
            validate_deeper_wreck_schema(MAP_PATH, map_data, contract_with_rebreather()),
        )
        map_data["zones"].append({"id": ZONE_ID, "oxygen_consumption_zone": True})
        failures = validate_deeper_wreck_schema(
            MAP_PATH, map_data, contract_with_rebreather()
        )
        self.assertTrue(any("requires exactly one material_projects" in failure for failure in failures), failures)
        self.assertTrue(any("requires exactly one survey_targets" in failure for failure in failures), failures)

    def test_progression_graph_classifies_zone_as_soft_pressure(self) -> None:
        graph = build_progression_graph([authored_fixture()], contract_with_rebreather())
        zone_key = graph.resolve(ZONE_ID, "production_level_01")
        capability_key = graph.resolve(CAPABILITY_ID)
        self.assertEqual("pressure", graph.nodes[zone_key].kind)
        requirements = [
            edge for edge in graph.outgoing(zone_key, "requires")
            if edge.target == capability_key
        ]
        self.assertEqual(1, len(requirements))
        self.assertFalse(requirements[0].hard)
        self.assertIn(graph.resolve(DISCOVERY_ID), graph.nodes)
        self.assertIn(graph.resolve(BOAT_ID, "production_level_01"), graph.nodes)


if __name__ == "__main__":
    unittest.main()
