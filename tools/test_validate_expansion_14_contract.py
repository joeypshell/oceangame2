#!/usr/bin/env python3
"""Focused fixtures for the Expansion 14 archive-current contract."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from progression_audit import audit_graph
from progression_contract import load_contract
from progression_graph import build_progression_graph
from test_validate_material_sources import valid_map, with_stabilizer_project
from validate_expansion_14_contract import (
    ARCHIVE_DISCOVERY_ID,
    CAPABILITY_ID,
    CORE_ID,
    DISCOVERY_ID,
    GATE_ID,
    LANDMARK_ID,
    PROJECT_ID,
    ROUTE_ID,
    SURVEY_ID,
    validate_expansion_14_contract,
    validate_expansion_14_schema,
)
from validate_material_sources import validate_material_source_schema
from validate_regional_journeys import validate_regional_journey_schema
from validate_survey_targets import validate_survey_target_schema


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "production_level_01.greybox.json"
INTERIOR_MAP_PATH = ROOT / "maps" / "transfer_hub_interior_01.greybox.json"


def current_map() -> dict:
    return json.loads(MAP_PATH.read_text(encoding="utf-8"))


def authored_fixture() -> dict:
    return current_map()


def without_expansion_14() -> dict:
    map_data = current_map()
    ids_by_collection = {
        "material_projects": {PROJECT_ID},
        "zones": {GATE_ID, LANDMARK_ID},
        "regional_journeys": {ROUTE_ID},
        "entities": {CORE_ID},
        "survey_targets": {SURVEY_ID},
    }
    for collection, item_ids in ids_by_collection.items():
        map_data[collection] = [
            item for item in map_data[collection] if item.get("id") not in item_ids
        ]
    map_data["background"] = [
        item for item in map_data["background"] if item.get("regional_journey_id") != ROUTE_ID
    ]
    return map_data


def fixture_graph(map_data: dict):
    contract = copy.deepcopy(load_contract())
    contract["canonical_start"] = {"map_id": "production_level_01", "entry_id": "surface_boat_entry"}
    interior_map = json.loads(INTERIOR_MAP_PATH.read_text(encoding="utf-8"))
    return build_progression_graph([map_data, interior_map], contract)


class Expansion14ContractTests(unittest.TestCase):
    def test_current_generated_map_matches_contract(self) -> None:
        self.assertEqual([], validate_expansion_14_contract(current_map()))

    def test_accepts_canonical_source_relationships_and_footprint_gate(self) -> None:
        map_data = authored_fixture()
        self.assertEqual([], validate_material_source_schema(map_data))
        self.assertEqual([], validate_regional_journey_schema(map_data))
        self.assertEqual([], validate_survey_target_schema(MAP_PATH, map_data))
        self.assertEqual([], validate_expansion_14_contract(map_data))

    def test_preserves_legacy_pair_and_rejects_mixed_pairings(self) -> None:
        legacy = with_stabilizer_project(valid_map())
        self.assertEqual([], validate_material_source_schema(legacy))
        legacy["material_projects"][-1]["target_gate_id"] = GATE_ID
        failures = validate_material_source_schema(legacy)
        self.assertTrue(any("target_gate_id must be 'lower_left_loop_current'" in failure for failure in failures), failures)

        canonical = authored_fixture()
        project = next(item for item in canonical["material_projects"] if item["id"] == PROJECT_ID)
        project["required_discovery_id"] = "lower_right_anomaly_discovery"
        failures = validate_material_source_schema(canonical)
        self.assertTrue(any(ARCHIVE_DISCOVERY_ID in failure for failure in failures), failures)

        unsupported = authored_fixture()
        unsupported["id"] = "uncontracted_future_map"
        failures = validate_material_source_schema(unsupported)
        self.assertTrue(any("not supported on map" in failure for failure in failures), failures)

    def test_rejects_wrong_recipe_target_and_capability_relationships(self) -> None:
        map_data = authored_fixture()
        project = next(item for item in map_data["material_projects"] if item["id"] == PROJECT_ID)
        gate = next(item for item in map_data["zones"] if item["id"] == GATE_ID)
        project["required_materials"]["titanium_scrap"] = 3
        project["target_gate_id"] = "missing_relay_gate"
        gate["required_capability_id"] = "propulsion_fins"
        failures = validate_material_source_schema(map_data) + validate_expansion_14_schema(map_data)
        self.assertTrue(any("required_materials must be exactly" in failure for failure in failures), failures)
        self.assertTrue(any("target_gate_id" in failure for failure in failures), failures)
        self.assertTrue(any("current_stabilizer" in failure or "project capability" in failure for failure in failures), failures)

    def test_rejects_duplicate_ownership_and_circular_discovery(self) -> None:
        map_data = authored_fixture()
        duplicate = copy.deepcopy(next(item for item in map_data["material_projects"] if item["id"] == PROJECT_ID))
        duplicate["id"] = "duplicate_stabilizer_owner"
        map_data["material_projects"].append(duplicate)
        route = next(item for item in map_data["regional_journeys"] if item["id"] == ROUTE_ID)
        route["required_discovery_id"] = DISCOVERY_ID
        failures = validate_expansion_14_schema(map_data)
        self.assertTrue(any("exactly one compatible project owner" in failure for failure in failures), failures)
        self.assertTrue(any("required_discovery_id" in failure for failure in failures), failures)
        graph_failures = audit_graph(fixture_graph(map_data)).failures
        self.assertTrue(any("Hard dependency cycle" in failure for failure in graph_failures), graph_failures)

    def test_progression_graph_orders_archive_project_gate_and_relay_result(self) -> None:
        graph = fixture_graph(authored_fixture())
        result = audit_graph(graph)
        self.assertEqual((), result.failures)
        chain = [
            ARCHIVE_DISCOVERY_ID,
            PROJECT_ID,
            CAPABILITY_ID,
            GATE_ID,
            SURVEY_ID,
            DISCOVERY_ID,
        ]
        keys = [graph.resolve(raw_id) for raw_id in chain]
        self.assertTrue(all(key in result.stages for key in keys))
        self.assertTrue(all(result.stages[left] < result.stages[right] for left, right in zip(keys, keys[1:])))
        self.assertTrue(any(edge.target == keys[0] for edge in graph.requirements(keys[1])))
        self.assertTrue(any(edge.target == keys[1] for edge in graph.requirements(keys[2])))
        self.assertTrue(any(edge.target == keys[2] for edge in graph.requirements(keys[3])))
        self.assertTrue(any(edge.target == graph.resolve(ROUTE_ID) for edge in graph.requirements(keys[4])))
        self.assertTrue(any(edge.target == keys[4] for edge in graph.requirements(keys[5])))

    def test_partial_record_requires_the_complete_contract(self) -> None:
        map_data = without_expansion_14()
        map_data["zones"].append({"id": GATE_ID})
        failures = validate_expansion_14_schema(map_data)
        self.assertTrue(any("requires exactly one material_projects" in failure for failure in failures), failures)
        self.assertTrue(any("requires exactly one survey_targets" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
