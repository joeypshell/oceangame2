# Controlled Gameplay Pass 15 Plan

Date: 2026-07-08

Issue: #298 `Plan Controlled Gameplay Pass 15 around objective follow-through readability`

## Decision

Controlled Gameplay Pass 15 should add one compact objective-follow-through cue after the player leaves the boat on the default `production_slice_01` slice.

Selected behavior:

```text
When the player reaches the lower-loop route context before banking the first required deep-cache objective target, show one compact cue that the current route step belongs to the active objective.
```

The cue should support the existing `deep_cache_route_objective` from Pass 13/14. It is not a quest log, objective selector, tutorial panel, broad route expansion, or new objective system.

## Target Experience

- The player starts with the Pass 14 cue: `Objective: Deep cache 0/2`.
- After leaving the boat, the player gets one in-route reminder near the first required objective step instead of losing the thread.
- The cue should point at the lower-loop commitment step without moving salvage, changing terrain, or adding rewards.
- The cue should yield to stronger existing feedback such as pickup, cargo-full, hazard, oxygen, result, and completion states.
- Completing or failing the objective still uses existing Pass 13 objective progress/result behavior.

## Selected Cue

Working source ids for later issues:

- objective id: `deep_cache_route_objective`
- route context: `deep_cache_commitment`
- first required target: `salvage_lower_loop`
- second required target: `salvage_deep_right_cache`
- recommended marker id: `deep_cache_first_step_cue`

Recommended compact text:

```text
Objective route: lower loop
```

The exact text can be refined in #299, but it should stay short enough for the existing overlay.

## Meaningful-Change Filter

Pass 15 is worth doing only if it adds at least one of:

- clearer follow-through from the start objective cue into the first required route step
- remembered-place progress for the lower-loop/deep-cache chain
- a reason to continue or retry the deep-cache objective after leaving the boat
- deterministic proof that the cue does not disturb salvage, cargo, oxygen, hazards, rest pockets, timed salvage, route outcome, Pass 13 objective progress, or Pass 14 start cue behavior

If the work becomes an objective log, quest system, economy, upgrade, inventory, enemy, save, procedural map, broad art pass, full-map productionization, or route-scale expansion, keep it out of this pass.

## Non-Goals

Pass 15 explicitly does not add:

- objective selection screens
- quest logs or persistent objective history
- economy, upgrades, inventory, loadouts, enemies, saves, or procedural generation
- additional salvage, rewards, or route objectives
- full-map productionization
- broad route expansion
- broad visual replacement
- terrain topology changes

## Planned Issue Batch

Recommended order:

1. #298 Plan Controlled Gameplay Pass 15 around objective follow-through readability.
2. #299 Document Pass 15 objective step cue source and text contract.
3. #300 Add Pass 15 objective step cue metadata validation if needed.
4. #301 Author one Pass 15 objective step cue marker in `production_slice_01` source.
5. #302 Implement compact Pass 15 objective step cue runtime feedback.
6. #303 Add deterministic Pass 15 objective follow-through smoke coverage.
7. #304 Add focused Pass 15 objective follow-through review capture.
8. #305 Review Pass 15 visual impact and baseline decision.
9. #306 Verify public Web preview after Pass 15 objective follow-through.
10. #307 Add Pass 15 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Primary source:

```text
maps/production_slice_01.greybox.json
```

Source changes, if needed, must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Preferred source shape:

```text
one source-authored marker zone that references the active route objective and the first required salvage target
```

Do not duplicate target coordinates, cargo limits, oxygen values, objective completion state, or result text state in runtime-only code.

## Runtime And UI Boundaries

Use existing systems:

- `route_objectives` metadata
- marker zones from the source map
- compact status overlay
- Pass 13 objective progress/result feedback
- Pass 14 boat/extraction start cue
- instant and timed salvage pickup
- cargo, oxygen, rest-pocket, hazard, return-pressure, and route-outcome state

The cue must not:

- change objective completion rules
- collect, hold, restore, or bank salvage
- change salvage score or oxygen bonus
- change cargo capacity
- change timed-salvage duration or cancel behavior
- change hazard warning, penalty, reset, or tint behavior
- change oxygen rest-pocket refill, cap, or feedback
- complete a run away from extraction

## Validation And Smoke Plan

Preserve existing coverage:

```text
--smoke-pass-14-objective-cue
--smoke-pass-13-route-commitment
--smoke-safe-deep-route-choice
--smoke-timed-salvage
--smoke-cargo-capacity
--smoke-hazard-pressure
```

Pass 15 should add one focused smoke:

```text
--smoke-pass-15-objective-follow-through
```

The smoke should verify cue visibility in the selected route context, hidden state at the boat when Pass 14 owns the start cue, hidden/completed state after objective progress, and no regression to existing objective, cargo, hazard, oxygen, or timed-salvage semantics.

## Visual And Capture Plan

Add one focused capture after runtime lands. It should frame:

- the lower-loop route context
- the player near the selected objective step cue marker
- compact objective-follow-through text in the existing overlay
- unchanged terrain, boat, player, salvage, hazard, rest-pocket, and route visuals outside the cue

Do not accept broad baseline changes. Normal production-slice captures should remain unchanged unless the cue is intentionally visible in a normal accepted capture.

## Deferred Work

Keep these out of Pass 15:

- #52 and #53 slice-03 camera/topology polish
- full-map productionization
- broad map-scale expansion
- more route objectives or objective selection
- objective logs, achievements, persistent history, or save systems
- economy, upgrades, inventory screens, loadouts, enemies, or procedural generation
- broad visual replacement or new asset generation

## Exit Criteria

Pass 15 is done when:

- the source/text contract documents exact cue visibility and text rules
- validation either confirms no new schema is needed or guards any narrowly added metadata
- the source map authors exactly one cue marker if the contract requires it
- runtime shows the cue only in the planned in-route context
- deterministic smoke protects cue visibility and existing objective semantics
- a focused capture exists for visual review
- visual review accepts only intentional differences or records no baseline change
- public Web preview is verified for the deployed cue state
- closeout records what changed, what stayed stable, and the recommended next direction
