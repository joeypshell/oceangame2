# Pass 27 Player-Facing Reproduction Note

Date: 2026-07-09

Issue: #603
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

The reported player direction-change flash should be treated as a transient visual/rendering issue until proven otherwise.

Current automation verifies final facing state after reversals, but it does not inspect every rendered frame for a double-facing sprite overlap. Pass 27 should therefore continue with a small runtime/rendering fix and stronger transition coverage.

## Current Player Setup

- Scene: `scenes/player/Player.tscn`
- Controller: `scripts/player/player_controller.gd`
- Root node: `CharacterBody2D`
- Visual body node: `Body` (`Sprite2D`, 4 horizontal swim frames)
- Light node: `LightCone` (`Sprite2D`)
- Collision: `CollisionShape2D` with a `26x18` rectangle
- Facing state: `_facing_sign`
- Right/left visual state:
  - root `scale.x` stays `1.0`
  - `Body.flip_h` changes with facing
  - `LightCone.position.x` and `LightCone.scale.x` mirror with facing

## Existing Automated Checks

`--smoke-player-facing`:

- Drives right, left, then right through `swim_in_direction()`.
- Confirms root scale stays stable.
- Confirms `Body.flip_h`, `LightCone.position.x`, and `LightCone.scale.x` match the expected final facing state.
- Does not inspect rendered intermediate frames.

`--smoke-movement-feel`:

- Drives start, stop, horizontal reversal, and diagonal movement.
- Confirms velocities move in expected directions and diagonal speed remains normalized.
- Does not inspect sprite composition.

## Verification Run

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
```

Observed output:

```text
Player facing smoke passed: root scale stayed stable while visual children flipped left/right with 4-frame swim sheet.
Movement feel probe passed: start=(155.0, 0.0) stop=(0.0, 0.0) reverse=(-200.0, 0.0) diagonal=(109.6, -109.6).
```

## Manual Reproduction Path

1. Run the default production slice locally:

   ```powershell
   .\tools\open_godot_project.ps1 -Run
   ```

2. In an open-water area near the start, repeatedly alternate `A`/`D` or Left/Right while the diver is already moving.
3. Watch the diver body and light cone during reversal frames, not only after movement settles.
4. Treat any frame where the diver appears to show left-facing and right-facing silhouettes at once as a reproduction of the reported flash.

## Reproduction Status

- Headless state smokes: passing.
- Local manual preview: still the required reproduction surface for the reported flash.
- Focused capture: not present yet; #607 should add it.
- Web preview: not checked in this diagnostic issue; #609 should verify after the fix lands.

## Recommended Next Step

#604 should make the smallest rendering/facing-state fix that prevents a transient double-facing visual while preserving root transform, collision, movement constants, camera behavior, and gameplay semantics.

#606 should then extend automation beyond final-state checks so repeated reversals and body/light alignment are harder to regress.
