# Controlled Gameplay Pass 27 Plan

Date: 2026-07-09

Issues: #602-#611
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

Pass 27 should make player movement and direction changes visually stable before release-candidate preparation.

The motivating report is that the player sprite can flash during direction changes and briefly appear to face both directions. Treat this as a player readability/game-feel issue, not an art replacement or movement-system rewrite.

## Target Experience

- Reversing direction should read as one clean diver facing state.
- The body sprite and light cone should agree after repeated left/right reversals.
- The player root, collision, camera, oxygen, cargo, salvage, hazard, objective, and result semantics should stay unchanged.
- Any movement tuning should be tiny and justified by reproduction evidence.

## Meaningful-Change Filter

This pass is worthwhile if it makes ordinary swimming feel more trustworthy in every dive. It should not add new objectives, connectors, salvage, hazards, upgrades, UI screens, audio systems, or map scale.

## Current Implementation Notes

- `scripts/player/player_controller.gd` currently keeps the `CharacterBody2D` root scale stable at `1.0`.
- Facing is represented by `_facing_sign`.
- `Body.flip_h` mirrors the diver sprite.
- `LightCone.position.x` and `LightCone.scale.x` follow `_facing_sign`.
- `get_facing_report()` already exposes root scale, body flip, light cone position/scale, and animation frame state for smoke coverage.
- Movement is currently `200 px/s` swim speed, `620 px/s^2` acceleration, and `900 px/s^2` deceleration.

## Planned Issue Batch

1. #602 Plan Pass 27 around player movement and direction-change readability.
2. #603 Reproduce and document the player direction-change flash.
3. #604 Fix player direction-change rendering so the diver never appears double-facing.
4. #605 Evaluate movement reversal feel without changing route semantics.
5. #606 Add deterministic Pass 27 smoke coverage for facing transitions.
6. #607 Add focused Pass 27 movement and facing review capture.
7. #608 Review Pass 27 visual impact without unrelated baseline drift.
8. #609 Verify public Web preview after Pass 27 player-facing pass.
9. #610 Add Pass 27 closeout and next-step evaluation.
10. #611 Refresh release-readiness blocker list after Pass 27.

## Runtime Boundaries

Prefer the smallest rendering/facing-state fix:

- Keep the player root transform stable.
- Keep collision shape size and position unchanged.
- Keep camera limits/smoothing behavior unchanged.
- Keep input actions and movement controller API unchanged.
- Avoid broad animation-system or asset replacement work.

Only adjust movement reversal values if #603 shows that acceleration/deceleration timing contributes to the visual flash or readability issue. If movement tuning changes, run route and oxygen smokes that could be affected by traversal timing.

## Validation And Smoke Plan

- Preserve `--smoke-player-facing`.
- Preserve `--smoke-movement-feel`.
- Add or extend smoke coverage for repeated reversals, body/light alignment, root scale stability, and post-reset facing state.
- Report facing state, body flip, light cone position/scale, animation frame, and any movement values in smoke output.
- Run focused route/oxygen smoke only if movement values change.

## Visual And Capture Plan

- Add one focused capture that frames the player during or immediately after a direction reversal.
- Use `production_slice_01` as the default review map.
- Do not accept production-slice baselines unless the only visible difference is intentional and stable.
- Treat any terrain, boat, salvage, hazard, camera, map, or UI drift as unrelated.

## Deferred Work

- #52 and #53 remain deferred optional slice-03 polish.
- Broad player art replacement is deferred.
- Audio/music, inventory/loadouts, enemy AI, economy expansion, procedural generation, save systems, and full-map productionization are out of scope.

## Exit Criteria

- Direction changes no longer show a double-facing flash in local review.
- Body and light facing stay aligned through repeated reversals.
- Existing gameplay semantics are unchanged.
- Smoke and capture coverage make the regression checkable.
- Visual/Web review records whether any baseline or public-preview follow-up is needed.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
