#!/usr/bin/env python3
"""Generate an organic cave tileset stress-test map."""

from __future__ import annotations

import json
import math
from collections import deque
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAP_PATH = ROOT / "maps" / "cave_tileset_test_01.greybox.json"
WIDTH = 64
HEIGHT = 38
TILE_SIZE = 32


def add_rect(cells: set[tuple[int, int]], x: int, y: int, w: int, h: int) -> None:
    for cy in range(y, y + h):
        for cx in range(x, x + w):
            add_cell(cells, cx, cy)


def add_cell(cells: set[tuple[int, int]], x: int, y: int) -> None:
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        cells.add((x, y))


def remove_cell(cells: set[tuple[int, int]], x: int, y: int) -> None:
    cells.discard((x, y))


def add_blob(cells: set[tuple[int, int]], cx: int, cy: int, rx: int, ry: int) -> None:
    for y in range(cy - ry - 1, cy + ry + 2):
        for x in range(cx - rx - 1, cx + rx + 2):
            nx = (x - cx) / max(rx, 1)
            ny = (y - cy) / max(ry, 1)
            ridge = 0.12 * math.sin(x * 1.7 + y * 0.4)
            if nx * nx + ny * ny <= 1.0 + ridge:
                add_cell(cells, x, y)


def remove_blob(cells: set[tuple[int, int]], cx: int, cy: int, rx: int, ry: int) -> None:
    for y in range(cy - ry - 1, cy + ry + 2):
        for x in range(cx - rx - 1, cx + rx + 2):
            nx = (x - cx) / max(rx, 1)
            ny = (y - cy) / max(ry, 1)
            if nx * nx + ny * ny <= 1.0:
                remove_cell(cells, x, y)


def add_jagged_pillar(cells: set[tuple[int, int]], cx: int, y0: int, y1: int, base_radius: int) -> None:
    for y in range(y0, y1 + 1):
        radius = base_radius + (1 if y % 5 in (0, 1) else 0) - (1 if y % 7 == 3 else 0)
        offset = -1 if y % 9 in (0, 1, 2) else 1 if y % 9 in (5, 6) else 0
        for x in range(cx + offset - radius, cx + offset + radius + 1):
            add_cell(cells, x, y)


def carve_winding_tunnel(cells: set[tuple[int, int]]) -> None:
    previous_center = None
    for y in range(8, 31):
        center = 32 + round(math.sin((y - 8) / 22 * math.pi * 2.2) * 8)
        if previous_center is None:
            previous_center = center
        step = 1 if center >= previous_center else -1
        for x in range(previous_center, center + step, step):
            for dy in (-2, -1, 0, 1, 2):
                for dx in (-2, -1, 0, 1, 2):
                    remove_cell(cells, x + dx, y + dy)
        previous_center = center

    # Side pockets connected to the main carved tunnel.
    remove_blob(cells, 24, 15, 4, 3)
    add_rect(cells, 21, 18, 4, 2)
    remove_blob(cells, 40, 23, 5, 3)
    add_rect(cells, 41, 20, 4, 2)


def add_boundaries(cells: set[tuple[int, int]]) -> None:
    for x in range(WIDTH):
        top_height = 2 + (1 if x % 11 in (0, 1, 2) else 0)
        bottom_height = 2 + (1 if x % 9 in (3, 4, 5) else 0)
        add_rect(cells, x, 0, 1, top_height)
        add_rect(cells, x, HEIGHT - bottom_height, 1, bottom_height)

    for y in range(HEIGHT):
        left_width = 2 + (1 if y % 8 in (0, 1, 2) else 0)
        right_width = 2 + (1 if y % 7 in (4, 5) else 0)
        add_rect(cells, 0, y, left_width, 1)
        add_rect(cells, WIDTH - right_width, y, right_width, 1)


