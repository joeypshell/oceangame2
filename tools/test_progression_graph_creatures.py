#!/usr/bin/env python3
"""Focused progression fixtures for proposed Living Expedition source nodes."""

from __future__ import annotations

import copy
import unittest

from progression_audit import audit_graph, render_review_doc
from progression_graph import build_progression_graph
from test_living_expedition_04_contract import valid_living_expedition_04_map
from test_validate_living_expedition_schema import valid_living_expedition_03_map, valid_map


def contract() -> dict:
    return {
        "version": 1,
        "canonical_start": {
            "map_id": "production_level_01",
            "entry_id": "surface_boat_entry",
        },
        "salvage_score_by_tier": {"common": 100, "valuable": 300},
        "session_upgrades": [
            {"id": "salvage_cutter", "cost": 0, "mandatory": False},
            {"id": "propulsion_fins", "cost": 0, "mandatory": False},
            {"id": "shock_prod", "cost": 0, "mandatory": False},
        ],
        "durable_capabilities": [
            {"id": "survey_scanner_1", "mandatory": False},
        ],
        "durable_purchases": [],
    }


class CreatureProgressionGraphTests(unittest.TestCase):
    def test_proposed_creature_chain_is_reachable_and_visibly_labeled(self) -> None:
        graph = build_progression_graph([valid_map()], contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        expected = (
            "spark_ray_rescue_01",
            "spark_ray_juvenile_01",
            "spark_ray_riding_review_01",
            "spark_ray_current_memory_01",
            "held_the_flow",
            "anchor_fins",
            "spark_ray_anchor_current_01",
        )
        keys = [graph.resolve(item) for item in expected]
        self.assertTrue(all(key in result.stages for key in keys), keys)
        proposed = [node for node in graph.nodes.values() if node.attrs.get("implementation_status") == "proposed"]
        self.assertTrue(proposed)
        self.assertTrue(all(node.label.startswith("[proposed]") for node in proposed))
        review = render_review_doc(graph, result)
        self.assertIn("[proposed] Spark Ray Rescue 01", review)
        self.assertLess(result.stages[keys[0]], result.stages[keys[1]])
        self.assertLess(result.stages[keys[3]], result.stages[keys[5]])
        self.assertLess(result.stages[keys[5]], result.stages[keys[6]])

    def test_circular_memory_adaptation_dependency_is_reported(self) -> None:
        map_data = copy.deepcopy(valid_map())
        map_data["creature_memory_opportunities"][0]["required_adaptation_id"] = "anchor_fins"
        graph = build_progression_graph([map_data], contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)

    def test_memory_and_payoff_retain_event_and_equipment_dependencies(self) -> None:
        graph = build_progression_graph([valid_map()], contract())
        memory = graph.resolve("spark_ray_current_memory_01")
        payoff = graph.resolve("spark_ray_anchor_current_01")
        gate = graph.resolve("spark_ray_memory_current")
        fins = graph.resolve("propulsion_fins")
        adaptation = graph.resolve("anchor_fins")
        self.assertTrue(any(edge.target == gate for edge in graph.requirements(memory)))
        self.assertTrue(any(edge.target == fins for edge in graph.requirements(memory)))
        self.assertTrue(any(edge.target == gate for edge in graph.requirements(payoff)))
        self.assertTrue(any(edge.target == adaptation for edge in graph.requirements(payoff)))

    def test_optional_trace_requires_mica_and_scanner_without_becoming_mandatory(self) -> None:
        graph = build_progression_graph([valid_map()], contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        trace = graph.resolve("veil_cuttle_trace_01")
        mica = graph.resolve("veil_cuttle_juvenile_01")
        scanner = graph.resolve("survey_scanner_1")
        self.assertFalse(graph.nodes[trace].mandatory)
        requirements = {edge.target for edge in graph.requirements(trace)}
        self.assertTrue({mica, scanner} <= requirements)

    def test_mica_path_is_optional_and_cannot_satisfy_equipment_gates(self) -> None:
        graph = build_progression_graph([valid_map()], contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        rescue = graph.resolve("veil_cuttle_rescue_01")
        trace = graph.resolve("veil_cuttle_trace_01")
        self.assertFalse(graph.nodes[rescue].mandatory)
        self.assertFalse(graph.nodes[trace].mandatory)
        self.assertIn(rescue, result.stages)
        self.assertIn(trace, result.stages)
        self.assertFalse([
            edge for edge in graph.outgoing(trace)
            if edge.relation in {"unlocks", "rewards", "guards", "funds"}
        ])
        equipment_dependents = [
            node.key
            for node in graph.nodes.values()
            if node.kind in {"capability", "upgrade", "gate", "pressure", "project"}
            and any(edge.target in {rescue, trace} for edge in graph.requirements(node.key))
        ]
        self.assertEqual([], equipment_dependents)

    def test_mica_drift_payoff_targets_a_non_rewarding_moving_hazard_node(self) -> None:
        graph = build_progression_graph([valid_living_expedition_03_map()], contract())
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        payoff = graph.resolve("veil_cuttle_drift_lens_payoff_01")
        patrol = graph.resolve("deep_route_jellyfish_patrol")
        self.assertEqual("moving_hazard", graph.nodes[patrol].kind)
        self.assertTrue(any(edge.target == patrol for edge in graph.requirements(payoff)))
        self.assertFalse([
            edge for edge in graph.outgoing(patrol)
            if edge.relation in {"unlocks", "rewards", "guards", "funds"}
        ])

    def test_companion_eel_relationship_preserves_defeat_only_resource_authority(self) -> None:
        map_data = valid_living_expedition_03_map()
        le04 = valid_living_expedition_04_map()
        map_data["entities"].extend(item for item in le04["entities"] if item["id"] == "salvage_deep_right_cache")
        map_data["entities"].append({"id": "starter_salvage", "type": "salvage", "x": 4, "y": 4, "tier": "common"})
        map_data["hostile_encounters"].extend(le04["hostile_encounters"])
        map_data["biological_resource_sources"] = copy.deepcopy(le04["biological_resource_sources"])
        map_data["biological_resource_sources"][0]["material_quantity"] = 1
        map_data["companion_hostile_responses"] = copy.deepcopy(le04["companion_hostile_responses"])
        test_contract = contract()
        test_contract["session_upgrades"][2]["funding_source_ids"] = ["starter_salvage"]
        graph = build_progression_graph([map_data], test_contract)
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        relationship = graph.resolve("deep_cache_eel_companion_response")
        hostile = graph.resolve("deep_cache_territorial_eel")
        harvest = graph.resolve("deep_cache_eel_electrocyte_harvest")
        cache = graph.resolve("salvage_deep_right_cache")
        defeat = f"defeat:production_level_01/deep_cache_territorial_eel"
        shock_prod = graph.resolve("shock_prod")
        requirements = {edge.target for edge in graph.requirements(relationship)}
        self.assertEqual("companion_hostile_response", graph.nodes[relationship].kind)
        self.assertTrue({
            graph.resolve("spark_ray_juvenile_01"),
            graph.resolve("veil_cuttle_juvenile_01"),
            graph.resolve("guardian_pulse"),
            graph.resolve("drift_lens"),
            shock_prod,
        } <= requirements)
        self.assertTrue(any(edge.target == hostile and edge.relation == "targets" for edge in graph.outgoing(relationship)))
        self.assertTrue(any(edge.target == harvest and edge.relation == "reviews" for edge in graph.outgoing(relationship)))
        self.assertTrue(any(edge.target == cache and edge.relation == "reviews" for edge in graph.outgoing(relationship)))
        self.assertIn(defeat, {edge.target for edge in graph.requirements(harvest)})
        self.assertIn(shock_prod, {edge.target for edge in graph.requirements(defeat)})
        self.assertNotIn(relationship, {edge.target for edge in graph.requirements(harvest)})
        self.assertNotIn(relationship, {edge.target for edge in graph.requirements(defeat)})
        self.assertFalse([
            edge for edge in graph.outgoing(relationship)
            if edge.relation in {"unlocks", "rewards", "guards", "funds"}
        ])


if __name__ == "__main__":
    unittest.main()
