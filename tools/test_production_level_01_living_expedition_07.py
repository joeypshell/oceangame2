"""Source/footprint proofs for Marl; real eel motion is checked in Godot."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import re
import unittest
from unittest.mock import patch

import create_production_level_01_map as generator
import living_expedition_07_contract as contract
import production_level_01_living_expedition_07 as source
from render_greybox_map import render_svg
from validate_full_level_traversal import (
    CollisionField, PlayerBody, load_player_body, map_point, rect_cells,
    shortest_path, solid_cells,
)
from validate_living_expedition_schema import validate_living_expedition_schema

ROOT = Path(__file__).resolve().parent.parent


class MarlSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.input = json.loads(generator.SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = generator.build_map_data(cls.input)
        with patch.object(source, "author", side_effect=lambda value: value):
            cls.before = generator.build_map_data(cls.input)
        cls.values = source.records()

    def test_transform_only_appends_declared_records(self) -> None:
        restored = deepcopy(self.map_data)
        restored.pop(contract.REFUGE_FIELD)
        restored["source"].pop(contract.SOURCE_KEY)
        for field in set(contract.RECORDS.values()) - {contract.REFUGE_FIELD}:
            restored[field] = [item for item in restored[field] if item["id"] not in contract.RECORDS]
        restored["camera_tests"] = [
            item for item in restored["camera_tests"] if item["id"] not in contract.CAMERA_IDS
        ]
        self.assertEqual(self.before, restored)
        self.assertEqual(self.before["terrain"], self.map_data["terrain"])
        self.assertEqual(
            generator.candidate_terrain(self.input, generator.global_gameplay_clearance_cells()),
            self.map_data["terrain"],
        )

    def test_repeatable_committed_output_and_schema(self) -> None:
        self.assertEqual(self.map_data, generator.build_map_data(self.input))
        self.assertEqual(self.map_data, json.loads(generator.OUTPUT_MAP_PATH.read_text(encoding="utf-8")))
        self.assertEqual([], validate_living_expedition_schema(self.map_data))
        self.assertEqual(source.source_provenance(), self.map_data["source"][contract.SOURCE_KEY])

    def test_guarantee_is_not_a_random_candidate_or_locked_reward(self) -> None:
        for record_id, field in contract.RECORDS.items():
            record = next(item for item in self.map_data[field] if item["id"] == record_id)
            self.assertEqual("all_supported_seeds", record["availability"])
            self.assertFalse({"seed", "day", "probability", "daily_condition_id"} & record.keys())
        for field in contract.HARD_ACCESS_COLLECTIONS:
            self.assertEqual(self.before.get(field), self.map_data.get(field), field)
        refuge = self.values[contract.REFUGE_ID]
        self.assertEqual(["dive_light_1"], refuge["required_access_ids"])
        self.assertEqual([], refuge["reward_ids"])
        self.assertFalse(refuge["bondable"] or refuge["harvestable"])
        opportunity = self.values[contract.OPPORTUNITY_ID]
        self.assertEqual("surface_boat_entry", opportunity["commit_entry_id"])
        self.assertEqual("silt_hound_rescue_01", opportunity["required_rescue_id"])

    def test_refuge_points_and_floor_anchors_support_both_full_bodies(self) -> None:
        scene = (ROOT / "scenes/companion/SiltHoundCompanion.tscn").read_text(encoding="utf-8")
        size = re.search(r"size\s*=\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)", scene)
        self.assertIsNotNone(size)
        marl = PlayerBody(float(size.group(1)), float(size.group(2)))
        units = self.map_data["units"]
        tile = units["tile_size_px"]
        solids = solid_cells(self.map_data)
        # Even without other equipment, this optional approach must not need a
        # current/pressure bypass. Light is visual-only, not collision.
        denied = set(solids)
        for zone in self.map_data["zones"]:
            if zone.get("required_capability_id"):
                denied.update(rect_cells(zone))
        refuge = self.values[contract.REFUGE_ID]
        approach = map_point(refuge["approach_point"], tile)
        dig = map_point(refuge["dig_point"], tile)
        points = [map_point(source.point(cell), tile) for cell in (
            *source.WILDLIFE_PATH, *source.GROUND_ANCHORS,
            *rect_cells(refuge),
        )]
        boat = next(item for item in self.map_data["entities"] if item["id"] == contract.BOAT_ID)
        boat_point = map_point(boat, tile, entry=True)
        for name, body in (("diver", load_player_body()), ("Marl", marl)):
            with self.subTest(body=name):
                field = CollisionField(units["width_tiles"], units["height_tiles"], tile, denied, body, step_px=32)
                self.assertTrue(field.center_is_clear(approach))
                self.assertTrue(field.segment_is_clear(approach, dig))
                for target in points:
                    self.assertTrue(field.center_is_clear(target), (name, target))
                    self.assertTrue(field.segment_is_clear(approach, target), (name, target))
                route = shortest_path(field, boat_point, approach)
                self.assertIsNotNone(route, name)
                # Collision is static: explicitly sweep the reversed route too.
                backward = tuple(reversed(route.points))
                for start, target in zip(backward, backward[1:]):
                    self.assertTrue(field.segment_is_clear(start, target))
                print(f"{name}: boat/refuge round trip {route.distance_px * 2:.0f}px, full footprint clear")
        for x, y in source.GROUND_ANCHORS:
            self.assertIn((x, y + 1), solids)

    def test_transform_rejects_duplicate_or_missing_dependencies(self) -> None:
        with self.assertRaises(ValueError):
            source.author(deepcopy(self.map_data))
        for field, record_id in (("hostile_encounters", contract.HOSTILE_ID), ("creature_rescues", contract.RESCUE_ID)):
            broken = deepcopy(self.before)
            broken[field] = [item for item in broken[field] if item["id"] != record_id]
            with self.assertRaises(ValueError):
                source.author(broken)

    def test_svg_includes_focused_source_projection(self) -> None:
        svg = render_svg(self.map_data)
        self.assertIn(contract.REFUGE_ID, svg)
        self.assertIn("Ground Pin anchors", svg)
        self.assertIn("cyan: approach / gold: dig / green: scallops", svg)


if __name__ == "__main__":
    unittest.main()
