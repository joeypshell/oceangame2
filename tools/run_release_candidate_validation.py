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
    "maps/production_level_01.greybox.json",
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
        Gate("progression: graph fixtures", python_command("tools/test_progression_graph.py")),
        Gate("progression: source graph audit", python_command("tools/audit_progression_graph.py")),
        Gate("creatures: living expedition schema fixtures", python_command("tools/test_validate_living_expedition_schema.py")),
        Gate("creatures: Living Expedition 04 relationship fixtures", python_command("tools/test_living_expedition_04_contract.py")),
        Gate("creatures: Living Expedition 05 schema fixtures", python_command("tools/test_living_expedition_05_contract.py")),
        Gate("creatures: Living Expedition 06 schema fixtures", python_command("tools/test_living_expedition_06_contract.py")),
        Gate("creatures: progression graph fixtures", python_command("tools/test_progression_graph_creatures.py")),
        Gate("creatures: Living Expedition 03 source", python_command("tools/test_production_level_01_living_expedition_03.py")),
        Gate("creatures: Living Expedition 04 source", python_command("tools/test_production_level_01_living_expedition_04.py")),
        Gate("creatures: Living Expedition 06 source", python_command("tools/test_production_level_01_living_expedition_06.py")),
        Gate("assets: manifest paths", python_command("tools/check_asset_manifest.py")),
        Gate("maps: current gate validator tests", python_command("tools/test_validate_current_gates.py")),
        Gate("maps: hostile encounter validator tests", python_command("tools/test_validate_hostile_encounters.py")),
        Gate("maps: material source validator tests", python_command("tools/test_validate_material_sources.py")),
        Gate("maps: progression container validator tests", python_command("tools/test_validate_progression_containers.py")),
        Gate("maps: regional journey validator tests", python_command("tools/test_validate_regional_journeys.py")),
        Gate("maps: deeper wreck validator tests", python_command("tools/test_validate_deeper_wreck_return.py")),
        Gate("maps: Expansion 16 source tests", python_command("tools/test_production_level_01_expansion_16.py")),
        Gate("maps: Expansion 14 contract validator tests", python_command("tools/test_validate_expansion_14_contract.py")),
        Gate("maps: pressure return validator tests", python_command("tools/test_validate_pressure_return.py")),
        Gate("maps: southeast wreck validator tests", python_command("tools/test_validate_southeast_wreck_return.py")),
        Gate("maps: tool-target reward validator tests", python_command("tools/test_validate_tool_target_rewards.py")),
        Gate("maps: survey target validator tests", python_command("tools/test_validate_survey_targets.py")),
        Gate("maps: regional journey footprint", python_command("tools/validate_regional_journeys.py", "maps/production_level_01.greybox.json")),
        Gate("maps: deeper wreck contract", python_command("tools/validate_deeper_wreck_return.py", "maps/production_level_01.greybox.json")),
        Gate("maps: pressure return contract", python_command("tools/validate_pressure_return.py", "maps/production_level_01.greybox.json")),
        Gate("maps: southeast wreck contract", python_command("tools/validate_southeast_wreck_return.py", "maps/production_level_01.greybox.json")),
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
        ("smoke: pass 26 result presentation", ["--quit-after", "1", "--smoke-pass-26-result-presentation"]),
        ("smoke: primary dive completion", ["--smoke-primary-dive-completion"]),
        ("smoke: release journey", ["--quit-after", "1", "--smoke-release-journey"]),
        ("smoke: anomaly survey journey", ["--smoke-anomaly-survey-journey"]),
        ("smoke: expedition day", ["--smoke-expedition-day"]),
        ("smoke: expansion 03 material project", ["--quit-after", "1", "--smoke-expansion-03-material-project"]),
        ("smoke: expansion 04 current pocket", ["--quit-after", "1", "--smoke-expansion-04-current-pocket"]),
        ("smoke: expansion 05 practical research", ["--quit-after", "1", "--smoke-expansion-05-practical-research"]),
        ("smoke: expansion 06 combat foundation", ["--quit-after", "1", "--smoke-expansion-06-combat-foundation"]),
        ("smoke: expansion 07 biological progression", ["--quit-after", "1", "--smoke-expansion-07-biological-progression"]),
        ("smoke: expansion 08 daily condition journey", ["--quit-after", "1", "--smoke-expansion-08-daily-condition-journey"]),
        ("smoke: expansion 09 full-level journey", ["--smoke-expansion-09-full-level-journey"]),
        ("smoke: expansion 10 regional journey", ["--smoke-expansion-10-regional-journey"]),
        ("smoke: expansion 11 light return", ["--smoke-expansion-11-deep-harmonic-light-return"]),
        ("smoke: expansion 12 pressure return", ["--smoke-expansion-12-abyssal-pressure-return"]),
        ("smoke: expansion 13 southeast wreck return", ["--smoke-expansion-13-southeast-wreck-return"]),
        ("smoke: expansion 13 scanner-cutter correction", ["--smoke-expansion-13-scanner-cutter-correction"]),
        ("smoke: expansion 14 archive-current return", ["--smoke-expansion-14-archive-current-return"]),
        ("smoke: expansion 15 expedition planning", ["--smoke-expansion-15-expedition-planning"]),
        ("smoke: expansion 16 deeper wreck", ["--smoke-expansion-16-deeper-wreck"]),
        ("smoke: expansion 17 wreck network", ["--smoke-expansion-17-wreck-network"]),
        ("smoke: active-tool selection", ["--smoke-active-tool-selection"]),
        ("smoke: pass 18 progression", ["--quit-after", "1", "--smoke-pass-18-progression"]),
        ("smoke: pass 19 cargo upgrade", ["--quit-after", "1", "--smoke-pass-19-cargo-upgrade"]),
        ("smoke: pass 20 durable-light compatibility", ["--quit-after", "1", "--smoke-pass-20-light-upgrade"]),
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
            "smoke: material runtime state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_material_runtime_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: material sprite assets",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_material_sprite_assets.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: material project state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_material_project_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: durable light project state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_durable_light_project_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: pressure suit project state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_pressure_suit_project_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: pressure zone state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_pressure_zone_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: oxygen consumption zone state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_oxygen_consumption_zone_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Expansion 16 integration state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_expansion_16_integration_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: companion profile state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_companion_profile_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Signal Reef journey profile state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_signal_reef_journey_profile_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: companion ecology observation",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_companion_ecology_observation.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Spark Ray riding",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_spark_ray_riding.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Anchor Fins payoff",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_anchor_fins_payoff.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Guardian Pulse payoff",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_guardian_pulse_payoff.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Veil Cuttle Drift Lens",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_veil_cuttle_drift_lens.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Veil Cuttle hostile intent",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_veil_cuttle_hostile_intent.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Living Expedition 01 journey",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_living_expedition_01_journey.gd", "--review-checkpoint=living_expedition_01_start"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Living Expedition 02 journey",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_two_species_sortie_integration.gd", "--review-checkpoint=living_expedition_02_start"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Living Expedition 03 journey",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_living_expedition_03_integration.gd", "--review-checkpoint=living_expedition_03_start"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Living Expedition 04 journey",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_living_expedition_04_journey.gd", "--review-checkpoint=living_expedition_04_start"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: player health state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_player_health_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: combat runtime state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_combat_runtime_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: mobile test controls",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_mobile_test_controls.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: cutter salvage state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_cutter_salvage_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: sealed wreck reward state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_sealed_wreck_reward_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: Expansion 14 runtime owners",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_expansion_14_runtime_owners.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: held cargo HUD",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_held_cargo_hud.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: current stabilizer project state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_current_stabilizer_project_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: current stabilizer gate state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_current_stabilizer_gate_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: current pocket feedback state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_current_pocket_feedback_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: practical research state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_practical_research_state.gd"],
            godot_backed=True,
            fail_on_godot_error=True,
        ),
        Gate(
            "smoke: practical research material state",
            [godot, "--headless", "--path", ".", "--script", "res://scripts/main/smoke/smoke_practical_research_material_state.gd"],
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
