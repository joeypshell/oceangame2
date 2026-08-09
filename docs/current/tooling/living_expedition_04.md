# Living Expedition 04 Evidence

Use the isolated `living_expedition_04_start` checkpoint for the companion-shaped
territorial-eel encounter. It loads `production_level_01` on Day 3 with Mica's
Drift Lens, Kite's Guardian Pulse, and the Shock Prod available. It does not
read or write the normal durable profile.

## Local Review

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --review-checkpoint=living_expedition_04_start
```

## Deterministic Journey

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_04_journey.gd --review-checkpoint=living_expedition_04_start
```

The journey proves Mica's read-only intent projection, Guardian Pulse's
non-damaging opening, ordinary retreat, Shock Prod defeat, explicit harvest,
cargo pressure, banking, failure restoration, connector reload, and fresh-day
restoration without changing access or the guarded cache.

## Focused Visual Review

Run the non-headless capture runner, then check its ignored output:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_04_capture_runner.gd --review-checkpoint=living_expedition_04_start
python tools/check_living_expedition_04_captures.py
```

It writes four desktop `1280x720` and four landscape-mobile `844x390` frames
under `visual_captures/living_expedition_04/`: Mica intent, Guardian opening,
Shock Prod damage, and defeated-eel harvest availability. The runner verifies
the encounter subjects, status feedback, active-tool hotbar, and mobile dive
controls remain inside the canvas. Generated captures are review evidence only
and remain ignored; this command does not accept or replace baselines.
