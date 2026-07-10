#!/usr/bin/env python3
"""Focused positive and negative tests for Expansion 07 biological sources."""

from __future__ import annotations

import copy
import unittest

from validate_biological_resources import (
    CAPACITOR_PROJECT_ID,
    HOSTILE_SOURCE_ID,
    PASSIVE_SOURCE_ID,
    validate_biological_resource_reachability,
    validate_biological_resource_schema,
)


def valid_map() -> dict:
    return {
        "id": "biological_fixture",
        "units": {"width_tiles": 80, "height_tiles": 80},
        "terrain": [],
        "entities": [{"id": "entry", "type": "spawn", "x": 1, "y": 1}],
        "zones": [
            {
                "id": "upper_right_current_pocket_gate",
                "type": "marker",
                "x": 65,
                "y": 40,
                "w": 2,
                "h": 2,
                "current_gate": True,
                "required_capability_id": "current_stabilizer",
            }
        ],
        "survey_targets": [],
        "hostile_encounters": [
            {
                "id": "deep_cache_territorial_eel",
                "x": 66,
                "y": 74,
                "required_weapon_capability_id": "shock_prod",
            }
        ],
        "biological_resource_sources": [
            {
                "id": PASSIVE_SOURCE_ID,
                "source_role": "passive_sample",
                "organism_kind": "glow_anemone",
                "x": 71,
                "y": 42,
                "required_capability_id": "survey_scanner_1",
                "interaction": "timed_sample",
                "interaction_seconds": 1.5,
                "material_id": "insulating_gel",
                "material_quantity": 1,
                "replenishment": "new_day",
                "display_label": "Glow anemone",
                "interaction_label": "Sampling glow anemone",
                "collected_label": "Insulating gel held",
                "route_context": "upper_right_current_pocket",
            },
            {
                "id": HOSTILE_SOURCE_ID,
                "source_role": "hostile_harvest",
                "organism_kind": "territorial_eel",
                "hostile_id": "deep_cache_territorial_eel",
                "interaction": "post_defeat_harvest",
                "interaction_seconds": 1.5,
                "material_id": "eel_electrocyte",
                "material_quantity": 1,
                "replenishment": "new_day",
                "display_label": "Eel electrocyte",
                "interaction_label": "Harvesting electrocyte",
                "collected_label": "Electrocyte held",
                "route_context": "deep_cache_pressure",
            },
        ],
        "material_projects": [
            {
                "id": "shock_prod_project",
                "required_discovery_id": "lower_right_anomaly_discovery",
                "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
                "unlocks_capability_id": "shock_prod",
                "target_hostile_id": "deep_cache_territorial_eel",
                "build_phase": "night_debrief",
            },
            {
                "id": CAPACITOR_PROJECT_ID,
                "required_project_id": "shock_prod_project",
                "required_discovery_id": "lower_right_anomaly_discovery",
                "required_materials": {
                    "conductive_coil": 1,
                    "insulating_gel": 1,
                    "eel_electrocyte": 1,
                },
                "unlocks_capability_id": "shock_prod_capacitor",
                "target_hostile_id": "deep_cache_territorial_eel",
                "capability_effect": "interrupt_warning_lunge",
                "build_phase": "night_debrief",
                "project_label": "Shock-prod capacitor project",
                "completion_label": "Shock-prod capacitor built",
            },
        ],
    }


class BiologicalResourceValidationTests(unittest.TestCase):
    def test_valid_schema_and_reachability(self) -> None:
        map_data = valid_map()
        self.assertEqual(validate_biological_resource_schema(map_data), [])
        reachable = {(x, y) for y in range(80) for x in range(80)}
        self.assertEqual(validate_biological_resource_reachability(map_data, set(), reachable), [])

    def test_optional_collection_is_backward_compatible(self) -> None:
        self.assertEqual(validate_biological_resource_schema({"material_projects": []}), [])

    def test_requires_list_and_locked_pair(self) -> None:
        self.assertEqual(
            validate_biological_resource_schema({"biological_resource_sources": {}}),
            ["biological_resource_sources must be a list when present."],
        )
        map_data = valid_map()
        map_data["biological_resource_sources"].pop()
        failures = validate_biological_resource_schema(map_data)
        self.assertTrue(any("exactly two" in failure for failure in failures), failures)
        self.assertTrue(any("locked Expansion 07 pair" in failure for failure in failures), failures)

    def test_rejects_passive_role_drift_and_runtime_fields(self) -> None:
        map_data = valid_map()
        passive = map_data["biological_resource_sources"][0]
        passive.update(
            {
                "organism_kind": "predator",
                "interaction": "damage_drop",
                "required_capability_id": "weapon",
                "progress": 0.5,
                "drop_chance": 0.5,
            }
        )
        failures = validate_biological_resource_schema(map_data)
        for expected in ("organism_kind", "interaction", "required_capability_id", "runtime/drop fields"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_hostile_link_and_automatic_drop(self) -> None:
        map_data = valid_map()
        hostile_source = map_data["biological_resource_sources"][1]
        hostile_source["hostile_id"] = "missing_hostile"
        hostile_source["interaction"] = "automatic_drop"
        hostile_source["loot"] = {"eel_electrocyte": 1}
        failures = validate_biological_resource_schema(map_data)
        for expected in ("hostile_id", "interaction", "runtime/drop fields"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_random_or_invalid_yield_contract(self) -> None:
        map_data = valid_map()
        passive = map_data["biological_resource_sources"][0]
        passive["interaction_seconds"] = float("inf")
        passive["material_quantity"] = 2
        passive["replenishment"] = "random"
        passive["display_label"] = "bad\nlabel"
        failures = validate_biological_resource_schema(map_data)
        for expected in ("finite positive", "exactly 1", "new_day", "display-safe"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_circular_or_drifted_project(self) -> None:
        map_data = valid_map()
        project = map_data["material_projects"][-1]
        project["required_project_id"] = CAPACITOR_PROJECT_ID
        project["required_materials"] = {"eel_electrocyte": 4}
        project["capability_effect"] = "double_damage"
        failures = validate_biological_resource_schema(map_data)
        for expected in ("required_project_id", "required_materials", "capability_effect"):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_duplicate_source_id(self) -> None:
        map_data = valid_map()
        map_data["entities"].append({"id": PASSIVE_SOURCE_ID, "type": "salvage", "x": 2, "y": 2})
        failures = validate_biological_resource_schema(map_data)
        self.assertTrue(any("Duplicate biological source id" in failure for failure in failures), failures)

    def test_rejects_solid_unreachable_pre_gate_or_overlap(self) -> None:
        map_data = valid_map()
        passive = map_data["biological_resource_sources"][0]
        point = (passive["x"], passive["y"])
        failures = validate_biological_resource_reachability(map_data, {point}, {(1, 1)})
        self.assertTrue(any("solid terrain" in failure for failure in failures), failures)
        passive["x"] = 65
        map_data["survey_targets"].append({"id": "survey", "x": 65, "y": 42, "w": 1, "h": 1})
        reachable = {(x, y) for y in range(80) for x in range(80)}
        failures = validate_biological_resource_reachability(map_data, set(), reachable)
        self.assertTrue(any("east of" in failure for failure in failures), failures)
        self.assertTrue(any("overlaps" in failure for failure in failures), failures)

    def test_fixture_mutations_are_isolated(self) -> None:
        first = valid_map()
        second = copy.deepcopy(first)
        second["biological_resource_sources"].clear()
        self.assertEqual(len(first["biological_resource_sources"]), 2)


if __name__ == "__main__":
    unittest.main()
