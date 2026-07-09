#!/usr/bin/env python3
"""Run the Simple Diver Game release-candidate validation gates."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GODOT_ERROR_MARKERS = ("SCRIPT ERROR", "ERROR:")
WINDOWS_GODOT_CANDIDATES = (
    Path(r"C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"),
    Path(r"C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe"),
)

MAPS = (
    "maps/cave_salvage_test_01.greybox.json",
    "maps/cave_salvage_organic_01.greybox.json",
    "maps/cave_tileset_test_01.greybox.json",
    "maps/full_cave_sketch_01.greybox.json",
    "maps/production_slice_01.greybox.json",
    "maps/production_slice_02.greybox.json",
    "maps/production_slice_03.greybox.json",
    "maps/production_slice_04.greybox.json",
)


@dataclass(frozen=True)
class Gate:
    name: str
    command: list[str]
    godot_backed: bool = False
    fail_on_godot_error: bool = False


def python_command(script: str, *args: str) -> list[str]:
    return [sys.executable, script, *args]


def resolve_godot(requested: str | None) -> str | None:
    if requested:
        return requested
    env_path = os.environ.get("GODOT_EXE") or os.environ.get("GODOT_BIN")
    if env_path:
        return env_path
    for candidate in WINDOWS_GODOT_CANDIDATES:
        if candidate.exists():
            return str(candidate)
    return shutil.which("godot")


def base_gates() -> list[Gate]:
    gates = [
        Gate("repo hygiene: file lengths", python_command("tools/check_file_lengths.py")),
        Gate("repo hygiene: whitespace", ["git", "diff", "--check"]),
        Gate("assets: manifest paths", python_command("tools/check_asset_manifest.py")),
        Gate("captures: production slice inventory", python_command("tools/check_production_slice_captures.py")),
        Gate(
            "visual baselines: accepted dirs clean",
            python_command("tools/manage_production_slice_baseline.py", "check-clean", "--all-slices"),
        ),
    ]
    for map_path in MAPS:
        gates.append(
            Gate(
                f"maps: validate {Path(map_path).name}",
                python_command("tools/validate_greybox_map.py", map_path),
            )
        )
    return gates


def godot_gates(godot: str) -> list[Gate]:
    smoke_flags = (
        ("smoke: salvage loop", ["--quit-after", "1", "--smoke-salvage-loop"]),
        ("smoke: cargo capacity", ["--quit-after", "1", "--smoke-cargo-capacity"]),
        ("smoke: oxygen pressure", ["--quit-after", "1", "--smoke-oxygen-pressure"]),
        ("smoke: hazard pressure", ["--smoke-hazard-pressure"]),
        ("smoke: safe/deep route choice", ["--smoke-safe-deep-route-choice"]),
        ("smoke: route outcome result", ["--quit-after", "1", "--smoke-route-outcome-result"]),
        ("smoke: primary dive completion", ["--smoke-primary-dive-completion"]),
        ("smoke: pass 18 progression", ["--quit-after", "1", "--smoke-pass-18-progression"]),
        ("smoke: pass 19 cargo upgrade", ["--quit-after", "1", "--smoke-pass-19-cargo-upgrade"]),
        ("smoke: pass 20 light upgrade", ["--quit-after", "1", "--smoke-pass-20-light-upgrade"]),
        ("smoke: pass 27 facing transitions", ["--smoke-pass-27-facing-transitions"]),
    )

    gates = [
        Gate(
            "godot: import assets",
            [godot, "--headless", "--path", ".", "--import"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "godot: headless startup",
            [godot, "--headless", "--path", ".", "--quit-after", "1"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "maps: Godot terrain/collision parity",
            python_command("tools/check_map_parity.py", "--godot", godot),
            godot_backed=True,
        ),
    ]
    for name, args in smoke_flags:
        gates.append(
            Gate(
                name,
                [godot, "--headless", "--path", ".", *args],
                godot_backed=True,
                fail_on_godot_error=True,
            )
        )
    return gates


def display_command(command: list[str]) -> str:
    return " ".join(f'"{part}"' if " " in part else part for part in command)


def tail(text: str, limit: int = 30) -> str:
    lines = text.splitlines()
    return "\n".join(lines[-limit:])


def run_gate(gate: Gate) -> bool:
    print(f"\n==> {gate.name}")
    print(display_command(gate.command))
    completed = subprocess.run(gate.command, cwd=ROOT, text=True, capture_output=True, check=False)
    output = completed.stdout + completed.stderr
    if completed.returncode != 0:
        print(f"FAIL: exit {completed.returncode}")
        if output.strip():
            print(tail(output))
        return False
    if gate.fail_on_godot_error and any(marker in output for marker in GODOT_ERROR_MARKERS):
        print("FAIL: Godot reported SCRIPT ERROR or ERROR output")
        print(tail(output))
        return False
    print("PASS")
    return True


def print_gate_list(gates: list[Gate], skipped: list[Gate]) -> None:
    print("Release-candidate validation gates:")
    for index, gate in enumerate(gates, start=1):
        print(f"{index}. {gate.name}: {display_command(gate.command)}")
    if skipped:
        print("\nSkipped Godot-backed gates:")
        for gate in skipped:
            print(f"- {gate.name}: {display_command(gate.command)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", help="Path to the Godot executable. Defaults to GODOT_EXE/GODOT_BIN, common Windows path, then PATH.")
    parser.add_argument("--skip-godot", action="store_true", help="Skip Godot-backed parity, startup, and smoke gates.")
    parser.add_argument("--require-godot", action="store_true", help="Fail when Godot is unavailable instead of skipping Godot-backed gates.")
    parser.add_argument("--list", action="store_true", help="List the gates without running them.")
    args = parser.parse_args()

    godot = resolve_godot(args.godot)
    gates = base_gates()
    skipped: list[Gate] = []

    if args.skip_godot:
        skipped = godot_gates(args.godot or "<godot>")
    elif godot:
        gates.extend(godot_gates(godot))
    elif args.require_godot:
        print("FAIL: Godot executable was not found.", file=sys.stderr)
        return 2
    else:
        skipped = godot_gates("<godot>")
        print("Godot executable was not found; skipping Godot-backed parity/startup/smoke gates.")
        print("Set GODOT_EXE, GODOT_BIN, pass --godot, or use --require-godot for release gating.")

    if args.list:
        print_gate_list(gates, skipped)
        return 0

    failures = 0
    for gate in gates:
        if not run_gate(gate):
            failures += 1

    if skipped:
        print("\nSkipped Godot-backed gates:")
        for gate in skipped:
            print(f"- {gate.name}")

    if failures:
        print(f"\nFAIL: {failures} release-candidate validation gate(s) failed.")
        return 1
    print("\nPASS: release-candidate validation gates completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
