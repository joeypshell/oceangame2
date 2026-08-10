#!/usr/bin/env python3
"""Focused source tests for Living Expedition 02 Veil Cuttle records."""

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
from production_level_01_living_expedition_02 import (
    ACTION_ID,
    AVAILABILITY,
    HABITAT_ID,
    INDIVIDUAL_ID,
    RESCUE_ID,
    REVIEW_CAMERA_ID,
    SPECIES_ID,
    TRACE_ID as RETIRED_TRACE_ID,
)
from production_level_01_living_expedition_03 import TRACE_ID
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


class ProductionLevelLivingExpedition02Tests(unittest.TestCase):
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

    def test_rescue_relationships_are_explicit_and_non_circular(self) -> None:
        rescue = _by_id(self.map_data, "creature_rescues", RESCUE_ID)
        self.assertEqual((38, 49), (rescue["x"], rescue["y"]))
        self.assertEqual((SPECIES_ID, INDIVIDUAL_ID), (rescue["species_id"], rescue["individual_id"]))
        self.assertEqual("physical_aid", rescue["rescue_kind"])
        self.assertEqual("salvage_cutter", rescue["required_capability_id"])
        self.assertEqual("surface_boat_entry", rescue["commit_entry_id"])
        self.assertEqual(HABITAT_ID, rescue["habitat_id"])
        self.assertEqual(TRACE_ID, rescue["trace_id"])
        self.assertEqual(REVIEW_CAMERA_ID, rescue["review_camera_id"])
        self.assertTrue(rescue["optional"])
        self.assertNotIn(ACTION_ID, rescue.values())
        self.assertEqual(AVAILABILITY, rescue["availability"])

    def test_habitat_is_canonical_boat_relationship_not_profile_state(self) -> None:
        habitat = _by_id(self.map_data, "companion_habitats", HABITAT_ID)
        self.assertEqual("canonical_boat", habitat["habitat_kind"])
        self.assertEqual("surface_boat_entry", habitat["entry_id"])
        self.assertEqual(
            ["spark_ray_juvenile_01", INDIVIDUAL_ID, "silt_hound_juvenile_01"],
            habitat["individual_ids"],
        )
        for forbidden in ("active_individual_id", "selected", "committed", "position"):
            self.assertNotIn(forbidden, habitat)

    def test_trace_is_optional_rewardless_and_requires_scanner_identification(self) -> None:
        trace = _by_id(self.map_data, "ecological_traces", TRACE_ID)
        self.assertEqual(ACTION_ID, trace["action_id"])
        self.assertEqual("survey_scanner_1", trace["scanner_capability_id"])
        self.assertEqual([], trace["required_access_ids"])
        self.assertTrue(trace["optional"])
        self.assertEqual([], trace["reward_ids"])
        self.assertEqual("none", trace["progression_effect"])
        self.assertEqual([], validate_living_expedition_schema(self.map_data))

    def test_rescue_habitat_and_trace_have_boat_round_trips_without_gate_crossing(self) -> None:
        records = [
            _by_id(self.map_data, "creature_rescues", RESCUE_ID),
            _by_id(self.map_data, "companion_habitats", HABITAT_ID),
            _by_id(self.map_data, "ecological_traces", TRACE_ID),
        ]
        gated_zones = [
            zone
            for zone in self.map_data["zones"]
            if any(key.startswith("required_") and value for key, value in zone.items())
        ]
        for record in records:
            target = map_point(record, self.tile_size)
            outbound = shortest_path(self.field, self.boat_point, target)
            inbound = shortest_path(self.field, target, self.boat_point)
            self.assertIsNotNone(outbound, record["id"])
            self.assertIsNotNone(inbound, record["id"])
            for zone in gated_zones:
                crossed = any(
                    zone["x"] <= x / self.tile_size < zone["x"] + zone["w"]
                    and zone["y"] <= y / self.tile_size < zone["y"] + zone["h"]
                    for x, y in outbound.points
                )
                self.assertFalse(crossed, f"{record['id']} crosses {zone['id']}")

    def test_review_camera_and_provenance_are_exact(self) -> None:
        camera = _by_id(self.map_data, "camera_tests", REVIEW_CAMERA_ID)
        self.assertEqual((45, 52), (camera["center_x"], camera["center_y"]))
        provenance = self.map_data["source"]["living_expedition_02"]
        self.assertEqual([RESCUE_ID], provenance["rescue_ids"])
        self.assertEqual([HABITAT_ID], provenance["habitat_ids"])
        self.assertEqual([], provenance["trace_ids"])
        self.assertEqual([RETIRED_TRACE_ID], provenance["retired_trace_ids"])
        self.assertEqual("living_expedition_03", provenance["trace_transition_owner"])
        self.assertNotIn(RETIRED_TRACE_ID, provenance["target_ids"])
        self.assertEqual([REVIEW_CAMERA_ID], provenance["camera_test_ids"])
        self.assertEqual([], provenance["terrain_changes"])

    def test_generation_is_repeatable_and_topology_is_unchanged(self) -> None:
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
