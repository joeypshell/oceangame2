# Controlled Gameplay Pass 07 Plan

Date: 2026-07-08

Issue: #170 `Plan Controlled Gameplay Pass 07 around hazard/navigation pressure`

## Decision

Controlled Gameplay Pass 07 should add one authored hazard/navigation pressure pattern in `production_slice_01`.

The pass should build on the current safe/deep route and timed-salvage work without expanding map scale. The target is not a new combat system. It is one readable route-pressure moment where the player must steer through or around danger while oxygen, cargo, and return distance matter.

Recommended starting segment for #171 review:

```text
lower-loop/deep-right approach near hazard_lower_bend, hazard_right_branch, salvage_lower_loop, and salvage_deep_right_cache
```

The expected player decision is: take the deeper route toward the timed deep cache while managing hazard spacing and oxygen, or bank/return after safer salvage.

## Target Experience

- The player sees a hazardous passage before committing.
- The route reads as navigable, not unfair or random.
- Warning feedback gives enough time to react before contact.
- Contact remains costly through oxygen penalty and reset, not a health/combat layer.
- The timed deep cache remains the payoff pressure point, not a separate system.
- Returning to the boat with cargo still feels like the main success loop.

## Meaningful-Change Filter

This pass is worth doing if it creates at least one of:

- clearer pressure: a visible route asks for careful movement
- clearer route choice: safe return versus deeper payoff becomes sharper
- clearer remembered-place progress: the lower route has a recognizable danger beat
- clearer replay reason: the player can try to navigate the route cleaner next run

If a proposed change only adds clutter, punishment, or broad systems, keep it out of this pass.

## Planned Issue Batch

Recommended implementation order:

1. #170 Plan Controlled Gameplay Pass 07 around hazard/navigation pressure.
2. #171 Select `production_slice_01` route segment for Pass 07 hazard pressure.
3. #172 Document Pass 07 hazard/navigation pressure rules.
4. #173 Author one source-driven hazard/navigation pressure pattern in `production_slice_01`.
5. #174 Tune hazard warning and contact feedback for the Pass 07 pattern.
6. #175 Add deterministic smoke coverage for Pass 07 hazard route pressure.
7. #176 Add focused Pass 07 hazard/navigation review capture.
8. #177 Review and accept Pass 07 hazard/navigation visual impact.
9. #178 Verify public Web preview after Pass 07 hazard/navigation pass.
10. #179 Add Pass 07 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

Map and hazard changes must come from the source/generator path:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, or camera positions to fake the pattern. If the source needs a hazard move, new hazard, or route annotation, change the source generator first, regenerate the map/preview, then validate reachability and parity.

The pass should preserve:

- `production_slice_01` as default preview
- `boat_spawn` entry and extraction
- existing safe/deep salvage route metadata
- `salvage_deep_right_cache` as the timed target
- existing terrain topology unless #171 proves a tiny source-topology change is necessary
- production slices 02-04 as reference slices

## Runtime/UI Boundaries

Use existing hazard behavior unless #172 proves a small feedback adjustment is needed:

- warning range reports nearby hazard pressure before contact
- contact applies the existing oxygen penalty and reset path
- held/unbanked salvage restores according to current semantics
- active timed-salvage progress clears on hazard or oxygen failure
- cargo, banking, result panel, and session-best behavior remain stable

Do not add:

- enemies or moving hazards
- health bars or damage types
- inventory, upgrades, economy, or tool loadouts
- tutorial modals, large HUD rewrites, or sound systems
- procedural maps or whole-map productionization

## Validation/Smoke Plan

Preserve existing coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `python tools/check_map_parity.py maps/production_slice_01.greybox.json`
- `--smoke-hazard-pressure`
- `--smoke-oxygen-pressure`
- `--smoke-timed-salvage`
- `--smoke-safe-deep-route-choice`
- `--smoke-salvage-loop`
- `--smoke-cargo-capacity`

Pass 07 should add or harden deterministic coverage for the selected route-pressure pattern. The smoke output should report route segment id, hazard id, warning state, oxygen before/after contact, held cargo, banked score, and reset/restoration state.

## Visual/Capture Plan

The visual pass should remain focused:

- add or update a focused hazard/navigation review capture
- frame the selected route segment, hazard, player, relevant salvage context, and overlay warning
- compare normal production-slice captures before accepting any baseline change
- accept only intentional hazard/navigation differences
- never commit `.import` sidecars

Terrain, boat, player, timed-salvage marker, unrelated props, camera framing, and reference slices should stay stable unless a separate issue explicitly selects them.

## Deferred Work

Keep these out of Pass 07:

- economy, upgrades, inventory screens, persistent saves, loadouts
- enemies, moving hazards, complex damage, or combat systems
- procedural maps or full-map productionization
- broad terrain, player, boat, prop, or background art replacement
- slice-03 polish issues #52 and #53 unless the selected goal changes back to slice-03 presentation

## Exit Criteria

Pass 07 is done when:

- the selected route-pressure segment is documented
- source-authored hazard/navigation pressure is implemented or confirmed from existing data
- feedback rules are documented
- deterministic smoke protects the selected pattern
- a focused capture shows the route pressure clearly
- normal visual baselines are reviewed for drift
- public Web preview is verified for the deployed runtime
- closeout recommends whether the next pass should deepen interaction, add another pressure pattern, or begin cautious route-scale expansion
