# Diver Animation Plan

Date: 2026-07-09

Issue: #447 `Plan diver animation states and sprite requirements`

## Decision

Use the current approved `player_diver_01.png` silhouette as the style anchor and add animation in small visual-only slices. Animation must not change the player `CharacterBody2D`, the 26x18 collision rectangle, movement tuning, camera behavior, light-cone semantics, map data, oxygen/cargo logic, or route validation.

The first implementation should be #448: one readable swim/idle slice that improves motion and direction-change clarity without replacing the whole player art pass.

## Current Baseline

- Scene: `scenes/player/Player.tscn`
- Controller: `scripts/player/player_controller.gd`
- Approved sprite: `assets/player/player_diver_01.png`
- Current visual node: one `Sprite2D` named `Body`
- Current facing rule: keep the player root scale at `1.0`, flip only `Body.flip_h`, and mirror `LightCone` position/scale.
- Existing regression smoke: `--smoke-player-facing`
- Existing review capture: `--capture-player-readability`

## First Animation States

1. `idle`
   - Low-priority still or subtle hover state.
   - Can start as the existing frame.
   - Must not add bobbing that changes collision or camera assumptions.

2. `swim`
   - Highest priority first visible improvement.
   - Should use 2-4 frames that keep the same 96x64 canvas, center, facing, and collision relationship as `player_diver_01.png`.
   - Good candidates: flipper sweep, small torso/arm motion, slight tank/hose readability.

3. `turn`
   - Treat as a visual guardrail, not a separate complex animation yet.
   - Direction changes should never show both left and right versions at once.
   - The first slice can preserve instant flip while ensuring animated frames do not leave stale mirrored children visible.

4. `interact_salvage`
   - Later state for timed/pry salvage.
   - Could start as a single frame or short loop with hand/tool posture.
   - Do not block #448 on this state.

5. `hit_stagger`
   - Later state for static/moving hazard contact.
   - Can start as tint/knockback-only because existing hazard feedback already works.
   - Do not add health or combat semantics.

6. `carry_return`
   - Optional later state only if held cargo needs stronger readability.
   - Avoid adding inventory visuals before the cargo loop needs them.

## Asset Requirements

The first animation asset should be a named committed sprite sheet or small frame set:

- Preferred first asset: `assets/player/player_diver_swim_01.png`
- Suggested canvas per frame: 96x64, matching `player_diver_01.png`
- Suggested first sheet: horizontal 4-frame strip, 384x64
- Direction: author right-facing frames only; runtime flips the visual node for left-facing.
- Review sheet: `references/asset_reviews/player_diver_swim_01_review.png`

If generated, extend `tools/generate_player_sprite.py` or create a tiny sibling generator that reuses the current palette and outputs both the sheet and review image. Do not overwrite `player_diver_01.png` as a side effect.

## Runtime Boundaries

#448 should add only the smallest useful animation runtime:

- Add `AnimatedSprite2D`, `SpriteFrames`, or a tiny visual helper if that fits Godot patterns cleanly.
- Keep the current `Body` node path or provide a narrow compatibility wrapper if existing smokes/captures rely on it.
- Choose `swim` when input direction or velocity is non-zero; choose `idle` otherwise.
- Preserve root scale at `1.0`.
- Continue flipping only the visual body and light cone.
- Do not change `swim_speed`, acceleration, deceleration, `move_and_slide()`, collision, camera, light upgrade math, or input handling.

## Capture And Baseline Plan

Use focused review before any baseline acceptance:

- Run `--capture-player-readability` for the existing close start-context shot.
- Add a focused swim-motion capture only if #448 needs a new review view.
- Compare against accepted production-slice baselines before accepting any broad visual difference.
- Expected intentional difference for #448: player body frame/pose only.
- Unintentional differences to reject: terrain, boat, salvage, hazards, camera framing, light range, UI, map topology, collision, and route markers.

## Verification

After #448 or any animation implementation:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-player-readability
python tools/check_asset_manifest.py
python tools/check_file_lengths.py
git diff --check
```

## Follow-Up Issue

#448 is the active implementation follow-up for the smallest useful swim/idle animation slice. Do not create a larger animation epic until #448 proves the asset/runtime path.

## Deferred

- Full animation state machine
- Tool-specific animations beyond one later salvage/interact frame
- Hit reaction animation beyond existing hazard feedback
- Carry/inventory visuals
- New movement mechanics
- Player collision resizing
- Broad player redesign or whole-scene visual replacement
