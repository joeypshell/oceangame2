#!/usr/bin/env python3
"""Focused positive and negative tests for Expansion 03 material source validation."""

from __future__ import annotations

import copy
import unittest

from validate_material_sources import validate_material_source_reachability, validate_material_source_schema


def material_entity(entity_id: str, material_id: str, pool_id: str, x: int) -> dict:
    return {
        "id": entity_id,
        "type": "material_candidate",
        "x": x,
        "y": 2,
        "kind": "wreck_fragment",
        "interaction": "material_collect",
        "material_id": material_id,
        "material_quantity": 1,
        "candidate_pool_id": pool_id,
    }


def valid_map() -> dict:
    titanium_ids = [f"material_titanium_{index}" for index in range(4)]
    coil_ids = [f"material_coil_{index}" for index in range(2)]
    entities = [{"id": "entry", "type": "spawn", "x": 1, "y": 1}]
    entities.extend(material_entity(entity_id, "titanium_scrap", "titanium_scrap_pool", index + 2) for index, entity_id in enumerate(titanium_ids))
    entities.extend(material_entity(entity_id, "conductive_coil", "conductive_coil_pool", index + 6) for index, entity_id in enumerate(coil_ids))
    entities.append(
        {
            "id": "salvage_sealed_wreck_cache",
            "type": "tool_target",
            "x": 8,
            "y": 2,
            "kind": "crate",
            "tier": "valuable",
            "interaction": "cutter_salvage",
            "interaction_seconds": 2.0,
            "interaction_label": "sealed wreck",
            "required_tool_id": "salvage_cutter",
            "tool_project_id": "salvage_cutter_project",
        }
    )
    return {
        "id": "material_fixture",
        "units": {"width_tiles": 12, "height_tiles": 8},
        "terrain": [],
        "entities": entities,
        "zones": [],
        "material_candidate_pools": [
            {
                "id": "titanium_scrap_pool",
                "material_id": "titanium_scrap",
                "selection_strategy": "day_rotation_v1",
                "select_count": 2,
                "candidate_ids": titanium_ids,
            },
            {
                "id": "conductive_coil_pool",
                "material_id": "conductive_coil",
                "selection_strategy": "day_rotation_v1",
                "select_count": 1,
                "candidate_ids": coil_ids,
            },
        ],
        "material_projects": [
            {
                "id": "salvage_cutter_project",
                "required_discovery_id": "lower_right_anomaly_discovery",
                "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
                "unlocks_capability_id": "salvage_cutter",
                "target_id": "salvage_sealed_wreck_cache",
                "build_phase": "night_debrief",
            }
        ],
    }


def with_stabilizer_project(map_data: dict) -> dict:
    map_data["zones"].append(
        {
            "id": "lower_left_loop_current",
            "type": "marker",
            "x": 9,
            "y": 3,
            "w": 2,
            "h": 2,
            "current_gate": True,
            "current_direction": "left",
            "current_strength": 2.2,
            "required_capability_id": "current_stabilizer",
        }
    )
    map_data["material_projects"].append(
        {
            "id": "current_stabilizer_project",
            "required_project_id": "salvage_cutter_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
            "unlocks_capability_id": "current_stabilizer",
            "target_gate_id": "lower_left_loop_current",
            "build_phase": "night_debrief",
        }
    )
    return map_data


