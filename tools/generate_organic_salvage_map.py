#!/usr/bin/env python3
"""Generate a playable organic salvage cave greybox map."""

from __future__ import annotations

import json
import math
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "cave_salvage_organic_01.greybox.json"
WIDTH = 80
HEIGHT = 45
TILE_SIZE = 32
SPAWN = (9, 31)


def add_cell(cells: set[tuple[int, int]], x: int, y: int) -> None:
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        cells.add((x, y))


def remove_cell(cells: set[tuple[int, int]], x: int, y: int) -> None:
    cells.discard((x, y))


def add_rect(cells: set[tuple[int, int]], x: int, y: int, w: int, h: int) -> None:
    for cy in range(y, y + h):
        for cx in range(x, x + w):
            add_cell(cells, cx, cy)


def remove_rect(cells: set[tuple[int, int]], x: int, y: int, w: int, h: int) -> None:
    for cy in range(y, y + h):
        for cx in range(x, x + w):
            remove_cell(cells, cx, cy)


def add_blob(cells: set[tuple[int, int]], cx: int, cy: int, rx: int, ry: int, phase: float = 0.0) -> None:
    for y in range(cy - ry - 2, cy + ry + 3):
        for x in range(cx - rx - 2, cx + rx + 3):
            nx = (x - cx) / max(rx, 1)
            ny = (y - cy) / max(ry, 1)
            ripple = 0.16 * math.sin(x * 0.9 + phase) + 0.10 * math.cos(y * 1.4 + phase)
            if nx * nx + ny * ny <= 1.0 + ripple:
                add_cell(cells, x, y)


def remove_blob(cells: set[tuple[int, int]], cx: int, cy: int, rx: int, ry: int) -> None:
    for y in range(cy - ry - 2, cy + ry + 3):
        for x in range(cx - rx - 2, cx + rx + 3):
            nx = (x - cx) / max(rx, 1)
            ny = (y - cy) / max(ry, 1)
            if nx * nx + ny * ny <= 1.0:
                remove_cell(cells, x, y)


def add_boundaries(cells: set[tuple[int, int]]) -> None:
    for x in range(WIDTH):
        top_depth = 2 + (1 if x % 13 in (0, 1, 2, 3) else 0) + (1 if x % 29 in (8, 9, 10) else 0)
        bottom_depth = 3 + (1 if x % 11 in (3, 4, 5, 6) else 0) + (1 if x % 23 in (15, 16) else 0)
        add_rect(cells, x, 0, 1, top_depth)
        add_rect(cells, x, HEIGHT - bottom_depth, 1, bottom_depth)

    for y in range(HEIGHT):
        left_width = 2 + (1 if y % 9 in (0, 1, 2) else 0)
        right_width = 2 + (1 if y % 8 in (4, 5, 6) else 0)
        add_rect(cells, 0, y, left_width, 1)
        add_rect(cells, WIDTH - right_width, y, right_width, 1)

    for x, depth in ((16, 6), (37, 5), (61, 7), (69, 4)):
        add_blob(cells, x, depth, 2, 4, x * 0.2)


def add_jagged_ledge(cells: set[tuple[int, int]], x0: int, x1: int, y: int, thickness: int, phase: int) -> None:
    for x in range(x0, x1 + 1):
        surface = y + (1 if (x + phase) % 7 in (0, 1) else 0) - (1 if (x + phase) % 11 == 4 else 0)
        height = thickness + (1 if (x + phase) % 9 in (3, 4) else 0)
        add_rect(cells, x, surface, 1, height)

    for notch_x in range(x0 + 4, x1, 11):
        remove_rect(cells, notch_x, y, 2, 1)


def carve_open_space(cells: set[tuple[int, int]]) -> None:
    # Keep important play spaces open after building organic solid masses.
    for cx, cy, rx, ry in (
        (9, 31, 7, 4),
        (22, 22, 9, 7),
        (39, 19, 12, 8),
        (58, 21, 12, 9),
        (66, 31, 8, 6),
        (31, 33, 8, 4),
        (47, 11, 9, 5),
    ):
        remove_blob(cells, cx, cy, rx, ry)


