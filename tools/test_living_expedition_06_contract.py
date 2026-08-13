#!/usr/bin/env python3
"""Focused schema and progression fixtures for Living Expedition 06."""

from __future__ import annotations

import copy
import unittest

from living_expedition_06_contract import (
    ACCESS_IDS,
    ANCHOR_CONTEXT_ID,
    BOAT_ENTRY_ID,
    CAMERA_IDS,
    COMMITMENT_EVENT_ID,
    DARK_ZONE_ID,
    EAST_GATE_ID,
    GUARDIAN_CONTEXT_ID,
    JOURNEY_ID,
    LANDMARK_ID,
    NURSERY_ID,
    PRESSURE_ID,
    ROUTE_ID,
    SCHOOL_ID,
    WEST_GATE_ID,
)
from progression_audit import audit_graph, render_review_doc
from progression_graph import build_progression_graph
from test_progression_graph_creatures import contract
from test_validate_living_expedition_schema import valid_map
from validate_living_expedition_schema import (
    validate_living_expedition_reachability,
    validate_living_expedition_schema,
)


def valid_living_expedition_06_map() -> dict:
    payload = copy.deepcopy(valid_map())
    payload["zones"].extend([
        {
            "id": WEST_GATE_ID, "type": "marker", "x": 8, "y": 5, "w": 2, "h": 3,
            "current_gate": True, "required_capability_id": "propulsion_fins",
        },
        {
            "id": EAST_GATE_ID, "type": "marker", "x": 16, "y": 5, "w": 2, "h": 3,
            "current_gate": True, "required_capability_id": "propulsion_fins",
        },
        {
            "id": LANDMARK_ID, "type": "marker", "x": 12, "y": 6, "w": 4, "h": 4,
            "regional_landmark": True, "regional_journey_id": ROUTE_ID,
        },
        {
            "id": DARK_ZONE_ID, "type": "marker", "x": 12, "y": 8, "w": 4, "h": 3,
            "visibility_zone": True, "required_upgrade_id": "dive_light_1",
        },
    ])
    payload["regional_journeys"] = [{
        "id": ROUTE_ID,
        "required_capability_id": "propulsion_fins",
        "entry_gate_ids": [WEST_GATE_ID, EAST_GATE_ID],
        "landmark_zone_id": LANDMARK_ID,
        "commit_entry_id": BOAT_ENTRY_ID,
    }]
    payload["material_projects"].append({
        "id": "light_fixture_project",
        "required_materials": {},
        "unlocks_capability_id": "dive_light_1",
    })
    payload["regional_creature_journeys"] = [{
        "id": JOURNEY_ID,
        "journey_kind": "regional_habitat_restoration",
        "species_id": "spark_ray",
        "individual_id": "spark_ray_juvenile_01",
        "school_id": SCHOOL_ID,
        "nursery_id": NURSERY_ID,
        "pressure_id": PRESSURE_ID,
        "adaptation_context_ids": [ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID],
        "route_id": ROUTE_ID,
        "gate_ids": [WEST_GATE_ID, EAST_GATE_ID],
        "landmark_zone_id": LANDMARK_ID,
        "dark_zone_id": DARK_ZONE_ID,
        "commit_map_id": "production_level_01",
        "commit_entry_id": BOAT_ENTRY_ID,
        "commitment_event_id": COMMITMENT_EVENT_ID,
        "review_camera_ids": CAMERA_IDS,
        "required_access_ids": ACCESS_IDS,
        "optional": True,
        "reward_ids": [],
        "progression_effect": "none",
        "availability": "all_supported_seeds",
    }]
    payload["passive_wildlife_groups"] = [{
        "id": SCHOOL_ID,
        "wildlife_kind": "juvenile_filter_skate_school",
        "x": 10,
        "y": 7,
        "path": [{"x": 10, "y": 7}, {"x": 12, "y": 7}, {"x": 14, "y": 8}],
        "nursery_id": NURSERY_ID,
        "pressure_id": PRESSURE_ID,
        "bondable": False,
        "harvestable": False,
        "collectible": False,
        "reward_ids": [],
        "availability": "all_supported_seeds",
    }]
    payload["creature_nurseries"] = [{
        "id": NURSERY_ID,
        "nursery_kind": "filter_skate_nursery",
        "x": 13,
        "y": 7,
        "w": 3,
        "h": 2,
        "school_id": SCHOOL_ID,
        "landmark_zone_id": LANDMARK_ID,
        "availability": "all_supported_seeds",
    }]
    payload["ecological_pressures"] = [{
        "id": PRESSURE_ID,
        "pressure_kind": "jellyfish_displacement_cycle",
        "x": 9,
        "y": 6,
        "w": 3,
        "h": 3,
        "path": [{"x": 9, "y": 6}, {"x": 11, "y": 6}],
        "school_id": SCHOOL_ID,
        "damaging": False,
        "reward_ids": [],
        "availability": "all_supported_seeds",
    }]
    payload["companion_contexts"].extend([
        {
            "id": ANCHOR_CONTEXT_ID,
            "context_kind": "regional_journey_action",
            "branch_kind": "current_lee",
            "species_id": "spark_ray",
            "individual_id": "spark_ray_juvenile_01",
            "journey_id": JOURNEY_ID,
            "action_id": "anchor_brace",
            "required_adaptation_id": "anchor_fins",
            "target_id": EAST_GATE_ID,
            "school_id": SCHOOL_ID,
            "nursery_id": NURSERY_ID,
            "required_access_ids": ACCESS_IDS,
            "availability": "all_supported_seeds",
        },
        {
            "id": GUARDIAN_CONTEXT_ID,
            "context_kind": "regional_journey_action",
            "branch_kind": "pressure_interrupt",
            "species_id": "spark_ray",
            "individual_id": "spark_ray_juvenile_01",
            "journey_id": JOURNEY_ID,
            "action_id": "guardian_pulse_action",
            "required_adaptation_id": "guardian_pulse",
            "target_id": PRESSURE_ID,
            "school_id": SCHOOL_ID,
            "nursery_id": NURSERY_ID,
            "required_access_ids": ACCESS_IDS,
            "availability": "all_supported_seeds",
        },
    ])
    payload["camera_tests"].extend([
        {"id": camera_id, "center_x": 12 + index, "center_y": 7, "zoom": 0.6}
        for index, camera_id in enumerate(CAMERA_IDS)
    ])
    payload["source"] = {
        "living_expedition_06": {
            "source": "tools/production_level_01_living_expedition_06.py",
            "journey_ids": [JOURNEY_ID],
            "passive_wildlife_ids": [SCHOOL_ID],
            "nursery_ids": [NURSERY_ID],
            "ecological_pressure_ids": [PRESSURE_ID],
            "companion_context_ids": [ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID],
            "camera_test_ids": CAMERA_IDS,
            "availability": "all_supported_seeds",
            "terrain_changes": [],
        }
    }
    return payload


