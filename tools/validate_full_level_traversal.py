#!/usr/bin/env python3
"""Validate full-level traversal with the real player collision footprint."""

from __future__ import annotations

import argparse
import heapq
import json
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "maps" / "production_level_01.greybox.json"
PLAYER_SCENE = ROOT / "scenes" / "player" / "Player.tscn"
PLAYER_CONTROLLER = ROOT / "scripts" / "player" / "player_controller.gd"
MAIN_SCRIPT = ROOT / "scripts" / "main" / "main.gd"
SESSION_PROGRESSION = ROOT / "scripts" / "main" / "session_progression.gd"
EXPEDITION_DAY_STATE = ROOT / "scripts" / "main" / "expedition_day_state.gd"

NAV_STEP_PX = 8
REVIEW_RESERVE_RATIO = 0.20
EXPECTED_ANCHORS = (
    "full_level_upper_left_anchor",
    "full_level_lower_left_anchor",
    "full_level_lower_right_anchor",
)
EPSILON = 1.0e-6
Point = tuple[int, int]


@dataclass(frozen=True)
class PlayerBody:
    width_px: float
    height_px: float

    @property
    def half_width(self) -> float:
        return self.width_px * 0.5

    @property
    def half_height(self) -> float:
        return self.height_px * 0.5


@dataclass(frozen=True)
class RuntimeBudgets:
    swim_speed_px_per_second: float
    base_oxygen_seconds: float
    upgraded_oxygen_seconds: float
    daylight_seconds: float


@dataclass(frozen=True)
class PathResult:
    points: tuple[Point, ...]
    distance_px: float


@dataclass(frozen=True)
class RouteResult:
    anchor_id: str
    outbound: PathResult | None
    return_path: PathResult | None


def rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item.get("h", 1)))
        for x in range(int(item["x"]), int(item["x"]) + int(item.get("w", 1)))
    }


def solid_cells(map_data: dict) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for item in map_data.get("terrain", []):
        if item.get("type") == "solid":
            cells.update(rect_cells(item))
    return cells


def boundary_cells(width: int, height: int) -> set[tuple[int, int]]:
    return (
        {(x, 0) for x in range(width)}
        | {(x, height - 1) for x in range(width)}
        | {(0, y) for y in range(height)}
        | {(width - 1, y) for y in range(height)}
    )


def _segment_hits_rect_interior(
    start: Point,
    end: Point,
    left: float,
    top: float,
    right: float,
    bottom: float,
) -> bool:
    bounds = (
        (float(start[0]), float(end[0] - start[0]), left + EPSILON, right - EPSILON),
        (float(start[1]), float(end[1] - start[1]), top + EPSILON, bottom - EPSILON),
    )
    enter = 0.0
    leave = 1.0
    for origin, delta, minimum, maximum in bounds:
        if minimum > maximum:
            return False
        if abs(delta) <= EPSILON:
            if origin < minimum or origin > maximum:
                return False
            continue
        first = (minimum - origin) / delta
        second = (maximum - origin) / delta
        if first > second:
            first, second = second, first
        enter = max(enter, first)
        leave = min(leave, second)
        if enter > leave:
            return False
    return leave >= 0.0 and enter <= 1.0