def add_playable_terrain(cells: set[tuple[int, int]]) -> None:
    add_boundaries(cells)

    # Base floor and nearby shelves.
    add_jagged_ledge(cells, 3, 22, 35, 5, 1)
    add_jagged_ledge(cells, 8, 21, 24, 3, 4)

    # Organic masses and ledges that shape route choices.
    add_blob(cells, 27, 18, 8, 8, 1.4)
    add_blob(cells, 45, 25, 11, 9, 2.1)
    add_blob(cells, 63, 15, 10, 7, 2.8)
    add_blob(cells, 64, 35, 9, 5, 3.6)
    add_blob(cells, 35, 35, 7, 4, 4.2)

    add_jagged_ledge(cells, 34, 50, 13, 3, 6)
    add_jagged_ledge(cells, 55, 72, 25, 4, 3)
    add_jagged_ledge(cells, 24, 39, 31, 3, 8)

    # Pillars/stalactites that break up long straight spans.
    for x, y0, h in ((18, 3, 7), (52, 3, 6), (70, 3, 5), (57, 25, 8)):
        for y in range(y0, y0 + h):
            radius = 1 + (1 if y % 4 == 0 else 0)
            offset = -1 if y % 5 == 1 else 1 if y % 5 == 3 else 0
            for px in range(x + offset - radius, x + offset + radius + 1):
                add_cell(cells, px, y)

    carve_open_space(cells)

    # Small side pockets carved into masses for salvage and hazards.
    for cx, cy, rx, ry in (
        (25, 14, 5, 3),
        (43, 11, 5, 3),
        (66, 19, 5, 4),
        (55, 34, 6, 3),
        (31, 30, 5, 3),
        (44, 33, 4, 3),
    ):
        remove_blob(cells, cx, cy, rx, ry)


def fill_unreachable_open_cells(cells: set[tuple[int, int]], spawn: tuple[int, int]) -> None:
    reachable: set[tuple[int, int]] = {spawn}
    queue: deque[tuple[int, int]] = deque([spawn])
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if nx < 0 or ny < 0 or nx >= WIDTH or ny >= HEIGHT:
                continue
            cell = (nx, ny)
            if cell in cells or cell in reachable:
                continue
            reachable.add(cell)
            queue.append(cell)

    for y in range(HEIGHT):
        for x in range(WIDTH):
            cell = (x, y)
            if cell not in cells and cell not in reachable:
                cells.add(cell)


def row_run_terrain(cells: set[tuple[int, int]]) -> list[dict]:
    terrain: list[dict] = []
    for y in range(HEIGHT):
        run_start: int | None = None
        for x in range(WIDTH + 1):
            solid = (x, y) in cells if x < WIDTH else False
            if solid and run_start is None:
                run_start = x
            elif not solid and run_start is not None:
                terrain.append({
                    "id": f"solid_y{y:02d}_x{run_start:02d}_{x - 1:02d}",
                    "type": "solid",
                    "x": run_start,
                    "y": y,
                    "w": x - run_start,
                    "h": 1,
                })
                run_start = None
    return terrain


