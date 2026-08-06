#!/usr/bin/env python3
"""Focused fixtures for Living Expedition creature catalog and map schema."""

from __future__ import annotations

import copy
import unittest

from validate_living_expedition_schema import (
    load_creature_catalog,
    validate_creature_catalog,
    validate_living_expedition_reachability,
    validate_living_expedition_schema,
)


def valid_map() -> dict:
    return {
        "id": "production_level_01",
        "units": {"width_tiles": 20, "height_tiles": 12, "tile_size_px": 32},
        "terrain": [],
        "entities": [{
            "id": "surface_boat_entry",
            "type": "boat_spawn",
            "x": 1,
            "y": 1,
            "w": 3,
            "h": 2,
            "entry_x": 2,
            "entry_y": 2,
        }],
        "zones": [{
            "id": "spark_ray_memory_current",
            "type": "marker",
            "x": 8,
            "y": 3,
            "w": 1,
            "h": 2,
            "current_gate": True,
            "required_capability_id": "propulsion_fins",
        }],
        "hostile_encounters": [{
            "id": "spark_ray_memory_eel",
            "x": 14,
            "y": 5,
            "territory": {"x": 13, "y": 4, "w": 3, "h": 3},
            "required_weapon_capability_id": "shock_prod",
        }],
        "creature_rescues": [
            {
                "id": "spark_ray_rescue_01",
                "species_id": "spark_ray",
                "individual_id": "spark_ray_juvenile_01",
                "x": 3,
                "y": 3,
                "rescue_kind": "physical_aid",
                "required_capability_id": "salvage_cutter",
                "commit_map_id": "production_level_01",
                "commit_entry_id": "surface_boat_entry",
                "riding_review_context_id": "spark_ray_riding_review_01",
                "availability": "all_supported_seeds",
            },
            {
                "id": "veil_cuttle_rescue_01",
                "species_id": "veil_cuttle",
                "individual_id": "veil_cuttle_juvenile_01",
                "x": 7,
                "y": 7,
                "rescue_kind": "physical_aid",
                "required_capability_id": "salvage_cutter",
                "commit_map_id": "production_level_01",
                "commit_entry_id": "surface_boat_entry",
                "habitat_id": "companion_habitat_01",
                "trace_id": "veil_cuttle_trace_01",
                "review_camera_id": "veil_cuttle_review_01",
                "optional": True,
                "availability": "all_supported_seeds",
            },
        ],
        "companion_habitats": [{
            "id": "companion_habitat_01",
            "habitat_kind": "canonical_boat",
            "x": 2,
            "y": 2,
            "entry_id": "surface_boat_entry",
            "individual_ids": ["spark_ray_juvenile_01", "veil_cuttle_juvenile_01"],
            "availability": "all_supported_seeds",
        }],
        "ecological_traces": [{
            "id": "veil_cuttle_trace_01",
            "trace_kind": "concealed_ecological_trace",
            "species_id": "veil_cuttle",
            "individual_id": "veil_cuttle_juvenile_01",
            "x": 9,
            "y": 7,
            "action_id": "reveal_trace",
            "reveal_radius_tiles": 6,
            "scanner_capability_id": "survey_scanner_1",
            "required_access_ids": [],
            "optional": True,
            "reward_ids": [],
            "progression_effect": "none",
            "availability": "all_supported_seeds",
        }],
        "camera_tests": [{
            "id": "veil_cuttle_review_01",
            "center_x": 8,
            "center_y": 7,
            "zoom": 0.6,
        }],
        "material_projects": [{
            "id": "scanner_fixture_project",
            "required_materials": {},
            "unlocks_capability_id": "survey_scanner_1",
        }],
        "companion_contexts": [
            {
                "id": "spark_ray_riding_review_01",
                "context_kind": "mounted_route_review",
                "species_id": "spark_ray",
                "action_id": "glide_surge",
                "route_points": [{"x": 3, "y": 3}, {"x": 6, "y": 3}],
                "required_access_ids": [],
                "dismount": {"outcome": "clear", "x": 6, "y": 3},
                "availability": "all_supported_seeds",
            },
            {
                "id": "spark_ray_anchor_independent_review_01",
                "context_kind": "independent_action_review",
                "species_id": "spark_ray",
                "action_id": "anchor_brace",
                "required_adaptation_id": "anchor_fins",
                "target_id": "spark_ray_memory_current",
                "availability": "all_supported_seeds",
            },
            {
                "id": "spark_ray_anchor_mounted_review_01",
                "context_kind": "mounted_action_review",
                "species_id": "spark_ray",
                "action_id": "anchor_brace",
                "required_adaptation_id": "anchor_fins",
                "target_id": "spark_ray_memory_current",
                "availability": "all_supported_seeds",
            },
            {
                "id": "spark_ray_guardian_independent_review_01",
                "context_kind": "independent_action_review",
                "species_id": "spark_ray",
                "action_id": "guardian_pulse_action",
                "required_adaptation_id": "guardian_pulse",
                "target_id": "spark_ray_memory_eel",
                "availability": "all_supported_seeds",
            },
            {
                "id": "spark_ray_guardian_mounted_review_01",
                "context_kind": "mounted_action_review",
                "species_id": "spark_ray",
                "action_id": "guardian_pulse_action",
                "required_adaptation_id": "guardian_pulse",
                "target_id": "spark_ray_memory_eel",
                "availability": "all_supported_seeds",
            },
        ],
        "creature_memory_opportunities": [
            {
                "id": "spark_ray_current_memory_01",
                "memory_id": "held_the_flow",
                "species_id": "spark_ray",
                "individual_id": "spark_ray_juvenile_01",
                "event_kind": "current_cycle_completed",
                "target_id": "spark_ray_memory_current",
                "adaptation_ids": ["anchor_fins"],
                "payoff_id": "spark_ray_anchor_current_01",
                "required_access_ids": ["propulsion_fins"],
                "availability": "all_supported_seeds",
            },
            {
                "id": "spark_ray_eel_memory_01",
                "memory_id": "stood_ground",
                "species_id": "spark_ray",
                "individual_id": "spark_ray_juvenile_01",
                "event_kind": "territorial_threat_cycle_resolved",
                "target_id": "spark_ray_memory_eel",
                "adaptation_ids": ["guardian_pulse"],
                "payoff_id": "spark_ray_guardian_eel_01",
                "required_access_ids": ["shock_prod"],
                "availability": "all_supported_seeds",
            },
        ],
        "creature_adaptation_payoffs": [
            {
                "id": "spark_ray_anchor_current_01",
                "species_id": "spark_ray",
                "adaptation_id": "anchor_fins",
                "target_id": "spark_ray_memory_current",
                "required_access_ids": ["propulsion_fins"],
                "independent_context_id": "spark_ray_anchor_independent_review_01",
                "mounted_context_id": "spark_ray_anchor_mounted_review_01",
                "availability": "all_supported_seeds",
            },
            {
                "id": "spark_ray_guardian_eel_01",
                "species_id": "spark_ray",
                "adaptation_id": "guardian_pulse",
                "target_id": "spark_ray_memory_eel",
                "required_access_ids": ["shock_prod"],
                "independent_context_id": "spark_ray_guardian_independent_review_01",
                "mounted_context_id": "spark_ray_guardian_mounted_review_01",
                "availability": "all_supported_seeds",
            },
        ],
    }