class CollisionField:
    def __init__(
        self,
        width_tiles: int,
        height_tiles: int,
        tile_size: int,
        solids: set[tuple[int, int]],
        body: PlayerBody,
        step_px: int = NAV_STEP_PX,
    ) -> None:
        self.width_tiles = width_tiles
        self.height_tiles = height_tiles
        self.tile_size = tile_size
        self.solids = solids
        self.body = body
        self.step_px = step_px
        self.width_px = width_tiles * tile_size
        self.height_px = height_tiles * tile_size
        self._center_cache: dict[Point, bool] = {}
        self._segment_cache: dict[tuple[Point, Point], bool] = {}

    def center_is_clear(self, point: Point) -> bool:
        cached = self._center_cache.get(point)
        if cached is not None:
            return cached
        x, y = point
        left = x - self.body.half_width
        right = x + self.body.half_width
        top = y - self.body.half_height
        bottom = y + self.body.half_height
        clear = not (
            left < -EPSILON
            or top < -EPSILON
            or right > self.width_px + EPSILON
            or bottom > self.height_px + EPSILON
        )
        if clear:
            min_x = max(0, math.floor((left + EPSILON) / self.tile_size))
            max_x = min(
                self.width_tiles - 1,
                math.floor((right - EPSILON) / self.tile_size),
            )
            min_y = max(0, math.floor((top + EPSILON) / self.tile_size))
            max_y = min(
                self.height_tiles - 1,
                math.floor((bottom - EPSILON) / self.tile_size),
            )
            clear = not any(
                (tile_x, tile_y) in self.solids
                for tile_y in range(min_y, max_y + 1)
                for tile_x in range(min_x, max_x + 1)
            )
        self._center_cache[point] = clear
        return clear

    def segment_is_clear(self, start: Point, end: Point) -> bool:
        key = (start, end)
        cached = self._segment_cache.get(key)
        if cached is not None:
            return cached
        if not self.center_is_clear(start) or not self.center_is_clear(end):
            self._segment_cache[key] = False
            return False

        sweep_left = min(start[0], end[0]) - self.body.half_width
        sweep_right = max(start[0], end[0]) + self.body.half_width
        sweep_top = min(start[1], end[1]) - self.body.half_height
        sweep_bottom = max(start[1], end[1]) + self.body.half_height
        min_x = max(0, math.floor(sweep_left / self.tile_size) - 1)
        max_x = min(self.width_tiles - 1, math.floor(sweep_right / self.tile_size) + 1)
        min_y = max(0, math.floor(sweep_top / self.tile_size) - 1)
        max_y = min(self.height_tiles - 1, math.floor(sweep_bottom / self.tile_size) + 1)

        clear = True
        for tile_y in range(min_y, max_y + 1):
            for tile_x in range(min_x, max_x + 1):
                if (tile_x, tile_y) not in self.solids:
                    continue
                left = tile_x * self.tile_size - self.body.half_width
                right = (tile_x + 1) * self.tile_size + self.body.half_width
                top = tile_y * self.tile_size - self.body.half_height
                bottom = (tile_y + 1) * self.tile_size + self.body.half_height
                if _segment_hits_rect_interior(start, end, left, top, right, bottom):
                    clear = False
                    break
            if not clear:
                break
        self._segment_cache[key] = clear
        return clear

    def neighbors(self, point: Point):
        x, y = point
        for dy in (-self.step_px, 0, self.step_px):
            for dx in (-self.step_px, 0, self.step_px):
                if dx == 0 and dy == 0:
                    continue
                neighbor = (x + dx, y + dy)
                if self.segment_is_clear(point, neighbor):
                    yield neighbor, math.hypot(dx, dy)


def shortest_path(field: CollisionField, start: Point, target: Point) -> PathResult | None:
    if not field.center_is_clear(start) or not field.center_is_clear(target):
        return None
    frontier: list[tuple[float, float, Point]] = [(math.dist(start, target), 0.0, start)]
    distance = {start: 0.0}
    came_from: dict[Point, Point] = {}

    while frontier:
        _, current_distance, current = heapq.heappop(frontier)
        if current_distance > distance.get(current, math.inf) + EPSILON:
            continue
        if current == target:
            break
        for neighbor, step_distance in field.neighbors(current):
            candidate_distance = current_distance + step_distance
            if candidate_distance + EPSILON >= distance.get(neighbor, math.inf):
                continue
            distance[neighbor] = candidate_distance
            came_from[neighbor] = current
            estimate = candidate_distance + math.dist(neighbor, target)
            heapq.heappush(frontier, (estimate, candidate_distance, neighbor))

    if target not in distance:
        return None
    points = [target]
    while points[-1] != start:
        points.append(came_from[points[-1]])
    points.reverse()
    return PathResult(tuple(points), distance[target])


def analyze_route(
    field: CollisionField, anchor_id: str, start: Point, target: Point
) -> RouteResult:
    return RouteResult(
        anchor_id,
        shortest_path(field, start, target),
        shortest_path(field, target, start),
    )


