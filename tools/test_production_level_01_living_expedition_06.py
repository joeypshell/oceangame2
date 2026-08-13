#!/usr/bin/env python3
"""Focused source tests for the Signal Reef nursery journey."""

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
from living_expedition_06_contract import (
    ACCESS_IDS,
    ANCHOR_CONTEXT_ID,
    AVAILABILITY,
    CAMERA_IDS,
    EAST_GATE_ID,
    GUARDIAN_CONTEXT_ID,
    JOURNEY_ID,
    NURSERY_ID,
    PRESSURE_ID,
    SCHOOL_ID,
)
from production_level_01_living_expedition_06 import (
    NURSERY_RECT,
    PRESSURE_PATH,
    PRESSURE_RECT,
    SCHOOL_PATH,
    SCHOOL_POINT,
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


class ProductionLevelLivingExpedition06Tests(unittest.TestCase):
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

    def test_source_relationship_matches_the_contract(self) -> None:
        journey = _by_id(self.map_data, "regional_creature_journeys", JOURNEY_ID)
        school = _by_id(self.map_data, "passive_wildlife_groups", SCHOOL_ID)
        nursery = _by_id(self.map_data, "creature_nurseries", NURSERY_ID)
        pressure = _by_id(self.map_data, "ecological_pressures", PRESSURE_ID)
        self.assertEqual(ACCESS_IDS, journey["required_access_ids"])
        self.assertEqual([ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID], journey["adaptation_context_ids"])
        self.assertTrue(journey["optional"])
        self.assertEqual([], journey["reward_ids"])
        self.assertEqual(SCHOOL_POINT, (school["x"], school["y"]))
        self.assertEqual(SCHOOL_PATH, tuple((point["x"], point["y"]) for point in school["path"]))
        self.assertEqual(NURSERY_RECT, (nursery["x"], nursery["y"], nursery["w"], nursery["h"]))
        self.assertEqual(PRESSURE_RECT, (pressure["x"], pressure["y"], pressure["w"], pressure["h"]))
        self.assertEqual(PRESSURE_PATH, tuple((point["x"], point["y"]) for point in pressure["path"]))

    def test_wildlife_is_passive_guaranteed_and_rewardless(self) -> None:
        school = _by_id(self.map_data, "passive_wildlife_groups", SCHOOL_ID)
        pressure = _by_id(self.map_data, "ecological_pressures", PRESSURE_ID)
        self.assertFalse(school["bondable"])
        self.assertFalse(school["harvestable"])
        self.assertFalse(school["collectible"])
        self.assertFalse(pressure["damaging"])
        for record in (
            _by_id(self.map_data, "regional_creature_journeys", JOURNEY_ID),
            school,
            _by_id(self.map_data, "creature_nurseries", NURSERY_ID),
            pressure,
            _by_id(self.map_data, "companion_contexts", ANCHOR_CONTEXT_ID),
            _by_id(self.map_data, "companion_contexts", GUARDIAN_CONTEXT_ID),
        ):
            self.assertEqual(AVAILABILITY, record["availability"])
        self.assertEqual([], school["reward_ids"])
        self.assertEqual([], pressure["reward_ids"])

    def test_adaptation_contexts_preserve_access_and_existing_targets(self) -> None:
        anchor = _by_id(self.map_data, "companion_contexts", ANCHOR_CONTEXT_ID)
        guardian = _by_id(self.map_data, "companion_contexts", GUARDIAN_CONTEXT_ID)
        self.assertEqual(("anchor_fins", "anchor_brace", EAST_GATE_ID), (
            anchor["required_adaptation_id"], anchor["action_id"], anchor["target_id"],
        ))
        self.assertEqual(("guardian_pulse", "guardian_pulse_action", PRESSURE_ID), (
            guardian["required_adaptation_id"], guardian["action_id"], guardian["target_id"],
        ))
        self.assertEqual(ACCESS_IDS, anchor["required_access_ids"])
        self.assertEqual(ACCESS_IDS, guardian["required_access_ids"])
        self.assertEqual(CAMERA_IDS, [
            item["id"] for item in self.map_data["camera_tests"] if item["id"] in CAMERA_IDS
        ])

    def test_authored_geometry_has_real_body_round_trips(self) -> None:
        for collection, record_id in (
            ("passive_wildlife_groups", SCHOOL_ID),
            ("creature_nurseries", NURSERY_ID),
            ("ecological_pressures", PRESSURE_ID),
        ):
            record = _by_id(self.map_data, collection, record_id)
            points = [(record["x"], record["y"])]
            points.extend((point["x"], point["y"]) for point in record.get("path", []))
            if "w" in record and "h" in record:
                points.extend(
                    (x, y)
                    for y in range(record["y"], record["y"] + record["h"])
                    for x in range(record["x"], record["x"] + record["w"])
                )
            for x, y in points:
                target = ((x + 0.5) * self.tile_size, (y + 0.5) * self.tile_size)
                self.assertIsNotNone(shortest_path(self.field, self.boat_point, target), (record_id, x, y))
                self.assertIsNotNone(shortest_path(self.field, target, self.boat_point), (record_id, x, y))

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
