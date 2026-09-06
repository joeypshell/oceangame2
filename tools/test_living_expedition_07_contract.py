#!/usr/bin/env python3
"""LE07 proposed source fixtures only; never writes production maps or profiles."""

from __future__ import annotations

import copy
import json
from pathlib import Path
import unittest

import living_expedition_07_contract as le07
from creature_catalog_contract import load_creature_catalog, validate_creature_catalog
from progression_audit import audit_graph
from progression_audit_views import load_audit_views
from progression_contract import load_contract
from progression_graph import build_progression_graph, load_production_maps
from progression_graph_marl import NIGHT_ID
from validate_full_level_traversal import solid_cells
from validate_living_expedition_schema import (
    validate_living_expedition_reachability, validate_living_expedition_schema,
)

ROOT = Path(__file__).resolve().parents[1]


def record(payload: dict, item_id: str) -> dict:
    return next(item for field in payload for item in le07.items(payload, field)
                if item.get("id") == item_id)


def proposed_map() -> dict:
    payload = json.loads((ROOT / "maps/production_level_01.greybox.json").read_text(encoding="utf-8"))
    for field in set(le07.RECORDS.values()):
        payload[field] = [item for item in payload.get(field, []) if item.get("id") not in le07.RECORDS]
    payload["camera_tests"] = [item for item in payload["camera_tests"] if item["id"] not in le07.CAMERA_IDS]
    for item_id, expected in le07.source_expectations().items():
        payload.setdefault(le07.RECORDS[item_id], []).append(copy.deepcopy(expected))
    # Synthetic tile-valid placement, not approved full-actor authoring evidence.
    record(payload, le07.REFUGE_ID).update({
        "x": 119, "y": 77, "w": 3, "h": 2,
        "approach_point": {"x": 118, "y": 77}, "dig_point": {"x": 120, "y": 78},
        "wildlife_path": [{"x": 118, "y": 77}, {"x": 119, "y": 78}, {"x": 120, "y": 78}],
    })
    record(payload, le07.CONTEXT_ID)["ground_anchors"] = [{"x": 120, "y": 78}, {"x": 122, "y": 78}]
    payload["camera_tests"].extend({"id": item_id, "center_x": 120, "center_y": 77, "zoom": 0.6}
                                   for item_id in le07.CAMERA_IDS)
    payload["source"][le07.SOURCE_KEY] = {
        "source": "tools/production_level_01_living_expedition_07.py",
        "refuge_ids": [le07.REFUGE_ID], "memory_opportunity_ids": [le07.OPPORTUNITY_ID],
        "companion_context_ids": [le07.CONTEXT_ID], "adaptation_payoff_ids": [le07.PAYOFF_ID],
        "camera_test_ids": le07.CAMERA_IDS.copy(), "availability": le07.AVAILABILITY, "terrain_changes": [],
    }
    return payload


def proposed_graph(payload: dict):
    view = next(view for view in load_audit_views() if view.detailed_review)
    maps = load_production_maps(view.map_paths)
    maps = [payload if item["id"] == payload["id"] else item for item in maps]
    contract = load_contract()
    contract["canonical_start"]["map_id"] = payload["id"]
    for collection in ("session_upgrades", "durable_purchases"):
        for item in contract[collection]:
            if "purchase_map_id" in item:
                item["purchase_map_id"] = view.map_id_aliases.get(item["purchase_map_id"], item["purchase_map_id"])
    return build_progression_graph(maps, contract)