def boundary_failures(map_data: dict, solids: set[tuple[int, int]]) -> list[str]:
    units = map_data["units"]
    width = int(units["width_tiles"])
    height = int(units["height_tiles"])
    opening_records = (
        map_data.get("source", {})
        .get("cleanup", {})
        .get("intentional_top_water_opening", [])
    )
    intentional = {(int(item["x"]), int(item["y"])) for item in opening_records}
    actual = boundary_cells(width, height) - solids
    failures: list[str] = []
    if actual != intentional:
        failures.append(
            "outer boundary opening mismatch: "
            f"missing={sorted(intentional - actual)} unexpected={sorted(actual - intentional)}"
        )

    boats = [
        entity
        for entity in map_data.get("entities", [])
        if entity.get("type") == "boat_spawn"
    ]
    if len(boats) != 1:
        failures.append(f"expected exactly one boat_spawn; found {len(boats)}")
        return failures
    boat = boats[0]
    boat_top = {
        (x, 0)
        for x in range(int(boat["x"]), int(boat["x"]) + int(boat.get("w", 1)))
    }
    if intentional != boat_top:
        failures.append(
            f"intentional opening {sorted(intentional)} does not match boat top {sorted(boat_top)}"
        )
    return failures


def transition_metadata_failures(map_data: dict) -> list[str]:
    forbidden = {
        "world_connector",
        "destination_map_id",
        "destination_map_path",
        "destination_entry_id",
        "teleport",
    }
    failures: list[str] = []
    for section in ("zones", "entities"):
        for item in map_data.get(section, []):
            present = forbidden & set(item)
            is_exceptional = (
                section == "zones"
                and item.get("world_connector") is True
                and item.get("connector_kind") == "exceptional_interior"
            )
            if is_exceptional and "teleport" not in present:
                continue
            if present:
                failures.append(
                    f"{section} record {item.get('id', '<missing>')} has transition metadata {sorted(present)}"
                )
    return failures


def _read_number(path: Path, pattern: str, label: str) -> float:
    match = re.search(pattern, path.read_text(encoding="utf-8"), flags=re.MULTILINE)
    if match is None:
        raise ValueError(f"Unable to read {label} from {path.relative_to(ROOT)}.")
    return float(match.group(1))


def load_player_body() -> PlayerBody:
    text = PLAYER_SCENE.read_text(encoding="utf-8")
    match = re.search(r"size\s*=\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)", text)
    if match is None:
        raise ValueError("Unable to read player RectangleShape2D size.")
    return PlayerBody(float(match.group(1)), float(match.group(2)))


def load_runtime_budgets() -> RuntimeBudgets:
    swim_speed = _read_number(
        PLAYER_CONTROLLER,
        r"@export var swim_speed\s*:=\s*([0-9.]+)",
        "swim speed",
    )
    base_oxygen = _read_number(
        MAIN_SCRIPT,
        r"const OXYGEN_MAX_SECONDS\s*:=\s*([0-9.]+)",
        "base oxygen",
    )
    oxygen_bonus = _read_number(
        SESSION_PROGRESSION,
        r"const OXYGEN_TANK_UPGRADE_SECONDS\s*:=\s*([0-9.]+)",
        "oxygen upgrade",
    )
    daylight = _read_number(
        EXPEDITION_DAY_STATE,
        r"const DEFAULT_DAYLIGHT_SECONDS\s*:=\s*([0-9.]+)",
        "daylight",
    )
    return RuntimeBudgets(swim_speed, base_oxygen, base_oxygen + oxygen_bonus, daylight)


