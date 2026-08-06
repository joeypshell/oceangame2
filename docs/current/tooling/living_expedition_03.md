# Living Expedition 03 Evidence

Use the isolated `living_expedition_03_start` checkpoint for the Mica ecology
journey. It loads `production_level_01` on Day 2 with Kite and Mica committed,
Mica selected, the Scanner available, and the southwest bloom active. It never
reads or writes the normal durable profile.

## Local Review

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_03_start
```

## Deterministic Journey

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_03_integration.gd
```

The journey separates Reveal Trace from held Scanner identification, preserves
oxygen/daylight/hazard pressure, discards only pending state on failure,
commits Followed the Bloom exactly once at the boat, consolidates Drift Lens at
night, restores it after reload, and proves Read Drift against conditional and
unconditional patrols without reward, access, or topology changes.

## Focused Visual Review

Run the non-headless capture runner, then check its ignored output:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_03_capture_runner.gd --review-checkpoint=living_expedition_03_start
python tools/check_living_expedition_03_captures.py
```

It writes six desktop `1280x720` and six landscape-mobile `844x390` frames
under `visual_captures/living_expedition_03/`. The runner verifies mobile
controls, the held Scanner card, and the night result panel remain bounded and
non-overlapping. Generated captures are review evidence only and remain
ignored; this command does not accept or replace production baselines.
