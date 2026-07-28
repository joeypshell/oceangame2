#!/usr/bin/env python3
"""Focused positive and negative tests for the Expansion 13 wreck chain."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from progression_audit import audit_graph
from progression_contract import load_contract
from progression_graph import build_progression_graph
from validate_regional_journeys import validate_regional_journey_schema
from validate_southeast_wreck_return import (
    BACKGROUND_ID,
    DISCOVERY_ID,
    LANDMARK_ID,
    NAVIGATION_DATA_ID,
    PAYOFF_TARGET_ID,
    PRESSURE_ZONE_ID,
    RECORDER_ID,
    ROUTE_ID,
    SURVEY_ID,
    southeast_wreck_route_budget,
    validate_southeast_wreck_routes,
    validate_southeast_wreck_schema,
)
from validate_survey_targets import validate_survey_target_schema


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "production_level_01.greybox.json"


def current_map() -> dict:
    return json.loads(MAP_PATH.read_text(encoding="utf-8"))


def map_without_wreck_records() -> dict:
    map_data = current_map()
    map_data["zones"] = [item for item in map_data["zones"] if item.get("id") != LANDMARK_ID]
    map_data["background"] = [item for item in map_data["background"] if item.get("id") != BACKGROUND_ID]
    map_data["entities"] = [item for item in map_data["entities"] if item.get("id") != RECORDER_ID]
    map_data["survey_targets"] = [
        item for item in map_data["survey_targets"]
        if item.get("id") != SURVEY_ID and item.get("discovery_id") != DISCOVERY_ID
    ]
    map_data["regional_journeys"] = [
        item for item in map_data["regional_journeys"] if item.get("id") != ROUTE_ID
    ]
    payoff = next(item for item in map_data["entities"] if item.get("id") == PAYOFF_TARGET_ID)
    for field in (
        "reward_kind", "reward_id", "reward_pending_label", "reward_commit_label",
        "reward_next_lead_label", "reward_commit_map_id", "reward_commit_map_path",
        "reward_commit_entry_id",
    ):
        payoff.pop(field, None)
    return map_data


def authored_fixture() -> dict:
    map_data = current_map()
    if any(item.get("id") == ROUTE_ID for item in map_data.get("regional_journeys", [])):
        return map_data
    map_data["zones"].append({
        "id": LANDMARK_ID,
        "type": "marker",
        "x": 146,
        "y": 143,
        "w": 5,
        "h": 9,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
        "landmark_label": "Southeast Wreck Archive",
    })
    map_data["background"].append({
        "id": BACKGROUND_ID,
        "type": "background",
        "x": 146,
        "y": 143,
        "w": 5,
        "h": 9,
        "regional_landmark": True,
        "regional_journey_id": ROUTE_ID,
        "intent": "Distinct non-collision archive silhouette in the far southeast chamber.",
    })
    map_data["entities"].append({
        "id": RECORDER_ID,
        "type": "tool_target",
        "x": 147,
        "y": 149,
        "kind": "crate",
        "tier": "valuable",
        "interaction": "cutter_salvage",
        "interaction_seconds": 2.0,
        "interaction_label": "wreck recorder",
        "required_tool_id": "salvage_cutter",
        "tool_project_id": "salvage_cutter_project",
        "unlocks_survey_target_id": SURVEY_ID,
        "durable_clearance": True,
        "intent": "Cutter-opened recorder whose clearance exposes the archive survey.",
    })
    map_data["survey_targets"].append({
        "id": SURVEY_ID,
        "target_type": "regional",
        "x": 149,
        "y": 149,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "required_pressure_capability_id": "pressure_suit_1",
        "required_route_id": ROUTE_ID,
        "route_context": ROUTE_ID,
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Survey wreck archive",
        "clue_label": "Wreck archive | Recorder access required",
        "finding_label": "Discovery logged: Southeast wreck archive",
        "next_lead_label": "Next lead: distant wreck network unresolved",
        "discovery_id": DISCOVERY_ID,
        "commit_map_id": "production_level_01",
        "commit_map_path": "res://maps/production_level_01.greybox.json",
        "commit_entry_id": "surface_boat_entry",
        "intent": "Pending archive finding returns to the canonical boat.",
    })
    map_data["regional_journeys"].append({
        "id": ROUTE_ID,
        "route_label": "Southeast wreck archive route",
        "promise_gate_id": "abyssal_basin_landmark",
        "entry_gate_ids": [PRESSURE_ZONE_ID],
        "required_capability_id": "pressure_suit_1",
        "required_discovery_id": NAVIGATION_DATA_ID,
        "landmark_zone_id": LANDMARK_ID,
        "tool_target_id": RECORDER_ID,
        "survey_target_id": SURVEY_ID,
        "commit_entry_id": "surface_boat_entry",
        "route_context": ROUTE_ID,
        "intent": "Reuse the pressure route for a cutter and scanner return chain.",
    })
    return map_data


class SoutheastWreckValidationTests(unittest.TestCase):
    def test_map_without_records_keeps_validator_dormant(self) -> None:
        self.assertEqual([], validate_southeast_wreck_schema(map_without_wreck_records()))
        self.assertEqual([], validate_southeast_wreck_routes(map_without_wreck_records()))

    def test_accepts_exact_chain_and_tight_optional_route_budget(self) -> None:
        map_data = authored_fixture()
        self.assertEqual([], validate_southeast_wreck_schema(map_data))
        self.assertEqual([], validate_southeast_wreck_routes(map_data))
        self.assertEqual([], validate_regional_journey_schema(map_data))
        self.assertEqual([], validate_survey_target_schema(MAP_PATH, map_data))
        budget = southeast_wreck_route_budget(map_data)
        self.assertGreater(float(budget["base_margin"]), 0.0)
        self.assertLess(float(budget["base_margin"]), 20.0)
        self.assertGreater(float(budget["upgraded_margin"]), float(budget["base_margin"]))

    def test_rejects_missing_duplicate_and_reciprocal_dependency(self) -> None:
        map_data = authored_fixture()
        recorder = next(item for item in map_data["entities"] if item["id"] == RECORDER_ID)
        survey = next(item for item in map_data["survey_targets"] if item["id"] == SURVEY_ID)
        recorder.pop("unlocks_survey_target_id")
        survey["required_tool_target_id"] = RECORDER_ID
        duplicate = copy.deepcopy(recorder)
        duplicate["id"] = "duplicate_wreck_recorder"
        duplicate["unlocks_survey_target_id"] = SURVEY_ID
        map_data["entities"].append(duplicate)
        failures = validate_southeast_wreck_schema(map_data)
        self.assertTrue(any("exactly one source unlock owner" in failure for failure in failures), failures)
        self.assertTrue(any("must not duplicate" in failure for failure in failures), failures)

    def test_progression_graph_orders_discovery_route_recorder_and_survey(self) -> None:
        map_data = authored_fixture()
        contract = copy.deepcopy(load_contract())
        contract["canonical_start"] = {"map_id": "production_level_01", "entry_id": "surface_boat_entry"}
        for purchase in contract["durable_purchases"]:
            purchase["purchase_map_id"] = "production_level_01"
            purchase["purchase_entry_id"] = "surface_boat_entry"
        graph = build_progression_graph([map_data], contract)
        result = audit_graph(graph)
        self.assertEqual((), result.failures)
        route = graph.resolve(ROUTE_ID)
        recorder = graph.resolve(RECORDER_ID)
        survey = graph.resolve(SURVEY_ID)
        navigation_data = graph.resolve(NAVIGATION_DATA_ID)
        payoff = graph.resolve(PAYOFF_TARGET_ID)
        discovery = graph.resolve(DISCOVERY_ID)
        boat = graph.resolve("surface_boat_entry")
        self.assertTrue(any(edge.target == navigation_data for edge in graph.requirements(route)))
        self.assertTrue(any(edge.target == payoff for edge in graph.requirements(navigation_data)))
        self.assertTrue(any(edge.target == recorder for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == route for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == survey for edge in graph.requirements(discovery)))
        self.assertTrue(any(edge.target == boat for edge in graph.requirements(discovery)))
        self.assertLess(result.stages[payoff], result.stages[navigation_data])
        self.assertLess(result.stages[navigation_data], result.stages[route])
        self.assertLess(result.stages[recorder], result.stages[survey])

    def test_rejects_circular_discovery_wrong_capability_and_terrain_drift(self) -> None:
        map_data = authored_fixture()
        route = next(item for item in map_data["regional_journeys"] if item["id"] == ROUTE_ID)
        survey = next(item for item in map_data["survey_targets"] if item["id"] == SURVEY_ID)
        producer = next(item for item in map_data["entities"] if item.get("id") == PAYOFF_TARGET_ID)
        producer["required_route_id"] = ROUTE_ID
        route["required_capability_id"] = "oxygen_tank_1"
        survey["required_pressure_capability_id"] = "wrong_suit"
        map_data["terrain"][0]["w"] += 1
        failures = validate_southeast_wreck_schema(map_data)
        self.assertTrue(any("must not depend on the route" in failure for failure in failures), failures)
        self.assertTrue(any("pressure_suit_1" in failure for failure in failures), failures)
        self.assertTrue(any("terrain topology" in failure for failure in failures), failures)

    def test_rejects_easy_bypass_and_non_tight_base_margin(self) -> None:
        map_data = authored_fixture()
        landmark = next(item for item in map_data["zones"] if item["id"] == LANDMARK_ID)
        backdrop = next(item for item in map_data["background"] if item["id"] == BACKGROUND_ID)
        recorder = next(item for item in map_data["entities"] if item["id"] == RECORDER_ID)
        survey = next(item for item in map_data["survey_targets"] if item["id"] == SURVEY_ID)
        near_boat = {"x": 96, "y": 10}
        landmark.update({**near_boat, "w": 4, "h": 4})
        backdrop.update({**near_boat, "w": 4, "h": 4})
        recorder.update({"x": 97, "y": 11})
        survey.update({"x": 98, "y": 11, "w": 1, "h": 1})
        failures = validate_southeast_wreck_routes(map_data)
        self.assertTrue(any("not tight" in failure for failure in failures), failures)
        self.assertTrue(any("bypasses" in failure for failure in failures), failures)

    def test_partial_record_activates_complete_contract(self) -> None:
        map_data = map_without_wreck_records()
        map_data["regional_journeys"].append({"id": ROUTE_ID})
        failures = validate_southeast_wreck_schema(map_data)
        self.assertTrue(any("requires exactly one entities" in failure for failure in failures), failures)
        self.assertTrue(any("requires exactly one survey_targets" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
