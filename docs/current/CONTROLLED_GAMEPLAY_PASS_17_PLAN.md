# Controlled Gameplay Pass 17 Plan

Date: 2026-07-09

Issue: #340 `Plan Controlled Gameplay Pass 17 around pry salvage interaction`
Milestone: Simple Diver Game 03 `Salvage Tools And Interaction Set`

## Decision

Pass 17 should add one compact source-authored `pry_salvage` interaction to `production_slice_01`.

This is the first Milestone 03 step after Pass 16 proved the default dive's primary completion arc. The goal is a second tool-like salvage verb that creates a small oxygen/cargo decision without introducing inventory, loadouts, upgrades, economy, enemies, or map-scale expansion.

## Target Experience

- The player finds one sealed or wedged salvage target on an optional route in the default slice.
- Staying near the target advances a short pry stage.
- Completed stages persist during normal exploration, so the player can retreat to breathe or bank cargo and return.
- Leaving range cancels only the current partial stage, not already completed stages.
- Finishing all stages converts the target into held cargo if cargo space is available.
- If cargo is full, the target stays available and visibly uncollected until the player banks cargo and returns.

## Meaningful-Change Filter

The pass is valuable only if it gives the current dive a new interaction rhythm:

- more than instant pickup
- meaningfully distinct from the existing continuous `timed_salvage`
- creates oxygen/time pressure while interacting
- lets the player make a small retreat-or-commit choice
- remains source-authored, smoke-covered, and reviewable

If the work becomes a general tool system, equipment menu, upgrade tree, crafting/economy system, lock-and-key map gate, enemy behavior, or full-map production pass, keep it out of Pass 17.

## Planned Issue Batch

Implementation order:

1. #340 Plan Controlled Gameplay Pass 17 around pry salvage interaction.
2. #341 Document pry salvage metadata schema and source contract.
3. #342 Add pry salvage metadata validation.
4. #343 Author one pry salvage target in `production_slice_01` source.
5. #344 Implement pry salvage interaction runtime.
6. #345 Add deterministic pry salvage smoke coverage.
7. #346 Add focused pry salvage review capture.
8. #347 Review Pass 17 visual impact and baseline decision.
9. #348 Verify public Web preview after Pass 17 pry salvage pass.
10. #349 Add Pass 17 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Primary source:

```text
tools/create_production_slice_map.py
maps/production_slice_01.greybox.json
```

Suggested source shape:

```json
{
  "id": "salvage_pry_locker",
  "type": "salvage",
  "kind": "crate",
  "tier": "valuable",
  "interaction": "pry_salvage",
  "interaction_seconds": 1.2,
  "pry_stages": 3,
  "interaction_label": "sealed cache"
}
```

Rules:

- `interaction` may be `instant`, `timed_salvage`, or `pry_salvage`.
- `pry_salvage` is supported only on salvage entities.
- `interaction_seconds` is the duration of each pry stage.
- `pry_stages` is a positive integer count of completed stages required.
- Placement must stay in-bounds, non-solid, reachable from the boat, and returnable to extraction.
- Do not author terrain topology, collision changes, score values, oxygen values, cargo limits, progress state, completion state, or primary-objective state in the pry metadata.

## Runtime/UI Boundaries

Runtime may:

- track completed pry stages and current partial stage for the active run
- advance progress while the player remains near the target
- reset only the current partial stage when the player leaves range
- preserve completed stages during normal movement, cargo banking, and oxygen refill
- show compact overlay text such as `Prying sealed cache 2/3`
- convert the target to held cargo only after all stages are complete and cargo space is available

Runtime must not:

- change instant or timed salvage behavior
- change cargo capacity or banking semantics
- change salvage score or oxygen bonus formulas
- change hazard penalty, oxygen drain, oxygen rest, or reset semantics
- make pry salvage part of the primary dive objective in Pass 17
- add an inventory/loadout/tool-selection screen

## Reset And Failure Semantics

- Manual reset clears pry progress.
- Oxygen failure clears pry progress on any uncollected pry target, matching unbanked expedition cleanup.
- Hazard reset clears pry progress on any unheld pry target, matching the existing held/unbanked salvage restoration model.
- If the target completed pry stages but was blocked by full cargo, hazard or oxygen failure seals it again.
- Banked or held salvage remains governed by existing cargo and reset rules.

## Validation And Smoke Plan

Validation should catch:

- `pry_salvage` metadata on non-salvage entities
- missing or non-positive `interaction_seconds`
- missing or invalid `pry_stages`
- unsupported interaction names
- invalid labels
- invalid placement, reachability, or returnability

Pass 17 should add:

```text
--smoke-pry-salvage
```

The smoke should verify non-instant collection, stage progress, partial-stage cancel on leave, completed-stage persistence during normal retreat, cargo-full blocking without deletion, banking, hazard reset, oxygen failure, and primary completion stability.

## Capture And Visual Plan

Add one focused capture:

```text
visual_captures/pry_salvage/
```

The capture should frame the target mid-interaction or just after completed stages with compact overlay text visible. It is a review artifact, not automatic baseline acceptance.

Visual review should compare normal production-slice baselines and accept only intentional differences. The expected outcome is likely no broad baseline change unless normal accepted captures visibly include the new target or overlay state.

## Deferred Work

Keep these out of Pass 17:

- #52 and #53 slice-03 camera/topology polish
- full-map productionization
- progression, economy, upgrades, unlocks, inventory, loadouts, crafting, or save systems
- enemies or broad hazard systems
- primary objective changes beyond preserving Pass 16 behavior
- broad art replacement or new asset generation unless a tiny procedural cue is required for readability

## Exit Criteria

Pass 17 is done when:

- the source contract is documented
- validation protects `pry_salvage` metadata
- one pry target is authored through the generator path
- runtime handles staged pry progress, cargo, banking, reset, hazard, and oxygen failure
- deterministic smoke covers the behavior
- a focused capture exists for review
- visual review records baseline impact
- public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
