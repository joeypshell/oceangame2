# Controlled Gameplay Pass 01 Plan

Date: 2026-07-06

Issue: #101 `Plan Controlled Gameplay Pass 01 for movement feel`

## Decision

Controlled Gameplay Pass 01 will tune player movement feel and readability.

This is not a new systems pass. It should make the existing diver easier to steer and visually read while preserving the current source-map, collision, camera, salvage, hazard, oxygen, and visual-baseline contracts.

## Single Target

Improve the feel of:

- acceleration from rest
- deceleration when input stops
- reversal when changing horizontal direction
- diagonal movement readability

The pass should keep the player responsive enough for narrow production-slice routes while avoiding abrupt direction snaps or renewed double-facing artifacts.

## Affected Areas

- `scripts/player/player_controller.gd`
- `scenes/player/Player.tscn` only if exported movement constants or review-only helpers need scene defaults
- `scripts/main.gd` only for a focused probe, smoke, or capture hook
- `tools/` only if a small deterministic movement-feel checker is needed
- `docs/current/PROJECT_CONTEXT.md` and the follow-up movement decision doc

## Untouched Areas

- `maps/*.greybox.json`
- terrain/collision source data and rendering
- player collision shape unless a future issue explicitly scopes collision clearance
- player sprite art, boat art, prop art, terrain atlas, and background art
- camera framing and production-slice camera tests
- salvage, hazard, oxygen, extraction, and reset semantics
- accepted visual baselines until a separate review issue approves changes

## Expected Behavior Changes

- Starting movement should feel deliberate but not sluggish.
- Releasing input should settle the diver without a long slide.
- Reversing direction should feel readable and should keep the root transform stable.
- Diagonal movement should remain normalized and should not make routes easier or harder by changing collision behavior.

## Unacceptable Drift

- Any map topology, route, salvage placement, hazard placement, or extraction change.
- Any collision change not explicitly planned in a new issue.
- Any return of the direction-change double-facing flash fixed by #98.
- Any visual baseline update folded into the implementation issue.
- Any new gameplay system such as stamina, upgrades, enemies, inventory, or health.

## Follow-Up Issues

- #102 `Add focused movement-feel capture or probe path`
- #103 `Tune player swim acceleration, deceleration, and turn feel`
- #104 `Record movement-feel validation decision`

## Verification Plan

The implementation chain should use:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-oxygen-pressure
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

After #102 adds a focused movement-feel probe or capture, #103 should use that check before and after tuning.
