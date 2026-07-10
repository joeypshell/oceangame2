#!/usr/bin/env python3
"""Focused positive and negative tests for Expansion 06 hostile source validation."""

from __future__ import annotations

import copy
import unittest

from validate_hostile_encounters import validate_hostile_encounter_reachability, validate_hostile_encounter_schema


def hostile() -> dict:
    return {
        "id": "deep_cache_territorial_eel",
        "kind": "territorial_eel",
        "x": 6,
        "y": 5,
        "behavior": "territorial_lunge",
        "territory": {"x": 2, "y": 2, "w": 8, "h": 6},
        "warning_radius_tiles": 4.0,
        "warning_seconds": 0.75,
        "lunge_speed_tiles_per_second": 6.0,
        "lunge_seconds": 0.45,
        "recovery_seconds": 1.25,
        "contact_radius_tiles": 0.75,
        "health": 3,
        "contact_damage": 1,
        "required_weapon_capability_id": "shock_prod",
        "warning_label": "Territorial eel - watch the lunge",
        "retreat_label": "Eel territory - retreat or evade",
        "defeated_label": "Territory clear for today",
        "route_context": "deep_cache_pressure",
        "intent": "Test hostile in unchanged room geometry.",
    }


def valid_map() -> dict:
    return {
        "id": "combat_fixture",
        "units": {"width_tiles": 12, "height_tiles": 10},
        "entities": [
            {"id": "salvage_lower_loop", "type": "salvage", "x": 1, "y": 8, "kind": "relic"},
            {
                "id": "salvage_deep_right_cache",
                "type": "salvage",
                "x": 6,
                "y": 6,
                "kind": "relic",
                "interaction": "timed_salvage",
                "required_capability_id": "shock_prod",
                "guarded_by_hostile_id": "deep_cache_territorial_eel",
                "locked_label": "Shock prod required - return after building it",
                "guard_active_label": "Shock prod ready - defeat eel to claim cache",
            },
        ],
        "zones": [],
        "material_projects": [],
        "route_objectives": [
            {"id": "relay_trail", "required_banked_targets": ["salvage_lower_loop"]},
        ],
        "hostile_encounters": [hostile()],
    }


class HostileEncounterValidationTests(unittest.TestCase):
    def test_accepts_bounded_hostile_and_open_evade_lane(self) -> None:
        map_data = valid_map()
        self.assertEqual(validate_hostile_encounter_schema(map_data), [])
        reachable = {(x, y) for y in range(10) for x in range(12)}
        self.assertEqual(validate_hostile_encounter_reachability(map_data["hostile_encounters"], set(), reachable), [])

    def test_collection_is_optional_but_supports_only_one_record(self) -> None:
        self.assertEqual(validate_hostile_encounter_schema({"units": {"width_tiles": 4, "height_tiles": 4}}), [])
        map_data = valid_map()
        map_data["hostile_encounters"].append(copy.deepcopy(map_data["hostile_encounters"][0]))
        failures = validate_hostile_encounter_schema(map_data)
        self.assertTrue(any("exactly one" in failure for failure in failures), failures)

    def test_rejects_unsupported_identity_behavior_and_capability(self) -> None:
        map_data = valid_map()
        value = map_data["hostile_encounters"][0]
        value.update({"id": "other_eel", "kind": "shark", "behavior": "pursuit", "required_weapon_capability_id": "laser"})
        failures = validate_hostile_encounter_schema(map_data)
        for expected in ("id must be", "kind must be", "behavior must be", "required_weapon_capability_id must be"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_runtime_drop_unknown_and_invalid_numeric_fields(self) -> None:
        map_data = valid_map()
        value = map_data["hostile_encounters"][0]
        value.update({"current_health": 2, "drops": ["eel_tissue"], "patrol_mode": "smart", "warning_seconds": float("inf"), "health": 4, "contact_damage": 2})
        failures = validate_hostile_encounter_schema(map_data)
        for expected in ("runtime/reward fields", "unsupported fields", "finite positive", "health must be exactly 3", "contact_damage must be exactly 1"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_bad_territory_home_labels_and_duplicate_cross_id(self) -> None:
        map_data = valid_map()
        value = map_data["hostile_encounters"][0]
        map_data["entities"] = [{"id": value["id"]}]
        value["territory"] = {"x": 0, "y": 0, "w": 2, "h": 2, "extra": 1}
        value["warning_label"] = "bad\nlabel"
        failures = validate_hostile_encounter_schema(map_data)
        for expected in ("Duplicate source id", "exactly x, y, w, and h", "home point must be inside", "display-safe"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_solid_home_and_blocked_lower_evade_lane(self) -> None:
        map_data = valid_map()
        value = map_data["hostile_encounters"][0]
        reachable = {(x, y) for y in range(10) for x in range(12)}
        solid = {(value["x"], value["y"]), (2, 7)}
        failures = validate_hostile_encounter_reachability(map_data["hostile_encounters"], solid, reachable - {(3, 7)})
        self.assertTrue(any("inside solid terrain" in failure for failure in failures), failures)
        self.assertTrue(any("evade lane" in failure for failure in failures), failures)

    def test_rejects_missing_mismatched_or_pre_weapon_guarded_target(self) -> None:
        missing = valid_map()
        missing["entities"] = [missing["entities"][0]]
        self.assertTrue(any("exactly one guarded" in failure for failure in validate_hostile_encounter_schema(missing)))

        mismatched = valid_map()
        target = mismatched["entities"][1]
        target["required_capability_id"] = "salvage_cutter"
        target["guarded_by_hostile_id"] = "other_eel"
        target["x"] = 11
        failures = validate_hostile_encounter_schema(mismatched)
        for expected in ("required_capability_id", "guarded_by_hostile_id", "inside the guarding"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

        circular = valid_map()
        circular["route_objectives"][0]["required_banked_targets"].append("salvage_deep_right_cache")
        failures = validate_hostile_encounter_schema(circular)
        self.assertTrue(any("cannot be required by pre-weapon" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
