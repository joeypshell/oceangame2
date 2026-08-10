#!/usr/bin/env python3
"""Focused source tests for Living Expedition 05's Silt Hound proof."""

from __future__ import annotations

import json
import unittest

from create_production_level_01_map import (
    OUTPUT_MAP_PATH,
    SOURCE_MAP_PATH,
    build_map_data,
    candidate_terrain,
    global_gameplay_clearance_cells,
)
from production_level_01_living_expedition_05 import (
    ACTION_ID,
    CANDIDATE_ID,
    CONTEXT_ID,
    DEPOSIT_POINT,
    EXCAVATE_CAMERA_ID,
    HABITAT_ID,
    INDIVIDUAL_ID,
    POOL_ID,
    RESCUE_CAMERA_ID,
    RESCUE_ID,
    RESCUE_POINT,
    SPECIES_ID,
)
from validate_full_level_traversal import (
    CollisionField,
    load_player_body,
    map_point,
    shortest_path,
    solid_cells,
)
from validate_living_expedition_schema import validate_living_expedition_schema


def _by_id(map_data: dict, collection: str, record_id: str) -> dict:
    return next(item for item in map_data[collection] if item["id"] == record_id)


class ProductionLevelLivingExpedition05Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(cls.source)
        units = cls.map_data["units"]
        cls.tile_size = int(units["tile_size_px"])
        cls.field = CollisionField(
            int(units["width_tiles"]),
            int(units["height_tiles"]),
            cls.tile_size,
            solid_cells(cls.map_data),
            load_player_body(),
            step_px=32,
        )
        boat = _by_id(cls.map_data, "entities", "surface_boat_entry")
        cls.boat_point = map_point(boat, cls.tile_size, entry=True)

    def test_rescue_and_excavation_relationship_are_exact(self) -> None:
        rescue = _by_id(self.map_data, "creature_rescues", RESCUE_ID)
        context = _by_id(self.map_data, "companion_contexts", CONTEXT_ID)
        candidate = _by_id(self.map_data, "entities", CANDIDATE_ID)
        self.assertEqual(RESCUE_POINT, (rescue["x"], rescue["y"]))
        self.assertEqual((SPECIES_ID, INDIVIDUAL_ID), (
            rescue["species_id"], rescue["individual_id"],
        ))
        self.assertEqual("salvage_cutter", rescue["required_capability_id"])
        self.assertEqual("surface_boat_entry", rescue["commit_entry_id"])
        self.assertEqual((CONTEXT_ID, CANDIDATE_ID), (
            rescue["excavation_context_id"], rescue["buried_candidate_id"],
        ))
        self.assertEqual((SPECIES_ID, INDIVIDUAL_ID, ACTION_ID, CANDIDATE_ID), (
            context["species_id"], context["individual_id"],
            context["action_id"], context["target_id"],
        ))
        self.assertEqual([], context["required_access_ids"])
        self.assertEqual(DEPOSIT_POINT, (candidate["x"], candidate["y"]))

    def test_mound_is_one_optional_normal_titanium_candidate(self) -> None:
        candidate = _by_id(self.map_data, "entities", CANDIDATE_ID)
        pool = _by_id(self.map_data, "material_candidate_pools", POOL_ID)
        self.assertEqual("material_collect", candidate["interaction"])
        self.assertEqual(("titanium_scrap", 1), (
            candidate["material_id"], candidate["material_quantity"],
        ))
        self.assertTrue(candidate["buried_deposit"])
        self.assertEqual(ACTION_ID, candidate["required_companion_action_id"])
        self.assertEqual(CONTEXT_ID, candidate["companion_context_id"])
        self.assertEqual("buried_mineral_mound", candidate["presentation_kind"])
        self.assertEqual("optional_bonus", pool["pool_role"])
        self.assertEqual([CANDIDATE_ID], pool["candidate_ids"])
        self.assertEqual([CANDIDATE_ID], pool["guaranteed_candidate_ids"])
        self.assertFalse(any(
            CANDIDATE_ID in json.dumps(project, sort_keys=True)
            or POOL_ID in json.dumps(project, sort_keys=True)
            for project in self.map_data["material_projects"]
        ))

    def test_habitat_and_review_records_preserve_stable_relationships(self) -> None:
        habitat = _by_id(self.map_data, "companion_habitats", HABITAT_ID)
        self.assertEqual([
            "spark_ray_juvenile_01",
            "veil_cuttle_juvenile_01",
            INDIVIDUAL_ID,
        ], habitat["individual_ids"])
        rescue_camera = _by_id(self.map_data, "camera_tests", RESCUE_CAMERA_ID)
        excavate_camera = _by_id(self.map_data, "camera_tests", EXCAVATE_CAMERA_ID)
        self.assertEqual(RESCUE_POINT[0], rescue_camera["center_x"])
        self.assertEqual(DEPOSIT_POINT[0], excavate_camera["center_x"])
        provenance = self.map_data["source"]["living_expedition_05"]
        self.assertEqual([RESCUE_ID], provenance["rescue_ids"])
        self.assertEqual([CONTEXT_ID], provenance["companion_context_ids"])
        self.assertEqual([CANDIDATE_ID], provenance["material_candidate_ids"])
        self.assertEqual([], provenance["terrain_changes"])

    def test_rescue_deposit_and_boat_have_ungated_round_trips(self) -> None:
        gated_zones = [
            zone for zone in self.map_data["zones"]
            if any(key.startswith("required_") and value for key, value in zone.items())
        ]
        for collection, record_id in (
            ("creature_rescues", RESCUE_ID),
            ("entities", CANDIDATE_ID),
        ):
            target = map_point(_by_id(self.map_data, collection, record_id), self.tile_size)
            outbound = shortest_path(self.field, self.boat_point, target)
            inbound = shortest_path(self.field, target, self.boat_point)
            self.assertIsNotNone(outbound, record_id)
            self.assertIsNotNone(inbound, record_id)
            for zone in gated_zones:
                crossed = any(
                    zone["x"] <= x / self.tile_size < zone["x"] + zone.get("w", 1)
                    and zone["y"] <= y / self.tile_size < zone["y"] + zone.get("h", 1)
                    for x, y in outbound.points
                )
                self.assertFalse(crossed, f"{record_id} crosses {zone['id']}")

    def test_generation_is_repeatable_valid_and_topology_unchanged(self) -> None:
        self.assertEqual([], validate_living_expedition_schema(self.map_data))
        self.assertEqual(self.map_data, build_map_data(self.source))
        self.assertEqual(
            candidate_terrain(self.source, global_gameplay_clearance_cells()),
            self.map_data["terrain"],
        )
        self.assertEqual(
            self.map_data,
            json.loads(OUTPUT_MAP_PATH.read_text(encoding="utf-8")),
        )


if __name__ == "__main__":
    unittest.main()
