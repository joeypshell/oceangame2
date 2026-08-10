#!/usr/bin/env python3
"""Focused schema and progression fixtures for Living Expedition 05."""

from __future__ import annotations

import copy
import unittest

from living_expedition_05_contract import (
    CANDIDATE_ID,
    CONTEXT_ID,
    EXCAVATE_CAMERA_ID,
    INDIVIDUAL_ID,
    POOL_ID,
    RESCUE_CAMERA_ID,
    RESCUE_ID,
)
from progression_audit import audit_graph
from progression_graph import build_progression_graph
from test_progression_graph_creatures import contract
from test_validate_living_expedition_schema import valid_map
from validate_living_expedition_schema import (
    load_creature_catalog,
    validate_creature_catalog,
    validate_living_expedition_reachability,
    validate_living_expedition_schema,
)


def valid_living_expedition_05_map() -> dict:
    payload = copy.deepcopy(valid_map())
    payload["creature_rescues"].append({
        "id": RESCUE_ID,
        "species_id": "silt_hound",
        "individual_id": INDIVIDUAL_ID,
        "x": 11,
        "y": 7,
        "rescue_kind": "physical_aid",
        "required_capability_id": "salvage_cutter",
        "commit_map_id": "production_level_01",
        "commit_entry_id": "surface_boat_entry",
        "habitat_id": "companion_habitat_01",
        "excavation_context_id": CONTEXT_ID,
        "buried_candidate_id": CANDIDATE_ID,
        "review_camera_id": RESCUE_CAMERA_ID,
        "optional": True,
        "availability": "all_supported_seeds",
    })
    payload["companion_habitats"][0]["individual_ids"].append(INDIVIDUAL_ID)
    payload["companion_contexts"].append({
        "id": CONTEXT_ID,
        "context_kind": "material_excavation_review",
        "species_id": "silt_hound",
        "individual_id": INDIVIDUAL_ID,
        "action_id": "excavate",
        "target_id": CANDIDATE_ID,
        "commit_entry_id": "surface_boat_entry",
        "required_access_ids": [],
        "availability": "all_supported_seeds",
    })
    payload["entities"].append({
        "id": CANDIDATE_ID,
        "type": "material_candidate",
        "x": 12,
        "y": 7,
        "interaction": "material_collect",
        "material_id": "titanium_scrap",
        "material_quantity": 1,
        "candidate_pool_id": POOL_ID,
        "buried_deposit": True,
        "required_companion_action_id": "excavate",
        "companion_context_id": CONTEXT_ID,
        "presentation_kind": "buried_mineral_mound",
    })
    payload["material_candidate_pools"] = [{
        "id": POOL_ID,
        "material_id": "titanium_scrap",
        "selection_strategy": "day_rotation_v1",
        "select_count": 1,
        "candidate_ids": [CANDIDATE_ID],
        "guaranteed_candidate_ids": [CANDIDATE_ID],
        "pool_role": "optional_bonus",
    }]
    payload["camera_tests"].extend([
        {"id": RESCUE_CAMERA_ID, "center_x": 11, "center_y": 7, "zoom": 0.6},
        {"id": EXCAVATE_CAMERA_ID, "center_x": 12, "center_y": 7, "zoom": 0.6},
    ])
    payload["source"] = {
        "living_expedition_05": {
            "source": "tools/production_level_01_living_expedition_05.py",
            "rescue_ids": [RESCUE_ID],
            "habitat_ids": ["companion_habitat_01"],
            "companion_context_ids": [CONTEXT_ID],
            "material_candidate_ids": [CANDIDATE_ID],
            "material_pool_ids": [POOL_ID],
            "camera_test_ids": [RESCUE_CAMERA_ID, EXCAVATE_CAMERA_ID],
            "availability": "all_supported_seeds",
            "terrain_changes": [],
        }
    }
    return payload


