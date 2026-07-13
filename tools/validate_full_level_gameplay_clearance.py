#!/usr/bin/env python3
"""Validate transformed gameplay with the real player collision footprint."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict, deque
from pathlib import Path

from validate_full_level_traversal import (
    CollisionField,
    load_player_body,
    map_point,
    solid_cells,
)


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAP = ROOT / "maps" / "production_level_01.greybox.json"
POINT_SECTIONS = (
    "progression_containers",
    "moving_hazards",
    "hostile_encounters",
    "biological_resource_sources",
    "survey_targets",
    "entities",
)


def indexed_records(map_data: dict, section: str) -> dict[str, dict]:
    return {
        str(item["id"]): item
        for item in map_data.get(section, [])
        if "id" in item
    }


def tile_center(item: dict, tile_size: int) -> tuple[int, int]:
    return (
        round((float(item["x"]) + 0.5) * tile_size),
        round((float(item["y"]) + 0.5) * tile_size),
    )


def zone_candidates(item: dict, tile_size: int) -> set[tuple[int, int]]:
    return {
        (round((x + 0.5) * tile_size), round((y + 0.5) * tile_size))
        for y in range(int(item["y"]), int(item["y"]) + int(item.get("h", 1)))
        for x in range(int(item["x"]), int(item["x"]) + int(item.get("w", 1)))
    }


def required_point_groups(map_data: dict, tile_size: int) -> dict[str, set[tuple[int, int]]]:
    provenance = map_data.get("source", {}).get("gameplay_overlay", {})
    reused_ids = provenance.get("reused_ids", {})
    groups: dict[str, set[tuple[int, int]]] = {}

    zones = indexed_records(map_data, "zones")
    for record_id in reused_ids.get("zones", []):
        groups[f"zones:{record_id}"] = zone_candidates(zones[record_id], tile_size)

    for section in POINT_SECTIONS:
        records = indexed_records(map_data, section)
        for record_id in reused_ids.get(section, []):
            record = records[record_id]
            if "x" not in record or "y" not in record:
                continue
            groups[f"{section}:{record_id}"] = {map_point(record, tile_size)}
            if section == "moving_hazards":
                for index, point in enumerate(record.get("path", [])):
                    groups[f"{section}:{record_id}:path:{index}"] = {
                        tile_center(point, tile_size)
                    }
            if section == "hostile_encounters" and "territory" in record:
                territory = record["territory"]
                for point in zone_candidates(territory, tile_size):
                    groups[
                        f"{section}:{record_id}:territory:{point[0]},{point[1]}"
                    ] = {point}

    return groups


def reachable_group_failures(
    field: CollisionField,
    start: tuple[int, int],
    groups: dict[str, set[tuple[int, int]]],
) -> list[str]:
    point_labels: dict[tuple[int, int], set[str]] = defaultdict(set)
    failures: list[str] = []
    unresolved = set(groups)

    for label, candidates in groups.items():
        clear_candidates = {point for point in candidates if field.center_is_clear(point)}
        if not clear_candidates:
            failures.append(f"{label} has no player-footprint-clear candidate point")
            unresolved.discard(label)
            continue
        for point in clear_candidates:
            point_labels[point].add(label)

    if not field.center_is_clear(start):
        return [f"boat entry {start} is not player-footprint clear", *failures]

    visited = {start}
    queue = deque([start])
    while queue and unresolved:
        current = queue.popleft()
        unresolved.difference_update(point_labels.get(current, set()))
        for neighbor, _distance in field.neighbors(current):
            if neighbor in visited:
                continue
            visited.add(neighbor)
            queue.append(neighbor)

    failures.extend(
        f"{label} has no player-footprint route from the canonical boat"
        for label in sorted(unresolved)
    )
    return failures


def run_validation(map_path: Path) -> int:
    map_data = json.loads(map_path.read_text(encoding="utf-8"))
    units = map_data["units"]
    tile_size = int(units["tile_size_px"])
    boats = [
        item for item in map_data.get("entities", []) if item.get("type") == "boat_spawn"
    ]
    if len(boats) != 1:
        print(f"HOLD: expected one canonical boat; found {len(boats)}", file=sys.stderr)
        return 1

    field = CollisionField(
        int(units["width_tiles"]),
        int(units["height_tiles"]),
        tile_size,
        solid_cells(map_data),
        load_player_body(),
    )
    start = map_point(boats[0], tile_size, entry=True)
    groups = required_point_groups(map_data, tile_size)
    failures = reachable_group_failures(field, start, groups)
    if failures:
        for failure in failures:
            print(f"HOLD: {failure}", file=sys.stderr)
        return 1

    print(
        f"{map_data['id']} gameplay clearance PASS: {len(groups)} transformed "
        "positions/zones are player-footprint clear and boat-reachable."
    )
    print(
        "Direct return PASS: the collision-only swim graph is undirected and every "
        "validated route returns to surface_boat_entry."
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("map_json", nargs="?", type=Path, default=DEFAULT_MAP)
    args = parser.parse_args()
    map_path = args.map_json if args.map_json.is_absolute() else ROOT / args.map_json
    return run_validation(map_path)


if __name__ == "__main__":
    raise SystemExit(main())