def build_solid_cells() -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    add_boundaries(cells)

    # A central solid mass with a carved S-tunnel through it.
    add_blob(cells, 32, 19, 17, 12)
    add_blob(cells, 33, 19, 12, 15)
    carve_winding_tunnel(cells)

    # Vertical pillars and island clusters.
    add_jagged_pillar(cells, 10, 5, 24, 2)
    add_jagged_pillar(cells, 54, 9, 31, 2)
    add_blob(cells, 17, 29, 6, 3)
    add_blob(cells, 48, 7, 5, 4)
    add_blob(cells, 11, 32, 4, 2)
    add_blob(cells, 49, 30, 5, 3)

    # Diagonal stair-step ridges.
    for i in range(9):
        add_rect(cells, 6 + i * 2, 27 - i, 4, 2)
        add_rect(cells, 46 + i, 11 + i, 4, 2)

    # Isolated single-cell islands used to exercise mask 15.
    for isolated in [(28, 6), (37, 7), (48, 22), (15, 14), (26, 32), (55, 6)]:
        add_cell(cells, *isolated)

    # Keep the spawn area and camera corridors open.
    remove_blob(cells, 6, 6, 3, 3)
    remove_blob(cells, 56, 32, 3, 2)
    fill_unreachable_open_cells(cells, (6, 6))
    return cells


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


def main() -> int:
    cells = build_solid_cells()
    map_data = {
        "id": "cave_tileset_test_01",
        "version": 1,
        "purpose": "Organic stress-test map for cave terrain tiles: winding tunnels, jagged edges, pillars, isolated islands, pockets, and diagonal stair-step terrain.",
        "units": {
            "tile_size_px": TILE_SIZE,
            "width_tiles": WIDTH,
            "height_tiles": HEIGHT,
        },
        "legend": {
            "water": "Open swimmable space",
            "solid": "Collision terrain authored on the 32px grid",
            "background": "Non-collision depth silhouette",
            "spawn": "Player/camera reference start",
            "salvage": "Stress-test collectible marker",
            "hazard": "Stress-test hazard marker",
            "marker": "Non-gameplay annotation",
        },
        "terrain": row_run_terrain(cells),
        "zones": [
            {
                "id": "winding_tunnel_focus",
                "type": "marker",
                "x": 20,
                "y": 8,
                "w": 25,
                "h": 23,
                "intent": "Exercises inner corners, jagged edges, and winding passage readability.",
            },
            {
                "id": "pillar_island_focus",
                "type": "marker",
                "x": 4,
                "y": 4,
                "w": 56,
                "h": 30,
                "intent": "Exercises pillars, isolated cells, and diagonal stair-step edges.",
            },
        ],
        "background": [
            {"id": "stress_bg_left", "type": "background", "x": 7, "y": 9, "w": 12, "h": 18},
            {"id": "stress_bg_right", "type": "background", "x": 46, "y": 11, "w": 11, "h": 17},
        ],
        "entities": [
            {"id": "player_start", "type": "spawn", "x": 6, "y": 6, "facing": "right"},
            {"id": "salvage_isolated_island", "type": "salvage", "x": 28, "y": 5, "kind": "stress_marker"},
            {"id": "salvage_winding_tunnel", "type": "salvage", "x": 32, "y": 19, "kind": "stress_marker"},
            {"id": "salvage_lower_island", "type": "salvage", "x": 45, "y": 27, "kind": "stress_marker"},
            {"id": "hazard_pillar_gap", "type": "hazard", "x": 8, "y": 17, "kind": "stress_marker"},
            {"id": "hazard_right_pillar", "type": "hazard", "x": 49, "y": 20, "kind": "stress_marker"},
        ],
        "camera_tests": [
            {
                "id": "tileset_overview",
                "center_x": 32,
                "center_y": 19,
                "zoom": 0.55,
                "intent": "Whole-map stress overview for organic cave shape readability.",
            },
            {
                "id": "winding_tunnel_view",
                "center_x": 36,
                "center_y": 18,
                "zoom": 0.85,
                "intent": "Inner corners and winding carved tunnel stress test.",
            },
            {
                "id": "pillars_islands_view",
                "center_x": 17,
                "center_y": 22,
                "zoom": 0.85,
                "intent": "Pillars, isolated islands, and diagonal stair-step terrain stress test.",
            },
        ],
        "review_questions": [
            "Do pillars and isolated islands render without stretched art?",
            "Do diagonal stair-step edges read as intentional cave terrain?",
            "Does repeated terrain remain acceptable at gameplay camera scale?",
            "Are winding tunnels readable without changing collision or source topology?",
        ],
    }

    MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    MAP_PATH.write_text(json.dumps(map_data, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {MAP_PATH.relative_to(ROOT)} with {len(map_data['terrain'])} solid row runs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
