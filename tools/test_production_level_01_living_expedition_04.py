#!/usr/bin/env python3
"""Focused source tests for Living Expedition 04's companion-shaped eel."""

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
from production_level_01_living_expedition_04 import (
    HARVEST_ID,
    HOSTILE_ID,
    RELATIONSHIP_ID,
    REVIEW_CAMERA_ID,
    REVIEW_CONTEXT_ID,
    SALVAGE_ID,
)
from validate_living_expedition_schema import validate_living_expedition_schema


def _by_id(map_data: dict, collection: str, record_id: str) -> dict:
    return next(item for item in map_data[collection] if item["id"] == record_id)


class ProductionLevelLivingExpedition04Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(cls.source)

    def test_relationship_references_existing_owners_without_copying_state(self) -> None:
        relationship = _by_id(self.map_data, "companion_hostile_responses", RELATIONSHIP_ID)
        self.assertEqual(HOSTILE_ID, relationship["hostile_id"])
        self.assertEqual(SALVAGE_ID, relationship["guarded_salvage_id"])
        self.assertEqual(HARVEST_ID, relationship["hostile_harvest_id"])
        self.assertEqual(REVIEW_CONTEXT_ID, relationship["review_context_id"])
        self.assertEqual(["veil_cuttle", "spark_ray"], [item["species_id"] for item in relationship["responses"]])
        for forbidden in (
            "territory", "health", "phase", "position", "reward_ids", "profile_state", "defeated"
        ):
            self.assertNotIn(forbidden, relationship)
        self.assertEqual([], validate_living_expedition_schema(self.map_data))

    def test_hostile_cache_and_harvest_source_are_unchanged(self) -> None:
        gameplay, _provenance = transform_gameplay_sections()
        for collection, record_id in (
            ("hostile_encounters", HOSTILE_ID),
            ("entities", SALVAGE_ID),
            ("biological_resource_sources", HARVEST_ID),
        ):
            self.assertEqual(
                _by_id(gameplay, collection, record_id),
                _by_id(self.map_data, collection, record_id),
            )

    def test_companion_effect_boundaries_are_explicit(self) -> None:
        responses = _by_id(
            self.map_data, "companion_hostile_responses", RELATIONSHIP_ID
        )["responses"]
        mica, kite = responses
        self.assertEqual(("hostile_intent_read", "none"), (mica["effect_kind"], mica["mutation"]))
        self.assertEqual(("support_interrupt", 0), (kite["effect_kind"], kite["damage"]))
        self.assertEqual(["shock_prod"], kite["required_access_ids"])

    def test_camera_and_provenance_are_derived_and_topology_free(self) -> None:
        hostile = _by_id(self.map_data, "hostile_encounters", HOSTILE_ID)
        territory = hostile["territory"]
        camera = _by_id(self.map_data, "camera_tests", REVIEW_CAMERA_ID)
        self.assertEqual(
            (territory["x"] + territory["w"] / 2, territory["y"] + territory["h"] / 2),
            (camera["center_x"], camera["center_y"]),
        )
        provenance = self.map_data["source"]["living_expedition_04"]
        self.assertEqual([RELATIONSHIP_ID], provenance["relationship_ids"])
        self.assertEqual([REVIEW_CAMERA_ID], provenance["camera_test_ids"])
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual(
            candidate_terrain(self.source, global_gameplay_clearance_cells()),
            self.map_data["terrain"],
        )

    def test_generation_is_repeatable_and_matches_committed_output(self) -> None:
        self.assertEqual(self.map_data, build_map_data(self.source))
        self.assertEqual(
            self.map_data,
            json.loads(OUTPUT_MAP_PATH.read_text(encoding="utf-8")),
        )


if __name__ == "__main__":
    unittest.main()
