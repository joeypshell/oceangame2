#!/usr/bin/env python3
"""Focused fixtures for Expansion 08 daily-condition validation."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from validate_daily_conditions import validate_daily_condition_schema
from validate_material_sources import validate_material_source_schema


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "production_slice_01.greybox.json"


def source_map() -> dict:
    return json.loads(MAP_PATH.read_text(encoding="utf-8"))


def with_condition() -> dict:
    data = source_map()
    data["daily_conditions"] = [{
        "id": "southwest_jellyfish_bloom",
        "schedule": "even_days_v1",
        "forecast_label": "Tomorrow: Southwest jellyfish bloom",
        "active_label": "Southwest bloom: jellyfish + coil trace",
        "route_context": "southwest_pocket_decision",
        "intent": "Forecast one optional southwest risk-reward opportunity.",
    }]
    data["entities"].append({
        "id": "material_coil_southwest_bloom",
        "type": "material_candidate",
        "x": 24,
        "y": 70,
        "kind": "conductive_fragment",
        "interaction": "material_collect",
        "material_id": "conductive_coil",
        "material_quantity": 1,
        "candidate_pool_id": "southwest_bloom_coil_bonus_pool",
    })
    data["material_candidate_pools"].append({
        "id": "southwest_bloom_coil_bonus_pool",
        "material_id": "conductive_coil",
        "selection_strategy": "day_rotation_v1",
        "select_count": 1,
        "candidate_ids": ["material_coil_southwest_bloom"],
        "pool_role": "optional_bonus",
        "daily_condition_id": "southwest_jellyfish_bloom",
    })
    data["moving_hazards"].append({
        "id": "southwest_bloom_jellyfish_patrol",
        "kind": "jellyfish",
        "x": 24,
        "y": 70,
        "movement": "linear_patrol",
        "path": [{"x": 24, "y": 70}, {"x": 30, "y": 70}],
        "speed_tiles_per_second": 1.0,
        "route_context": "southwest_pocket_decision",
        "display_label": "Bloom jellyfish patrol",
        "daily_condition_id": "southwest_jellyfish_bloom",
    })
    return data


class DailyConditionValidationTests(unittest.TestCase):
    def test_omitted_condition_preserves_existing_source(self) -> None:
        self.assertEqual([], validate_daily_condition_schema(source_map()))

    def test_accepts_locked_condition_links(self) -> None:
        data = with_condition()
        self.assertEqual([], validate_daily_condition_schema(data))
        self.assertEqual([], validate_material_source_schema(data))

    def test_rejects_invalid_schedule_and_runtime_state(self) -> None:
        data = with_condition()
        data["daily_conditions"][0]["schedule"] = "random_weighted"
        data["daily_conditions"][0]["active"] = True
        failures = validate_daily_condition_schema(data)
        self.assertTrue(any("schedule must be 'even_days_v1'" in failure for failure in failures), failures)
        self.assertTrue(any("runtime condition state" in failure for failure in failures), failures)

    def test_rejects_dangling_and_misplaced_links(self) -> None:
        data = with_condition()
        data.pop("daily_conditions")
        data["entities"][0]["daily_condition_id"] = "southwest_jellyfish_bloom"
        failures = validate_daily_condition_schema(data)
        self.assertTrue(any("links require one" in failure for failure in failures), failures)
        self.assertTrue(any("only supported" in failure for failure in failures), failures)

    def test_rejects_missing_pool_and_hazard_pair(self) -> None:
        data = with_condition()
        data["material_candidate_pools"].pop()
        data["moving_hazards"].pop()
        failures = validate_daily_condition_schema(data)
        self.assertTrue(any("exactly one condition-bound material pool" in failure for failure in failures), failures)
        self.assertTrue(any("exactly one condition-bound moving hazard" in failure for failure in failures), failures)

    def test_optional_bonus_does_not_satisfy_project_floor(self) -> None:
        data = with_condition()
        base_pool = next(pool for pool in data["material_candidate_pools"] if pool["id"] == "conductive_coil_pool")
        base_pool["select_count"] = 0
        failures = validate_material_source_schema(data)
        self.assertTrue(
            any("requires 1 conductive_coil, but daily sources guarantee only 0" in failure for failure in failures),
            failures,
        )


if __name__ == "__main__":
    unittest.main()
