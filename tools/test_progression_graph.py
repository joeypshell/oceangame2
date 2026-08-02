#!/usr/bin/env python3
"""Focused fixtures for the cross-map progression graph audit."""

from __future__ import annotations

import copy
import unittest

from progression_audit import audit_graph
from progression_audit_views import build_view_graph, load_audit_views
from progression_contract import load_contract, validate_contract
from progression_graph import Edge, Node, ProgressionGraph, ROOT, build_progression_graph, load_production_maps


def graph_with_start() -> ProgressionGraph:
    graph = ProgressionGraph()
    graph.add_node(Node("map:start", "Start", "map", "start", attrs={"start": True}), "start")
    return graph


class ProgressionGraphAuditTests(unittest.TestCase):
    def test_durable_light_declaration_is_not_a_purchase_owner(self) -> None:
        contract = load_contract()
        declaration = next(item for item in contract["durable_capabilities"] if item["id"] == "dive_light_1")
        self.assertEqual("dive_light_1", declaration["id"])
        self.assertNotIn("cost", declaration)
        graph = build_progression_graph(load_production_maps(), contract)
        light = graph.resolve("dive_light_1")
        self.assertEqual("capability", graph.nodes[light].kind)
        self.assertFalse(graph.requirements(light))
        self.assertNotIn(light, audit_graph(graph).stages)

    def test_durable_capability_declaration_rejects_purchase_fields(self) -> None:
        contract = load_contract()
        next(item for item in contract["durable_capabilities"] if item["id"] == "survey_scanner_1")["cost"] = 300
        failures = validate_contract(contract)
        self.assertTrue(any("unsupported ownership fields" in failure for failure in failures), failures)

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
            "east_current_scanner_blueprint_chest",
            "survey_scanner_blueprint",
            "survey_scanner_project",
            "survey_scanner_1",
            "lower_right_anomaly_survey",
            "lower_right_anomaly_discovery",
            "salvage_cutter_blueprint",
            "salvage_cutter_project",
            "east_current_signal_reef_route",
            "lower_right_signal_reef_survey",
            "lower_right_signal_reef_discovery",
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
        cutter_blueprint = level_graph.resolve("salvage_cutter_blueprint")
        cutter_project = level_graph.resolve("salvage_cutter_project")
        boat = level_graph.resolve("surface_boat_entry")
        self.assertTrue(any(edge.target == fins for edge in level_graph.requirements(gate)))
        self.assertTrue(any(edge.target == scanner for edge in level_graph.requirements(survey)))
        self.assertTrue(any(edge.target == boat for edge in level_graph.requirements(discovery)))
        self.assertTrue(any(edge.target == survey for edge in level_graph.requirements(cutter_blueprint)))
        self.assertTrue(any(edge.target == boat for edge in level_graph.requirements(cutter_blueprint)))
        self.assertTrue(any(edge.target == cutter_blueprint for edge in level_graph.requirements(cutter_project)))

        route = level_graph.resolve("east_current_signal_reef_route")
        regional_survey = level_graph.resolve("lower_right_signal_reef_survey")
        regional_discovery = level_graph.resolve("lower_right_signal_reef_discovery")
        self.assertTrue(level_graph.nodes[route].mandatory)
        self.assertTrue(level_graph.nodes[regional_survey].mandatory)
        self.assertTrue(level_graph.nodes[regional_discovery].mandatory)
        self.assertTrue(any(edge.target == fins for edge in level_graph.requirements(route)))
        self.assertTrue(any(edge.target == route for edge in level_graph.requirements(regional_survey)))
        self.assertTrue(any(edge.target == scanner for edge in level_graph.requirements(regional_survey)))
        self.assertTrue(any(edge.target == regional_survey for edge in level_graph.requirements(regional_discovery)))
        self.assertTrue(any(edge.target == boat for edge in level_graph.requirements(regional_discovery)))
        self.assertLess(level_result.stages[route], level_result.stages[regional_survey])
        self.assertLess(level_result.stages[regional_survey], level_result.stages[regional_discovery])

    def test_full_level_view_rejects_circular_regional_prerequisite(self) -> None:
        view = next(view for view in load_audit_views() if view.id == "promoted_full_level")
        graph = build_view_graph(view, load_contract())
        route = graph.resolve("east_current_signal_reef_route")
        survey = graph.resolve("lower_right_signal_reef_survey")
        graph.add_edge(route, survey, "requires", hard=True, note="invalid circular route capability")
        result = audit_graph(graph)
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)

    def test_wreck_network_analysis_requires_both_committed_fragments(self) -> None:
        maps = load_production_maps((ROOT / "maps" / "production_level_01.greybox.json",))
        level = maps[0]
        fragments = (
            "western_chasm_wreck_fragment_discovery",
            "abyssal_shelf_wreck_fragment_discovery",
        )
        for index, discovery_id in enumerate(fragments):
            level["survey_targets"].append({
                "id": f"fragment_survey_{index}",
                "discovery_id": discovery_id,
                "required_capability_id": "survey_scanner_1",
                "commit_map_id": "production_level_01",
                "commit_entry_id": "surface_boat_entry",
            })
        level["wreck_network_investigations"] = [{
            "id": "wreck_network_triangulation",
            "required_discovery_id": "far_west_deeper_wreck_discovery",
            "fragment_discovery_ids": list(fragments),
            "analysis_discovery_id": "wreck_network_triangulation_discovery",
        }]
        contract = copy.deepcopy(load_contract())
        contract["canonical_start"]["map_id"] = "production_level_01"
        graph = build_progression_graph(maps, contract)

        investigation = graph.resolve("wreck_network_triangulation")
        final_discovery = graph.resolve("wreck_network_triangulation_discovery")
        requirements = {edge.target for edge in graph.requirements(investigation)}
        self.assertIn(graph.resolve("far_west_deeper_wreck_discovery"), requirements)
        self.assertTrue({graph.resolve(item) for item in fragments}.issubset(requirements))
        self.assertTrue(any(edge.target == investigation for edge in graph.requirements(final_discovery)))
        self.assertEqual((), audit_graph(graph, check_canonical=False).failures)

    def test_exceptional_interior_chain_requires_coordinates_cutter_and_boat(self) -> None:
        exterior = load_production_maps((ROOT / "maps" / "production_level_01.greybox.json",))[0]
        exterior["entities"].append({"id": "transfer_hub_exterior_return", "type": "spawn"})
        exterior["zones"].append({
            "id": "transfer_hub_exterior_entrance", "type": "marker",
            "world_connector": True, "connector_kind": "exceptional_interior",
            "connector_direction": "forward", "destination_map_id": "transfer_hub_interior_01",
            "destination_entry_id": "transfer_hub_interior_entry",
            "required_discovery_id": "wreck_network_triangulation_discovery",
        })
        interior = {
            "id": "transfer_hub_interior_01",
            "entities": [
                {"id": "transfer_hub_interior_entry", "type": "spawn"},
                {
                    "id": "transfer_hub_navigation_core_cradle", "type": "tool_target",
                    "required_tool_id": "salvage_cutter", "reward_kind": "held_discovery_cargo",
                    "reward_id": "transfer_hub_navigation_core_discovery",
                    "reward_commit_map_id": "production_level_01",
                    "reward_commit_entry_id": "surface_boat_entry",
                },
            ],
            "zones": [{
                "id": "transfer_hub_interior_return", "type": "marker",
                "world_connector": True, "connector_kind": "exceptional_interior",
                "connector_direction": "return", "destination_map_id": "production_level_01",
                "destination_entry_id": "transfer_hub_exterior_return",
            }],
        }
        contract = copy.deepcopy(load_contract())
        contract["canonical_start"] = {"map_id": "production_level_01", "entry_id": "surface_boat_entry"}
        graph = build_progression_graph([exterior, interior], contract)
        entrance = graph.resolve("transfer_hub_exterior_entrance", "production_level_01")
        core = graph.resolve("transfer_hub_navigation_core_cradle", "transfer_hub_interior_01")
        discovery = graph.resolve("transfer_hub_navigation_core_discovery")
        self.assertTrue(any(edge.target == graph.resolve("wreck_network_triangulation_discovery") for edge in graph.requirements(entrance)))
        self.assertTrue(any(edge.target == graph.resolve("salvage_cutter") for edge in graph.requirements(core)))
        requirements = {edge.target for edge in graph.requirements(discovery)}
        self.assertIn(core, requirements)
        self.assertIn(graph.resolve("surface_boat_entry", "production_level_01"), requirements)
        self.assertEqual((), audit_graph(graph, check_canonical=False).failures)

    def test_deep_harmonic_chain_includes_durable_light_requirement(self) -> None:
        maps = load_production_maps((ROOT / "maps" / "production_level_01.greybox.json",))
        level = next(item for item in maps if item.get("id") == "production_level_01")
        level["material_projects"].append({
            "id": "dive_light_1_project",
            "required_discovery_id": "lower_right_signal_reef_discovery",
            "required_materials": {"titanium_scrap": 1, "conductive_coil": 1, "insulating_gel": 1},
            "unlocks_capability_id": "dive_light_1",
            "target_id": "signal_reef_deep_harmonic_survey",
        })
        level["survey_targets"].append({
            "id": "signal_reef_deep_harmonic_survey",
            "target_type": "regional",
            "required_capability_id": "survey_scanner_1",
            "required_light_capability_id": "dive_light_1",
            "required_route_id": "east_current_signal_reef_route",
            "route_context": "east_current_signal_reef_route",
            "discovery_id": "signal_reef_deep_harmonic_discovery",
            "commit_map_id": "production_level_01",
            "commit_entry_id": "surface_boat_entry",
        })
        contract = copy.deepcopy(load_contract())
        contract["session_upgrades"] = [item for item in contract["session_upgrades"] if item["id"] != "dive_light_1"]
        contract["canonical_start"]["map_id"] = "production_level_01"
        for purchase in contract["durable_purchases"]:
            purchase["purchase_map_id"] = "production_level_01"
        graph = build_progression_graph(maps, contract)

        project = graph.resolve("dive_light_1_project")
        light = graph.resolve("dive_light_1")
        survey = graph.resolve("signal_reef_deep_harmonic_survey")
        signal_reef = graph.resolve("lower_right_signal_reef_discovery")
        scanner = graph.resolve("survey_scanner_1")
        route = graph.resolve("east_current_signal_reef_route")
        discovery = graph.resolve("signal_reef_deep_harmonic_discovery")
        self.assertTrue(any(edge.target == signal_reef for edge in graph.requirements(project)))
        self.assertTrue(any(edge.target == project for edge in graph.requirements(light)))
        self.assertTrue(any(edge.target == light for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == scanner for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == route for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == survey for edge in graph.requirements(discovery)))
        self.assertEqual((), audit_graph(graph).failures)

    def test_abyssal_chain_includes_pressure_project_route_and_boat_commit(self) -> None:
        maps = load_production_maps((ROOT / "maps" / "production_level_01.greybox.json",))
        level = maps[0]
        level["material_projects"].append({
            "id": "pressure_suit_1_project",
            "required_discovery_id": "signal_reef_deep_harmonic_discovery",
            "required_materials": {"titanium_scrap": 2, "rubber_sheet": 1, "insulating_gel": 1},
            "unlocks_capability_id": "pressure_suit_1",
            "target_id": "abyssal_basin_harmonic_source_survey",
        })
        level["zones"].extend([
            {
                "id": "abyssal_basin_pressure_zone",
                "type": "marker",
                "pressure_zone": True,
                "required_capability_id": "pressure_suit_1",
                "route_context": "deep_harmonic_abyssal_basin_route",
            },
            {
                "id": "abyssal_basin_landmark",
                "type": "marker",
                "regional_landmark": True,
                "route_context": "deep_harmonic_abyssal_basin_route",
            },
        ])
        level["regional_journeys"].append({
            "id": "deep_harmonic_abyssal_basin_route",
            "required_capability_id": "pressure_suit_1",
            "promise_gate_id": "signal_reef_deep_harmonic_dark_zone",
            "entry_gate_ids": ["abyssal_basin_pressure_zone"],
            "landmark_zone_id": "abyssal_basin_landmark",
            "survey_target_id": "abyssal_basin_harmonic_source_survey",
            "commit_entry_id": "surface_boat_entry",
        })
        level["survey_targets"].append({
            "id": "abyssal_basin_harmonic_source_survey",
            "target_type": "regional",
            "required_capability_id": "survey_scanner_1",
            "required_pressure_capability_id": "pressure_suit_1",
            "required_route_id": "deep_harmonic_abyssal_basin_route",
            "route_context": "deep_harmonic_abyssal_basin_route",
            "discovery_id": "abyssal_basin_harmonic_source_discovery",
            "commit_map_id": "production_level_01",
            "commit_entry_id": "surface_boat_entry",
        })
        contract = copy.deepcopy(load_contract())
        contract["canonical_start"]["map_id"] = "production_level_01"
        graph = build_progression_graph(maps, contract)

        knowledge = graph.resolve("signal_reef_deep_harmonic_discovery")
        project = graph.resolve("pressure_suit_1_project")
        suit = graph.resolve("pressure_suit_1")
        route = graph.resolve("deep_harmonic_abyssal_basin_route")
        survey = graph.resolve("abyssal_basin_harmonic_source_survey")
        scanner = graph.resolve("survey_scanner_1")
        discovery = graph.resolve("abyssal_basin_harmonic_source_discovery")
        boat = graph.resolve("surface_boat_entry", "production_level_01")
        self.assertTrue(any(edge.target == knowledge for edge in graph.requirements(project)))
        self.assertTrue(any(edge.target == project for edge in graph.requirements(suit)))
        self.assertTrue(any(edge.target == suit for edge in graph.requirements(route)))
        self.assertTrue(any(edge.target == suit for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == scanner for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == route for edge in graph.requirements(survey)))
        self.assertTrue(any(edge.target == survey for edge in graph.requirements(discovery)))
        self.assertTrue(any(edge.target == boat for edge in graph.requirements(discovery)))
        self.assertEqual((), audit_graph(graph).failures)

    def test_full_level_view_rejects_self_gated_fins_blueprint(self) -> None:
        view = next(view for view in load_audit_views() if view.id == "promoted_full_level")
        graph = build_view_graph(view, load_contract())
        chest = graph.resolve("lower_loop_upgrade_chest", "production_level_01")
        fins = graph.resolve("propulsion_fins")
        graph.add_edge(chest, fins, "requires", hard=True, note="invalid self gate")
        result = audit_graph(graph)
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)

    def test_full_level_scanner_uses_gated_blueprint_project_without_wallet(self) -> None:
        view = next(view for view in load_audit_views() if view.id == "promoted_full_level")
        graph = build_view_graph(view, load_contract())
        scanner = graph.resolve("survey_scanner_1")
        project = graph.resolve("survey_scanner_project")
        blueprint = graph.resolve("survey_scanner_blueprint")
        chest = graph.resolve("east_current_scanner_blueprint_chest", "production_level_01")
        fins = graph.resolve("propulsion_fins")
        cache = graph.resolve("salvage_current_pocket_cache", "production_level_01")
        coil_pool = graph.resolve("conductive_coil_pool", "production_level_01")
        coil_floor = graph.resolve("material_coil_scanner_floor", "production_level_01")
        self.assertTrue(any(edge.target == project for edge in graph.requirements(scanner)))
        self.assertTrue(any(edge.target == blueprint for edge in graph.requirements(project)))
        self.assertTrue(any(edge.target == chest for edge in graph.requirements(blueprint)))
        self.assertTrue(any(edge.target == fins for edge in graph.requirements(chest)))
        self.assertFalse(any(edge.target == cache for edge in graph.requirements(scanner)))
        self.assertEqual(graph.nodes[coil_pool].attrs.get("guaranteed_candidate_ids"), ["material_coil_scanner_floor"])
        self.assertIn(coil_floor, graph.nodes[coil_pool].attrs.get("candidate_keys", []))
        self.assertEqual([edge.target for edge in graph.requirements(coil_floor)], ["map:production_level_01"])
        self.assertEqual(0, int(graph.nodes[scanner].attrs.get("cost", 0)))

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
