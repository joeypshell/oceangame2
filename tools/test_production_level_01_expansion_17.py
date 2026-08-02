#!/usr/bin/env python3
"""Focused source tests for the Expansion 17 production-level records."""

from __future__ import annotations

import hashlib
import json
import unittest

from create_production_level_01_map import OUTPUT_MAP_PATH, SOURCE_MAP_PATH, build_map_data
from production_level_01_expansion_17 import (
    ABYSS_ARTIFACT_ID,
    ABYSS_DISCOVERY_ID,
    ABYSS_GATE_ID,
    ABYSS_JOURNEY_ID,
    ABYSS_LANDMARK_ID,
    ABYSS_PRESENTATION_ID,
    ABYSS_SURVEY_ID,
    FINAL_DISCOVERY_ID,
    INVESTIGATION_ID,
    PREREQUISITE_ID,
    WEST_ARTIFACT_ID,
    WEST_DISCOVERY_ID,
    WEST_GATE_ID,
    WEST_JOURNEY_ID,
    WEST_LANDMARK_ID,
    WEST_PRESENTATION_ID,
    WEST_SURVEY_ID,
)
from validate_expansion_14_contract import TERRAIN_SHA256
from validate_expedition_leads import validate_expedition_lead_schema
from validate_regional_journeys import (
    validate_regional_journey_footprint,
    validate_regional_journey_schema,
)
from validate_survey_targets import validate_survey_target_schema
from validate_wreck_network_investigations import validate_wreck_network_investigation_schema


