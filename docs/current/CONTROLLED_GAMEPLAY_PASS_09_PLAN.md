# Controlled Gameplay Pass 09 Plan

Date: 2026-07-08

Issue: #191 `Plan Controlled Gameplay Pass 09 around the southwest pocket route decision`

## Decision

Controlled Gameplay Pass 09 should deepen the Pass 08 southwest return pocket into one small authored route decision.

Selected decision target:

```text
southwest_return_pocket_extension
current cue: salvage_southwest_return_cache
nearby return context: salvage_return_branch, lower_loop_route, boat extraction
```

The pass should make this pocket read as a deliberate optional detour: spend a little oxygen and route time for an extra payoff, or skip it and continue the lower-loop/deep-cache route.

This is not a map-scale expansion pass. `production_slice_01` remains the default preview map, and the full sketch remains a topology/planning source.

## Target Experience

- The player recognizes the southwest pocket as an optional detour, not accidental leftover space.
- The pocket has a compact payoff/cue that creates a reason to enter it.
- Returning to the boat still matters because cargo capacity and oxygen remain active.
- Existing deep-route pressure still works: `salvage_lower_loop`, `hazard_right_branch`, and timed `salvage_deep_right_cache` stay stable.
- Completing the detour can be named in compact route/status/result feedback without adding a broad UI system.

## Meaningful-Change Filter

Pass 09 is worth doing only if it adds at least one of:

- a clearer choice between returning safely and detouring for extra payoff
- a remembered-place beat in the southwest pocket
- a small payoff that makes oxygen/cargo route timing matter
- deterministic smoke/capture coverage for the new decision

If the work becomes only topology clutter, baseline churn, or abstract architecture cleanup, keep it out of this pass.

## Planned Issue Batch

Recommended order:

1. #191 Plan Controlled Gameplay Pass 09 around the southwest pocket route decision.
2. #192 Define Pass 09 route-decision source rules for the southwest pocket.
3. #193 Author Pass 09 southwest pocket route-decision payoff in `production_slice_01`.
4. #194 Add Pass 09 southwest pocket route-decision runtime feedback.
5. #195 Add deterministic Pass 09 southwest pocket route-decision smoke coverage.
6. #196 Add focused Pass 09 southwest pocket route-decision review capture.
7. #197 Review and accept Pass 09 southwest pocket visual impact.
8. #198 Verify public Web preview after Pass 09 southwest pocket pass.
9. #199 Add Pass 09 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Source changes must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, or runtime nodes to fake the route decision.

Prefer existing salvage route metadata:

- `route_choice_id`
- `validation_route`
- `route_order`

Pass 09 source convention:

- tag the pocket payoff with `validation_route: "southwest_pocket_decision"`
- use a specific `route_choice_id`, recommended `southwest_pocket_detour`
- make the pocket payoff `valuable` only if the detour needs a stronger reason to exist
- keep the target a normal salvage entity so reachability, cargo, score, oxygen, hazard reset, and banking rules stay unchanged
- keep `expanded_route_choice` metadata reserved for the existing deeper lower-loop/deep-cache route

Add new map schema only if existing fields cannot describe the pocket decision.

## Runtime/UI Boundaries

Use existing systems:

- salvage collection
- cargo capacity and banking
- oxygen pressure
- hazard reset/restore behavior
- route outcome/result text
- compact status overlay

Do not add:

- economy, upgrades, inventory screens, persistent saves, or loadouts
- enemies, moving hazards, health systems, or combat
- procedural maps or whole full-sketch productionization
- broad terrain, player, boat, prop, or background art replacement
- modal tutorial UI or a large HUD rewrite

If runtime feedback needs code, keep it narrowly scoped and avoid growing oversized files when a small helper is practical.

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-production-slice-route`
- `--smoke-safe-deep-route-choice`
- `--smoke-pass-08-route-extension`
- `--smoke-pass-07-hazard-route-pressure`
- `--smoke-timed-salvage`
- `--smoke-hazard-pressure`

Pass 09 should add one focused smoke for the pocket decision. The smoke should report segment id, target id, route id/result, path sizes, held cargo, banked score, oxygen, and return state.

## Visual/Capture Plan

Add one focused capture for the southwest pocket decision. It should frame:

- the pocket marker/payoff context
- the player near or after the detour payoff
- compact overlay or result text if runtime feedback changes
- enough terrain context to see why it is a detour

Do not accept broad baseline changes until comparison sheets show the intentional difference. Reference slices 02-04 should stay unchanged.

## Deferred Work

Keep these out of Pass 09:

- slice-03 polish issues #52 and #53
- another broad connector or full-map productionization
- economy, upgrades, inventory, enemies, saves, and procedural generation
- broad art replacement
- multi-tool or complex interaction systems

## Exit Criteria

Pass 09 is done when:

- the source rule is documented
- the pocket payoff/metadata is authored through the generator/source path
- existing route systems remain stable
- deterministic smoke protects the pocket decision
- a focused capture exists for visual review
- intentional visual differences are reviewed and accepted or explicitly deferred
- public Web preview is verified for the deployed state
- closeout records what changed, what stayed stable, and the recommended next direction