def valid_living_expedition_03_map() -> dict:
    map_data = valid_map()
    map_data["creature_rescues"][1]["trace_id"] = "southwest_bloom_migration_trace"
    trace = map_data["ecological_traces"][0]
    trace.update({
        "id": "southwest_bloom_migration_trace",
        "relationship_kind": "moving_hazard_migration",
        "observation_id": "southwest_bloom_migration_observation",
        "daily_condition_id": "southwest_jellyfish_bloom",
        "moving_hazard_id": "southwest_bloom_jellyfish_patrol",
        "memory_opportunity_id": "veil_cuttle_bloom_memory_01",
        "adaptation_payoff_id": "veil_cuttle_drift_lens_payoff_01",
    })
    map_data["daily_conditions"] = [{
        "id": "southwest_jellyfish_bloom",
        "schedule": "even_days_v1",
    }]
    map_data["moving_hazards"] = [
        {
            "id": "deep_route_jellyfish_patrol",
            "kind": "jellyfish",
            "x": 12,
            "y": 8,
            "movement": "linear_patrol",
            "path": [{"x": 12, "y": 8}, {"x": 15, "y": 8}],
        },
        {
            "id": "southwest_bloom_jellyfish_patrol",
            "kind": "jellyfish",
            "x": 8,
            "y": 8,
            "movement": "linear_patrol",
            "path": [{"x": 8, "y": 8}, {"x": 10, "y": 8}],
            "daily_condition_id": "southwest_jellyfish_bloom",
        },
    ]
    map_data["companion_contexts"].append({
        "id": "veil_cuttle_drift_review_01",
        "context_kind": "independent_action_review",
        "species_id": "veil_cuttle",
        "action_id": "read_drift",
        "required_adaptation_id": "drift_lens",
        "target_id": "deep_route_jellyfish_patrol",
        "availability": "all_supported_seeds",
    })
    map_data["creature_memory_opportunities"].append({
        "id": "veil_cuttle_bloom_memory_01",
        "memory_id": "followed_the_bloom",
        "species_id": "veil_cuttle",
        "individual_id": "veil_cuttle_juvenile_01",
        "event_kind": "ecological_observation_committed",
        "target_id": "southwest_bloom_migration_trace",
        "adaptation_ids": ["drift_lens"],
        "payoff_id": "veil_cuttle_drift_lens_payoff_01",
        "required_access_ids": [],
        "availability": "all_supported_seeds",
    })
    map_data["creature_adaptation_payoffs"].append({
        "id": "veil_cuttle_drift_lens_payoff_01",
        "species_id": "veil_cuttle",
        "adaptation_id": "drift_lens",
        "target_id": "deep_route_jellyfish_patrol",
        "required_access_ids": [],
        "independent_context_id": "veil_cuttle_drift_review_01",
        "availability": "all_supported_seeds",
    })
    return map_data


