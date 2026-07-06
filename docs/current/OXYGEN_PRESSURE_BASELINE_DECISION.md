# Oxygen Pressure Baseline Decision

Date: 2026-07-06

Issue: #113 `Record oxygen pressure baseline decision`
Implementation issue: #112 `Tune oxygen pressure thresholds and warning timing`

## Decision

Accept the #112 oxygen pressure timing as the current prototype baseline for Controlled Gameplay Pass 02.

Accepted runtime values:

- `OXYGEN_MAX_SECONDS`: `90.0`
- `OXYGEN_REFILL_SECONDS_PER_SECOND`: `25.0`
- `OXYGEN_LOW_WARNING_SECONDS`: `35.0`
- `OXYGEN_CRITICAL_WARNING_SECONDS`: `12.0`

## Reviewed Behavior

The 90-second tank remains intentionally generous for the current prototype. The tuning change is about warning timing, not making the first route-choice pass punishing.

The new route-choice probe returned from the lower-loop target with `31.9` seconds remaining. With the `LOW` threshold at `35` seconds, that deeper route now reads as pressured near return without forcing a fail state. The `CRITICAL` threshold at `12` seconds gives the overlay a final escalation before depletion.

Expected behavior for future agents:

- Nearby salvage remains comfortable.
- The lower-loop route-choice target creates mild oxygen pressure.
- Returning to extraction refills oxygen using the existing refill behavior.
- Depletion still surfaces the player, restores held/unbanked salvage to the map, and refills oxygen to max.

## Verification

Oxygen pressure smoke:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
```

Result:

```text
Oxygen pressure smoke passed: depleted, surfaced, restored salvage, refilled, and banked salvage.
```

Route-choice probe:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-route-choice
```

Result:

```text
Route choice probe passed: target=salvage_lower_loop collected=1 banked=2 returned_to=boat extraction run_complete=false oxygen=31.9.
```

Additional checks run for #112:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

## Scope Confirmation

This decision accepts only oxygen timing and overlay warning labels. It does not change or accept changes to:

- map source data
- terrain/collision generation
- route topology
- salvage placement or value
- player movement constants
- player collision shape
- hazard behavior
- extraction semantics
- accepted visual baselines
- public Web preview deployment state

## Follow-Up

Continue with #114 to add salvage value tiers to the map schema and validation. If manual play review later finds the 35-second `LOW` threshold too early or too late after the risk/reward placement lands, create a separate tuning issue rather than reopening this baseline decision.
