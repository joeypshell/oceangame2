# Pass 27 Movement Reversal Evaluation

Date: 2026-07-09

Issue: #605
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

Do not change movement tuning for Pass 27.

The direction-change flash is best treated as a rendering/frame-sampling issue after #603, and #604 addressed it by clipping the active swim-sheet frame on the player body sprite. The movement-feel smoke still reports the accepted baseline values, so changing acceleration, deceleration, speed, route timing, oxygen pressure, or traversal feel would add unnecessary drift.

## Current Movement Values

- `swim_speed`: `200 px/s`
- `acceleration`: `620 px/s^2`
- `deceleration`: `900 px/s^2`
- Collision rectangle: `26x18 px`

These remain the accepted movement-feel baseline from `docs/current/MOVEMENT_FEEL_BASELINE_DECISION.md`.

## Observed Reversal Behavior

The current movement-feel smoke drives the real player controller through:

- right-input start
- release/stop
- horizontal reversal to the left
- diagonal movement

The probe output remains:

```text
Movement feel probe passed: start=(155.0, 0.0) stop=(0.0, 0.0) reverse=(-200.0, 0.0) diagonal=(109.6, -109.6).
```

This confirms reversal reaches the expected leftward velocity and diagonal movement remains normalized.

## Facing Check

The player-facing smoke also passes after the #604 frame-clipping fix:

```text
Player facing smoke passed: root scale stayed stable while visual children flipped left/right with 4-frame swim sheet.
```

This confirms the root transform stays stable while `Body` and `LightCone` visuals flip.

## Scope Confirmation

No movement constants changed in this issue. No route, map, oxygen, cargo, salvage, objective, camera, collision, baseline, or Web export behavior changed.

If manual review later still shows a direction-change artifact, continue with #606 and #607 to strengthen repeated-reversal smoke/capture coverage before considering movement tuning.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
python tools/check_file_lengths.py
git diff --check
```
