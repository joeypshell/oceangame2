# Controlled Gameplay Pass 08 Plan

Date: 2026-07-08

Issue: #180 `Plan Controlled Gameplay Pass 08 around cautious route-scale expansion`

## Decision

Controlled Gameplay Pass 08 should begin cautious route-scale expansion from the source workflow.

The pass should add one small playable route extension, connector, or return-loop beat to `production_slice_01`. This is not full-map productionization. The goal is to prove that the accepted default slice can grow by one source-authored segment while preserving validation, visual consistency, route readability, existing timed-salvage behavior, and the Pass 07 hazard-pressure beat.

Recommended starting direction for #181 review:

```text
Add a tiny lower-loop route extension or return pocket near the existing lower-loop/deep-cache route.
```

That area already carries the current deepest route pressure: valuable salvage, timed salvage, cargo pressure, oxygen pressure, and `hazard_right_branch`. A small extension there can test route-scale growth without changing the entry shaft, boat spawn, or safe route.

## Target Experience

- The player sees one new small optional route shape, not a new map.
- The extension reads as a deliberate place to explore or use as a return choice.
- Existing oxygen, cargo, timed salvage, and hazard pressure still matter.
- Returning to the boat remains the core success loop.
- The change creates a remembered-place beat that can be reviewed in captures and smokes.

## Meaningful-Change Filter

This pass is worth doing if it creates at least one of:

- route scale: the default slice feels slightly less like a single corridor
- route choice: the player can choose whether to enter a small optional branch or return
- payoff: a small source-authored cue gives the new route a reason to exist
- pressure: oxygen, cargo, or hazard spacing makes the route decision matter
- repeatability: deterministic smoke and captures can protect the new segment

If the selected segment only adds topology clutter, cosmetic noise, or broad system work, keep it out of Pass 08.

## Planned Issue Batch

Recommended implementation order:

1. #180 Plan Controlled Gameplay Pass 08 around cautious route-scale expansion.
2. #181 Select `production_slice_01` route extension segment for Pass 08.
3. #182 Document Pass 08 route-scale source rules.
4. #183 Add Pass 08 source annotation and camera target.
5. #184 Author one tiny source-driven route extension in `production_slice_01`.
6. #185 Add one Pass 08 route-extension payoff or return cue.
7. #186 Add deterministic smoke coverage for Pass 08 route extension.
8. #187 Add focused Pass 08 route-extension review capture.
9. #188 Review and accept Pass 08 route-extension visual impact.
10. #189 Verify public Web preview after Pass 08 route-scale pass.
11. #190 Add Pass 08 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

Map changes must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, runtime nodes, or camera positions to fake the route extension. Change the generator/source path first, regenerate JSON and SVG, then validate reachability and parity.

The pass should preserve:

- `production_slice_01` as the default preview map
- `surface_boat_entry` as the entry and extraction point
- `salvage_entry_shaft` as the short safe target
- `salvage_lower_loop` and `salvage_deep_right_cache` as deeper route targets
- `salvage_deep_right_cache` as the timed-salvage target
- `lower_loop_to_deep_cache_pressure` and `hazard_right_branch` as the Pass 07 pressure beat
- production slices 02-04 as reference slices

## Runtime/UI Boundaries

Use existing runtime behavior unless a later issue documents a small, scoped need:

- salvage collection and cargo capacity stay unchanged
- oxygen drain, refill, failure, and result panel stay unchanged
- timed-salvage progress/cancel/complete behavior stays unchanged
- hazard warning/contact/reset behavior stays unchanged
- route outcome result text stays stable unless the new cue deliberately uses existing route metadata

Do not add:

- enemies, moving hazards, health bars, or combat systems
- inventory, upgrades, economy, tool loadouts, or save files
- tutorial popups, large HUD rewrites, or sound systems
- procedural generation or whole-map productionization
- broad terrain, player, boat, prop, or background art replacement

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-production-slice-route`
- `--smoke-safe-deep-route-choice`
- `--smoke-pass-07-hazard-route-pressure`
- `--smoke-timed-salvage`
- `--smoke-hazard-pressure`
- `--smoke-oxygen-pressure`
- `--smoke-cargo-capacity`

Pass 08 should add deterministic coverage for the selected extension. The smoke output should report segment id, any Pass 08 target/cue id, oxygen, held cargo, banked score, return state, and whether existing deep-route pressure remains intact.

## Visual/Capture Plan

The visual pass should remain focused:

- add or update one focused Pass 08 route-extension capture
- frame the selected route extension, player, relevant cue/payoff, and overlay context
- regenerate only affected normal/debug production-slice captures
- compare normal production-slice captures before accepting any baseline change
- accept only intentional route-extension differences
- never commit `.import` sidecars

Terrain, boat, player, timed-salvage marker, Pass 07 hazard-pressure marker, unrelated props, camera framing, and reference slices should stay stable unless a separate issue explicitly selects them.

## Deferred Work

Keep these out of Pass 08:

- economy, upgrades, inventory screens, persistent saves, loadouts
- enemies, moving hazards, complex damage, or combat systems
- procedural maps or full-map productionization
- broad terrain, player, boat, prop, or background art replacement
- slice-03 polish issues #52 and #53 unless the selected goal changes back to slice-03 presentation

## Exit Criteria

Pass 08 is done when:

- the selected extension segment is documented
- the source rules are documented
- the route extension and any payoff/cue are authored through the generator
- JSON/SVG, reachability, and parity checks pass
- deterministic smoke protects the selected extension
- a focused capture shows the new segment clearly
- normal visual baselines are reviewed for drift
- public Web preview is verified for the deployed runtime
- closeout recommends whether the next pass should deepen the new route, add another small connector, or return to interaction depth
