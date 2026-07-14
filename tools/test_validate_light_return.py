#!/usr/bin/env python3
"""Focused positive and negative tests for the Expansion 11 light chain."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from validate_light_return import (
    validate_light_return_reachability,
    validate_light_return_schema,
)


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "production_level_01.greybox.json"
GOOD_CONTRACT = {"session_upgrades": [], "durable_purchases": []}


def valid_map() -> dict:
    titanium = [f"material_titanium_{index}" for index in range(2)]
    coils = [f"material_coil_{index}" for index in range(2)]
    entities = [{
        "id": "surface_boat_entry",
        "type": "boat_spawn",
        "x": 0,
        "y": 0,
        "w": 3,
        "h": 2,
        "entry_x": 1,
        "entry_y": 2,
    }]
    entities.extend({
        "id": entity_id,
        "type": "material_candidate",
        "x": index + 2,
        "y": 3,
        "material_id": "titanium_scrap",
        "candidate_pool_id": "titanium_scrap_pool",
    } for index, entity_id in enumerate(titanium))
    entities.extend({
        "id": entity_id,
        "type": "material_candidate",
        "x": index + 4,
        "y": 3,
        "material_id": "conductive_coil",
        "candidate_pool_id": "conductive_coil_pool",
    } for index, entity_id in enumerate(coils))
    return {
        "id": "production_level_01",
        "units": {"width_tiles": 12, "height_tiles": 12},
        "terrain": [],
        "entities": entities,
        "zones": [{
            "id": "signal_reef_deep_harmonic_dark_zone",
            "type": "marker",
            "x": 7,
            "y": 7,
            "w": 3,
            "h": 3,
            "visibility_zone": True,
            "visibility_level": "dark",
            "visibility_label": "Deep harmonic dark water",
            "required_upgrade_id": "dive_light_1",
            "visual_only": True,
            "route_context": "east_current_signal_reef_route",
        }],
        "material_candidate_pools": [
            {
                "id": "titanium_scrap_pool",
                "material_id": "titanium_scrap",
                "selection_strategy": "day_rotation_v1",
                "select_count": 1,
                "candidate_ids": titanium,
            },
            {
                "id": "conductive_coil_pool",
                "material_id": "conductive_coil",
                "selection_strategy": "day_rotation_v1",
                "select_count": 1,
                "candidate_ids": coils,
            },
        ],
        "biological_resource_sources": [{
            "id": "upper_right_glow_anemone_sample",
            "source_role": "passive_sample",
            "required_capability_id": "survey_scanner_1",
            "material_id": "insulating_gel",
            "material_quantity": 1,
            "replenishment": "new_day",
        }],
        "material_projects": [{
            "id": "dive_light_1_project",
            "required_discovery_id": "lower_right_signal_reef_discovery",
            "required_materials": {"titanium_scrap": 1, "conductive_coil": 1, "insulating_gel": 1},
            "unlocks_capability_id": "dive_light_1",
            "target_id": "signal_reef_deep_harmonic_survey",
            "build_phase": "night_debrief",
            "project_label": "Dive light project",
            "completion_label": "Dive light built",
        }],
        "regional_journeys": [{
            "id": "east_current_signal_reef_route",
            "required_capability_id": "propulsion_fins",
            "route_context": "east_current_signal_reef_route",
        }],
        "survey_targets": [
            {
                "id": "lower_right_signal_reef_survey",
                "discovery_id": "lower_right_signal_reef_discovery",
                "required_capability_id": "survey_scanner_1",
            },
            {
                "id": "signal_reef_deep_harmonic_survey",
                "target_type": "regional",
                "x": 8,
                "y": 8,
                "w": 1,
                "h": 1,
                "required_capability_id": "survey_scanner_1",
                "required_light_capability_id": "dive_light_1",
                "required_route_id": "east_current_signal_reef_route",
                "route_context": "east_current_signal_reef_route",
                "interaction": "survey",
                "interaction_seconds": 3.0,
                "interaction_label": "Survey deep harmonic",
                "clue_label": "Deep harmonic | Stronger light required",
                "finding_label": "Discovery logged: Deep harmonic chart",
                "next_lead_label": "Next lead: signal descends into deeper water",
                "discovery_id": "signal_reef_deep_harmonic_discovery",
                "commit_map_id": "production_level_01",
                "commit_map_path": "res://maps/production_level_01.greybox.json",
                "commit_entry_id": "surface_boat_entry",
            },
        ],
    }


class LightReturnValidationTests(unittest.TestCase):
    def test_accepts_exact_chain_and_open_return_route(self) -> None:
        map_data = valid_map()
        self.assertEqual(validate_light_return_schema(MAP_PATH, map_data, GOOD_CONTRACT), [])
        reachable = {(x, y) for y in range(12) for x in range(12)}
        self.assertEqual(validate_light_return_reachability(map_data, set(), reachable), [])

    def test_rejects_dual_owner_recipe_order_and_circular_knowledge(self) -> None:
        map_data = valid_map()
        project = map_data["material_projects"][0]
        project["required_materials"]["titanium_scrap"] = 2
        project["required_project_id"] = "shock_prod_project"
        map_data["survey_targets"][0]["required_light_capability_id"] = "dive_light_1"
        contract = {"session_upgrades": [{"id": "dive_light_1"}], "durable_purchases": []}
        failures = validate_light_return_schema(MAP_PATH, map_data, contract)
        self.assertTrue(any("required_materials must be exactly" in failure for failure in failures), failures)
        self.assertTrue(any("must omit required_project_id" in failure for failure in failures), failures)
        self.assertTrue(any("session/purchase ownership" in failure for failure in failures), failures)
        self.assertTrue(any("must not require the light" in failure for failure in failures), failures)

    def test_rejects_non_guaranteed_or_combat_gel_and_self_gated_candidates(self) -> None:
        map_data = valid_map()
        map_data["material_candidate_pools"][1]["select_count"] = 0
        map_data["entities"][1]["required_capability_id"] = "dive_light_1"
        gel = map_data["biological_resource_sources"][0]
        gel.update({"source_role": "hostile_harvest", "hostile_id": "eel", "replenishment": "never"})
        failures = validate_light_return_schema(MAP_PATH, map_data, GOOD_CONTRACT)
        self.assertTrue(any("daily pools guarantee 0" in failure for failure in failures), failures)
        self.assertTrue(any("cannot require dive_light_1" in failure for failure in failures), failures)
        self.assertTrue(any("source_role must be exactly 'passive_sample'" in failure for failure in failures), failures)
        self.assertTrue(any("must remain noncombat" in failure for failure in failures), failures)

    def test_rejects_hidden_target_collision_and_broken_return(self) -> None:
        map_data = valid_map()
        map_data["zones"][0]["solid"] = True
        map_data["survey_targets"][1]["hidden_until_capability"] = "dive_light_1"
        map_data["survey_targets"][1]["x"] = 4
        failures = validate_light_return_schema(MAP_PATH, map_data, GOOD_CONTRACT)
        self.assertTrue(any("pre-light hiding/collision fields" in failure for failure in failures), failures)
        self.assertTrue(any("must be contained inside" in failure for failure in failures), failures)

        reachable = {(1, 2)}
        failures = validate_light_return_reachability(map_data, {(7, 7)}, reachable)
        self.assertTrue(any("must remain non-solid" in failure for failure in failures), failures)
        self.assertTrue(any("returnable to the boat" in failure for failure in failures), failures)

    def test_historical_darkness_zone_alone_does_not_activate_expansion_contract(self) -> None:
        with MAP_PATH.open("r", encoding="utf-8") as handle:
            current_map = json.load(handle)
        self.assertEqual(validate_light_return_schema(MAP_PATH, current_map), [])

        partial = copy.deepcopy(valid_map())
        partial["material_projects"] = []
        failures = validate_light_return_schema(MAP_PATH, partial, GOOD_CONTRACT)
        self.assertTrue(any("requires exactly one material_projects" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