def map_point(item: dict, tile_size: int, entry: bool = False) -> Point:
    if entry:
        x = float(item.get("entry_x", item["x"])) + 0.5
        y = float(item.get("entry_y", item["y"])) + 0.5
    else:
        x = float(item["x"]) + float(item.get("w", 1)) * 0.5
        y = float(item["y"]) + float(item.get("h", 1)) * 0.5
    point = (round(x * tile_size), round(y * tile_size))
    if point[0] % NAV_STEP_PX or point[1] % NAV_STEP_PX:
        raise ValueError(f"Map point {point} does not align to {NAV_STEP_PX}px navigation grid.")
    return point


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    units = map_data["units"]
    tile_size = int(units["tile_size_px"])
    body = load_player_body()
    budgets = load_runtime_budgets()
    solids = solid_cells(map_data)
    failures = boundary_failures(map_data, solids)
    failures.extend(transition_metadata_failures(map_data))

    boats = [
        item for item in map_data.get("entities", []) if item.get("type") == "boat_spawn"
    ]
    anchor_items = [
        item
        for item in map_data.get("zones", [])
        if item.get("validation_anchor") is True
    ]
    anchors = {
        str(item.get("id", "")): item
        for item in anchor_items
    }
    if len(anchors) != len(anchor_items):
        failures.append("sector anchor ids must be unique")
    missing_anchors = set(EXPECTED_ANCHORS) - set(anchors)
    extra_anchors = set(anchors) - set(EXPECTED_ANCHORS)
    if missing_anchors or extra_anchors:
        failures.append(
            f"sector anchor mismatch: missing={sorted(missing_anchors)} extra={sorted(extra_anchors)}"
        )
    if len(boats) != 1 or failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1

    field = CollisionField(
        int(units["width_tiles"]),
        int(units["height_tiles"]),
        tile_size,
        solids,
        body,
    )
    boat_point = map_point(boats[0], tile_size, entry=True)
    routes = [
        analyze_route(field, anchor_id, boat_point, map_point(anchors[anchor_id], tile_size))
        for anchor_id in EXPECTED_ANCHORS
    ]

    print(
        f"{map_data['id']} traversal: body={body.width_px:g}x{body.height_px:g}px "
        f"tile={tile_size}px nav_step={NAV_STEP_PX}px speed={budgets.swim_speed_px_per_second:g}px/s"
    )
    print(
        f"Boundary PASS: intentional_open={len(boundary_cells(int(units['width_tiles']), int(units['height_tiles'])) - solids)} "
        f"boat={boats[0]['id']} collision=active path_mode=continuous_no_transition"
    )

    ideal_round_trips: list[float] = []
    for route in routes:
        if route.outbound is None:
            failures.append(f"{route.anchor_id} is not reachable by the player footprint")
            continue
        if route.return_path is None:
            failures.append(f"{route.anchor_id} has no direct player-footprint return to the boat")
            continue
        round_trip_px = route.outbound.distance_px + route.return_path.distance_px
        ideal_seconds = round_trip_px / budgets.swim_speed_px_per_second
        ideal_round_trips.append(ideal_seconds)
        print(
            f"Route {route.anchor_id}: one_way={route.outbound.distance_px:.1f}px "
            f"return={route.return_path.distance_px:.1f}px round_trip={round_trip_px:.1f}px "
            f"ideal={ideal_seconds:.1f}s base{budgets.base_oxygen_seconds:g}_headroom="
            f"{budgets.base_oxygen_seconds - ideal_seconds:.1f}s "
            f"upgraded{budgets.upgraded_oxygen_seconds:g}_headroom="
            f"{budgets.upgraded_oxygen_seconds - ideal_seconds:.1f}s"
        )

    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1

    reserved_times = [seconds * (1.0 + REVIEW_RESERVE_RATIO) for seconds in ideal_round_trips]
    day_total = sum(reserved_times)
    review_viable = (
        all(seconds <= budgets.upgraded_oxygen_seconds for seconds in reserved_times)
        and day_total <= budgets.daylight_seconds
    )
    decision = "PASS" if review_viable else "HOLD"
    print(
        f"Review configuration {decision}: three separate boat-return sorties, "
        f"tank={budgets.upgraded_oxygen_seconds:g}s oxygen=active collision=active "
        f"reserve={REVIEW_RESERVE_RATIO:.0%} reserved_swim={day_total:.1f}/{budgets.daylight_seconds:g}s daylight"
    )
    if not review_viable:
        print(
            "HOLD: route budget needs a scoped pacing/anchor review; do not add a refuge, "
            "teleport, stabilizer, or hidden bypass.",
            file=sys.stderr,
        )
        return 2
    print("PASS: all contracted sectors are footprint-clear, directly returnable, and review-budget viable.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", nargs="?", type=Path, default=DEFAULT_MAP)
    args = parser.parse_args()
    map_path = args.map_json if args.map_json.is_absolute() else ROOT / args.map_json
    return run_validation(map_path)


if __name__ == "__main__":
    raise SystemExit(main())
