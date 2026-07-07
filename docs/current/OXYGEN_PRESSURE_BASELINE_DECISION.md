# Oxygen Pressure Baseline Decision

Date: 2026-07-06
Updated: 2026-07-07

Issue: #113 `Record oxygen pressure baseline decision`
Implementation issue: #112 `Tune oxygen pressure thresholds and warning timing`
Pass 04 update: #143 `Tune oxygen thresholds for safe and deep route readability`

## Decision

Accept the #143 oxygen feedback timing as the current prototype baseline for Controlled Gameplay Pass 04. This updates the #112 warning thresholds using the safe/deep route comparison smoke, while keeping tank size and depletion/refill behavior unchanged.

Accepted runtime values:

- `OXYGEN_MAX_SECONDS`: `90.0`
- `OXYGEN_REFILL_SECONDS_PER_SECOND`: `25.0`
- `OXYGEN_LOW_WARNING_SECONDS`: `40.0`
- `OXYGEN_CRITICAL_WARNING_SECONDS`: `15.0`

## Reviewed Behavior

The 90-second tank remains intentionally generous for the current prototype. The tuning change is about warning readability, not making the first route-choice pass punishing.

The safe/deep comparison smoke now returns from the short safe route with about `79.8` seconds remaining and `comfortable` feedback. The deeper `expanded_route_choice` route returns with about `10.9` seconds remaining after showing both `LOW` and `CRITICAL` feedback. With the `LOW` threshold at `40` seconds and `CRITICAL` at `15` seconds, the deep route gets a clearer warning window while still finishing without arbitrary failure.

Expected behavior for future agents:

- Nearby salvage remains comfortable.
- The short `safe_route_choice` target remains comfortable.
- The deeper `expanded_route_choice` route creates visible `LOW` and `CRITICAL` pressure before return.
- Returning to extraction refills oxygen using the existing refill behavior.
- Depletion still surfaces the player, restores held/unbanked salvage to the map, and refills oxygen to max.

## Verification

Safe/deep route comparison smoke:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
```

Result:

```text
Safe/deep route comparison smoke passed: safe_targets=salvage_entry_shaft safe_cargo=1/2 safe_banked=1 safe_score=100 safe_oxygen=79.8 safe_feedback=comfortable deep_targets=salvage_lower_loop,salvage_deep_right_cache deep_cargo=2/2 deep_banked=2 deep_score=600 deep_oxygen=10.9 deep_feedback=LOW,CRITICAL.
```

Oxygen pressure smoke:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
```

Result:

```text
Oxygen pressure smoke passed: depleted, surfaced, restored salvage, refilled, and banked salvage.
```

Historical route-choice probe from #112:

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

Continue with the Pass 04 route-outcome result panel and review-capture issues. If manual play review later finds the 40-second `LOW` threshold or 15-second `CRITICAL` threshold too early or too late after visual route-outcome review, create a separate tuning issue rather than reopening this baseline decision.
