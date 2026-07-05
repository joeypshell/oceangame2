#!/usr/bin/env python3
"""Compare authored greybox JSON terrain with Godot's runtime map output."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MAPS = [
    ROOT / "maps" / "cave_salvage_organic_01.greybox.json",
    ROOT / "maps" / "cave_salvage_test_01.greybox.json",
    ROOT / "maps" / "cave_tileset_test_01.greybox.json",
    ROOT / "maps" / "full_cave_sketch_01.greybox.json",
    ROOT / "maps" / "production_slice_01.greybox.json",
]
WINDOWS_GODOT_CANDIDATES = [
    Path(r"C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"),
    Path(r"C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"),
]


def rect_cells(item: dict) -> set[tuple[int, int]]:
    return {
        (x, y)
        for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
    }


def expected_solid_cells(map_data: dict) -> set[tuple[int, int]]:
    solid: set[tuple[int, int]] = set()
    for terrain in map_data.get("terrain", []):
        if terrain.get("type") == "solid":
            solid.update(rect_cells(terrain))
    return solid


def resolve_godot(requested: str | None) -> str:
    if requested:
        return requested
    env_path = os.environ.get("GODOT_EXE")
    if env_path:
        return env_path
    for candidate in WINDOWS_GODOT_CANDIDATES:
        if candidate.exists():
            return str(candidate)
    return "godot"


def to_res_path(path: Path) -> str:
    absolute = path.resolve()
    try:
        relative = absolute.relative_to(ROOT)
    except ValueError as exc:
        raise ValueError(f"{absolute} is not inside {ROOT}") from exc
    return "res://" + relative.as_posix()


def parse_cell_rows(rows: list[list[int]]) -> set[tuple[int, int]]:
    return {(int(row[0]), int(row[1])) for row in rows}


def sample(cells: set[tuple[int, int]], limit: int = 12) -> list[tuple[int, int]]:
    return sorted(cells, key=lambda cell: (cell[1], cell[0]))[:limit]


def run_godot_parity(godot: str, map_path: Path) -> tuple[dict, str]:
    with tempfile.NamedTemporaryFile(prefix="oceangame2-parity-", suffix=".json", delete=False) as handle:
        report_path = Path(handle.name)

    command = [
        godot,
        "--headless",
        "--path",
        str(ROOT),
        "--quit-after",
        "1",
        "--check-map-parity",
        f"--map-path={to_res_path(map_path)}",
        f"--parity-output={report_path.as_posix()}",
    ]
    completed = subprocess.run(command, cwd=ROOT, text=True, capture_output=True, check=False)
    output = completed.stdout + completed.stderr
    if completed.returncode != 0:
        raise RuntimeError(f"Godot parity command failed for {map_path}:\n{output}")
    if "SCRIPT ERROR" in output or "ERROR:" in output:
        raise RuntimeError(f"Godot reported errors for {map_path}:\n{output}")

    try:
        with report_path.open("r", encoding="utf-8") as handle:
            return json.load(handle), output
    finally:
        report_path.unlink(missing_ok=True)


def check_map(godot: str, map_path: Path) -> list[str]:
    with map_path.open("r", encoding="utf-8") as handle:
        map_data = json.load(handle)

    expected = expected_solid_cells(map_data)
    report, godot_output = run_godot_parity(godot, map_path)
    failures: list[str] = []

    expected_id = str(map_data.get("id", ""))
    if str(report.get("map_id", "")) != expected_id:
        failures.append(f"map id mismatch: JSON {expected_id!r}, Godot {report.get('map_id')!r}")

    units = map_data["units"]
    expected_tile_size = int(units["tile_size_px"])
    expected_width = int(units["width_tiles"])
    expected_height = int(units["height_tiles"])
    if int(report.get("tile_size_px", -1)) != expected_tile_size:
        failures.append(f"tile size mismatch: JSON {expected_tile_size}, Godot {report.get('tile_size_px')}")
    if int(report.get("width_tiles", -1)) != expected_width:
        failures.append(f"width mismatch: JSON {expected_width}, Godot {report.get('width_tiles')}")
    if int(report.get("height_tiles", -1)) != expected_height:
        failures.append(f"height mismatch: JSON {expected_height}, Godot {report.get('height_tiles')}")

    terrain = parse_cell_rows(report.get("terrain_cells", []))
    missing_terrain = expected - terrain
    extra_terrain = terrain - expected
    if missing_terrain:
        failures.append(f"missing terrain cells: {len(missing_terrain)} sample {sample(missing_terrain)}")
    if extra_terrain:
        failures.append(f"extra terrain cells: {len(extra_terrain)} sample {sample(extra_terrain)}")

    collision = parse_cell_rows(report.get("collision_cells", []))
    missing_collision = expected - collision
    extra_collision = collision - expected
    if missing_collision:
        failures.append(f"missing collision cells: {len(missing_collision)} sample {sample(missing_collision)}")
    if extra_collision:
        failures.append(f"extra collision cells: {len(extra_collision)} sample {sample(extra_collision)}")

    if failures:
        failures.insert(0, f"{map_path.relative_to(ROOT)} failed parity check. Godot output:\n{godot_output}")
    else:
        print(
            f"{map_data['id']} parity passed: "
            f"{len(expected)} terrain cells, {len(report.get('collision_rects', []))} collision rects."
        )
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("maps", nargs="*", type=Path, default=DEFAULT_MAPS)
    parser.add_argument("--godot", help="Path to a Godot executable. Defaults to GODOT_EXE, local Windows path, or godot.")
    args = parser.parse_args()

    godot = resolve_godot(args.godot)
    failures: list[str] = []
    for map_path in args.maps:
        resolved_map = map_path if map_path.is_absolute() else ROOT / map_path
        failures.extend(check_map(godot, resolved_map))

    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
