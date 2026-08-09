#!/usr/bin/env python3
"""Focused fixtures for the Living Expedition 04 relationship contract."""

from __future__ import annotations

import copy
import unittest

from test_validate_living_expedition_schema import valid_map
from validate_living_expedition_schema import validate_living_expedition_schema


def valid_living_expedition_04_map() -> dict:
    map_data = valid_map()
    map_data["entities"].append({
        "id": "salvage_deep_right_cache",
        "type": "salvage",
        "x": 15,
        "y": 6,
        "kind": "relic",
        "guarded_by_hostile_id": "deep_cache_territorial_eel",
    })
    map_data["hostile_encounters"].append({
        "id": "deep_cache_territorial_eel",
        "kind": "territorial_eel",
        "behavior": "territorial_lunge",
        "required_weapon_capability_id": "shock_prod",
    })
    map_data["biological_resource_sources"] = [{
        "id": "deep_cache_eel_electrocyte_harvest",
        "source_role": "hostile_harvest",
        "organism_kind": "territorial_eel",
        "hostile_id": "deep_cache_territorial_eel",
        "interaction": "post_defeat_harvest",
        "material_id": "eel_electrocyte",
    }]
    map_data["companion_hostile_responses"] = [{
        "id": "deep_cache_eel_companion_response",
        "kind": "companion_hostile_response",
        "hostile_id": "deep_cache_territorial_eel",
        "guarded_salvage_id": "salvage_deep_right_cache",
        "hostile_harvest_id": "deep_cache_eel_electrocyte_harvest",
        "review_context_id": "living_expedition_04_eel_review_01",
        "responses": [
            {
                "species_id": "veil_cuttle",
                "individual_id": "veil_cuttle_juvenile_01",
                "required_adaptation_id": "drift_lens",
                "action_id": "read_drift",
                "effect_kind": "hostile_intent_read",
                "mutation": "none",
            },
            {
                "species_id": "spark_ray",
                "individual_id": "spark_ray_juvenile_01",
                "required_adaptation_id": "guardian_pulse",
                "action_id": "guardian_pulse_action",
                "effect_kind": "support_interrupt",
                "damage": 0,
                "required_access_ids": ["shock_prod"],
            },
        ],
        "availability": "all_supported_seeds",
    }]
    return map_data


def validate(map_data: dict) -> list[str]:
    return validate_living_expedition_schema(map_data)


class LivingExpedition04ContractTests(unittest.TestCase):
    def test_complete_relationship_passes(self) -> None:
        self.assertEqual([], validate(valid_living_expedition_04_map()))

    def test_absent_relationship_preserves_existing_maps(self) -> None:
        self.assertEqual([], validate(valid_map()))

    def test_rejects_dangling_or_drifted_source_links(self) -> None:
        cases = {
            "hostile_id": "existing hostile encounter",
            "guarded_salvage_id": "existing salvage",
            "hostile_harvest_id": "existing biological source",
        }
        for field, expected_failure in cases.items():
            with self.subTest(field=field):
                map_data = valid_living_expedition_04_map()
                map_data["companion_hostile_responses"][0][field] = "missing_record"
                failures = validate(map_data)
                self.assertTrue(any(expected_failure in failure for failure in failures), failures)

        map_data = valid_living_expedition_04_map()
        map_data["entities"][-1]["guarded_by_hostile_id"] = "other_hostile"
        map_data["biological_resource_sources"][0]["interaction"] = "automatic_drop"
        failures = validate(map_data)
        self.assertTrue(any("hostile guard relationship" in failure for failure in failures), failures)
        self.assertTrue(any("defeat-only eel electrocyte" in failure for failure in failures), failures)

    def test_rejects_damage_access_and_action_drift(self) -> None:
        map_data = valid_living_expedition_04_map()
        mica, kite = map_data["companion_hostile_responses"][0]["responses"]
        mica["action_id"] = "guardian_pulse_action"
        kite["damage"] = 1
        kite["required_access_ids"] = []
        failures = validate(map_data)
        self.assertTrue(any("action_id must be 'read_drift'" in failure for failure in failures), failures)
        self.assertTrue(any("damage must be 0" in failure for failure in failures), failures)
        self.assertTrue(any("required_access_ids must be ['shock_prod']" in failure for failure in failures), failures)

    def test_rejects_copied_state_rewards_geometry_and_harvest_authority(self) -> None:
        map_data = valid_living_expedition_04_map()
        relationship = map_data["companion_hostile_responses"][0]
        relationship.update({"territory": {"x": 1}, "reward_ids": ["loot"], "profile_state": {}})
        relationship["responses"][0].update({"phase": "warning", "defeated": True})
        relationship["responses"][1]["exposes_harvest"] = True
        failures = validate(map_data)
        self.assertTrue(any("copied state, reward, geometry" in failure for failure in failures), failures)
        self.assertTrue(any("unsupported authority fields" in failure for failure in failures), failures)
        self.assertTrue(any("outside its bounded effect" in failure for failure in failures), failures)

    def test_rejects_duplicate_or_unsupported_companion_response(self) -> None:
        map_data = valid_living_expedition_04_map()
        relationship = map_data["companion_hostile_responses"][0]
        relationship["responses"][1] = copy.deepcopy(relationship["responses"][0])
        failures = validate(map_data)
        self.assertTrue(any("ordered species" in failure for failure in failures), failures)

        relationship["responses"][1]["species_id"] = "unknown_species"
        failures = validate(map_data)
        self.assertTrue(any("no supported LE04 response" in failure for failure in failures), failures)

    def test_rejects_invalid_ids_shape_and_availability(self) -> None:
        map_data = valid_living_expedition_04_map()
        relationship = map_data["companion_hostile_responses"][0]
        relationship["id"] = "Bad Relationship"
        relationship["review_context_id"] = "Bad Context"
        relationship["availability"] = "daily_roll"
        failures = validate(map_data)
        self.assertTrue(any("lower_snake_case" in failure for failure in failures), failures)
        self.assertTrue(any("all_supported_seeds" in failure for failure in failures), failures)

        map_data["companion_hostile_responses"] = []
        failures = validate(map_data)
        self.assertTrue(any("exactly one relationship object" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
