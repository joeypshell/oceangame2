#!/usr/bin/env python3
"""Focused fixtures for actual-player full-level traversal validation."""

from __future__ import annotations

import json
import unittest

from validate_full_level_traversal import (
    ROOT,
    CollisionField,
    PlayerBody,
    analyze_route,
    boundary_cells,
    boundary_failures,
    load_player_body,
    load_runtime_budgets,
    shortest_path,
    solid_cells,
    transition_metadata_failures,
)


BODY = PlayerBody(26.0, 18.0)


def field(
    width: int,
    height: int,
    solids: set[tuple[int, int]] | None = None,
    tile_size: int = 32,
) -> CollisionField:
    return CollisionField(width, height, tile_size, solids or set(), BODY, step_px=8)


def terrain(cells: set[tuple[int, int]]) -> list[dict]:
    return [
        {
            "id": f"solid_{x}_{y}",
            "type": "solid",
            "x": x,
            "y": y,
            "w": 1,
            "h": 1,
        }
        for x, y in sorted(cells, key=lambda point: (point[1], point[0]))
    ]


def boundary_fixture(leak: bool = False) -> dict:
    width = 4
    height = 4
    intentional = {(1, 0), (2, 0)}
    solids = boundary_cells(width, height) - intentional
    if leak:
        solids.remove((3, 2))
    return {
        "id": "boundary_fixture",
        "source": {
            "cleanup": {
                "intentional_top_water_opening": [
                    {"x": x, "y": y} for x, y in sorted(intentional)
                ]
            }
        },
        "units": {"tile_size_px": 32, "width_tiles": width, "height_tiles": height},
        "terrain": terrain(solids),
        "entities": [
            {
                "id": "surface_boat_entry",
                "type": "boat_spawn",
                "x": 1,
                "y": 0,
                "w": 2,
                "h": 1,
                "entry_x": 1,
                "entry_y": 0,
            }
        ],
    }


class EastOnlyField(CollisionField):
    def segment_is_clear(self, start, end) -> bool:
        if end[0] < start[0]:
            return False
        return super().segment_is_clear(start, end)


class FullLevelTraversalValidationTests(unittest.TestCase):
    def test_clear_fixture_is_reachable_and_returnable(self) -> None:
        navigation = field(6, 6)
        result = analyze_route(navigation, "clear_anchor", (16, 16), (176, 176))
        self.assertIsNotNone(result.outbound)
        self.assertIsNotNone(result.return_path)
        self.assertGreater(result.outbound.distance_px, 0.0)

    def test_corner_blocked_fixture_rejects_diagonal_clipping(self) -> None:
        navigation = field(2, 2, {(1, 0), (0, 1)})
        self.assertTrue(navigation.center_is_clear((16, 16)))
        self.assertTrue(navigation.center_is_clear((48, 48)))
        self.assertIsNone(shortest_path(navigation, (16, 16), (48, 48)))

    def test_narrow_fixture_rejects_corridor_smaller_than_body(self) -> None:
        solids = {(x, y) for x in range(5) for y in (0, 2)}
        navigation = field(5, 3, solids, tile_size=16)
        self.assertFalse(navigation.center_is_clear((24, 24)))
        self.assertIsNone(shortest_path(navigation, (24, 24), (56, 24)))

    def test_unreachable_fixture_rejects_full_collision_wall(self) -> None:
        solids = {(3, y) for y in range(5)}
        navigation = field(7, 5, solids)
        self.assertIsNone(shortest_path(navigation, (48, 80), (176, 80)))

    def test_boundary_leak_fixture_reports_unexpected_opening(self) -> None:
        valid = boundary_fixture()
        self.assertEqual(boundary_failures(valid, solid_cells(valid)), [])
        leaking = boundary_fixture(leak=True)
        failures = boundary_failures(leaking, solid_cells(leaking))
        self.assertTrue(any("unexpected" in failure for failure in failures), failures)

    def test_transition_metadata_is_rejected(self) -> None:
        map_data = {"zones": [{"id": "bad_connector", "world_connector": True}]}
        failures = transition_metadata_failures(map_data)
        self.assertTrue(any("world_connector" in failure for failure in failures), failures)

    def test_non_returnable_fixture_is_reported_separately(self) -> None:
        navigation = EastOnlyField(6, 3, 32, set(), BODY, step_px=8)
        result = analyze_route(navigation, "one_way_anchor", (16, 48), (176, 48))
        self.assertIsNotNone(result.outbound)
        self.assertIsNone(result.return_path)

    def test_runtime_sources_match_current_player_and_budgets(self) -> None:
        self.assertEqual(load_player_body(), BODY)
        budgets = load_runtime_budgets()
        self.assertEqual(budgets.swim_speed_px_per_second, 200.0)
        self.assertEqual(budgets.base_oxygen_seconds, 90.0)
        self.assertEqual(budgets.upgraded_oxygen_seconds, 105.0)
        self.assertEqual(budgets.daylight_seconds, 300.0)

    def test_committed_candidate_boundary_is_safe(self) -> None:
        map_data = json.loads(
            (ROOT / "maps" / "production_level_01.greybox.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(boundary_failures(map_data, solid_cells(map_data)), [])


if __name__ == "__main__":
    unittest.main()