def validate_all(map_data: dict) -> list[str]:
    reachable = {(x, y) for x in range(20) for y in range(12)}
    return [
        *validate_living_expedition_schema(map_data),
        *validate_living_expedition_reachability(map_data, set(), reachable),
    ]


class LivingExpeditionSchemaTests(unittest.TestCase):
    def test_catalog_and_complete_two_individual_fixture_pass(self) -> None:
        self.assertEqual([], validate_creature_catalog(load_creature_catalog()))
        self.assertEqual([], validate_all(valid_map()))

    def test_complete_living_expedition_03_relationship_passes(self) -> None:
        self.assertEqual([], validate_all(valid_living_expedition_03_map()))

    def test_existing_map_without_creature_records_preserves_behavior(self) -> None:
        map_data = valid_map()
        for field in (
            "creature_rescues",
            "companion_habitats",
            "ecological_traces",
            "companion_contexts",
            "creature_memory_opportunities",
            "creature_adaptation_payoffs",
        ):
            map_data.pop(field)
        self.assertEqual([], validate_living_expedition_schema(map_data))

    def test_rejects_duplicate_unknown_and_mutable_source(self) -> None:
        map_data = valid_map()
        duplicate = copy.deepcopy(map_data["companion_contexts"][0])
        duplicate["mounted"] = True
        duplicate["action_id"] = "missing_action"
        map_data["companion_contexts"].append(duplicate)
        map_data["companion_contexts"][0]["dismount"]["progress"] = 0.5
        failures = validate_all(map_data)
        self.assertTrue(any("Duplicate creature map id" in failure for failure in failures), failures)
        self.assertTrue(any("mutable or seed-dependent" in failure for failure in failures), failures)
        self.assertTrue(any("dismount.progress" in failure for failure in failures), failures)
        self.assertTrue(any("unknown action" in failure for failure in failures), failures)

    def test_rejects_catalog_relationship_drift_and_duplicate_ids(self) -> None:
        catalog = copy.deepcopy(load_creature_catalog())
        catalog["memories"][0]["adaptation_ids"] = ["guardian_pulse"]
        catalog["actions"][0]["id"] = "spark_ray"
        next(item for item in catalog["species"] if item["id"] == "veil_cuttle")["base_action_ids"] = ["glide_surge"]
        next(item for item in catalog["individuals"] if item["id"] == "veil_cuttle_juvenile_01")["species_id"] = "spark_ray"
        next(item for item in catalog["adaptations"] if item["id"] == "drift_lens")["mounted_action_id"] = "anchor_brace"
        failures = validate_creature_catalog(catalog)
        self.assertTrue(any("Duplicate creature catalog id" in failure for failure in failures), failures)
        self.assertTrue(any("unsupported memory/adaptation" in failure for failure in failures), failures)
        self.assertTrue(any("species veil_cuttle.base_action_ids" in failure for failure in failures), failures)
        self.assertTrue(any("individual veil_cuttle_juvenile_01.species_id" in failure for failure in failures), failures)
        self.assertTrue(any("adaptation 'drift_lens' has unsupported roles" in failure for failure in failures), failures)

    def test_rejects_dangling_and_circular_memory_payoff_links(self) -> None:
        map_data = valid_map()
        memory = map_data["creature_memory_opportunities"][0]
        memory["payoff_id"] = "missing_payoff"
        memory["required_adaptation_id"] = "anchor_fins"
        failures = validate_all(map_data)
        self.assertTrue(any("circularly requires" in failure for failure in failures), failures)
        self.assertTrue(any("malformed adaptation link" in failure for failure in failures), failures)

    def test_rejects_seed_dependent_required_opportunity(self) -> None:
        map_data = valid_map()
        memory = map_data["creature_memory_opportunities"][0]
        memory["availability"] = "daily_roll"
        memory["day_seed"] = 4
        failures = validate_all(map_data)
        self.assertTrue(any("day_seed" in failure for failure in failures), failures)
        self.assertTrue(any("all_supported_seeds" in failure for failure in failures), failures)

    def test_rejects_rewarding_or_gated_optional_trace(self) -> None:
        map_data = valid_map()
        trace = map_data["ecological_traces"][0]
        trace["required_access_ids"] = ["pressure_suit"]
        trace["reward_ids"] = ["progression_reward"]
        trace["progression_effect"] = "unlock"
        failures = validate_all(map_data)
        self.assertTrue(any("already accessible terrain" in failure for failure in failures), failures)
        self.assertTrue(any("optional, rewardless, and non-progression" in failure for failure in failures), failures)

    def test_rejects_copied_patrol_authority_and_wrong_relationship_link(self) -> None:
        map_data = valid_living_expedition_03_map()
        trace = map_data["ecological_traces"][0]
        trace["path"] = [{"x": 8, "y": 8}, {"x": 10, "y": 8}]
        trace["moving_hazard_id"] = "deep_route_jellyfish_patrol"
        failures = validate_all(map_data)
        self.assertTrue(any("copies moving-hazard authority" in failure for failure in failures), failures)
        self.assertTrue(any("moving_hazard_id must be" in failure for failure in failures), failures)

    def test_rejects_each_mismatched_migration_relationship_id(self) -> None:
        fields = (
            "species_id",
            "individual_id",
            "action_id",
            "daily_condition_id",
            "moving_hazard_id",
            "memory_opportunity_id",
            "adaptation_payoff_id",
        )
        for field in fields:
            with self.subTest(field=field):
                map_data = valid_living_expedition_03_map()
                map_data["ecological_traces"][0][field] = "wrong_id"
                failures = validate_all(map_data)
                self.assertTrue(any(f".{field} must be" in failure for failure in failures), failures)

    def test_rejects_missing_condition_hazard_and_mutable_patrol_state(self) -> None:
        map_data = valid_living_expedition_03_map()
        map_data["daily_conditions"] = []
        map_data["moving_hazards"] = []
        map_data["ecological_traces"][0]["phase"] = 0.5
        failures = validate_all(map_data)
        self.assertTrue(any("requires daily condition" in failure for failure in failures), failures)
        self.assertTrue(any("condition-owned migration hazard" in failure for failure in failures), failures)
        self.assertTrue(any("copies moving-hazard authority" in failure for failure in failures), failures)

    def test_rejects_mica_identity_access_reward_and_availability_drift(self) -> None:
        map_data = valid_living_expedition_03_map()
        memory = map_data["creature_memory_opportunities"][-1]
        memory["species_id"] = "spark_ray"
        memory["availability"] = "daily_roll"
        payoff = map_data["creature_adaptation_payoffs"][-1]
        payoff["reward_ids"] = ["generic_research_currency"]
        map_data["ecological_traces"][0]["required_access_ids"] = ["pressure_suit"]
        failures = validate_all(map_data)
        self.assertTrue(any("eligible for 'followed_the_bloom'" in failure for failure in failures), failures)
        self.assertTrue(any("all_supported_seeds" in failure for failure in failures), failures)
        self.assertTrue(any("cannot grant score" in failure for failure in failures), failures)
        self.assertTrue(any("cannot grant or require equipment access" in failure for failure in failures), failures)

    def test_rejects_rider_footprint_clipping_and_missing_dismount(self) -> None:
        map_data = valid_map()
        map_data["terrain"] = [{"id": "route_block", "type": "solid", "x": 4, "y": 3, "w": 1, "h": 1}]
        map_data["companion_contexts"][0].pop("dismount")
        failures = validate_all(map_data)
        self.assertTrue(any("rider footprint clips terrain" in failure for failure in failures), failures)
        self.assertTrue(any("reviewed clear dismount" in failure for failure in failures), failures)

    def test_rejects_mounted_equipment_gate_bypass(self) -> None:
        map_data = valid_map()
        gate = map_data["zones"][0]
        gate.update({"x": 4, "y": 3, "w": 1, "h": 1})
        failures = validate_all(map_data)
        self.assertTrue(any("bypasses equipment gate" in failure for failure in failures), failures)
        map_data["companion_contexts"][0]["required_access_ids"] = ["propulsion_fins"]
        self.assertEqual([], validate_all(map_data))

    def test_rejects_payoff_that_drops_target_equipment_requirement(self) -> None:
        map_data = valid_map()
        map_data["creature_adaptation_payoffs"][0]["required_access_ids"] = []
        failures = validate_all(map_data)
        self.assertTrue(any("would bypass target equipment" in failure for failure in failures), failures)

    def test_rejects_unreachable_required_records(self) -> None:
        map_data = valid_map()
        failures = validate_living_expedition_reachability(map_data, set(), {(0, 0)})
        self.assertTrue(any("rescue site is unreachable" in failure for failure in failures), failures)
        self.assertTrue(any("mounted route point is unreachable" in failure for failure in failures), failures)
        self.assertTrue(any("target" in failure and "unreachable" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
