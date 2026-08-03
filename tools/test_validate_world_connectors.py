#!/usr/bin/env python3
"""Focused positive and negative tests for paired exceptional interiors."""

from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

from validate_world_connectors import validate_world_connector_schema


def connector(
    connector_id: str,
    direction: str,
    destination_map_id: str,
    destination_entry_id: str,
    paired_id: str,
) -> dict:
    item = {
        "id": connector_id,
        "type": "marker",
        "x": 2,
        "y": 2,
        "w": 2,
        "h": 2,
        "world_connector": True,
        "connector_kind": "exceptional_interior",
        "connector_label": "Transfer Hub",
        "destination_map_id": destination_map_id,
        "destination_map_path": f"res://maps/{destination_map_id}.greybox.json",
        "destination_entry_id": destination_entry_id,
        "connector_direction": direction,
        "paired_connector_id": paired_id,
    }
    if direction == "forward":
        item["required_discovery_id"] = "wreck_network_triangulation_discovery"
    return item


class WorldConnectorValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.maps = self.root / "maps"
        self.maps.mkdir()
        self.exterior_path = self.maps / "production_level_01.greybox.json"
        self.interior_path = self.maps / "transfer_hub_interior_01.greybox.json"
        self.exterior = {
            "id": "production_level_01",
            "units": {"width_tiles": 20, "height_tiles": 12},
            "entities": [
                {"id": "surface_boat_entry", "type": "boat_spawn"},
                {"id": "transfer_hub_exterior_return", "type": "spawn"},
            ],
            "zones": [connector(
                "transfer_hub_exterior_entrance", "forward",
                "transfer_hub_interior_01", "transfer_hub_interior_entry",
                "transfer_hub_interior_return",
            )],
        }
        self.interior = {
            "id": "transfer_hub_interior_01",
            "units": {"width_tiles": 16, "height_tiles": 10},
            "entities": [{"id": "transfer_hub_interior_entry", "type": "spawn"}],
            "zones": [connector(
                "transfer_hub_interior_return", "return",
                "production_level_01", "transfer_hub_exterior_return",
                "transfer_hub_exterior_entrance",
            )],
        }
        self._write_maps()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_maps(self) -> None:
        self.exterior_path.write_text(json.dumps(self.exterior), encoding="utf-8")
        self.interior_path.write_text(json.dumps(self.interior), encoding="utf-8")

    def test_accepts_reciprocal_exceptional_interior_pair(self) -> None:
        self.assertEqual([], validate_world_connector_schema(self.exterior_path, self.exterior))
        self.assertEqual([], validate_world_connector_schema(self.interior_path, self.interior))

    def test_rejects_missing_or_nonreciprocal_pair(self) -> None:
        self.interior["zones"][0]["paired_connector_id"] = "wrong_origin"
        self._write_maps()
        failures = validate_world_connector_schema(self.exterior_path, self.exterior)
        self.assertTrue(any("point back" in failure for failure in failures), failures)

    def test_rejects_prerequisite_on_return_and_missing_on_forward(self) -> None:
        exterior = copy.deepcopy(self.exterior)
        exterior["zones"][0].pop("required_discovery_id")
        failures = validate_world_connector_schema(self.exterior_path, exterior)
        self.assertTrue(any("requires lower_snake_case" in failure for failure in failures), failures)
        interior = copy.deepcopy(self.interior)
        interior["zones"][0]["required_discovery_id"] = "wrong_return_gate"
        failures = validate_world_connector_schema(self.interior_path, interior)
        self.assertTrue(any("must not repeat" in failure for failure in failures), failures)

    def test_rejects_runtime_state_and_legacy_pair_fields(self) -> None:
        exterior = copy.deepcopy(self.exterior)
        exterior["zones"][0]["unlocked"] = True
        failures = validate_world_connector_schema(self.exterior_path, exterior)
        self.assertTrue(any("runtime state" in failure for failure in failures), failures)
        legacy = copy.deepcopy(exterior)
        legacy["zones"][0].pop("connector_kind")
        failures = validate_world_connector_schema(self.exterior_path, legacy)
        self.assertTrue(any("requires connector_kind" in failure for failure in failures), failures)

    def test_validates_optional_source_owned_mission_guidance(self) -> None:
        entrance = self.exterior["zones"][0]
        entrance.update({
            "mission_id": "transfer_hub_core_recovery",
            "mission_guidance": "Transfer Hub | Descend to lowest central chamber",
            "mission_return_guidance": "Navigation core secured | Return to surface boat",
        })
        self._write_maps()
        self.assertEqual([], validate_world_connector_schema(self.exterior_path, self.exterior))
        entrance.pop("mission_return_guidance")
        failures = validate_world_connector_schema(self.exterior_path, self.exterior)
        self.assertTrue(any("mission guidance is missing" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