def progression_contract() -> dict:
    value = copy.deepcopy(contract())
    value["durable_capabilities"].append({"id": "dive_light_1", "mandatory": False})
    return value


class LivingExpedition06ContractTests(unittest.TestCase):
    def test_complete_relationship_is_valid_and_reachable(self) -> None:
        payload = valid_living_expedition_06_map()
        reachable = {(x, y) for x in range(20) for y in range(12)}
        self.assertEqual([], validate_living_expedition_schema(payload))
        self.assertEqual([], validate_living_expedition_reachability(payload, set(), reachable))

    def test_missing_branch_and_unsupported_action_are_rejected(self) -> None:
        payload = valid_living_expedition_06_map()
        payload["companion_contexts"] = [
            item for item in payload["companion_contexts"] if item["id"] != GUARDIAN_CONTEXT_ID
        ]
        payload["companion_contexts"][-1]["action_id"] = "guardian_pulse_action"
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any(GUARDIAN_CONTEXT_ID in failure for failure in failures), failures)
        self.assertTrue(any("must be 'anchor_brace'" in failure for failure in failures), failures)
        self.assertTrue(any("adaptation/action combination is unsupported" in failure for failure in failures), failures)

    def test_rewards_mutable_state_and_seed_weights_are_rejected(self) -> None:
        payload = valid_living_expedition_06_map()
        payload["regional_creature_journeys"][0]["reward_ids"] = ["mystery_reward"]
        payload["passive_wildlife_groups"][0]["field_state"] = "restored"
        payload["ecological_pressures"][0]["spawn_chance"] = 0.5
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("reward_ids must be []" in failure for failure in failures), failures)
        self.assertTrue(any("mutable or seed-dependent fields" in failure for failure in failures), failures)

    def test_cross_collection_duplicate_id_is_rejected(self) -> None:
        payload = valid_living_expedition_06_map()
        payload["entities"].append({"id": SCHOOL_ID, "type": "salvage", "x": 5, "y": 5})
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("must occur exactly once" in failure for failure in failures), failures)

    def test_missing_target_camera_and_solid_geometry_are_rejected(self) -> None:
        payload = valid_living_expedition_06_map()
        payload["zones"] = [item for item in payload["zones"] if item["id"] != DARK_ZONE_ID]
        payload["camera_tests"] = [item for item in payload["camera_tests"] if item["id"] != CAMERA_IDS[-1]]
        payload["terrain"] = [{"type": "solid", "x": 13, "y": 7, "w": 1, "h": 1}]
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any(DARK_ZONE_ID in failure and "does not resolve" in failure for failure in failures), failures)
        self.assertTrue(any(CAMERA_IDS[-1] in failure and "does not resolve" in failure for failure in failures), failures)
        self.assertTrue(any("inside solid terrain" in failure for failure in failures), failures)

    def test_optional_journey_cannot_become_a_required_dependency(self) -> None:
        payload = valid_living_expedition_06_map()
        payload["material_projects"].append({
            "id": "bad_nursery_project",
            "required_discovery_id": COMMITMENT_EVENT_ID,
            "required_materials": {},
        })
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any("cannot depend on the optional LE06 chain" in failure for failure in failures), failures)

    def test_all_authored_wildlife_geometry_must_remain_reachable(self) -> None:
        payload = valid_living_expedition_06_map()
        reachable = {(x, y) for x in range(20) for y in range(12)} - {(14, 8)}
        failures = validate_living_expedition_reachability(payload, set(), reachable)
        self.assertTrue(any(SCHOOL_ID in failure for failure in failures), failures)

    def test_graph_exposes_optional_alternative_branches_and_restoration(self) -> None:
        graph = build_progression_graph([valid_living_expedition_06_map()], progression_contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        journey = graph.resolve(JOURNEY_ID)
        commitment = graph.resolve(COMMITMENT_EVENT_ID)
        restoration = graph.resolve(f"{JOURNEY_ID}_restored")
        self.assertTrue(all(key in result.stages for key in (journey, commitment, restoration)))
        self.assertLess(result.stages[journey], result.stages[commitment])
        self.assertLess(result.stages[commitment], result.stages[restoration])
        self.assertFalse(graph.nodes[journey].mandatory)
        requirements = {edge.target for edge in graph.requirements(journey)}
        self.assertTrue({graph.resolve(item) for item in ACCESS_IDS} <= requirements)
        alternatives = {
            edge.target for edge in graph.outgoing(commitment)
            if edge.relation == "requires" and not edge.hard
        }
        self.assertEqual({graph.resolve(ANCHOR_CONTEXT_ID), graph.resolve(GUARDIAN_CONTEXT_ID)}, alternatives)
        self.assertFalse([
            edge for edge in graph.outgoing(journey)
            if edge.relation in {"rewards", "guards", "funds"}
        ])
        review = render_review_doc(graph, result)
        self.assertIn("Signal Reef Nursery Journey 01", review)
        self.assertIn("Spark Ray Anchor Nursery Context 01", review)
        self.assertIn("Spark Ray Guardian Nursery Context 01", review)
        self.assertIn("one valid adaptation response", review)

    def test_progression_audit_reports_a_hard_relationship_cycle(self) -> None:
        payload = valid_living_expedition_06_map()
        payload["regional_creature_journeys"][0]["route_id"] = ANCHOR_CONTEXT_ID
        graph = build_progression_graph([payload], progression_contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)


if __name__ == "__main__":
    unittest.main()
