# Living Expedition 05 Evidence

Use the isolated `living_expedition_05_start` checkpoint for the Silt Hound
proof. It loads `production_level_01` on Day 4 with Kite and Mica committed,
Marl's lower-loop rescue unresolved, and the optional buried titanium mound
closed. It does not read or write the normal durable profile.

## Local Review

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_05_start
```

Review the Cutter rescue, return to the canonical boat, three-row habitat
selection, next-sortie Marl follow behavior, deliberate BOND Excavate command,
and normal typed-material pickup/banking boundaries.

## Deterministic Journey

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_05_journey.gd --review-checkpoint=living_expedition_05_start
```

The journey protects schema-v3 migration, rescue commitment, active selection,
the full Excavate phase sequence, cargo-full preservation, pickup, banking,
retry/oxygen/reload restoration, duplicate prevention, and diver equipment
gates.

## Focused Visual Review

Run the non-headless capture runner, then validate its ignored output:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_05_capture_runner.gd --review-checkpoint=living_expedition_05_start
python tools/check_living_expedition_05_captures.py
```

It writes ten desktop and ten landscape-mobile frames under
`visual_captures/living_expedition_05/`, spanning rescue through bankable
titanium. The runner verifies source/runtime state, subjects, HUDs, hotbar,
habitat/command panels, and mobile controls. These captures are review evidence
only and never accept or replace production baselines.
