# Backlog Refresh After Controlled Gameplay Pass 01

Date: 2026-07-06

Purpose: restore the actionable issue queue after accepting the first movement-feel baseline and the salvage/oxygen feedback polish.

## Current State

- The focused map-production workflow is proven across production slices 01-04.
- The current default preview remains `production_slice_01`.
- Controlled visual revisions have produced accepted current-prototype terrain, prop, player, boat, and background assets.
- The player direction-change artifact is fixed and covered by smoke validation.
- Controlled Gameplay Pass 01 established a usable movement-feel baseline.
- The salvage/oxygen overlay now separates banked salvage, held salvage, oxygen, and prompt/status feedback.
- #52 and #53 remain intentionally deferred slice-03 polish issues. Do not pull them into the active queue unless slice-03 presentation becomes the selected goal.

## Recommendation

Move into Controlled Gameplay Pass 02: route choice, oxygen pressure, and salvage payoff. The pass should stay small and source-of-truth friendly: data should define the route/payoff setup, renderer/runtime changes should be narrow, and validation should prove the authored route is reachable and returnable.

Recommended order:

1. Refresh the roadmap after Controlled Gameplay Pass 01.
2. Plan Controlled Gameplay Pass 02 around route choice and expedition pressure.
3. Add a deterministic route-choice review probe.
4. Tune oxygen pressure thresholds and warning timing.
5. Record the oxygen pressure baseline decision after review.
6. Add salvage value tiers to the map schema and validation.
7. Render high-value salvage with a distinct prototype marker or sprite.
8. Author one risk/reward salvage placement in `production_slice_01`.
9. Validate the risk/reward route for reachability, collection, and return.
10. Verify the public Web preview after the route/payoff pass lands.

## Issue Shape

Each issue should include:

- summary or user story
- acceptance criteria
- relevant docs and code areas
- dependencies or blockers
- implementation notes
- verification steps

Keep implementation issues separate from review/decision issues. If a task starts touching map topology, gameplay tuning, renderer behavior, and deployed preview verification at once, split it before implementation.
