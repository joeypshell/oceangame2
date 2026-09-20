"""Focused LE07 integration gates plus retained Marl/pause regression owners."""


def source_gates(gate, python_command):
    return [
        gate("creatures: Living Expedition 07 schema fixtures", python_command("tools/test_living_expedition_07_contract.py")),
        gate("creatures: Living Expedition 07 source", python_command("tools/test_production_level_01_living_expedition_07.py")),
    ]


def runtime_gates(gate, godot):
    scripts = [
        ("silt_hound_companion", []),
        ("silt_hound_excavate", []),
        ("silt_hound_journey_guidance", []),
        ("marl_refuge", []),
        ("marl_memory_night", []),
        ("marl_ground_pin", []),
        ("living_expedition_05_journey", ["--review-checkpoint=living_expedition_05_start"]),
        ("living_expedition_05_checkpoint_runtime", ["--review-checkpoint=living_expedition_05_excavate_ready"]),
        ("companion_command_tactical_pause", ["--review-checkpoint=living_expedition_04_start"]),
    ]
    scripts.extend(
        ("living_expedition_07_checkpoint_runtime", [f"--review-checkpoint=living_expedition_07_{state}", "--show-mobile-controls"])
        for state in ("refuge", "night", "pin")
    )
    scripts.append(("living_expedition_07_journey", [
        "--smoke-living-expedition-07", "--review-checkpoint=living_expedition_07_refuge", "--show-mobile-controls",
    ]))
    return [
        gate(
            f"smoke: {script}" + (f" {args[0]}" if args else ""),
            [godot, "--headless", "--path", ".", "--fixed-fps", "60", "--script",
             f"res://scripts/main/smoke/smoke_{script}.gd", "--", *args],
            godot_backed=True, fail_on_godot_error=True,
        )
        for script, args in scripts
    ]
