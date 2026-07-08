# Controlled Gameplay Pass 13 Plan

Date: 2026-07-08

Issue: #236 `Plan Controlled Gameplay Pass 13 around route commitment objective`

## Decision

Controlled Gameplay Pass 13 should add one source-authored route commitment objective in `production_slice_01`.

Selected direction:

```text
Name and track the existing deep-cache route as a small expedition objective: bank `salvage_lower_loop` and `salvage_deep_right_cache` in the same committed route chain.
```

This does not add economy, upgrades, enemies, inventory, save files, procedural generation, broad art replacement, full-map productionization, or a new map-scale connector. The point is to make one already-authored route chain feel more intentional: the player chooses to commit beyond the safe pickup, manages cargo, timed salvage, hazards, oxygen, the Pass 12 rest pocket, and return pressure, then sees whether the route objective was completed.

## Target Experience

- The player can still do a short safe-route run and bank normally.
- The deep-cache route has a compact objective/readability cue, not a tutorial panel.
- Collecting only one target does not complete the objective.
- Completing the objective requires banking both selected targets at extraction.
- Failure, hazard reset, oxygen depletion, or returning without both targets leaves the objective incomplete.
- The result panel can name the objective outcome so the run has a clearer retry target.

## Selected Objective

Working source ids for later issues:

- objective id: `deep_cache_route_objective`
- route context: `deep_cache_commitment`
- display label: `Deep cache route`
- required banked targets:
  - `salvage_lower_loop`
  - `salvage_deep_right_cache`

The target chain is already source-authored and validated:

- `salvage_lower_loop` is the lower-loop valuable payoff.
- `salvage_deep_right_cache` is the timed valuable cache on the deeper branch.
- `lower_loop_to_deep_cache_pressure` already frames the hazard/navigation pressure.
- `lower_loop_oxygen_rest_pocket` already gives limited oxygen-rest pressure management.
- `return_pressure_to_boat` and `salvage_return_branch` already cover return/banking pressure.

Pass 13 should not move these existing targets or require terrain topology changes. If the selected objective needs a new marker, #237 should document the exact marker rectangle and #239 should author it through `tools/create_production_slice_map.py`.

## Meaningful-Change Filter

Pass 13 is worth doing only if it adds at least one of:

- a clearer reason to choose the deep route over the safe route
- a compact run objective that creates a reason to retry after failure or partial completion
- stronger remembered-place progress for the lower-loop/deep-cache chain
- deterministic proof that objective tracking does not disturb salvage, cargo, oxygen, hazard, timed salvage, rest-pocket, banking, or route outcome semantics

If the work becomes a quest system, achievement system, inventory, economy, upgrade, enemy, save, tutorial overlay, full-map expansion, or unrelated visual pass, keep it out of this pass.

## Planned Issue Batch

Recommended order:

1. #236 Plan Controlled Gameplay Pass 13 around route commitment objective.
2. #237 Document Pass 13 route commitment source rules and target route chain.
3. #238 Add Pass 13 route objective metadata schema to map spec and validator.
4. #239 Author one Pass 13 route commitment objective in `production_slice_01` source.
5. #240 Implement compact Pass 13 route commitment runtime feedback.
6. #241 Add deterministic Pass 13 route commitment smoke coverage.
7. #242 Add focused Pass 13 route commitment review capture.
8. #243 Review and accept only intentional Pass 13 visual differences.
9. #244 Verify public Web preview after Pass 13.
10. #245 Add Pass 13 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Source changes, if needed, must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, runtime nodes, collision, or camera positions to fake the objective.

Recommended source shape for later issues:

```text
one route-objective marker or metadata record that references existing salvage target ids
```

Do not duplicate target positions in runtime code. The source should identify the objective id, label, route context, and required target ids; runtime can derive progress from existing salvage/banking state.

## Runtime/UI Boundaries

Use existing systems:

- source-authored route and salvage metadata
- compact status overlay
- existing route outcome/result panel
- instant and timed salvage pickup
- two-item cargo capacity
- scoped oxygen pressure
- Pass 12 oxygen rest pocket
- hazard warning and oxygen penalty/reset
- boat extraction and banking

Recommended runtime rule:

```text
The objective becomes complete only when all required target salvage ids are banked at extraction during the run.
```

Suggested compact text:

- while relevant route progress exists: `Objective: Deep cache 1/2`
- after banking both targets: `Objective complete: Deep cache`
- result panel: `Objective: Deep cache complete` or `Objective: Deep cache incomplete`

The objective must not:

- change salvage score or oxygen bonus
- change cargo capacity
- collect or bank salvage automatically
- complete the run by itself away from extraction
- create a new inventory, quest log, economy, upgrade, enemy, save, or tool system
- replace existing route outcome text unless the implementation deliberately folds the objective into that same compact result surface

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-salvage-loop`
- `--smoke-cargo-capacity`
- `--smoke-oxygen-pressure`
- `--smoke-hazard-pressure`
- `--smoke-safe-deep-route-choice`
- `--smoke-timed-salvage`
- `--smoke-pass-12-oxygen-rest-pressure`

Pass 13 should add one focused smoke, for example `--smoke-pass-13-route-commitment`. It should report objective id, route context, required target ids, target progress, held cargo, banked score, oxygen, result text, and reset/failure state.

The smoke should verify:

- safe-route completion does not complete the deep-cache objective
- banking only one required target leaves the objective incomplete
- banking both required targets completes the objective
- timed salvage progress remains required for `salvage_deep_right_cache`
- cargo capacity still requires return planning
- hazard or oxygen failure restores unbanked held state and clears incomplete objective progress as appropriate
- Pass 12 rest-pocket feedback still works and does not complete the objective

## Visual/Capture Plan

Add one focused capture for the objective state. It should frame:

- the lower-loop/deep-cache route commitment context
- the player near a required target, route marker, or return segment
- compact objective feedback in the existing overlay or result panel
- unchanged terrain, boat, player, salvage, hazard, and rest-pocket presentation outside the selected cue

Do not accept broad baseline changes until comparison sheets show intentional differences. Reference slices 02-04 should stay unchanged.

## Deferred Work

Keep these out of Pass 13:

- slice-03 polish issues #52 and #53
- full-map productionization or another route-scale connector pass
- economy, upgrades, inventory screens, loadouts, enemies, saves, achievements, and procedural generation
- multiple objectives, objective selection screens, or persistent objective history
- broad art replacement
- new interaction families beyond the selected route objective

## Exit Criteria

Pass 13 is done when:

- the source rules doc records the exact objective metadata and target chain
- the map spec and validator understand the objective metadata
- the generator authors exactly one route commitment objective
- runtime feedback/result text makes objective progress readable
- deterministic smoke protects objective success, partial completion, failure/reset, and existing semantics
- a focused capture exists for visual review
- intentional visual differences are reviewed and accepted or explicitly deferred
- public Web preview is verified for the deployed state
- closeout records what changed, what stayed stable, and the recommended next direction
