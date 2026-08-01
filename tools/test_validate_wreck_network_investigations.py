#!/usr/bin/env python3
"""Focused positive and negative tests for wreck-network investigation validation."""

from __future__ import annotations

import copy
import unittest

from validate_wreck_network_investigations import (
    ANALYSIS_DISCOVERY_ID,
    FRAGMENTS,
    INVESTIGATION_ID,
    PREREQUISITE_ID,
    validate_wreck_network_investigation_schema,
)


def _survey(discovery_id: str, expected: dict[str, str], x: int) -> dict:
    return {
        "id": expected["survey_id"],
        "investigation_id": INVESTIGATION_ID,
        "target_type": "regional",
        "x": x,
        "y": 8,
        "w": 2,
        "h": 2,
        "required_capability_id": "survey_scanner_1",
        "interaction": "survey",
        "interaction_seconds": 3.0,
        "interaction_label": "Scan wreck relay",
        "discovery_id": discovery_id,
        "required_route_id": expected["journey_id"],
        "route_context": expected["journey_id"],
        "commit_map_id": "production_level_01",
        "commit_entry_id": "surface_boat_entry",
        "scan_subject_kind": "artifact",
        "scan_subject_id": expected["artifact_id"],
        "scan_reward_kind": "discovery",
        "scan_reward_id": discovery_id,
    }


def _journey(expected: dict[str, str], order: int) -> dict:
    return {
        "id": expected["journey_id"],
        "required_discovery_id": PREREQUISITE_ID,
        "required_capability_id": expected["route_capability_id"],
        "survey_target_id": expected["survey_id"],
        "commit_entry_id": "surface_boat_entry",
        "route_context": expected["journey_id"],
        "expedition_lead": {
            "lead_type": "regional_journey",
            "label": f"Relay fragment {order}",
            "summary": f"Trace physical wreck relay {order}",
            "active_guidance": f"Follow broad relay signal {order}",
            "order": order,
        },
    }


def valid_map() -> dict:
    fragments = list(FRAGMENTS.items())
    return {
        "id": "production_level_01",
        "entities": [{"id": "surface_boat_entry", "type": "boat_spawn"}],
        "survey_targets": [
            {"id": "far_west_deeper_wreck_survey", "discovery_id": PREREQUISITE_ID},
            *[_survey(discovery_id, expected, 10 + index * 10) for index, (discovery_id, expected) in enumerate(fragments)],
        ],
        "regional_journeys": [
            _journey(expected, index + 20) for index, (_, expected) in enumerate(fragments)
        ],
        "material_projects": [
            {
                "id": "current_stabilizer_project",
                "unlocks_capability_id": "current_stabilizer",
                "required_discovery_id": "southeast_wreck_archive_discovery",
            },
            {
                "id": "pressure_suit_1_project",
                "unlocks_capability_id": "pressure_suit_1",
                "required_discovery_id": "signal_reef_deep_harmonic_discovery",
            },
        ],
        "wreck_network_investigations": [{
            "id": INVESTIGATION_ID,
            "required_discovery_id": PREREQUISITE_ID,
            "fragment_discovery_ids": list(FRAGMENTS),
            "analysis_discovery_id": ANALYSIS_DISCOVERY_ID,
            "analysis_phase": "night_debrief",
            "analysis_label": "Triangulate wreck network",
            "analysis_result_label": "Wreck network triangulated",
            "next_lead_label": "Next lead: transfer hub beyond mapped cave",
            "commit_map_id": "production_level_01",
            "commit_entry_id": "surface_boat_entry",
        }],
    }


class WreckNetworkInvestigationValidationTests(unittest.TestCase):
    def test_accepts_complete_two_fragment_contract(self) -> None:
        self.assertEqual(validate_wreck_network_investigation_schema(valid_map()), [])

    def test_accepts_map_without_optional_collection(self) -> None:
        self.assertEqual(validate_wreck_network_investigation_schema({}), [])

    def test_rejects_duplicate_or_wrong_fragment_set(self) -> None:
        map_data = valid_map()
        first = next(iter(FRAGMENTS))
        map_data["wreck_network_investigations"][0]["fragment_discovery_ids"] = [first, first]
        failures = validate_wreck_network_investigation_schema(map_data)
        self.assertTrue(any("exactly two unique" in failure for failure in failures), failures)
        self.assertTrue(any("match the two contract fragments" in failure for failure in failures), failures)

    def test_rejects_fragment_chain_and_noncanonical_commit(self) -> None:
        map_data = valid_map()
        journey = map_data["regional_journeys"][0]
        journey["required_discovery_id"] = list(FRAGMENTS)[1]
        map_data["wreck_network_investigations"][0]["commit_entry_id"] = "remote_entry"
        failures = validate_wreck_network_investigation_schema(map_data)
        self.assertTrue(any("journey required_discovery_id" in failure for failure in failures), failures)
        self.assertTrue(any("commit_entry_id must be 'surface_boat_entry'" in failure for failure in failures), failures)

    def test_rejects_mutable_state_cost_and_selection_lock(self) -> None:
        map_data = valid_map()
        investigation = map_data["wreck_network_investigations"][0]
        investigation["score"] = 300
        investigation["analysis_ready"] = True
        map_data["survey_targets"][1]["selected_lead_id"] = map_data["regional_journeys"][0]["id"]
        failures = validate_wreck_network_investigation_schema(map_data)
        self.assertTrue(any("runtime, cost, or reward state" in failure for failure in failures), failures)
        self.assertTrue(any("survey must not author mutable" in failure for failure in failures), failures)

    def test_rejects_identical_route_shape_or_lead_presentation(self) -> None:
        map_data = valid_map()
        first, second = map_data["regional_journeys"]
        second["required_capability_id"] = first["required_capability_id"]
        second["expedition_lead"] = copy.deepcopy(first["expedition_lead"])
        failures = validate_wreck_network_investigation_schema(map_data)
        self.assertTrue(any("distinct non-empty labels" in failure for failure in failures), failures)
        self.assertTrue(any("distinct contexts and capability shapes" in failure for failure in failures), failures)

    def test_rejects_final_discovery_from_an_interaction(self) -> None:
        map_data = valid_map()
        map_data["survey_targets"].append({
            "id": "wrong_final_survey",
            "discovery_id": ANALYSIS_DISCOVERY_ID,
        })
        failures = validate_wreck_network_investigation_schema(map_data)
        self.assertTrue(any("only by explicit night analysis" in failure for failure in failures), failures)


if __name__ == "__main__":
    unittest.main()
