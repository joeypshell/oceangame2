#!/usr/bin/env python3
"""Focused progression fixtures for proposed Living Expedition source nodes."""

from __future__ import annotations

import copy
import unittest

from progression_audit import audit_graph, render_review_doc
from progression_graph import build_progression_graph
from test_validate_living_expedition_schema import valid_map


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


if __name__ == "__main__":
    unittest.main()
