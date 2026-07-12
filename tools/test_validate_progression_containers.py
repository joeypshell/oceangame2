#!/usr/bin/env python3
"""Focused tests for source-authored progression container rewards."""

from __future__ import annotations

import unittest

from validate_progression_containers import validate_progression_container_schema


def valid_map() -> dict:
    return {
        "units": {"width_tiles": 20, "height_tiles": 12},
        "material_projects": [
            {
                "id": "propulsion_fins_project",
                "required_discovery_id": "propulsion_fins_blueprint",
            }
        ],
        "progression_containers": [
            {
                "id": "lower_loop_upgrade_chest",
                "display_label": "Fins blueprint chest",
                "container_type": "upgrade_chest",
                "interaction": "instant",
                "reward_type": "blueprint",
                "reward_id": "propulsion_fins_blueprint",
                "route_context": "lower_loop_reward",
                "x": 4,
                "y": 4,
                "w": 2,
                "h": 2,
            }
        ],
    }


class ProgressionContainerValidationTests(unittest.TestCase):
    def test_accepts_blueprint_linked_to_one_project(self) -> None:
        self.assertEqual(validate_progression_container_schema(valid_map()), [])

    def test_rejects_unlinked_blueprint(self) -> None:
        map_data = valid_map()
        map_data["material_projects"][0].pop("required_discovery_id")
        failures = validate_progression_container_schema(map_data)
        self.assertIn(
            "lower_loop_upgrade_chest blueprint reward_id must unlock exactly one material project.",
            failures,
        )

    def test_rejects_blueprint_reward_amount(self) -> None:
        map_data = valid_map()
        map_data["progression_containers"][0]["reward_amount"] = 400
        failures = validate_progression_container_schema(map_data)
        self.assertIn("lower_loop_upgrade_chest blueprint reward must not define reward_amount.", failures)


if __name__ == "__main__":
    unittest.main()