def _terrain_hash(map_data: dict) -> str:
    payload = json.dumps(map_data["terrain"], sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def _by_id(map_data: dict, collection: str, record_id: str) -> dict:
    return next(item for item in map_data[collection] if item["id"] == record_id)


class ProductionLevelExpansion17Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        source = json.loads(SOURCE_MAP_PATH.read_text(encoding="utf-8"))
        cls.map_data = build_map_data(source)

    def test_exact_investigation_and_generic_schemas_pass(self) -> None:
        self.assertEqual([], validate_wreck_network_investigation_schema(self.map_data))
        self.assertEqual([], validate_expedition_lead_schema(self.map_data))
        self.assertEqual([], validate_regional_journey_schema(self.map_data))
        self.assertEqual([], validate_regional_journey_footprint(self.map_data))
        self.assertEqual([], validate_survey_target_schema(OUTPUT_MAP_PATH, self.map_data))

    def test_two_parallel_fragments_use_distinct_existing_capabilities(self) -> None:
        investigation = self.map_data["wreck_network_investigations"][0]
        self.assertEqual(INVESTIGATION_ID, investigation["id"])
        self.assertEqual(PREREQUISITE_ID, investigation["required_discovery_id"])
        self.assertEqual([WEST_DISCOVERY_ID, ABYSS_DISCOVERY_ID], investigation["fragment_discovery_ids"])
        self.assertEqual(FINAL_DISCOVERY_ID, investigation["analysis_discovery_id"])
        west = _by_id(self.map_data, "regional_journeys", WEST_JOURNEY_ID)
        abyss = _by_id(self.map_data, "regional_journeys", ABYSS_JOURNEY_ID)
        self.assertEqual("current_stabilizer", west["required_capability_id"])
        self.assertEqual("pressure_suit_1", abyss["required_capability_id"])
        self.assertNotEqual(west["expedition_lead"]["label"], abyss["expedition_lead"]["label"])
        self.assertNotEqual(west["expedition_lead"]["active_guidance"], abyss["expedition_lead"]["active_guidance"])

    def test_physical_artifacts_and_seams_are_source_owned_and_non_solid(self) -> None:
        solids = {
            (x, y)
            for terrain in self.map_data["terrain"]
            if terrain["type"] == "solid"
            for y in range(terrain["y"], terrain["y"] + terrain["h"])
            for x in range(terrain["x"], terrain["x"] + terrain["w"])
        }
        expected = (
            (WEST_GATE_ID, (24, 119, 1, 3), WEST_LANDMARK_ID, (19, 119, 5, 2), WEST_SURVEY_ID, WEST_ARTIFACT_ID, WEST_PRESENTATION_ID),
            (ABYSS_GATE_ID, (114, 147, 1, 3), ABYSS_LANDMARK_ID, (120, 147, 8, 3), ABYSS_SURVEY_ID, ABYSS_ARTIFACT_ID, ABYSS_PRESENTATION_ID),
        )
        for gate_id, gate_rect, landmark_id, landmark_rect, survey_id, artifact_id, presentation_id in expected:
            gate = _by_id(self.map_data, "zones", gate_id)
            landmark = _by_id(self.map_data, "zones", landmark_id)
            survey = _by_id(self.map_data, "survey_targets", survey_id)
            self.assertEqual(gate_rect, tuple(gate[field] for field in ("x", "y", "w", "h")))
            self.assertEqual(landmark_rect, tuple(landmark[field] for field in ("x", "y", "w", "h")))
            self.assertEqual(artifact_id, survey["scan_subject_id"])
            self.assertEqual(presentation_id, survey["scan_presentation_id"])
            self.assertFalse({
                (x, y)
                for y in range(landmark["y"], landmark["y"] + landmark["h"])
                for x in range(landmark["x"], landmark["x"] + landmark["w"])
            } & solids)

    def test_transponders_explain_the_split_transfer_hub_coordinates(self) -> None:
        investigation = self.map_data["wreck_network_investigations"][0]
        self.assertEqual("Compare transfer-hub coordinates", investigation["analysis_label"])
        self.assertEqual("Transfer hub coordinates recovered", investigation["analysis_result_label"])
        self.assertIn("transfer hub", investigation["next_lead_label"].lower())

        west = _by_id(self.map_data, "survey_targets", WEST_SURVEY_ID)
        abyss = _by_id(self.map_data, "survey_targets", ABYSS_SURVEY_ID)
        self.assertNotEqual(west["scan_presentation_id"], abyss["scan_presentation_id"])
        self.assertEqual("Current-scoured navigation transponder", west["scan_subject_label"])
        self.assertIn("western half", west["scan_subject_description"])
        self.assertIn("West coordinate half", west["clue_label"])
        self.assertEqual("Pressure-crushed navigation transponder", abyss["scan_subject_label"])
        self.assertIn("eastern half", abyss["scan_subject_description"])
        self.assertIn("East coordinate half", abyss["clue_label"])

        west_journey = _by_id(self.map_data, "regional_journeys", WEST_JOURNEY_ID)
        abyss_journey = _by_id(self.map_data, "regional_journeys", ABYSS_JOURNEY_ID)
        for journey in (west_journey, abyss_journey):
            self.assertIn("coordinate half", journey["expedition_lead"]["summary"])
            self.assertIn("transfer-hub coordinates", journey["expedition_lead"]["active_guidance"])

    def test_lead_selection_never_owns_target_validity(self) -> None:
        forbidden = {"active", "eligible", "selected", "selected_lead_id", "visible"}
        for survey_id in (WEST_SURVEY_ID, ABYSS_SURVEY_ID):
            survey = _by_id(self.map_data, "survey_targets", survey_id)
            self.assertFalse(forbidden & set(survey))
        for journey_id in (WEST_JOURNEY_ID, ABYSS_JOURNEY_ID):
            journey = _by_id(self.map_data, "regional_journeys", journey_id)
            self.assertFalse(forbidden & set(journey))

    def test_terrain_and_provenance_remain_focused(self) -> None:
        self.assertEqual(TERRAIN_SHA256, _terrain_hash(self.map_data))
        provenance = self.map_data["source"]["expansion_17"]
        self.assertEqual([], provenance["terrain_changes"])
        self.assertEqual([INVESTIGATION_ID], provenance["investigation_ids"])
        self.assertEqual([WEST_JOURNEY_ID, ABYSS_JOURNEY_ID], provenance["journey_ids"])
        self.assertEqual([WEST_ARTIFACT_ID, ABYSS_ARTIFACT_ID], provenance["artifact_ids"])

    def test_committed_map_matches_generator(self) -> None:
        committed = json.loads(OUTPUT_MAP_PATH.read_text(encoding="utf-8"))
        self.assertEqual(self.map_data, committed)


if __name__ == "__main__":
    unittest.main()
