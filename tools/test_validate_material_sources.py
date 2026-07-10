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


class MaterialSourceValidationTests(unittest.TestCase):
    def test_valid_schema_and_reachability(self) -> None:
        map_data = valid_map()
        self.assertEqual(validate_material_source_schema(map_data), [])
        reachable = {(x, y) for y in range(8) for x in range(12)}
        self.assertEqual(validate_material_source_reachability(map_data["entities"], set(), reachable), [])

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
            "required_discovery_id must be one of",
            "required_materials must be exactly",
            "unlocks_capability_id must be one of",
            "cutter target must use tier 'valuable'",
            "required_tool_id must be one of",
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
        self.assertTrue(any("requires exactly one material project" in failure for failure in failures))
        self.assertTrue(any("not referenced by a material project" in failure for failure in failures))

    def test_input_mutations_do_not_affect_fixture_factory(self) -> None:
        first = valid_map()
        second = copy.deepcopy(first)
        second["material_candidate_pools"].clear()
        self.assertEqual(len(first["material_candidate_pools"]), 2)


if __name__ == "__main__":
    unittest.main()
