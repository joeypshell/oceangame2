#!/usr/bin/env python3
"""Focused fixtures for Expansion 15 expedition-lead validation."""

from __future__ import annotations

import copy
import json
import unittest

from create_production_level_01_map import SOURCE_MAP_PATH, build_map_data
from validate_expedition_leads import (
    validate_expedition_lead_schema,
    validate_expedition_planning_schema,
)
from validate_regional_journeys import validate_regional_journey_schema


RELAY_ID = "upper_left_wreck_relay_route"
BLOOM_ID = "southwest_jellyfish_bloom"


def source_map() -> dict:
    source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
    return build_map_data(source)


def with_leads() -> dict:
    data = source_map()
    relay = next(item for item in data["regional_journeys"] if item["id"] == RELAY_ID)
    bloom = next(item for item in data["daily_conditions"] if item["id"] == BLOOM_ID)
    relay["expedition_lead"] = {
        "lead_type": "regional_journey",
        "label": "Northwest Wreck Relay",
        "summary": "Use the Current Stabilizer to survey the transmitting wreck",
        "active_guidance": "Plan: Follow the archive signal northwest",
        "order": 10,
    }
    bloom["expedition_lead"] = {
        "lead_type": "daily_condition",
        "label": "Southwest Jellyfish Bloom",
        "summary": "Risk the migration lane for an optional conductive-coil trace",
        "active_guidance": "Plan: Search the southwest migration lane",
        "order": 20,
    }
    return data


class ExpeditionLeadValidationTests(unittest.TestCase):
    def test_omitted_metadata_preserves_existing_maps(self) -> None:
        self.assertEqual([], validate_expedition_planning_schema(source_map()))

    def test_accepts_locked_relay_and_bloom_metadata(self) -> None:
        data = with_leads()
        self.assertEqual([], validate_expedition_planning_schema(data))
        self.assertEqual([], validate_regional_journey_schema(data))

    def test_rejects_duplicate_ids_and_orders(self) -> None:
        data = with_leads()
        bloom = data["daily_conditions"][0]
        bloom["id"] = RELAY_ID
        bloom["expedition_lead"]["order"] = 10
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("Duplicate expedition lead id" in failure for failure in failures), failures)
        self.assertTrue(any("Duplicate expedition lead order" in failure for failure in failures), failures)

    def test_rejects_unsupported_or_mismatched_lead_types(self) -> None:
        data = with_leads()
        relay = next(item for item in data["regional_journeys"] if item["id"] == RELAY_ID)
        bloom = data["daily_conditions"][0]
        relay["expedition_lead"]["lead_type"] = "mission"
        bloom["expedition_lead"]["lead_type"] = "regional_journey"
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("lead_type 'mission' is unsupported" in failure for failure in failures), failures)
        self.assertTrue(any("must match parent type 'daily_condition'" in failure for failure in failures), failures)

    def test_rejects_invalid_and_oversized_text(self) -> None:
        data = with_leads()
        relay = next(item for item in data["regional_journeys"] if item["id"] == RELAY_ID)
        lead = relay["expedition_lead"]
        lead["label"] = "Bad\nLabel"
        lead["summary"] = "x" * 97
        lead["active_guidance"] = "Plan: invalid @ guidance"
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("label must be" in failure for failure in failures), failures)
        self.assertTrue(any("summary must be" in failure for failure in failures), failures)
        self.assertTrue(any("active_guidance must be" in failure for failure in failures), failures)

    def test_rejects_runtime_reward_and_unknown_fields(self) -> None:
        data = with_leads()
        relay = next(item for item in data["regional_journeys"] if item["id"] == RELAY_ID)
        lead = relay["expedition_lead"]
        lead["selected"] = True
        lead["reward_id"] = "free_capability"
        lead["coordinates"] = [1, 2]
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("runtime selection or rewards" in failure for failure in failures), failures)
        self.assertTrue(any("unsupported fields: coordinates" in failure for failure in failures), failures)

    def test_rejects_dangling_relay_references(self) -> None:
        data = with_leads()
        relay = next(item for item in data["regional_journeys"] if item["id"] == RELAY_ID)
        relay["survey_target_id"] = "missing_survey"
        relay["required_discovery_id"] = "missing_discovery"
        relay["required_capability_id"] = "missing_capability"
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("dangling survey_target_id" in failure for failure in failures), failures)
        self.assertTrue(any("required_discovery_id must resolve" in failure for failure in failures), failures)
        self.assertTrue(any("required_capability_id must resolve" in failure for failure in failures), failures)

    def test_rejects_missing_daily_opportunity_links(self) -> None:
        data = with_leads()
        data["material_candidate_pools"] = [
            item
            for item in data["material_candidate_pools"]
            if item.get("daily_condition_id") != BLOOM_ID
        ]
        data["moving_hazards"] = [
            item
            for item in data["moving_hazards"]
            if item.get("daily_condition_id") != BLOOM_ID
        ]
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("no linked daily-condition material pool" in failure for failure in failures), failures)
        self.assertTrue(any("no linked daily-condition moving hazard" in failure for failure in failures), failures)

    def test_rejects_misplaced_metadata(self) -> None:
        data = with_leads()
        data["entities"][0]["expedition_lead"] = copy.deepcopy(
            data["daily_conditions"][0]["expedition_lead"]
        )
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("supported only on" in failure for failure in failures), failures)

    def test_rejects_invalid_order_values(self) -> None:
        data = with_leads()
        relay = next(item for item in data["regional_journeys"] if item["id"] == RELAY_ID)
        relay["expedition_lead"]["order"] = True
        failures = validate_expedition_lead_schema(data)
        self.assertTrue(any("order must be a non-negative integer" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