class LivingExpedition07ContractTests(unittest.TestCase):
    def assert_invalid(self, payload: dict, text: str) -> None:
        failures = validate_living_expedition_schema(payload)
        self.assertTrue(any(text in failure for failure in failures), failures)

    def test_catalog_and_proposed_source_validate_without_authoring_live_map(self) -> None:
        self.assertEqual([], validate_creature_catalog(load_creature_catalog()))
        self.assertEqual([], validate_living_expedition_schema(proposed_map()))
        current = json.loads((ROOT / "maps/production_level_01.greybox.json").read_text(encoding="utf-8"))
        self.assertEqual([], validate_living_expedition_schema(current))

    def test_catalog_rejects_cross_species_growth_and_damaging_or_mounted_pin(self) -> None:
        for collection, item_id, field, value in (
            ("species", "spark_ray", "memory_ids", [le07.MEMORY_ID]),
            ("species", le07.SPECIES_ID, "adaptation_ids", ["guardian_pulse"]),
            ("memories", le07.MEMORY_ID, "adaptation_ids", ["anchor_fins"]),
            ("adaptations", le07.ADAPTATION_ID, "required_memory_id", "stood_ground"),
            ("actions", le07.ACTION_ID, "damaging", True),
            ("actions", le07.ACTION_ID, "roles", ["independent", "mounted"]),
        ):
            with self.subTest(field=field, item=item_id):
                catalog = load_creature_catalog()
                next(item for item in catalog[collection] if item["id"] == item_id)[field] = value
                self.assertTrue(validate_creature_catalog(catalog))

    def test_wrong_ids_species_actions_and_references_are_rejected(self) -> None:
        for item_id, field, value in (
            (le07.REFUGE_ID, "id", "unknown_refuge"),
            (le07.OPPORTUNITY_ID, "individual_id", "veil_cuttle_juvenile_01"),
            (le07.OPPORTUNITY_ID, "species_id", "spark_ray"),
            (le07.OPPORTUNITY_ID, "memory_id", "stood_ground"),
            (le07.OPPORTUNITY_ID, "hostile_id", "spark_ray_memory_eel"),
            (le07.OPPORTUNITY_ID, "target_id", "missing_refuge"),
            (le07.OPPORTUNITY_ID, "commit_entry_id", "wrong_boat"),
            (le07.CONTEXT_ID, "action_id", "guardian_pulse_action"),
            (le07.PAYOFF_ID, "adaptation_id", "anchor_fins"),
        ):
            with self.subTest(item=item_id, field=field):
                payload = proposed_map()
                record(payload, item_id)[field] = value
                self.assert_invalid(payload, field if field != "id" else "requires exactly one")

    def test_duplicate_partial_and_malformed_collections_are_rejected(self) -> None:
        for item_id, field in le07.RECORDS.items():
            with self.subTest(item=item_id):
                payload = proposed_map()
                payload[field].append(copy.deepcopy(record(payload, item_id)))
                self.assert_invalid(payload, "exactly one")
                payload = proposed_map()
                payload[field] = [item for item in payload[field] if item["id"] != item_id]
                self.assert_invalid(payload, "requires exactly one")
        payload = proposed_map()
        payload["entities"].append(copy.deepcopy(record(payload, le07.REFUGE_ID)))
        self.assert_invalid(payload, "across source collections")
        for value in ({}, [None], ["invalid"]):
            payload = proposed_map()
            payload[le07.REFUGE_FIELD] = value
            self.assert_invalid(payload, "burrow_refuges")

    def test_source_presence_cannot_be_hidden_by_removing_provenance_or_refuge(self) -> None:
        payload = proposed_map()
        del payload["source"][le07.SOURCE_KEY]
        del payload[le07.REFUGE_FIELD]
        self.assertTrue(le07.uses_living_expedition_07(payload))
        self.assert_invalid(payload, "source.living_expedition_07")

    def test_mutable_random_reward_and_uncontracted_fields_are_rejected(self) -> None:
        for field, value in (
            ("spawn_chance", 0.5), ("position", {"x": 0, "y": 0}),
            ("active_pin", True), ("held_seconds", 0.7), ("nursery_history", []),
            ("reward_ids", ["shock_prod"]), ("harvestable", True),
            ("availability", "seed_rotation"), ("required_adaptation_id", "root_claws"),
        ):
            with self.subTest(field=field):
                payload = proposed_map()
                record(payload, le07.REFUGE_ID)[field] = value
                self.assert_invalid(payload, field)
        payload = proposed_map()
        payload["source"][le07.SOURCE_KEY]["terrain_changes"] = ["carve_refuge"]
        self.assert_invalid(payload, "terrain_changes")

    def test_bounds_and_timing_are_strict_and_finite(self) -> None:
        for field, values in (
            ("x", [-1, 999999, True, 119.5]), ("w", [0, -1, 999999, True]),
        ):
            for value in values:
                with self.subTest(field=field, value=value):
                    payload = proposed_map()
                    record(payload, le07.REFUGE_ID)[field] = value
                    self.assert_invalid(payload, "integer bounds")
        for field in ("max_hold_seconds", "cooldown_seconds", "damage"):
            for value in (True, -1, float("nan"), float("inf"), "1.75", 99):
                with self.subTest(field=field, value=value):
                    payload = proposed_map()
                    record(payload, le07.CONTEXT_ID)[field] = value
                    self.assert_invalid(payload, field)

    def test_anchor_point_and_wildlife_path_constraints(self) -> None:
        for anchors, expected in (
            ([], "1-4"), ([None], "integer x/y"),
            ([{"x": True, "y": 78}], "in-bounds integer"),
            ([{"x": 120, "y": 78, "active": True}], "only integer"),
            ([{"x": 120, "y": 77}], "solid floor"),
            ([{"x": 120, "y": 79}], "solid terrain"),
            ([{"x": 120, "y": 78}] * 2, "duplicate"),
            ([{"x": -1, "y": 78}], "in-bounds"),
        ):
            with self.subTest(anchors=anchors):
                payload = proposed_map()
                record(payload, le07.CONTEXT_ID)["ground_anchors"] = anchors
                self.assert_invalid(payload, expected)
        payload = proposed_map()
        record(payload, le07.HOSTILE_ID)["territory"] = {"x": 0, "y": 0, "w": 1, "h": 1}
        self.assert_invalid(payload, "existing eel territory")
        for field, value, expected in (
            ("dig_point", {"x": 118, "y": 77}, "inside its bounds"),
            ("wildlife_path", [], "2-8 points"),
            ("wildlife_path", [{"x": 120, "y": 78}, {"x": 118, "y": 77}], "end inside shelter"),
        ):
            payload = proposed_map()
            record(payload, le07.REFUGE_ID)[field] = value
            self.assert_invalid(payload, expected)

    def test_access_and_existing_physical_rescue_authority_remain_intact(self) -> None:
        for item_id, field, value in (
            (le07.RESCUE_ID, "required_capability_id", "root_claws"),
            (le07.DARK_ZONE_ID, "visual_only", False),
            (le07.CACHE_ID, "required_capability_id", "ground_pin"),
            (le07.REFUGE_ID, "required_access_ids", []),
            (le07.CONTEXT_ID, "required_access_ids", ["dive_light_1"]),
        ):
            with self.subTest(item=item_id, field=field):
                payload = proposed_map()
                record(payload, item_id)[field] = value
                self.assert_invalid(payload, field if item_id != le07.CACHE_ID else "attemptable")
        payload = proposed_map()
        payload["material_projects"][0]["required_companion_action_id"] = "ground_pin"
        self.assert_invalid(payload, "cannot depend on the optional LE07 chain")

    def test_all_refuge_and_ground_points_and_boat_must_be_reachable(self) -> None:
        payload = proposed_map()
        units = payload["units"]
        solids = solid_cells(payload)
        reachable = {(x, y) for x in range(units["width_tiles"]) for y in range(units["height_tiles"])} - solids
        self.assertEqual([], validate_living_expedition_reachability(payload, solids, reachable))
        reachable.remove((120, 78))
        boat = record(payload, le07.BOAT_ID)
        reachable.discard((boat["entry_x"], boat["entry_y"]))
        failures = validate_living_expedition_reachability(payload, solids, reachable)
        self.assertIn("LE07 source point (120, 78) is unreachable.", failures)
        self.assertIn("LE07 canonical boat return is unreachable.", failures)

    def test_graph_orders_rescue_selection_event_boat_night_and_action(self) -> None:
        graph = proposed_graph(proposed_map())
        result = audit_graph(graph)
        self.assertEqual((), result.failures)
        chain = [le07.RESCUE_ID, f"{le07.INDIVIDUAL_ID}_commitment",
                 f"{le07.INDIVIDUAL_ID}_active_selection", le07.REFUGE_ID, le07.OPPORTUNITY_ID,
                 le07.MEMORY_ID, NIGHT_ID, le07.ADAPTATION_ID, le07.ACTION_ID, le07.CONTEXT_ID]
        stages = [result.stages[graph.resolve(item)] for item in chain]
        self.assertTrue(all(a < b for a, b in zip(stages, stages[1:])), list(zip(chain, stages)))
        for item_id, required_id in (
            (le07.RESCUE_ID, "salvage_cutter"), (le07.MEMORY_ID, le07.BOAT_ID),
            (le07.OPPORTUNITY_ID, "dive_light_1"), (le07.CONTEXT_ID, "shock_prod"),
        ):
            requirements = {edge.target for edge in graph.requirements(graph.resolve(item_id))}
            self.assertIn(graph.resolve(required_id), requirements)
        for item_id in le07.RECORDS:
            node = graph.nodes[graph.resolve(item_id)]
            self.assertEqual(le07.AVAILABILITY, node.attrs["availability"])
            self.assertFalse(node.mandatory)
            self.assertTrue(node.label.startswith("[proposed]"))
        optional_keys = {graph.resolve(item) for item in chain[3:]}
        self.assertFalse(any(edge.target in optional_keys for node in graph.nodes.values()
                             if node.kind in {"upgrade", "project", "capability"} or node.key == graph.resolve(le07.CACHE_ID)
                             for edge in graph.requirements(node.key)))

    def test_circular_growth_requirement_is_rejected_by_schema_and_graph(self) -> None:
        payload = proposed_map()
        record(payload, le07.OPPORTUNITY_ID)["required_adaptation_id"] = le07.ADAPTATION_ID
        self.assert_invalid(payload, "circularly requires")
        result = audit_graph(proposed_graph(payload))
        self.assertTrue(any("Hard dependency cycle" in failure for failure in result.failures), result.failures)


if __name__ == "__main__":
    unittest.main()