class LivingExpedition05ContractTests(unittest.TestCase):
    def test_catalog_and_complete_relationship_are_valid(self) -> None:
        catalog = load_creature_catalog()
        self.assertEqual([], validate_creature_catalog(catalog))
        self.assertEqual([], validate_living_expedition_schema(valid_living_expedition_05_map(), catalog))

    def test_unknown_action_material_and_endpoint_are_rejected(self) -> None:
        payload = valid_living_expedition_05_map()
        payload["companion_contexts"][-1]["action_id"] = "mystery_dig"
        payload["entities"][-1]["material_id"] = "mystery_ore"
        payload["camera_tests"] = [
            item for item in payload["camera_tests"] if item["id"] != EXCAVATE_CAMERA_ID
        ]
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("unknown action" in failure for failure in failures), failures)
        self.assertTrue(any("material_id" in failure for failure in failures), failures)
        self.assertTrue(any(EXCAVATE_CAMERA_ID in failure for failure in failures), failures)

    def test_duplicates_geometry_and_unrelated_metadata_are_rejected(self) -> None:
        payload = valid_living_expedition_05_map()
        payload["material_candidate_pools"].append(copy.deepcopy(payload["material_candidate_pools"][-1]))
        payload["creature_rescues"][-1]["x"] = 20
        payload["terrain"] = [{"type": "solid", "x": 12, "y": 7, "w": 1, "h": 1}]
        payload["entities"][0]["buried_deposit"] = True
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("exactly one material_candidate_pools" in failure for failure in failures), failures)
        self.assertTrue(any("out of bounds" in failure for failure in failures), failures)
        self.assertTrue(any("inside solid terrain" in failure for failure in failures), failures)
        self.assertTrue(any("cannot use Silt Hound excavation metadata" in failure for failure in failures), failures)

    def test_optional_chain_cannot_become_a_required_project_dependency(self) -> None:
        payload = valid_living_expedition_05_map()
        payload["material_projects"].append({
            "id": "bad_required_excavation",
            "required_materials": {CANDIDATE_ID: 1},
        })
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("cannot depend on the optional Silt Hound chain" in failure for failure in failures))

    def test_uncontracted_required_metadata_is_rejected(self) -> None:
        payload = valid_living_expedition_05_map()
        payload["companion_contexts"][-1]["required_adaptation_id"] = "root_claws"
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("unsupported source fields" in failure for failure in failures), failures)

    def test_rescue_deposit_and_boat_must_share_reachable_water(self) -> None:
        payload = valid_living_expedition_05_map()
        reachable = {(x, y) for x in range(20) for y in range(12)} - {(11, 7), (12, 7), (2, 2)}
        failures = validate_living_expedition_reachability(payload, set(), reachable)
        self.assertTrue(any("rescue site is unreachable" in failure for failure in failures), failures)
        self.assertTrue(any("excavation deposit is unreachable" in failure for failure in failures), failures)
        self.assertTrue(any("canonical boat return is unreachable" in failure for failure in failures), failures)

    def test_graph_exposes_ordered_optional_rescue_to_bank_chain(self) -> None:
        graph = build_progression_graph([valid_living_expedition_05_map()], contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        aliases = (
            RESCUE_ID,
            f"{INDIVIDUAL_ID}_commitment",
            f"{INDIVIDUAL_ID}_active_selection",
            CONTEXT_ID,
            CANDIDATE_ID,
            f"{CANDIDATE_ID}_banked",
        )
        keys = [graph.resolve(alias) for alias in aliases]
        self.assertTrue(all(key in result.stages for key in keys), keys)
        self.assertTrue(all(
            result.stages[first] < result.stages[second]
            for first, second in zip(keys, keys[1:])
        ))
        self.assertTrue(all(not graph.nodes[key].mandatory for key in keys))
        self.assertLessEqual(result.stages[graph.resolve(INDIVIDUAL_ID)], result.stages[keys[2]])
        candidate = graph.resolve(CANDIDATE_ID)
        hard_dependents = [
            node.key
            for node in graph.nodes.values()
            if node.mandatory and any(edge.target == candidate for edge in graph.requirements(node.key))
        ]
        self.assertEqual([], hard_dependents)
        pool = graph.resolve(POOL_ID)
        self.assertTrue(any(edge.relation == "optional_reward" for edge in graph.outgoing(pool)))


if __name__ == "__main__":
    unittest.main()