def build_map_data() -> dict:
    cells: set[tuple[int, int]] = set()
    add_playable_terrain(cells)
    fill_unreachable_open_cells(cells, SPAWN)

    return {
        "id": "cave_salvage_organic_01",
        "version": 1,
        "purpose": "Playable organic salvage cave pass with less rectangular terrain, carved pockets, ledges, arches, and route choices while preserving JSON map source-of-truth workflow.",
        "units": {
            "tile_size_px": TILE_SIZE,
            "width_tiles": WIDTH,
            "height_tiles": HEIGHT,
        },
        "legend": {
            "water": "Open swimmable space",
            "solid": "Collision terrain authored on the 32px grid",
            "base": "Safe extraction / bank-score area",
            "background": "Non-collision depth silhouette",
            "spawn": "Player start",
            "salvage": "Collectible objective",
            "hazard": "Damage or avoidance pressure",
            "marker": "Non-gameplay annotation",
        },
        "terrain": row_run_terrain(cells),
        "zones": [
            {
                "id": "extraction_zone",
                "type": "base",
                "x": 5,
                "y": 31,
                "w": 12,
                "h": 3,
                "intent": "Safe return and score banking area tucked into the left cave mouth.",
            },
            {
                "id": "main_cavern_route",
                "type": "marker",
                "x": 16,
                "y": 12,
                "w": 42,
                "h": 18,
                "intent": "Primary swim route through carved open water and central terrain masses.",
            },
            {
                "id": "upper_side_pocket",
                "type": "marker",
                "x": 35,
                "y": 7,
                "w": 17,
                "h": 8,
                "intent": "Optional upper pocket with salvage and hazard pressure.",
            },
            {
                "id": "lower_return_loop",
                "type": "marker",
                "x": 24,
                "y": 30,
                "w": 38,
                "h": 9,
                "intent": "Lower return route that gives a second way back toward extraction.",
            },
            {
                "id": "right_salvage_pocket",
                "type": "marker",
                "x": 59,
                "y": 17,
                "w": 12,
                "h": 12,
                "intent": "Right-side pocket that makes the far end feel like a destination.",
            },
        ],
        "background": [
            {"id": "distant_arch_left", "type": "background", "x": 9, "y": 10, "w": 16, "h": 21},
            {"id": "distant_ruin_mid", "type": "background", "x": 35, "y": 9, "w": 15, "h": 25},
            {"id": "distant_shelf_right", "type": "background", "x": 55, "y": 14, "w": 18, "h": 23},
        ],
        "entities": [
            {"id": "player_start", "type": "spawn", "x": SPAWN[0], "y": SPAWN[1], "facing": "right"},
            {"id": "salvage_left_pocket", "type": "salvage", "x": 24, "y": 14, "kind": "crate"},
            {"id": "salvage_upper_pocket", "type": "salvage", "x": 43, "y": 10, "kind": "crate"},
            {"id": "salvage_right_pocket", "type": "salvage", "x": 67, "y": 19, "kind": "crate"},
            {"id": "salvage_lower_loop", "type": "salvage", "x": 55, "y": 34, "kind": "wreck_fragment"},
            {"id": "salvage_return_route", "type": "salvage", "x": 31, "y": 31, "kind": "crate"},
            {"id": "hazard_left_choke", "type": "hazard", "x": 28, "y": 21, "kind": "mine"},
            {"id": "hazard_upper_pocket", "type": "hazard", "x": 49, "y": 13, "kind": "jellyfish"},
            {"id": "hazard_right_pocket", "type": "hazard", "x": 63, "y": 24, "kind": "mine"},
            {"id": "hazard_lower_loop", "type": "hazard", "x": 44, "y": 33, "kind": "jellyfish"},
        ],
        "camera_tests": [
            {
                "id": "organic_start_view",
                "center_x": 15,
                "center_y": 28,
                "zoom": 0.72,
                "intent": "Shows extraction, player start, left pocket, and first route choice.",
            },
            {
                "id": "organic_center_route_view",
                "center_x": 39,
                "center_y": 20,
                "zoom": 0.68,
                "intent": "Shows central carved route, hazards, upper side pocket, and lower loop entrance.",
            },
            {
                "id": "organic_right_pocket_view",
                "center_x": 62,
                "center_y": 23,
                "zoom": 0.72,
                "intent": "Shows right-side salvage pocket and lower return connection.",
            },
            {
                "id": "organic_overview",
                "center_x": 40,
                "center_y": 23,
                "zoom": 0.48,
                "intent": "Whole-map review for organic topology and route readability.",
            },
        ],
        "review_questions": [
            "Does the cave read as more organic than long rectangular shelves?",
            "Are the main route, upper side pocket, right salvage pocket, and lower return loop understandable?",
            "Can the player return to extraction without every route feeling identical?",
            "Do all gameplay objects remain reachable from spawn?",
            "Does the map still leave enough open water to feel like swimming?",
        ],
    }


def main() -> int:
    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    map_data = build_map_data()
    MAP_PATH.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {MAP_PATH.relative_to(ROOT)} with {len(map_data['terrain'])} solid row runs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
