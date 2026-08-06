#!/usr/bin/env python3
"""Focused source tests for Living Expedition 03's Mica migration relationship."""

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
from production_level_01_gameplay_transform import transform_gameplay_sections
from production_level_01_living_expedition_03 import (
    ADAPTATION_ID,
    CONDITION_ID,
    CONTEXT_ID,
    LEGACY_TRACE_ID,
    MEMORY_ID,
    MEMORY_RECORD_ID,
    MIGRATION_HAZARD_ID,
    OBSERVATION_ID,
    PAYOFF_HAZARD_ID,
    PAYOFF_ID,
    REVIEW_CAMERA_ID,
    TRACE_ID,
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


class ProductionLevelLivingExpedition03Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(cls.source)

    def test_relationship_is_linked_without_copying_patrol_authority(self) -> None:
        trace = _by_id(self.map_data, "ecological_traces", TRACE_ID)
        hazard = _by_id(self.map_data, "moving_hazards", MIGRATION_HAZARD_ID)
        first, last = hazard["path"][0], hazard["path"][-1]
        expected_anchor = (
            round((first["x"] + last["x"]) / 2),
            round((first["y"] + last["y"]) / 2),
        )
        self.assertEqual(expected_anchor, (trace["x"], trace["y"]))
        self.assertEqual(CONDITION_ID, trace["daily_condition_id"])
        self.assertEqual(MIGRATION_HAZARD_ID, trace["moving_hazard_id"])
        self.assertEqual(OBSERVATION_ID, trace["observation_id"])
        self.assertEqual(MEMORY_RECORD_ID, trace["memory_opportunity_id"])
        self.assertEqual(PAYOFF_ID, trace["adaptation_payoff_id"])
        for forbidden in (
            "active",
            "current_position",
            "elapsed",
            "path",
            "phase",
            "position",
            "speed_tiles_per_second",
        ):
            self.assertNotIn(forbidden, trace)

    def test_existing_bloom_schedule_and_patrol_geometry_are_unchanged(self) -> None:
        gameplay, _provenance = transform_gameplay_sections()
        source_condition = _by_id(gameplay, "daily_conditions", CONDITION_ID)
        generated_condition = _by_id(self.map_data, "daily_conditions", CONDITION_ID)
        for field, value in source_condition.items():
            self.assertEqual(value, generated_condition[field], field)
        for record_id in (MIGRATION_HAZARD_ID, PAYOFF_HAZARD_ID):
            self.assertEqual(
                _by_id(gameplay, "moving_hazards", record_id),
                _by_id(self.map_data, "moving_hazards", record_id),
            )

    def test_memory_payoff_and_field_context_form_one_rewardless_chain(self) -> None:
        memory = _by_id(self.map_data, "creature_memory_opportunities", MEMORY_RECORD_ID)
        payoff = _by_id(self.map_data, "creature_adaptation_payoffs", PAYOFF_ID)
        context = _by_id(self.map_data, "companion_contexts", CONTEXT_ID)
        self.assertEqual(MEMORY_ID, memory["memory_id"])
        self.assertEqual(TRACE_ID, memory["target_id"])
        self.assertEqual([ADAPTATION_ID], memory["adaptation_ids"])
        self.assertEqual(PAYOFF_ID, memory["payoff_id"])
        self.assertEqual(ADAPTATION_ID, payoff["adaptation_id"])
        self.assertEqual(PAYOFF_HAZARD_ID, payoff["target_id"])
        self.assertEqual(CONTEXT_ID, payoff["independent_context_id"])
        self.assertEqual("read_drift", context["action_id"])
        self.assertEqual([], memory["required_access_ids"])
        self.assertEqual([], payoff["required_access_ids"])
        self.assertEqual([], validate_living_expedition_schema(self.map_data))

    def test_trace_and_canonical_boat_have_a_reachable_round_trip(self) -> None:
        units = self.map_data["units"]
        tile_size = int(units["tile_size_px"])
        field = CollisionField(
            int(units["width_tiles"]),
            int(units["height_tiles"]),
            tile_size,
            solid_cells(self.map_data),
            load_player_body(),
            step_px=32,
        )
        boat = _by_id(self.map_data, "entities", "surface_boat_entry")
        trace = _by_id(self.map_data, "ecological_traces", TRACE_ID)
        boat_point = map_point(boat, tile_size, entry=True)
        trace_point = map_point(trace, tile_size)
        outbound = shortest_path(field, boat_point, trace_point)
        self.assertIsNotNone(outbound)
        self.assertIsNotNone(shortest_path(field, trace_point, boat_point))
        for zone in self.map_data["zones"]:
            if not any(key.startswith("required_") and value for key, value in zone.items()):
                continue
            crossed = any(
                zone["x"] <= x / tile_size < zone["x"] + zone.get("w", 1)
                and zone["y"] <= y / tile_size < zone["y"] + zone.get("h", 1)
                for x, y in outbound.points
            )
            self.assertFalse(crossed, zone["id"])

    def test_review_camera_and_transition_provenance_are_explicit(self) -> None:
        trace = _by_id(self.map_data, "ecological_traces", TRACE_ID)
        camera = _by_id(self.map_data, "camera_tests", REVIEW_CAMERA_ID)
        self.assertEqual((trace["x"], trace["y"]), (camera["center_x"], camera["center_y"]))
        source = self.map_data["source"]
        self.assertEqual([LEGACY_TRACE_ID], source["living_expedition_02"]["retired_trace_ids"])
        provenance = source["living_expedition_03"]
        self.assertEqual([TRACE_ID], provenance["relationship_ids"])
        self.assertEqual([MIGRATION_HAZARD_ID, PAYOFF_HAZARD_ID], provenance["moving_hazard_ids"])
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
