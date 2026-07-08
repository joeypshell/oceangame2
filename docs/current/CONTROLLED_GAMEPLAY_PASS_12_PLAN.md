# Controlled Gameplay Pass 12 Plan

Date: 2026-07-08

Issue: #224 `Plan Controlled Gameplay Pass 12 around oxygen/rest route pressure`

## Decision

Controlled Gameplay Pass 12 should add one limited oxygen rest opportunity in `production_slice_01` using source-authored map metadata, compact overlay feedback, deterministic smoke, focused capture, visual review, Web verification, and closeout.

Selected direction:

```text
Author one lower-loop rest pocket that lets the player recover a small oxygen margin before committing to the return path.
```

This is not a new upgrade, inventory, economy, tool, enemy, save, procedural generation, broad art replacement, full-map expansion, or slice-03 polish pass. The goal is one readable in-cave decision: spend movement/time reaching a rest pocket to stabilize oxygen, then choose whether to continue the lower-loop/southwest pocket route or return to the boat.

## Target Experience

- The player takes the lower-loop route and sees a compact rest-pocket cue before or during the return-pressure segment.
- Entering the authored rest pocket briefly changes oxygen feedback from pure drain pressure to limited recovery/rest feedback.
- The rest pocket never banks cargo, completes the run, replaces the boat extraction, or creates a second base.
- The rest effect is capped so oxygen still matters after leaving the pocket.
- Existing timed salvage, cargo capacity, hazard penalties, route outcome, banking, reset, and result-panel behavior remain stable.

## Selected Opportunity

Use a new source-authored marker or zone in the lower-loop return corridor, near the existing `return_pressure_to_boat` segment and `salvage_return_branch` decision.

Working source ids for the next issue:

- marker/zone: `lower_loop_oxygen_rest_pocket`
- route context: `oxygen_rest_pressure`
- display label: `Rest pocket`

The exact coordinates should be documented in the source-rules issue before implementation. Prefer a small rectangle that is reachable from the boat, reachable from the lower loop, and returnable to extraction without terrain edits. If the selected placement requires topology changes, stop and split that into a separate map-source issue.

## Meaningful-Change Filter

Pass 12 is worth doing only if it adds at least one of:

- clearer oxygen pressure management away from the boat
- a route decision between pressing deeper, pausing at a rest pocket, or returning to bank
- a stronger remembered-place role for the lower-loop return corridor
- deterministic proof that limited oxygen recovery does not disturb salvage, cargo, hazards, reset, route outcome, or banking semantics

If the work becomes a general oxygen system, a permanent checkpoint, a second extraction zone, tutorial UI, full-map expansion, or unrelated visual churn, keep it out of this pass.

## Planned Issue Batch

Recommended order:

1. #224 Plan Controlled Gameplay Pass 12 around oxygen/rest route pressure.
2. #225 Document Pass 12 oxygen/rest source rules and target segment.
3. #226 Add oxygen/rest metadata schema to map spec and validator.
4. #227 Author one oxygen/rest route-pressure opportunity in `production_slice_01`.
5. #228 Implement compact oxygen/rest runtime feedback.
6. #229 Add deterministic Pass 12 oxygen/rest smoke coverage.
7. #230 Add focused Pass 12 oxygen/rest review capture.
8. #231 Review and accept only intentional Pass 12 visual differences.
9. #232 Verify public Web preview after Pass 12.
10. #233 Add Pass 12 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Source changes, if needed, must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, runtime nodes, or camera positions to fake the rest pocket. The source marker/zone should drive runtime behavior, validation, smoke setup, and focused capture framing.

Pass 12 should prefer a small metadata extension over broad map edits. The rest pocket should be represented as an authored marker/zone with explicit oxygen-rest fields rather than inferred from art, screenshots, or player pathing alone.

## Runtime/UI Boundaries

Use existing systems:

- source-authored marker or zone metadata
- compact status overlay
- scoped oxygen drain/refill/failure
- instant and timed salvage pickup
- two-item cargo capacity
- hazard warning and oxygen penalty/reset
- boat extraction and banking
- route/result text

Recommended runtime rule:

```text
While inside the rest pocket, oxygen recovers slowly up to a limited rest cap and shows compact rest feedback. Outside the pocket, normal oxygen drain/refill rules resume.
```

The rest pocket must not:

- bank cargo or complete the expedition
- restore oxygen to the full boat/extraction maximum unless the plan is deliberately revised in #225
- create a new inventory, upgrade, loadout, save, enemy, or tool system
- change salvage score, cargo capacity, hazard penalty, or result scoring semantics

If runtime code is needed, keep it narrow and avoid growing oversized files when an existing helper or small new helper can own the behavior.

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-oxygen-pressure`
- `--smoke-hazard-pressure`
- `--smoke-timed-salvage`
- `--smoke-safe-deep-route-choice`
- `--smoke-pass-10-return-pressure`
- `--smoke-pass-11-pre-pickup-route-cue`

Pass 12 should add one focused smoke, for example `--smoke-pass-12-oxygen-rest-pressure`. It should report marker id, route context, oxygen before/inside/after the pocket, rest cap behavior, cargo state, banked score, reset behavior, and whether normal extraction still owns completion.

## Visual/Capture Plan

Add one focused capture for the rest-pocket state. It should frame:

- the player inside or approaching `lower_loop_oxygen_rest_pocket`
- enough lower-loop terrain to show why the pocket is a route decision
- compact overlay feedback showing rest/oxygen state
- unchanged salvage, hazard, cargo, boat, and terrain presentation outside the intended cue

Do not accept broad baseline changes until comparison sheets show intentional differences. Reference slices 02-04 should stay unchanged.

## Deferred Work

Keep these out of Pass 12:

- slice-03 polish issues #52 and #53
- full-map productionization or another route-scale connector pass
- economy, upgrades, inventory screens, loadouts, enemies, saves, and procedural generation
- broad art replacement
- general oxygen-station networks, multiple rest pockets, or permanent checkpoints
- new interaction families beyond the selected limited rest pocket

## Exit Criteria

Pass 12 is done when:

- the rest-pocket source target and metadata rules are documented
- the map source/generator authors exactly one rest pocket
- validation catches invalid rest-pocket metadata
- compact runtime feedback makes the oxygen/rest behavior readable
- deterministic smoke protects the behavior and reset semantics
- a focused capture exists for visual review
- intentional visual differences are reviewed and accepted or explicitly deferred
- public Web preview is verified for the deployed state
- closeout records what changed, what stayed stable, and the recommended next direction
