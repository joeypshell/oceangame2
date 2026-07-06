# Backlog Refresh After CVR05 And Player-Facing Fix

Date: 2026-07-06

Purpose: restore the actionable issue queue after the controlled visual-revision terrain pass and the player direction-change artifact fix.

## Current State

- The focused slice-production workflow is proven across production slices 01-04.
- Controlled Visual Revisions 01-05 are implemented, reviewed, accepted, and verified through the terrain tileset v2 public preview.
- `assets/terrain_tiles/cave_tileset_v2.png` is the active approved runtime terrain atlas; `cave_tileset_v1.png` remains committed for comparison and rollback.
- #98 fixed the player direction-change double-facing artifact by keeping the player root transform stable and flipping only visual children.
- #52 and #53 remain intentionally deferred optional slice-03 cleanup. Do not pull them into the active queue unless a future accepted-baseline replacement intentionally changes slice 03.

## Recommendation

Move from controlled visual revisions into a small controlled gameplay/readability phase. The next issues should preserve the map/source-of-truth discipline while making the prototype feel better to run locally and safer to deploy.

Recommended order:

1. Verify the public Web preview after the #98 player-facing fix.
2. Add `--smoke-player-facing` to the Godot Smoke CI workflow.
3. Plan Controlled Gameplay Pass 01 around player movement feel and readability.
4. Add a focused movement-feel capture or deterministic probe path.
5. Tune player swim acceleration, deceleration, and turn feel.
6. Record a movement-feel validation decision after review.
7. Plan a salvage/oxygen feedback readability pass.
8. Implement the salvage/oxygen feedback polish pass.
9. Review and accept any baseline updates from the feedback polish pass.
10. Verify the public Web preview after the feedback polish pass.

## Issue Shape

Each issue should include:

- summary or user story
- acceptance criteria
- relevant docs and code areas
- dependencies or blockers
- implementation notes
- verification steps

Use implementation issues for code changes, decision issues for review/acceptance points, and Web preview issues for deployed Pages verification after runtime or asset changes.
