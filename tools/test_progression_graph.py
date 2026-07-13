#!/usr/bin/env python3
"""Focused fixtures for the cross-map progression graph audit."""

from __future__ import annotations

import unittest

from progression_audit import audit_graph
from progression_audit_views import build_view_graph, load_audit_views
from progression_contract import load_contract
from progression_graph import Edge, Node, ProgressionGraph, build_progression_graph, load_production_maps


def graph_with_start() -> ProgressionGraph:
    graph = ProgressionGraph()
    graph.add_node(Node("map:start", "Start", "map", "start", attrs={"start": True}), "start")
    return graph


class ProgressionGraphAuditTests(unittest.TestCase):
    def test_current_source_chain_is_reachable_and_non_circular(self) -> None:
        graph = build_progression_graph(load_production_maps(), load_contract())
        result = audit_graph(graph)
        self.assertEqual((), result.failures)
        shock = graph.resolve("shock_prod")
        cache = graph.resolve("salvage_deep_right_cache")
        capacitor = graph.resolve("shock_prod_capacitor_project")
        self.assertLess(result.stages[shock], result.stages[cache])
        self.assertLess(result.stages[cache], result.stages[capacitor])

    def test_promoted_full_level_is_a_separate_canonical_view(self) -> None:
        contract = load_contract()
        views = {view.id: view for view in load_audit_views()}
        slice_graph = build_view_graph(views["slice_provenance"], contract)
        level_graph = build_view_graph(views["promoted_full_level"], contract)
        level_result = audit_graph(level_graph)

        self.assertEqual((), level_result.failures)
        self.assertEqual("production_slice_01", contract["canonical_start"]["map_id"])
        self.assertIn("map:production_slice_01", slice_graph.nodes)
        self.assertNotIn("map:production_slice_01", level_graph.nodes)
        self.assertTrue(level_graph.nodes["map:production_level_01"].attrs["start"])
        self.assertEqual(
            "production_level_01",
            level_graph.nodes[level_graph.resolve("surface_boat_entry")].map_id,
        )

        expected_chain = (
            "deep_cache_next_dive_prompt",
            "propulsion_fins",
            "upper_right_current_pocket_gate",
            "salvage_current_pocket_cache",
            "survey_scanner_1",
            "lower_right_anomaly_survey",
            "lower_right_anomaly_discovery",
            "surface_boat_entry",
        )
        for raw_id in expected_chain:
            key = level_graph.resolve(raw_id)
            self.assertIn(key, level_graph.nodes, raw_id)
            self.assertIn(key, level_result.stages, raw_id)

        gate = level_graph.resolve("upper_right_current_pocket_gate")
        fins = level_graph.resolve("propulsion_fins")
        survey = level_graph.resolve("lower_right_anomaly_survey")
        scanner = level_graph.resolve("survey_scanner_1")
        discovery = level_graph.resolve("lower_right_anomaly_discovery")
        boat = level_graph.resolve("surface_boat_entry")
        self.assertTrue(any(edge.target == fins for edge in level_graph.requirements(gate)))
        self.assertTrue(any(edge.target == scanner for edge in level_graph.requirements(survey)))
        self.assertTrue(any(edge.target == boat for edge in level_graph.requirements(discovery)))

    def test_full_level_view_rejects_self_gated_fins_blueprint(self) -> None:
        view = next(view for view in load_audit_views() if view.id == "promoted_full_level")
        graph = build_view_graph(view, load_contract())
        chest = graph.resolve("lower_loop_upgrade_chest", "production_level_01")
        fins = graph.resolve("propulsion_fins")
        graph.add_edge(chest, fins, "requires", hard=True, note="invalid self gate")
        result = audit_graph(graph)
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)

    def test_full_level_view_rejects_scanner_funding_below_cost(self) -> None:
        view = next(view for view in load_audit_views() if view.id == "promoted_full_level")
        contract = load_contract()
        contract["durable_purchases"][0]["cost"] = 301
        result = audit_graph(build_view_graph(view, contract))
        self.assertTrue(
            any("Survey Scanner 1" in failure and "funding floor 300" in failure for failure in result.failures),
            result.failures,
        )

    def test_optional_material_pool_does_not_join_mandatory_chain(self) -> None:
        maps = load_production_maps()
        target = next(item for item in maps if item.get("id") == "production_slice_01")
        target["entities"].append({
            "id": "test_optional_coil", "type": "material_candidate", "x": 1, "y": 1,
            "material_id": "conductive_coil", "candidate_pool_id": "test_optional_pool",
        })
        target["material_candidate_pools"].append({
            "id": "test_optional_pool", "material_id": "conductive_coil", "select_count": 1,
            "candidate_ids": ["test_optional_coil"], "pool_role": "optional_bonus",
        })
        graph = build_progression_graph(maps, load_contract())
        pool_key = graph.resolve("test_optional_pool")
        self.assertFalse(graph.nodes[pool_key].mandatory)
        self.assertTrue(any(edge.relation == "optional_reward" for edge in graph.outgoing(pool_key)))

    def test_rejects_unresolved_reference(self) -> None:
        graph = graph_with_start()
        graph.add_node(Node("objective:test", "Test objective", "objective", mandatory=True), "test_objective")
        graph.add_edge("objective:test", "unresolved:missing::cache", "requires", hard=True)
        result = audit_graph(graph, check_canonical=False)
        self.assertTrue(any("Unresolved target" in failure for failure in result.failures), result.failures)

    def test_contract_funding_typo_becomes_unresolved_diagnostic(self) -> None:
        contract = load_contract()
        contract["session_upgrades"][-1]["funding_source_ids"] = ["missing_funding_cache"]
        graph = build_progression_graph(load_production_maps(), contract)
        result = audit_graph(graph)
        self.assertTrue(any("missing_funding_cache" in failure and "Unresolved source" in failure for failure in result.failures), result.failures)

    def test_rejects_direct_hard_cycle(self) -> None:
        graph = graph_with_start()
        graph.add_node(Node("capability:a", "A", "capability", mandatory=True), "a")
        graph.add_node(Node("project:b", "B", "project", mandatory=True), "b")
        graph.add_edge("capability:a", "project:b", "requires", hard=True)
        graph.add_edge("project:b", "capability:a", "requires", hard=True)
        result = audit_graph(graph, check_canonical=False)
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)

    def test_rejects_indirect_guard_counter_cycle(self) -> None:
        graph = graph_with_start()
        for node in (
            Node("hostile:eel", "Eel", "hostile"),
            Node("defeat:eel", "Defeat eel", "defeat"),
            Node("salvage:cache", "Guarded cache", "salvage", mandatory=True),
            Node("capability:prod", "Shock prod", "capability", mandatory=True),
            Node("project:prod", "Shock prod project", "project", mandatory=True),
        ):
            graph.add_node(node)
        graph.add_edge("hostile:eel", "salvage:cache", "guards")
        graph.add_edge("salvage:cache", "defeat:eel", "requires", hard=True)
        graph.add_edge("defeat:eel", "hostile:eel", "requires", hard=True)
        graph.add_edge("defeat:eel", "capability:prod", "requires", hard=True, note="counter")
        graph.add_edge("capability:prod", "project:prod", "requires", hard=True)
        graph.add_edge("project:prod", "salvage:cache", "requires", hard=True)
        result = audit_graph(graph, check_canonical=False)
        self.assertTrue(any("Guarded target" in failure and "counter" in failure for failure in result.failures), result.failures)

    def test_rejects_unreachable_mandatory_prerequisite(self) -> None:
        graph = graph_with_start()
        graph.add_node(Node("map:remote", "Remote", "map", "remote"), "remote")
        graph.add_node(Node("payoff:remote", "Remote payoff", "payoff", "remote", mandatory=True), "remote_payoff")
        graph.add_edge("payoff:remote", "map:remote", "requires", hard=True)
        result = audit_graph(graph, check_canonical=False)
        self.assertTrue(any("Remote payoff" in failure and "unreachable" in failure for failure in result.failures), result.failures)

    def test_soft_gate_is_annotation_not_blocker(self) -> None:
        graph = graph_with_start()
        graph.add_node(Node("pressure:dark", "Dark water", "pressure", "start", mandatory=True), "dark_water")
        graph.add_node(Node("upgrade:light", "Dive light", "upgrade"), "dive_light")
        graph.add_edge("pressure:dark", "map:start", "requires", hard=True)
        graph.add_edge("pressure:dark", "upgrade:light", "requires", hard=False, note="soft pressure")
        result = audit_graph(graph, check_canonical=False)
        self.assertEqual((), result.failures)
        self.assertIn("pressure:dark", result.stages)
        self.assertEqual(1, len(result.soft_annotations))


if __name__ == "__main__":
    unittest.main()
