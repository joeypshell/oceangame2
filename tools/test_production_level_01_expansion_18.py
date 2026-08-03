#!/usr/bin/env python3
"""Focused source and footprint tests for the Expansion 18 map pair."""

from __future__ import annotations

import hashlib
import json
import unittest

from create_production_level_01_map import (
    OUTPUT_MAP_PATH as EXTERIOR_PATH,
    SOURCE_MAP_PATH,
    build_map_data as build_exterior,
)
from create_transfer_hub_interior_01_map import (
    BOAT_ID,
    CORE_DISCOVERY_ID,
    CORE_ID,
    ENTRY_ID,
    EXTERIOR_ENTRANCE_ID,
    EXTERIOR_RETURN_ID,
    MAP_ID,
    OUTPUT_MAP_PATH as INTERIOR_PATH,
    RETURN_ID,
    build_map_data as build_interior,
)
from production_level_01_expansion_18 import PREREQUISITE_ID
from validate_expansion_14_contract import TERRAIN_SHA256
from validate_full_level_traversal import (
    CollisionField,
    load_player_body,
    map_point,
    shortest_path,
    solid_cells,
)
from validate_material_sources import validate_material_source_schema
from validate_tool_target_rewards import validate_tool_target_reward_schema
from validate_world_connectors import validate_world_connector_schema


def _by_id(map_data: dict, collection: str, record_id: str) -> dict:
    return next(item for item in map_data[collection] if item["id"] == record_id)


def _terrain_hash(map_data: dict) -> str:
    payload = json.dumps(
        map_data["terrain"], sort_keys=True, separators=(",", ":")
    ).encode()
    return hashlib.sha256(payload).hexdigest()


def _field(map_data: dict) -> CollisionField:
    units = map_data["units"]
    return CollisionField(
        int(units["width_tiles"]),
        int(units["height_tiles"]),
        int(units["tile_size_px"]),
        solid_cells(map_data),
        load_player_body(),
        step_px=32,
    )


class ProductionLevelExpansion18Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.exterior = build_exterior(source)
        cls.interior = build_interior()

    def assert_round_trip(self, map_data: dict, start_item: dict, target: dict, *, entry: bool = False) -> None:
        tile_size = int(map_data["units"]["tile_size_px"])
        field = _field(map_data)
        start = map_point(start_item, tile_size, entry=entry)
        destination = map_point(target, tile_size)
        self.assertTrue(field.center_is_clear(start))
        self.assertTrue(field.center_is_clear(destination))
        self.assertIsNotNone(shortest_path(field, start, destination))
        self.assertIsNotNone(shortest_path(field, destination, start))

    def test_pair_uses_exact_reciprocal_contract(self) -> None:
        entrance = _by_id(self.exterior, "zones", EXTERIOR_ENTRANCE_ID)
        exterior_return = _by_id(self.exterior, "entities", EXTERIOR_RETURN_ID)
        interior_return = _by_id(self.interior, "zones", RETURN_ID)
        self.assertEqual("spawn", exterior_return["type"])
        self.assertEqual(MAP_ID, entrance["destination_map_id"])
        self.assertEqual(ENTRY_ID, entrance["destination_entry_id"])
        self.assertEqual(RETURN_ID, entrance["paired_connector_id"])
        self.assertEqual(PREREQUISITE_ID, entrance["required_discovery_id"])
        self.assertEqual("transfer_hub_core_recovery", entrance["mission_id"])
        self.assertIn("lowest central chamber", entrance["mission_guidance"])
        self.assertIn("surface boat", entrance["mission_return_guidance"])
        self.assertEqual(EXTERIOR_ENTRANCE_ID, interior_return["paired_connector_id"])
        self.assertEqual(EXTERIOR_RETURN_ID, interior_return["destination_entry_id"])
        self.assertNotIn("required_discovery_id", interior_return)
        self.assertEqual([], validate_world_connector_schema(EXTERIOR_PATH, self.exterior))
        self.assertEqual([], validate_world_connector_schema(INTERIOR_PATH, self.interior))

    def test_navigation_core_is_one_cross_map_held_reward(self) -> None:
        core = _by_id(self.interior, "entities", CORE_ID)
        self.assertEqual("cutter_salvage", core["interaction"])
        self.assertEqual("salvage_cutter", core["required_tool_id"])
        self.assertEqual("held_discovery_cargo", core["reward_kind"])
        self.assertEqual(CORE_DISCOVERY_ID, core["reward_id"])
        self.assertEqual("production_level_01", core["reward_commit_map_id"])
        self.assertEqual(BOAT_ID, core["reward_commit_entry_id"])
        self.assertEqual("transfer_hub_core_recovery", core["mission_id"])
        self.assertIn("Select Cutter", core["mission_guidance"])
        self.assertIn("west door", core["mission_return_guidance"])
        self.assertEqual([], validate_tool_target_reward_schema(self.interior))
        self.assertEqual([], validate_material_source_schema(self.interior))

    def test_exterior_and_interior_have_player_footprint_round_trips(self) -> None:
        boat = _by_id(self.exterior, "entities", BOAT_ID)
        entrance = _by_id(self.exterior, "zones", EXTERIOR_ENTRANCE_ID)
        self.assert_round_trip(self.exterior, boat, entrance, entry=True)
        arrival = _by_id(self.interior, "entities", ENTRY_ID)
        self.assert_round_trip(
            self.interior, arrival, _by_id(self.interior, "entities", CORE_ID)
        )
        self.assert_round_trip(
            self.interior, arrival, _by_id(self.interior, "zones", RETURN_ID)
        )

    def test_interior_has_no_commit_or_refill_owner(self) -> None:
        self.assertFalse(any(item["type"] == "boat_spawn" for item in self.interior["entities"]))
        self.assertFalse(any(item["type"] == "base" for item in self.interior["zones"]))
        self.assertFalse(any(item.get("oxygen_rest") for item in self.interior["zones"]))
        self.assertNotIn("daily_conditions", self.interior)
        self.assertTrue(all(cell in solid_cells(self.interior) for cell in (
            *((x, 0) for x in range(self.interior["units"]["width_tiles"])),
            *((x, self.interior["units"]["height_tiles"] - 1) for x in range(self.interior["units"]["width_tiles"])),
        )))

    def test_exterior_terrain_is_unchanged_and_sources_are_repeatable(self) -> None:
        self.assertEqual(TERRAIN_SHA256, _terrain_hash(self.exterior))
        self.assertEqual([], self.exterior["source"]["expansion_18"]["terrain_changes"])
        self.assertEqual(
            self.exterior,
            json.loads(EXTERIOR_PATH.read_text(encoding="utf-8")),
        )
        self.assertEqual(
            self.interior,
            json.loads(INTERIOR_PATH.read_text(encoding="utf-8")),
        )


if __name__ == "__main__":
    unittest.main()
