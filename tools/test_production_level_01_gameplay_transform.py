#!/usr/bin/env python3
"""Focused tests for the slice-local to full-level gameplay transform."""

from __future__ import annotations

import copy
import json
import unittest

from create_production_level_01_map import (
    SOURCE_MAP_PATH,
    build_map_data,
    global_gameplay_clearance_cells,
    solid_cells,
)

from production_level_01_gameplay_transform import (
    CANDIDATE_MAP_ID,
    CANDIDATE_MAP_PATH,
    CANDIDATE_SOURCE_OVERRIDES,
    EXCLUDED_IDS,
    LOCAL_TO_GLOBAL_OFFSET,
    POINT_FIELDS,
    POINT_LIST_FIELDS,
    RECT_FIELDS,
    SPATIAL_SECTIONS,
    slice_local_gameplay_sections,
    transform_gameplay_sections,
)


def by_id(records: list[dict]) -> dict[str, dict]:
    return {str(record["id"]): record for record in records}


class ProductionLevelGameplayTransformTests(unittest.TestCase):
    def setUp(self) -> None:
        self.source = slice_local_gameplay_sections()
        self.before = copy.deepcopy(self.source)
        self.transformed, self.provenance = transform_gameplay_sections(self.source)

    def test_source_is_not_mutated(self) -> None:
        self.assertEqual(self.source, self.before)

    def test_top_level_and_nested_geometry_shift_once(self) -> None:
        for section in SPATIAL_SECTIONS:
            source_records = by_id(self.source[section])
            transformed_records = by_id(self.transformed[section])
            for record_id, result in transformed_records.items():
                original = source_records[record_id]
                if section == "camera_tests":
                    self.assertEqual(
                        result["center_x"],
                        original["center_x"] + LOCAL_TO_GLOBAL_OFFSET["x"],
                    )
                    self.assertEqual(result["center_y"], original["center_y"])
                    continue
                if "x" in original:
                    self.assertEqual(
                        result["x"], original["x"] + LOCAL_TO_GLOBAL_OFFSET["x"]
                    )
                    self.assertEqual(result["y"], original["y"])
                for field in POINT_FIELDS:
                    if field in original:
                        self.assertEqual(result[field]["x"], original[field]["x"] + 58)
                        self.assertEqual(result[field]["y"], original[field]["y"])
                for field in POINT_LIST_FIELDS:
                    for local_point, global_point in zip(
                        original.get(field, []), result.get(field, [])
                    ):
                        self.assertEqual(global_point["x"], local_point["x"] + 58)
                        self.assertEqual(global_point["y"], local_point["y"])
                for field in RECT_FIELDS:
                    if field in original:
                        self.assertEqual(result[field]["x"], original[field]["x"] + 58)
                        self.assertEqual(result[field]["y"], original[field]["y"])

    def test_exclusions_and_canonical_boat_ownership(self) -> None:
        for section, excluded_ids in EXCLUDED_IDS.items():
            actual = set(by_id(self.transformed[section]))
            self.assertTrue(actual.isdisjoint(excluded_ids))
        self.assertNotIn("surface_boat_entry", by_id(self.transformed["entities"]))

    def test_standard_fins_gate_and_project_remain(self) -> None:
        zones = by_id(self.transformed["zones"])
        projects = by_id(self.transformed["material_projects"])
        self.assertIn("upper_right_current_pocket_gate", zones)
        self.assertEqual(
            zones["upper_right_current_pocket_gate"]["required_capability_id"],
            "propulsion_fins",
        )
        self.assertIn("propulsion_fins_project", projects)
        self.assertNotIn("current_stabilizer_project", projects)

    def test_connector_and_destination_metadata_are_absent(self) -> None:
        forbidden = {
            "world_connector",
            "destination_map_id",
            "destination_map_path",
            "destination_entry_id",
        }

        def visit(value) -> None:
            if isinstance(value, dict):
                self.assertTrue(forbidden.isdisjoint(value))
                for nested in value.values():
                    visit(nested)
            elif isinstance(value, list):
                for nested in value:
                    visit(nested)

        visit(self.transformed)

        serialized = json.dumps(self.transformed).lower()
        self.assertNotIn("relay", serialized)

    def test_surveys_commit_to_candidate_boat(self) -> None:
        for survey in self.transformed["survey_targets"]:
            self.assertEqual(survey["commit_map_id"], CANDIDATE_MAP_ID)
            self.assertEqual(survey["commit_map_path"], CANDIDATE_MAP_PATH)
            self.assertEqual(survey["commit_entry_id"], "surface_boat_entry")

    def test_full_level_authors_named_cutter_blueprint_artifact(self) -> None:
        survey = by_id(self.transformed["survey_targets"])["lower_right_anomaly_survey"]
        project = by_id(self.transformed["material_projects"])["salvage_cutter_project"]
        self.assertEqual(survey["scan_subject_kind"], "artifact")
        self.assertEqual(survey["scan_subject_id"], "salvage_cutter_maintenance_case")
        self.assertEqual(survey["scan_presentation_id"], "salvage_cutter_blueprint_case")
        self.assertEqual(survey["scan_anchor"], {"x": 126, "y": 44})
        self.assertEqual(survey["scan_reward_kind"], "blueprint")
        self.assertEqual(survey["scan_reward_id"], "salvage_cutter_blueprint")
        self.assertEqual(survey["discovery_id"], "lower_right_anomaly_discovery")
        self.assertEqual(project["required_discovery_id"], survey["scan_reward_id"])
        self.assertEqual(
            CANDIDATE_SOURCE_OVERRIDES[("survey_targets", survey["id"])]["scan_anchor"],
            {"x": 68, "y": 44},
        )
        self.assertNotIn("scan_subject_id", by_id(self.source["survey_targets"])[survey["id"]])
        self.assertEqual(
            by_id(self.source["material_projects"])[project["id"]]["required_discovery_id"],
            "lower_right_anomaly_discovery",
        )

    def test_provenance_records_local_and_global_geometry(self) -> None:
        records = {
            (record["section"], record["id"]): record
            for record in self.provenance["coordinate_records"]
        }
        patrol = records[("moving_hazards", "deep_route_jellyfish_patrol")]
        self.assertEqual(patrol["slice_local"]["path"][0], {"x": 54, "y": 68})
        self.assertEqual(patrol["full_global"]["path"][0], {"x": 112, "y": 68})
        eel = records[("hostile_encounters", "deep_cache_territorial_eel")]
        self.assertEqual(eel["slice_local"]["territory"]["x"], 60)
        self.assertEqual(eel["full_global"]["territory"]["x"], 118)

    def test_generated_candidate_owns_cleanup_and_one_boat(self) -> None:
        source_map = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        candidate = build_map_data(source_map)
        candidate_solids = solid_cells(candidate)
        self.assertTrue(global_gameplay_clearance_cells().isdisjoint(candidate_solids))
        boats = [
            item for item in candidate["entities"] if item.get("type") == "boat_spawn"
        ]
        self.assertEqual([boat["id"] for boat in boats], ["surface_boat_entry"])
        self.assertIn(
            "salvage_southwest_return_cache",
            by_id(candidate["entities"]),
        )
        self.assertEqual(
            candidate["source"]["stats"]["gameplay_clearance_opened_cells"], 29
        )

    def test_generated_candidate_owns_signal_reef_route_without_terrain_edits(self) -> None:
        source_map = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        candidate = build_map_data(source_map)
        zones = by_id(candidate["zones"])
        journey = candidate["regional_journeys"][0]

        self.assertEqual(journey["id"], "east_current_signal_reef_route")
        self.assertEqual(journey["entry_gate_ids"], [
            "lower_right_west_current_gate",
            "lower_right_east_current_gate",
        ])
        for gate_id in journey["entry_gate_ids"]:
            self.assertEqual(zones[gate_id]["required_capability_id"], "propulsion_fins")
            self.assertEqual(zones[gate_id]["route_context"], journey["id"])
        landmark = zones[journey["landmark_zone_id"]]
        self.assertEqual(
            {field: landmark[field] for field in ("x", "y", "w", "h")},
            {"x": 132, "y": 108, "w": 10, "h": 10},
        )
        self.assertEqual(candidate["source"]["expansion_10"]["terrain_changes"], [])


if __name__ == "__main__":
    unittest.main()
