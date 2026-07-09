# Controlled Gameplay Pass 16 Plan

Date: 2026-07-08

Issue: #320 `Plan Pass 16 around primary dive completion`
Milestone: Simple Diver Game 02 `Core Diver Loop Vertical Slice`

## Decision

Pass 16 should make the default `production_slice_01` dive complete around one source-authored primary objective instead of requiring every salvage item in the map.

Selected behavior:

```text
When a playable map names a primary route objective, returning to extraction completes the run only after that objective's required salvage has been banked.
```

For `production_slice_01`, the primary objective should be the existing:

```text
deep_cache_route_objective
```

Maps without primary-objective metadata should preserve the current all-salvage completion behavior.

## Target Experience

- The player starts at the boat and sees the existing deep-cache objective cue.
- The player can still collect optional salvage and bank cargo at the boat.
- Banking optional or partial cargo does not end the run too early.
- Banking the lower-loop target plus the timed deep-right cache target completes the authored dive when the player returns to extraction.
- The result panel should feel like a completed authored dive, not just a map-cleanup counter.
- Retry/reset should remain immediate and familiar.

## Meaningful-Change Filter

Pass 16 is valuable only if it improves the default run as a playable dive:

- clearer start-middle-return-complete arc
- stronger reason to pursue the deep-cache objective
- less pressure to collect every object before seeing a successful result
- stable oxygen, cargo, hazard, timed salvage, objective, result, and retry behavior

If the work becomes an inventory system, economy, upgrade tree, quest log, objective selector, procedural map, full-map production pass, or broad UI replacement, keep it out of this pass.

## Planned Issue Batch

Recommended order:

1. #320 Plan Pass 16 around primary dive completion.
2. #321 Document primary dive objective source contract.
3. #322 Add primary dive objective validation.
4. #323 Author primary dive objective in `production_slice_01` source.
5. #324 Implement primary objective gated run completion.
6. #325 Add deterministic primary dive completion smoke coverage.
7. #326 Add focused primary dive completion review capture.
8. #327 Review Pass 16 visual impact and baseline decision.
9. #328 Verify public Web preview after primary dive completion pass.
10. #329 Add Pass 16 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Primary source:

```text
maps/production_slice_01.greybox.json
```

Source changes must start from:

```text
tools/create_production_slice_map.py
```

Preferred source shape:

```json
{
  "primary_route_objective_id": "deep_cache_route_objective"
}
```

The field should be a pointer to an existing `route_objectives` entry. It should not duplicate required targets, target coordinates, score, oxygen, cargo limits, progress, completion state, or result text.

## Runtime Boundaries

Runtime may:

- read the map's primary objective id
- resolve it against existing route objective metadata
- derive completion from banked required target ids
- keep the run active after partial or optional banking
- complete the run at extraction once the primary objective is satisfied

Runtime must not:

- change how held salvage banks
- delete optional salvage on partial banking
- change salvage score or oxygen bonus formulas
- change cargo capacity
- change timed-salvage progress/cancel/complete behavior
- change oxygen drain/refill/rest/failure behavior
- change hazard warning, penalty, reset, or tint behavior
- change source map topology, collision, spawn, extraction, camera tests, or visual baselines

## Legacy And Reference Maps

If `primary_route_objective_id` is omitted, current behavior remains valid:

```text
bank all playable salvage to complete the run
```

This preserves original comparison maps, later reference slices, and old smokes until they intentionally opt into primary-dive completion.

## Validation And Smoke Plan

Validation should catch:

- primary objective pointer is not a string
- id is not lower_snake_case
- id does not reference an existing route objective
- referenced objective has invalid or unreachable required targets through existing objective validation

Pass 16 should add:

```text
--smoke-primary-dive-completion
```

The smoke should verify:

- partial return banks cargo but does not complete the run
- banking the primary objective targets completes the run at extraction
- reset clears primary-completion state
- oxygen failure and hazard reset do not leave stale completion state

Regression smokes should include existing salvage loop, cargo, timed salvage, hazard, oxygen, and Pass 13-15 objective coverage.

## Capture And Visual Plan

Add one focused capture after runtime and smoke land:

```text
visual_captures/primary_dive_completion/
```

The capture should frame the completed primary dive result state. It is a review artifact, not automatic baseline acceptance.

Visual review should compare normal production-slice baselines and accept only intentional differences. The expected outcome is likely no broad baseline change unless normal accepted captures visibly include the new completion text.

## Deferred Work

Keep these out of Pass 16:

- #52 and #53 slice-03 camera/topology polish
- full-map productionization
- route-scale expansion
- objective selector, quest log, mission board, or persistent objective history
- economy, upgrades, inventory, loadouts, enemies, saves, or procedural generation
- broad visual replacement or new asset generation

## Exit Criteria

Pass 16 is done when:

- the primary objective source contract is documented
- validation protects the source field
- `production_slice_01` authors the primary objective through the generator path
- runtime completion is gated by the primary objective only for opted-in maps
- deterministic smoke covers partial banking, primary completion, reset, and failure cleanup
- a focused capture exists for review
- visual review records baseline impact
- public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