def with_propulsion_project(map_data: dict) -> dict:
    rubber_ids = ["material_rubber_entry", "material_rubber_lower_loop"]
    map_data["entities"].extend(
        material_entity(entity_id, "rubber_sheet", "rubber_sheet_pool", index + 9)
        for index, entity_id in enumerate(rubber_ids)
    )
    map_data["material_candidate_pools"].append(
        {
            "id": "rubber_sheet_pool",
            "material_id": "rubber_sheet",
            "selection_strategy": "day_rotation_v1",
            "select_count": 1,
            "candidate_ids": rubber_ids,
        }
    )
    map_data["zones"].append(
        {
            "id": "upper_right_current_pocket_gate",
            "type": "marker",
            "x": 9,
            "y": 3,
            "w": 2,
            "h": 2,
            "current_gate": True,
            "current_direction": "right",
            "current_strength": 2.2,
            "required_capability_id": "propulsion_fins",
        }
    )
    map_data["material_projects"].insert(
        0,
        {
            "id": "propulsion_fins_project",
            "required_discovery_id": "propulsion_fins_blueprint",
            "required_materials": {"titanium_scrap": 2, "rubber_sheet": 1},
            "unlocks_capability_id": "propulsion_fins",
            "target_gate_id": "upper_right_current_pocket_gate",
            "build_phase": "night_debrief",
            "project_label": "Propulsion fins project",
            "completion_label": "Propulsion fins built",
        },
    )
    return map_data


def with_scanner_project(map_data: dict) -> dict:
    map_data["survey_targets"] = [{
        "id": "lower_right_anomaly_survey",
        "required_capability_id": "survey_scanner_1",
    }]
    map_data["material_projects"].insert(0, {
        "id": "survey_scanner_project",
        "required_discovery_id": "survey_scanner_blueprint",
        "required_materials": {"titanium_scrap": 1, "conductive_coil": 1},
        "unlocks_capability_id": "survey_scanner_1",
        "target_id": "lower_right_anomaly_survey",
        "build_phase": "night_debrief",
        "project_label": "Survey scanner project",
        "completion_label": "Survey scanner built",
    })
    return map_data


def with_shock_prod_project(map_data: dict) -> dict:
    with_stabilizer_project(map_data)
    map_data["hostile_encounters"] = [
        {
            "id": "deep_cache_territorial_eel",
            "required_weapon_capability_id": "shock_prod",
        }
    ]
    map_data["material_projects"].append(
        {
            "id": "shock_prod_project",
            "required_project_id": "salvage_cutter_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
            "unlocks_capability_id": "shock_prod",
            "target_hostile_id": "deep_cache_territorial_eel",
            "build_phase": "night_debrief",
            "project_label": "Shock prod project",
            "completion_label": "Shock prod built",
        }
    )
    return map_data


def with_capacitor_project(map_data: dict) -> dict:
    with_shock_prod_project(map_data)
    map_data["biological_resource_sources"] = [
        {"id": "upper_right_glow_anemone_sample", "material_id": "insulating_gel", "material_quantity": 1},
        {"id": "deep_cache_eel_electrocyte_harvest", "material_id": "eel_electrocyte", "material_quantity": 1},
    ]
    map_data["material_projects"].append(
        {
            "id": "shock_prod_capacitor_project",
            "required_project_id": "shock_prod_project",
            "required_discovery_id": "lower_right_anomaly_discovery",
            "required_materials": {"conductive_coil": 1, "insulating_gel": 1, "eel_electrocyte": 1},
            "unlocks_capability_id": "shock_prod_capacitor",
            "target_hostile_id": "deep_cache_territorial_eel",
            "capability_effect": "interrupt_warning_lunge",
            "build_phase": "night_debrief",
            "project_label": "Shock-prod capacitor project",
            "completion_label": "Shock-prod capacitor built",
        }
    )
    return map_data


def with_dive_light_project(map_data: dict) -> dict:
    map_data["biological_resource_sources"] = [{
        "id": "upper_right_glow_anemone_sample",
        "material_id": "insulating_gel",
        "material_quantity": 1,
    }]
    map_data["survey_targets"] = [{
        "id": "signal_reef_deep_harmonic_survey",
        "required_light_capability_id": "dive_light_1",
    }]
    map_data["material_projects"].append({
        "id": "dive_light_1_project",
        "required_discovery_id": "lower_right_signal_reef_discovery",
        "required_materials": {"titanium_scrap": 1, "conductive_coil": 1, "insulating_gel": 1},
        "unlocks_capability_id": "dive_light_1",
        "target_id": "signal_reef_deep_harmonic_survey",
        "build_phase": "night_debrief",
        "project_label": "Dive light project",
        "completion_label": "Dive light built",
    })
    return map_data


