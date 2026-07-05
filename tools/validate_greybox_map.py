#!/usr/bin/env python3
"""Validate basic greybox map reachability from the player spawn."""

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

    spawn_entities = [entity for entity in map_data.get("entities", []) if entity.get("type") == "spawn"]
    if len(spawn_entities) != 1:
        print(f"Expected exactly one spawn entity, found {len(spawn_entities)}.")
        return 1

    spawn = (int(spawn_entities[0]["x"]), int(spawn_entities[0]["y"]))
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

    failures: list[str] = []
    for entity in map_data.get("entities", []):
        point = (int(entity["x"]), int(entity["y"]))
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

    print(f"{map_data['id']} passed reachability validation from spawn {spawn}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
