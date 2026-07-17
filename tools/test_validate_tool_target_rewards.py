#!/usr/bin/env python3
"""Focused positive and negative tests for cutter discovery rewards."""

from __future__ import annotations

import copy
import unittest

from validate_tool_target_rewards import validate_tool_target_reward_schema


REWARD_ID = "southeast_wreck_navigation_data"
TARGET_ID = "salvage_sealed_wreck_cache"
ROUTE_ID = "southeast_wreck_archive_route"


def valid_map() -> dict:
    return {
        "id": "production_level_01",
        "entities": [
            {"id": "surface_boat_entry", "type": "boat_spawn"},
            {
                "id": TARGET_ID,
                "type": "tool_target",
                "tier": "valuable",
                "interaction": "cutter_salvage",
                "reward_kind": "discovery",
                "reward_id": REWARD_ID,
                "reward_pending_label": "Wreck navigation data secured | Return to surface boat",
                "reward_commit_label": "Navigation data logged: Southeast wreck coordinates",
                "reward_next_lead_label": "Wreck coordinates | Signal continues deep southeast",
                "reward_commit_map_id": "production_level_01",
                "reward_commit_map_path": "res://maps/production_level_01.greybox.json",
                "reward_commit_entry_id": "surface_boat_entry",
            },
        ],
        "survey_targets": [],
        "regional_journeys": [{"id": ROUTE_ID, "required_discovery_id": REWARD_ID}],
    }


class ToolTargetRewardValidationTests(unittest.TestCase):
    def test_accepts_canonical_pending_discovery_reward(self) -> None:
        self.assertEqual([], validate_tool_target_reward_schema(valid_map()))

    def test_rejects_missing_and_unsupported_reward_metadata(self) -> None:
        map_data = valid_map()
        target = map_data["entities"][1]
        target.pop("reward_pending_label")
        target["reward_kind"] = "wallet"
        failures = validate_tool_target_reward_schema(map_data)
        self.assertTrue(any("missing required fields" in failure for failure in failures), failures)
        self.assertTrue(any("reward_kind must be 'discovery'" in failure for failure in failures), failures)

    def test_rejects_invalid_commit_ownership(self) -> None:
        map_data = valid_map()
        target = map_data["entities"][1]
        target["reward_commit_map_id"] = "production_slice_02"
        target["reward_commit_map_path"] = "res://maps/production_slice_02.greybox.json"
        target["reward_commit_entry_id"] = "relay_sub_entry"
        failures = validate_tool_target_reward_schema(map_data)
        self.assertTrue(any("reward_commit_map_id" in failure for failure in failures), failures)
        self.assertTrue(any("reward_commit_map_path" in failure for failure in failures), failures)
        self.assertTrue(any("canonical boat_spawn" in failure for failure in failures), failures)

    def test_rejects_progression_self_gate_and_duplicate_owner(self) -> None:
        map_data = valid_map()
        target = map_data["entities"][1]
        target["required_route_id"] = ROUTE_ID
        duplicate = copy.deepcopy(target)
        duplicate["id"] = "duplicate_navigation_reward"
        duplicate.pop("required_route_id")
        map_data["entities"].append(duplicate)
        failures = validate_tool_target_reward_schema(map_data)
        self.assertTrue(any("must not depend on the journey" in failure for failure in failures), failures)
        self.assertTrue(any("exactly one source owner" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
