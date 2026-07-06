# Movement-Feel Baseline Decision

Date: 2026-07-06

Issue: #104 `Record movement-feel validation decision`

## Decision

The Controlled Gameplay Pass 01 movement-feel tuning from #103 is accepted as the current prototype movement baseline.

Accepted constants:

- `swim_speed`: `200 px/s`
- `acceleration`: `620 px/s^2`
- `deceleration`: `900 px/s^2`

## Reviewed Behavior

The accepted tuning keeps route traversal at the existing top speed while making start and reversal less abrupt than the previous `820 px/s^2` acceleration. Deceleration remains quick enough that releasing input settles the diver without a long slide.

Expected behavior for future agents:

- Movement starts below full speed during the first review window, instead of immediately snapping to max speed.
- Releasing input settles the diver quickly.
- Horizontal reversal remains readable and keeps the player root transform stable.
- Diagonal movement remains normalized and does not change collision size, map data, or route topology.

## Verification

Movement-feel probe:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
```

Result:

```text
Movement feel probe passed: start=(155.0, 0.0) stop=(0.0, 0.0) reverse=(-200.0, 0.0) diagonal=(109.6, -109.6).
```

Player-facing smoke:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
```

Result:

```text
Player facing smoke passed: root scale stayed stable while visual children flipped left/right.
```

Additional #103 verification already confirmed salvage-loop, hazard-interaction, oxygen-pressure, and production-slice route smokes for slices 01-04 after the tuning change.

## Scope Confirmation

This decision accepts only the movement constants and the movement-feel probe behavior. It does not accept or change:

- map source data
- terrain/collision generation
- player collision shape
- player sprite art
- camera framing
- salvage, hazard, oxygen, extraction, or reset semantics
- accepted visual baselines

## Follow-Up

No immediate movement-feel follow-up is required. Continue with the planned salvage/oxygen feedback readability pass unless manual play review finds a concrete movement regression.
