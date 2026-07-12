#!/usr/bin/env python3
"""Focused positive and negative tests for current-gate source validation."""

from __future__ import annotations

import copy
import unittest

from validate_current_gates import validate_current_gate_reachability, validate_current_gate_schema


def gate(requirement_field: str = "required_upgrade_id") -> dict:
    return {
        "id": "test_current_gate",
        "type": "marker",
        "x": 2,
        "y": 2,
        "w": 2,
        "h": 2,
        "current_gate": True,
        "current_direction": "left",
        "current_strength": 2.2,
        requirement_field: "propulsion_fins" if requirement_field == "required_upgrade_id" else "current_stabilizer",
        "current_gate_label": "Ripping current",
        "current_affordance_role": "barrier",
        "route_context": "test_route",
    }


def map_with_gate(requirement_field: str = "required_upgrade_id") -> dict:
    return {
        "id": "current_gate_fixture",
        "units": {"width_tiles": 8, "height_tiles": 8},
        "entities": [],
        "zones": [gate(requirement_field)],
    }


class CurrentGateValidationTests(unittest.TestCase):
    def test_accepts_legacy_upgrade_and_durable_capability_requirements(self) -> None:
        self.assertEqual(validate_current_gate_schema(map_with_gate("required_upgrade_id")), [])
        self.assertEqual(validate_current_gate_schema(map_with_gate("required_capability_id")), [])

    def test_rejects_both_or_neither_requirement_kind(self) -> None:
        both = map_with_gate("required_upgrade_id")
        both["zones"][0]["required_capability_id"] = "current_stabilizer"
        neither = map_with_gate("required_upgrade_id")
        del neither["zones"][0]["required_upgrade_id"]
        for map_data in (both, neither):
            failures = validate_current_gate_schema(map_data)
            self.assertTrue(any("exactly one" in failure for failure in failures), failures)

    def test_rejects_invalid_capability_id_and_non_marker_metadata(self) -> None:
        map_data = map_with_gate("required_capability_id")
        map_data["zones"][0]["required_capability_id"] = "Current Stabilizer"
        map_data["entities"] = [{"id": "bad_entity", "current_direction": "left"}]
        failures = validate_current_gate_schema(map_data)
        self.assertTrue(any("required_capability_id" in failure and "lower_snake_case" in failure for failure in failures))
        self.assertTrue(any("only supported on marker zones" in failure for failure in failures))

    def test_rejects_solid_and_unreachable_gate_cells(self) -> None:
        zone = gate("required_capability_id")
        cells = {(2, 2), (3, 2), (2, 3), (3, 3)}
        failures = validate_current_gate_reachability([zone], {(2, 2)}, cells - {(3, 3)})
        self.assertTrue(any("contains solid cells" in failure for failure in failures))
        self.assertTrue(any("contains unreachable cells" in failure for failure in failures))

    def test_rejects_unknown_affordance_role(self) -> None:
        map_data = map_with_gate("required_capability_id")
        map_data["zones"][0]["current_affordance_role"] = "secret_shortcut"
        failures = validate_current_gate_schema(map_data)
        self.assertTrue(any("current_affordance_role must be one of" in failure for failure in failures), failures)

    def test_fixture_mutation_is_isolated(self) -> None:
        original = map_with_gate("required_capability_id")
        mutated = copy.deepcopy(original)
        mutated["zones"].clear()
        self.assertEqual(len(original["zones"]), 1)


if __name__ == "__main__":
    unittest.main()
