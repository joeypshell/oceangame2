# Controlled Gameplay Pass 11 Plan

Date: 2026-07-08

Issue: #214 `Plan Controlled Gameplay Pass 11 around pre-pickup route readability`

## Decision

Controlled Gameplay Pass 11 should add one pre-pickup readability cue in `production_slice_01` using existing source metadata, compact overlay feedback, deterministic smoke, focused capture, visual review, Web verification, and closeout.

Selected direction:

```text
Make the southwest return-pocket detour readable before the player collects its payoff.
```

This pass should not add economy, upgrades, enemies, inventory, procedural maps, full-map productionization, broad art replacement, or slice-03 polish. The goal is to make one optional detour feel intentional before pickup, not only after collection.

## Target Experience

- The player reaches the southwest return-pocket approach and gets a compact cue that the pocket is optional but promising.
- The cue appears before collecting `salvage_southwest_return_cache`.
- Existing collection feedback and route outcome text remain stable after pickup and banking.
- Oxygen and cargo continue to matter normally while the player decides whether to commit.
- The selected cue can be reviewed through a deterministic smoke and focused capture.

## Meaningful-Change Filter

Pass 11 is worth doing only if it adds at least one of:

- clearer pre-pickup route readability
- a stronger sense that the southwest pocket is an authored optional detour
- a visible reason to enter a remembered-place pocket before the reward fires
- deterministic proof that cue feedback does not disturb salvage, cargo, oxygen, hazard, reset, or banking semantics

If the work becomes only text churn, tutorial UI, broad HUD redesign, route-scale expansion, or unrelated baseline drift, keep it out of this pass.

## Planned Issue Batch

Recommended order:

1. #213 Correct current-state issue text after #210 and #211.
2. #214 Plan Controlled Gameplay Pass 11 around pre-pickup route readability.
3. #215 Document Pass 11 source rules and target route segment.
4. #216 Author Pass 11 pre-pickup readability metadata in `production_slice_01` source.
5. #217 Implement compact Pass 11 pre-pickup route cue feedback.
6. #218 Add deterministic Pass 11 pre-pickup route cue smoke coverage.
7. #219 Add focused Pass 11 pre-pickup route cue review capture.
8. #220 Review and accept only intentional Pass 11 visual differences.
9. #221 Verify public Web preview after Pass 11.
10. #222 Add Pass 11 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Source changes, if needed, must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, runtime nodes, or camera positions to fake readability.

Pass 11 should prefer existing concepts:

- route/review marker rectangles
- `route_choice_id`
- `validation_route`
- compact overlay status text
- existing salvage tiers and banking semantics

The exact source ids and metadata belong in #215. Good candidates are the existing southwest return-pocket marker and the `salvage_southwest_return_cache` payoff because Pass 09 already proved the payoff after collection.

## Runtime/UI Boundaries

Use existing systems:

- source-authored marker or route metadata
- compact status overlay
- instant salvage pickup
- two-item cargo capacity
- oxygen drain/refill/failure
- boat extraction and banking
- route/result text

Do not add:

- inventory, economy, upgrades, loadouts, saves, or tools
- enemies, combat, health bars, or moving hazards
- procedural maps or full-sketch productionization
- broad terrain, player, boat, prop, or background art replacement
- modal tutorial UI or a HUD redesign

If runtime code is needed, keep it narrow and avoid growing oversized files when an existing helper or small new helper can own the behavior.

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-production-slice-route`
- `--smoke-safe-deep-route-choice`
- `--smoke-timed-salvage`
- `--smoke-hazard-pressure`
- `--smoke-pass-09-southwest-pocket-decision`
- `--smoke-pass-10-return-pressure`

Pass 11 should add one focused smoke for the pre-pickup cue. The smoke should report cue id, route or marker id, cue text, player state before pickup, collection/banking state after pickup, oxygen, and held/banked cargo where relevant.

## Visual/Capture Plan

Add one focused capture for the selected pre-pickup cue state. It should frame:

- the player at the southwest pocket approach before collecting the payoff
- enough surrounding terrain to explain the optional detour
- compact overlay feedback that names the cue
- existing props and markers without broad baseline acceptance

Do not accept broad baseline changes until comparison sheets show intentional differences. Reference slices 02-04 should stay unchanged.

## Deferred Work

Keep these out of Pass 11:

- slice-03 polish issues #52 and #53
- full-map productionization or another route-scale connector pass
- economy, upgrades, inventory screens, loadouts, enemies, saves, and procedural generation
- broad art replacement
- new interaction families beyond current salvage, timed salvage, hazard, oxygen, cargo, extraction, route, and overlay behavior

## Exit Criteria

Pass 11 is done when:

- the selected pre-pickup cue source target is documented
- any source annotation is authored through the generator/source path
- compact runtime feedback makes the cue readable before collection
- deterministic smoke protects the behavior
- a focused capture exists for visual review
- intentional visual differences are reviewed and accepted or explicitly deferred
- public Web preview is verified for the deployed state
- closeout records what changed, what stayed stable, and the recommended next direction
