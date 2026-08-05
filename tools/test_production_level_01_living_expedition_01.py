#!/usr/bin/env python3
"""Focused source tests for the Living Expedition 01 Spark Ray proof."""

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
from production_level_01_living_expedition_01 import (
    ANCHOR_PAYOFF_ID,
    ANCHOR_PAYOFF_TARGET_ID,
    AVAILABILITY,
    CURRENT_MEMORY_ID,
    CURRENT_MEMORY_TARGET_ID,
    EEL_MEMORY_ID,
    EEL_TARGET_ID,
    GUARDIAN_PAYOFF_ID,
    RESCUE_ID,
    RIDING_REVIEW_ID,
)
from validate_full_level_traversal import (
    CollisionField,
    load_player_body,
    map_point,
    shortest_path,
    solid_cells,
)
from validate_living_expedition_schema import validate_living_expedition_schema


CAMERA_IDS = {
    "living_expedition_01_rescue",
    "living_expedition_01_follow",
    "living_expedition_01_mounted_route",
    "living_expedition_01_held_the_flow",
    "living_expedition_01_stood_ground",
    "living_expedition_01_night_choice",
    "living_expedition_01_anchor_payoff",
    "living_expedition_01_guardian_payoff",
}


def _by_id(map_data: dict, collection: str, record_id: str) -> dict:
    return next(item for item in map_data[collection] if item["id"] == record_id)


def _candidate_points(item: dict, tile_size: int) -> list[tuple[int, int]]:
    if "w" not in item or "h" not in item:
        return [map_point(item, tile_size)]
    return [
        (round((x + 0.5) * tile_size), round((y + 0.5) * tile_size))
        for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
    ]


class ProductionLevelLivingExpedition01Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(cls.source)

    def test_rescue_is_physical_guaranteed_and_boat_committed(self) -> None:
        rescue = _by_id(self.map_data, "creature_rescues", RESCUE_ID)
        self.assertEqual((118, 41), (rescue["x"], rescue["y"]))
        self.assertEqual("physical_aid", rescue["rescue_kind"])
        self.assertEqual("salvage_cutter", rescue["required_capability_id"])
        self.assertEqual("surface_boat_entry", rescue["commit_entry_id"])
        self.assertEqual(RIDING_REVIEW_ID, rescue["riding_review_context_id"])
        self.assertEqual(AVAILABILITY, rescue["availability"])
        self.assertIn("maintenance cable", rescue["intent"])

    def test_riding_route_has_clear_footprint_and_no_gate_dependency(self) -> None:
        context = _by_id(self.map_data, "companion_contexts", RIDING_REVIEW_ID)
        self.assertEqual("mounted_route_review", context["context_kind"])
        self.assertEqual("glide_surge", context["action_id"])
        self.assertEqual([], context["required_access_ids"])
        self.assertEqual(
            [(95, 8), (98, 14), (102, 19), (108, 22)],
            [(point["x"], point["y"]) for point in context["route_points"]],
        )
        self.assertEqual(
            {"outcome": "clear", "x": 108, "y": 22}, context["dismount"]
        )
        self.assertEqual([], validate_living_expedition_schema(self.map_data))

    def test_memories_and_payoffs_retain_existing_equipment_gates(self) -> None:
        current_memory = _by_id(
            self.map_data, "creature_memory_opportunities", CURRENT_MEMORY_ID
        )
        eel_memory = _by_id(
            self.map_data, "creature_memory_opportunities", EEL_MEMORY_ID
        )
        anchor = _by_id(
            self.map_data, "creature_adaptation_payoffs", ANCHOR_PAYOFF_ID
        )
        guardian = _by_id(
            self.map_data, "creature_adaptation_payoffs", GUARDIAN_PAYOFF_ID
        )
        self.assertEqual(CURRENT_MEMORY_TARGET_ID, current_memory["target_id"])
        self.assertEqual(["propulsion_fins"], current_memory["required_access_ids"])
        self.assertEqual(EEL_TARGET_ID, eel_memory["target_id"])
        self.assertEqual(["shock_prod"], eel_memory["required_access_ids"])
        self.assertEqual(ANCHOR_PAYOFF_TARGET_ID, anchor["target_id"])
        self.assertEqual(["propulsion_fins"], anchor["required_access_ids"])
        self.assertEqual(EEL_TARGET_ID, guardian["target_id"])
        self.assertEqual(["shock_prod"], guardian["required_access_ids"])
        self.assertNotEqual(current_memory["target_id"], anchor["target_id"])

    def test_required_points_have_physical_round_trips_from_boat(self) -> None:
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
        start = map_point(boat, tile_size, entry=True)
        targets = [
            _by_id(self.map_data, "creature_rescues", RESCUE_ID),
            *(
                _by_id(self.map_data, "zones", target_id)
                for target_id in (
                    CURRENT_MEMORY_TARGET_ID,
                    ANCHOR_PAYOFF_TARGET_ID,
                )
            ),
            _by_id(self.map_data, "hostile_encounters", EEL_TARGET_ID),
        ]
        for target in targets:
            round_trip_points = [
                destination
                for destination in _candidate_points(target, tile_size)
                if shortest_path(field, start, destination) is not None
                and shortest_path(field, destination, start) is not None
            ]
            self.assertTrue(round_trip_points, target["id"])

    def test_review_evidence_and_provenance_are_complete(self) -> None:
        camera_ids = {item["id"] for item in self.map_data["camera_tests"]}
        self.assertTrue(CAMERA_IDS <= camera_ids)
        provenance = self.map_data["source"]["living_expedition_01"]
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual(AVAILABILITY, provenance["availability"])
        self.assertEqual(CAMERA_IDS, set(provenance["camera_test_ids"]))
        self.assertEqual(
            {CURRENT_MEMORY_TARGET_ID, ANCHOR_PAYOFF_TARGET_ID, EEL_TARGET_ID},
            set(provenance["target_ids"]),
        )

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
