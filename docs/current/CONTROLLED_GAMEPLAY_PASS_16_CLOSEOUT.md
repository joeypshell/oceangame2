# Controlled Gameplay Pass 16 Closeout

Date: 2026-07-09

Issue: #329 `Add Pass 16 closeout and next-step evaluation`
Implementation issues: #320-#328

## Result

Controlled Gameplay Pass 16 is complete.

The pass made `production_slice_01` complete around one source-authored primary dive objective instead of requiring every salvage pickup in the map. The default dive now has a clearer start, route commitment, return, and completion arc:

```text
Bank salvage_lower_loop and salvage_deep_right_cache, then return to the boat to complete Deep cache.
```

Optional salvage remains collectible and bankable, but it no longer forces map-cleanup pacing before the player can see a successful expedition result.

## Implemented Behavior

- `production_slice_01` now sets `primary_route_objective_id` to `deep_cache_route_objective`.
- Runtime resolves the primary objective through existing route-objective metadata.
- Returning to extraction after banking only optional or partial cargo banks that cargo but does not complete the run.
- Returning to extraction after banking the required deep-cache targets completes the authored dive.
- Maps without `primary_route_objective_id` keep the legacy all-salvage completion rule.
- Reset, hazard reset, and oxygen failure clear or preserve state according to the existing expedition semantics.

## Source And Validation Decisions

The source-of-truth path stayed intact:

```text
tools/create_production_slice_map.py
maps/production_slice_01.greybox.json
references/greybox/production_slice_01.svg
docs/MAP_SPEC.md
```

The new source field is intentionally small:

```json
{
  "primary_route_objective_id": "deep_cache_route_objective"
}
```

Validation now catches missing, malformed, or dangling primary objective references through the greybox map validator and route-objective helper.

## Verification

Pass 16 added deterministic smoke coverage:

```text
--smoke-primary-dive-completion
```

The smoke verifies partial optional banking does not complete the run, banking the primary objective targets does complete the run, and reset, hazard, and oxygen-failure paths do not leave stale completion state.

Regression coverage during the pass included salvage loop, cargo capacity, timed salvage, hazard pressure, safe/deep route choice, route outcome, oxygen pressure, session best score, oxygen bonus, production-slice routes, and Pass 13-15 objective smokes.

## Capture And Visual Decision

Focused review capture:

```text
visual_captures/primary_dive_completion/production_slice_01_primary_dive_completion.png
```

Visual decision:

```text
docs/current/PASS_16_PRIMARY_DIVE_COMPLETION_VISUAL_BASELINE_DECISION.md
```

No production-slice baseline changes were accepted. Normal slice 01-04 captures matched accepted baselines, and the focused Pass 16 capture remains a review artifact only.

## Web Preview

Web verification:

```text
docs/current/PASS_16_PRIMARY_DIVE_COMPLETION_WEB_PREVIEW_VERIFICATION.md
```

The public preview was verified against deployed runtime commit:

```text
9b1b530efde042287e6cbc6b143b866ca45709a4
```

The browser check matched `build_info.json`, initialized the Godot canvas, and reported no missing resources, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages.

## Stable Areas

Pass 16 did not change:

- terrain topology or collision
- spawn, boat, extraction, route scale, or camera tests
- salvage placement, score values, cargo capacity, or banking semantics
- timed-salvage duration, progress, cancellation, or completion behavior
- oxygen drain, refill, rest-pocket cap, failure, or result behavior
- hazard warning, penalty, reset, or player tint behavior
- accepted visual baselines
- #52/#53 deferred slice-03 polish status

## Remaining Gaps

Milestone 02's core vertical-slice goal is now proven at prototype level, but the game still needs more interesting interaction before progression or map-scale expansion.

Still deferred:

- #52 `Tune production slice 03 camera framing`
- #53 `Clean production slice 03 topology artifacts in source generator`

Keep them deferred unless slice-03 presentation becomes the selected goal.

## Next Recommendation

Use `docs/current/SIMPLE_DIVER_GAME_ROADMAP.md` as the north star and create the next actionable batch from:

```text
Milestone 03: Salvage Tools And Interaction Set
```

Recommended next direction: add one more small, source-authored, tool-like salvage interaction in `production_slice_01`, such as pry, cut, scan, or clear obstruction. Keep it narrower than an inventory/loadout system, and do not jump to economy, upgrades, enemies, procedural generation, or full-map productionization yet.