def with_pressure_suit_project(map_data: dict) -> dict:
    with_propulsion_project(map_data)
    map_data["biological_resource_sources"] = [{
        "id": "upper_right_glow_anemone_sample",
        "material_id": "insulating_gel",
        "material_quantity": 1,
    }]
    map_data["survey_targets"] = [{
        "id": "abyssal_basin_harmonic_source_survey",
        "required_pressure_capability_id": "pressure_suit_1",
    }]
    map_data["material_projects"].append({
        "id": "pressure_suit_1_project",
        "required_discovery_id": "signal_reef_deep_harmonic_discovery",
        "required_materials": {"titanium_scrap": 2, "rubber_sheet": 1, "insulating_gel": 1},
        "unlocks_capability_id": "pressure_suit_1",
        "target_id": "abyssal_basin_harmonic_source_survey",
        "build_phase": "night_debrief",
        "project_label": "Pressure suit project",
        "completion_label": "Pressure suit built",
    })
    return map_data


class MaterialSourceValidationTests(unittest.TestCase):
    def test_valid_schema_and_reachability(self) -> None:
        map_data = valid_map()
        self.assertEqual(validate_material_source_schema(map_data), [])
        reachable = {(x, y) for y in range(8) for x in range(12)}
        self.assertEqual(validate_material_source_reachability(map_data["entities"], set(), reachable), [])

    def test_accepts_ordered_stabilizer_project_and_durable_gate(self) -> None:
        self.assertEqual(validate_material_source_schema(with_stabilizer_project(valid_map())), [])

    def test_accepts_blueprint_gated_propulsion_project_without_score(self) -> None:
        self.assertEqual(validate_material_source_schema(with_propulsion_project(valid_map())), [])

    def test_accepts_blueprint_gated_scanner_project_without_score(self) -> None:
        self.assertEqual(validate_material_source_schema(with_scanner_project(valid_map())), [])

    def test_accepts_regional_gates_reusing_the_promised_fins_capability(self) -> None:
        map_data = with_propulsion_project(valid_map())
        map_data["zones"].append({
            **map_data["zones"][0],
            "id": "regional_fins_gate",
            "x": 7,
            "route_context": "regional_fins_route",
        })
        map_data["regional_journeys"] = [{
            "id": "regional_fins_route",
            "promise_gate_id": "upper_right_current_pocket_gate",
            "entry_gate_ids": ["regional_fins_gate"],
            "required_capability_id": "propulsion_fins",
        }]
        self.assertEqual(validate_material_source_schema(map_data), [])
        map_data["regional_journeys"][0]["promise_gate_id"] = "later_landmark"
        map_data["regional_journeys"][0]["required_discovery_id"] = "later_discovery"
        self.assertEqual(validate_material_source_schema(map_data), [])

    def test_rejects_propulsion_project_without_blueprint_requirement(self) -> None:
        map_data = with_propulsion_project(valid_map())
        map_data["material_projects"][0].pop("required_discovery_id")
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("required_discovery_id must be 'propulsion_fins_blueprint'" in failure for failure in failures))

    def test_accepts_non_enemy_shock_prod_recipe_and_hostile_link(self) -> None:
        self.assertEqual(validate_material_source_schema(with_shock_prod_project(valid_map())), [])

    def test_accepts_guaranteed_biological_capacitor_recipe(self) -> None:
        self.assertEqual(validate_material_source_schema(with_capacitor_project(valid_map())), [])

    def test_accepts_light_project_with_guaranteed_gel_and_survey_link(self) -> None:
        self.assertEqual(validate_material_source_schema(with_dive_light_project(valid_map())), [])

        map_data = with_dive_light_project(valid_map())
        map_data["survey_targets"][0]["required_light_capability_id"] = "wrong_light"
        map_data["material_projects"][-1]["required_materials"]["insulating_gel"] = 2
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("target survey does not link back" in failure for failure in failures), failures)
        self.assertTrue(any("required_materials must be exactly" in failure for failure in failures), failures)

    def test_accepts_pressure_project_with_recipe_and_survey_link(self) -> None:
        self.assertEqual(validate_material_source_schema(with_pressure_suit_project(valid_map())), [])

        map_data = with_pressure_suit_project(valid_map())
        map_data["survey_targets"][0]["required_pressure_capability_id"] = "wrong_suit"
        map_data["material_projects"][-1]["required_materials"]["rubber_sheet"] = 2
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("target survey does not link back" in failure for failure in failures), failures)
        self.assertTrue(any("required_materials must be exactly" in failure for failure in failures), failures)

    def test_rejects_capacitor_effect_or_unguaranteed_biology(self) -> None:
        map_data = with_capacitor_project(valid_map())
        map_data["biological_resource_sources"].pop()
        map_data["material_projects"][-1]["capability_effect"] = "double_damage"
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("capability_effect" in failure for failure in failures), failures)
        self.assertTrue(any("daily sources guarantee only 0" in failure for failure in failures), failures)

    def test_rejects_unlinked_or_mislabeled_shock_prod_project(self) -> None:
        map_data = with_shock_prod_project(valid_map())
        project = map_data["material_projects"][-1]
        del project["completion_label"]
        project["target_hostile_id"] = "missing_hostile"
        project["weapon_damage"] = 99
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("requires completion_label" in failure for failure in failures), failures)
        self.assertTrue(any("does not reference a hostile encounter" in failure for failure in failures), failures)
        self.assertTrue(any("not referenced by a material project" in failure for failure in failures), failures)
        self.assertTrue(any("unsupported project fields" in failure for failure in failures), failures)

    def test_rejects_invalid_and_duplicate_candidate_pools(self) -> None:
        map_data = valid_map()
        pool = map_data["material_candidate_pools"][0]
        pool["select_count"] = 8
        pool["candidate_ids"][1] = pool["candidate_ids"][0]
        pool["selection_strategy"] = "random"
        map_data["material_candidate_pools"][1]["candidate_ids"].append("missing_material")
        failures = validate_material_source_schema(map_data)
        for expected in (
            "selection_strategy must be one of",
            "Duplicate material candidate id",
            "select_count exceeds its candidate count",
            "does not reference a material_candidate entity",
        ):
            self.assertTrue(any(expected in failure for failure in failures), expected)

    def test_validates_guaranteed_candidate_subset(self) -> None:
        map_data = valid_map()
        pool = map_data["material_candidate_pools"][0]
        pool["guaranteed_candidate_ids"] = [pool["candidate_ids"][0]]
        self.assertEqual(validate_material_source_schema(map_data), [])
        pool["guaranteed_candidate_ids"] = [pool["candidate_ids"][0], pool["candidate_ids"][1], "missing_candidate"]
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("must belong to candidate_ids" in failure for failure in failures), failures)
        self.assertTrue(any("must not exceed select_count" in failure for failure in failures), failures)
        pool["guaranteed_candidate_ids"] = [pool["candidate_ids"][0], {"invalid": "id"}]
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("must be a non-empty string" in failure for failure in failures), failures)

    def test_rejects_invalid_material_metadata_and_runtime_state(self) -> None:
        map_data = valid_map()
        entity = map_data["entities"][1]
        entity.update({"material_id": "gold", "material_quantity": 2, "interaction": "timed_salvage", "selected": True})
        del entity["candidate_pool_id"]
        failures = validate_material_source_schema(map_data)
        for expected in (
            "missing required field candidate_pool_id",
            "material_id must be one of",
            "material_quantity must be exactly 1",
            "material candidate interaction must be 'material_collect'",
            "must not author runtime/profile state fields: selected",
        ):
            self.assertTrue(any(expected in failure for failure in failures), expected)

    def test_rejects_missing_prerequisites_and_invalid_tool_payoff(self) -> None:
        map_data = valid_map()
        project = map_data["material_projects"][0]
        project["required_discovery_id"] = "unknown_discovery"
        project["required_materials"] = {"titanium_scrap": 3, "conductive_coil": 1}
        project["unlocks_capability_id"] = "laser"
        target = map_data["entities"][-1]
        target["tier"] = "common"
        target["required_tool_id"] = "laser"
        target["tool_project_id"] = "unknown_project"
        failures = validate_material_source_schema(map_data)
        for expected in (
            "required_discovery_id must be",
            "required_materials must be exactly",
            "unlocks_capability_id must be one of",
            "cutter target must use tier 'valuable'",
            "required_tool_id must be salvage_cutter",
            "tool_project_id must be one of",
        ):
            self.assertTrue(any(expected in failure for failure in failures), expected)

    def test_rejects_solid_and_unreachable_sources(self) -> None:
        map_data = valid_map()
        material = map_data["entities"][1]
        target = map_data["entities"][-1]
        failures = validate_material_source_reachability(
            map_data["entities"],
            {(material["x"], material["y"])},
            {(1, 1), (target["x"], target["y"])},
        )
        self.assertTrue(any("inside solid terrain" in failure for failure in failures))
        self.assertTrue(any("unreachable" in failure for failure in failures))

    def test_requires_lists_and_project_target_linkage(self) -> None:
        self.assertEqual(
            validate_material_source_schema({"material_candidate_pools": {}, "entities": []}),
            ["material_candidate_pools must be a list when present."],
        )
        map_data = valid_map()
        map_data["material_projects"] = []
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("requires at least one material project" in failure for failure in failures))
        self.assertTrue(any("not referenced by a material project" in failure for failure in failures))

    def test_allows_durable_target_to_reuse_existing_tool_project(self) -> None:
        map_data = valid_map()
        recorder = copy.deepcopy(map_data["entities"][-1])
        recorder.update({
            "id": "southeast_wreck_recorder",
            "x": 9,
            "interaction_label": "wreck recorder",
            "durable_clearance": True,
            "unlocks_survey_target_id": "southeast_wreck_archive_survey",
        })
        map_data["entities"].append(recorder)
        self.assertEqual([], validate_material_source_schema(map_data))

        recorder["required_tool_id"] = "wrong_tool"
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("required_tool_id must be salvage_cutter" in failure for failure in failures), failures)
        self.assertTrue(any("not referenced by a material project" in failure for failure in failures), failures)

    def test_rejects_invalid_project_order_target_kind_and_gate_link(self) -> None:
        map_data = with_stabilizer_project(valid_map())
        project = map_data["material_projects"].pop()
        project["target_id"] = "salvage_sealed_wreck_cache"
        map_data["material_projects"].insert(0, project)
        map_data["zones"][0]["required_capability_id"] = "wrong_capability"
        failures = validate_material_source_schema(map_data)
        for expected in (
            "required_project_id must reference an earlier project",
            "must define exactly one supported project target field",
            "not referenced by a material project",
        ):
            self.assertTrue(any(expected in failure for failure in failures), (expected, failures))

    def test_rejects_missing_project_prerequisite_and_unguaranteed_recipe(self) -> None:
        map_data = with_stabilizer_project(valid_map())
        project = map_data["material_projects"][1]
        project["required_project_id"] = "missing_project"
        project["required_materials"] = {"titanium_scrap": 3, "conductive_coil": 1}
        failures = validate_material_source_schema(map_data)
        self.assertTrue(any("required_project_id must be 'salvage_cutter_project'" in failure for failure in failures))
        self.assertTrue(any("does not exist" in failure for failure in failures))
        self.assertTrue(any("required_materials must be exactly" in failure for failure in failures))

    def test_input_mutations_do_not_affect_fixture_factory(self) -> None:
        first = valid_map()
        second = copy.deepcopy(first)
        second["material_candidate_pools"].clear()
        self.assertEqual(len(first["material_candidate_pools"]), 2)


if __name__ == "__main__":
    unittest.main()
