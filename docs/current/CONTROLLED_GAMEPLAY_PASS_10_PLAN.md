# Controlled Gameplay Pass 10 Plan

Date: 2026-07-08

Issue: #201 `Plan Controlled Gameplay Pass 10 around return/banking pressure`

## Decision

Controlled Gameplay Pass 10 should make return and banking pressure clearer in `production_slice_01` using existing systems.

Selected direction:

```text
Create one readable carry-return decision around cargo capacity, oxygen, route commitment, and boat extraction.
```

This pass should not add a new economy, inventory screen, tool system, enemy behavior, procedural map, or full-map expansion. The goal is to make the current loop feel more intentional: collect, decide whether to keep pushing, then return safely before oxygen/cargo pressure turns the route against the player.

`production_slice_01` remains the default preview map. The full sketch and production slices 02-04 remain reference/planning sources, not active expansion targets.

## Target Experience

- The player can read one moment where returning to the boat is the sensible choice.
- Cargo capacity feels like route pressure, not just a hidden blocker.
- Oxygen continues to matter while the player carries unbanked salvage.
- Banking at the boat remains the payoff and reset point for the next push.
- Existing route beats stay stable: safe/deep route, timed deep cache, hazard pressure, southwest pocket payoff, and result-panel route text.
- The selected Pass 10 state can be reviewed through compact overlay text, deterministic smoke, and a focused capture.

## Meaningful-Change Filter

Pass 10 is worth doing only if it adds at least one of:

- a clearer choice between banking now and pushing farther
- better pre-return readability for full or valuable cargo
- more visible pressure from oxygen/cargo while returning
- deterministic proof that banking frees capacity and preserves existing reset semantics
- a focused review capture that shows why the return decision matters

If the work becomes only text churn, broad UI redesign, map-scale expansion, or baseline drift, keep it out of this pass.

## Planned Issue Batch

Recommended order:

1. #201 Plan Controlled Gameplay Pass 10 around return/banking pressure.
2. #202 Document Pass 10 return-pressure source rules and target route segment.
3. #203 Author Pass 10 return-pressure metadata in `production_slice_01` source.
4. #204 Implement compact Pass 10 return/banking pressure feedback.
5. #205 Add deterministic Pass 10 return-pressure smoke coverage.
6. #206 Add focused Pass 10 return-pressure review capture.
7. #207 Review Pass 10 visual impact and accept only intentional differences.
8. #208 Verify public Web preview after Pass 10 return-pressure pass.
9. #209 Add Pass 10 closeout and next-step evaluation.

Issue #210 is related tooling-doc hygiene for the repo drift evaluation skill and may run independently.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Source changes, if needed, must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, runtime nodes, or camera positions to fake return pressure.

Pass 10 should prefer existing map concepts:

- salvage ids and tiers
- `route_choice_id`
- `validation_route`
- `route_order`
- route/review markers if a focused source annotation is needed

The exact target route segment belongs in #202. Good candidates are near the lower-loop/deep-cache route or southwest return pocket because those already exercise valuable cargo, timed salvage, oxygen, hazard, and return-to-boat pressure.

## Runtime/UI Boundaries

Use existing systems:

- salvage pickup and held cargo
- two-item cargo capacity
- boat extraction and banking
- oxygen drain/refill/failure
- hazard reset and held-salvage restore
- compact status overlay
- route/result text

Do not add:

- inventory, economy, upgrades, loadouts, or saves
- enemies, combat, health bars, or moving hazards
- procedural maps or whole full-sketch productionization
- broad terrain, player, boat, prop, or background art replacement
- modal tutorial UI or a HUD redesign

If new runtime code is needed, keep it narrowly scoped and avoid growing oversized files when an existing helper can own the behavior.

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-production-slice-route`
- `--smoke-safe-deep-route-choice`
- `--smoke-cargo-capacity`
- `--smoke-timed-salvage`
- `--smoke-hazard-pressure`
- `--smoke-pass-08-route-extension`
- `--smoke-pass-09-southwest-pocket-decision`

Pass 10 should add one focused smoke for the return-pressure decision. The smoke should report target id, route or marker id, held cargo, banked score, blocked/available pickup state if relevant, oxygen, return status, and compact feedback text.

## Visual/Capture Plan

Add one focused capture for the selected return-pressure state. It should frame:

- the player carrying or attempting to carry relevant salvage
- the return route or extraction context
- compact overlay feedback that makes the pressure readable
- enough surrounding terrain to explain the route decision

Do not accept broad baseline changes until comparison sheets show the intentional difference. Reference slices 02-04 should stay unchanged.

## Deferred Work

Keep these out of Pass 10:

- slice-03 polish issues #52 and #53
- full-map productionization or another map-scale connector pass
- economy, upgrades, inventory screens, loadouts, enemies, saves, and procedural generation
- broad art replacement
- new interaction families beyond the existing salvage, timed salvage, hazard, oxygen, cargo, and extraction loop

## Exit Criteria

Pass 10 is done when:

- the selected route/return target is documented
- any source annotation is authored through the generator/source path
- compact runtime feedback makes the return/banking decision readable
- deterministic smoke protects the behavior
- a focused capture exists for visual review
- intentional visual differences are reviewed and accepted or explicitly deferred
- public Web preview is verified for the deployed state
- closeout records what changed, what stayed stable, and the recommended next direction
