#!/usr/bin/env python3
"""Validate basic greybox map reachability from the player entry cell."""

from __future__ import annotations

import argparse
import json
from collections import deque
from pathlib import Path


def rect_cells(item: dict) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells


def neighbors(x: int, y: int) -> tuple[tuple[int, int], ...]:
    return ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))


def spawn_cell(entity: dict) -> tuple[int, int]:
    if entity.get("type") == "boat_spawn":
        return (int(entity["entry_x"]), int(entity["entry_y"]))
    return (int(entity["x"]), int(entity["y"]))


def validate_boat_spawn(entity: dict, solid: set[tuple[int, int]], width: int, height: int) -> list[str]:
    failures: list[str] = []
    required_fields = ("x", "y", "w", "h", "entry_x", "entry_y")
    for field in required_fields:
        if field not in entity:
            failures.append(f"{entity.get('id', 'boat_spawn')} is missing required boat_spawn field {field}.")
    if failures:
        return failures

    entry = spawn_cell(entity)
    if entry[0] < 0 or entry[1] < 0 or entry[0] >= width or entry[1] >= height:
        failures.append(f"{entity['id']} entry is outside map bounds at {entry}.")
        return failures
    if entry in solid:
        failures.append(f"{entity['id']} entry is inside solid terrain at {entry}.")

    boat_cells = rect_cells(entity)
    out_of_bounds = [
        cell for cell in boat_cells if cell[0] < 0 or cell[1] < 0 or cell[0] >= width or cell[1] >= height
    ]
    if out_of_bounds:
        failures.append(f"{entity['id']} boat extraction rectangle extends outside map bounds. Sample: {out_of_bounds[:4]}")
    if entry not in boat_cells:
        failures.append(f"{entity['id']} entry {entry} is outside the boat extraction rectangle.")
    if not boat_cells - solid:
        failures.append(f"{entity['id']} boat extraction rectangle has no open cells.")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", type=Path)
    args = parser.parse_args()

    with args.map_json.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)

    width = int(map_data["units"]["width_tiles"])
    height = int(map_data["units"]["height_tiles"])

    solid: set[tuple[int, int]] = set()
    for terrain in map_data.get("terrain", []):
        if terrain.get("type") == "solid":
            solid.update(rect_cells(terrain))

    spawn_entities = [
        entity for entity in map_data.get("entities", []) if entity.get("type") in ("spawn", "boat_spawn")
    ]
    if len(spawn_entities) != 1:
        print(f"Expected exactly one spawn or boat_spawn entity, found {len(spawn_entities)}.")
        return 1

    failures: list[str] = []
    if spawn_entities[0].get("type") == "boat_spawn":
        failures.extend(validate_boat_spawn(spawn_entities[0], solid, width, height))
    if failures:
        for failure in failures:
            print(failure)
        return 1

    spawn = spawn_cell(spawn_entities[0])
    if spawn in solid:
        print(f"Spawn {spawn_entities[0]['id']} is inside solid terrain at {spawn}.")
        return 1

    reachable: set[tuple[int, int]] = {spawn}
    queue: deque[tuple[int, int]] = deque([spawn])

    while queue:
        x, y = queue.popleft()
        for nx, ny in neighbors(x, y):
            if nx < 0 or ny < 0 or nx >= width or ny >= height:
                continue
            cell = (nx, ny)
            if cell in solid or cell in reachable:
                continue
            reachable.add(cell)
            queue.append(cell)

    open_cells = {(x, y) for y in range(height) for x in range(width) if (x, y) not in solid}
    unreachable = open_cells - reachable
    if unreachable:
        sample = sorted(unreachable)[:12]
        print(f"Found {len(unreachable)} unreachable open tiles. Sample: {sample}")
        return 1

    for entity in map_data.get("entities", []):
        point = spawn_cell(entity) if entity.get("type") == "boat_spawn" else (int(entity["x"]), int(entity["y"]))
        if point in solid:
            failures.append(f"{entity['id']} is inside solid terrain at {point}.")
        elif point not in reachable:
            failures.append(f"{entity['id']} is unreachable at {point}.")

    for zone in map_data.get("zones", []):
        if zone.get("type") == "marker":
            continue
        cells = rect_cells(zone)
        if not cells - solid:
            failures.append(f"{zone['id']} has no open cells.")
        elif not (cells & reachable):
            failures.append(f"{zone['id']} is unreachable.")

    if failures:
        for failure in failures:
            print(failure)
        return 1

    print(f"{map_data['id']} passed reachability validation from entry {spawn}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
