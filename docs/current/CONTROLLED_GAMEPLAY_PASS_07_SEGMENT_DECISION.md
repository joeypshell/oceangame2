# Controlled Gameplay Pass 07 Segment Decision

Date: 2026-07-08

Issue: #171 `Select production_slice_01 route segment for Pass 07 hazard pressure`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_07_PLAN.md`

## Decision

Select the lower-loop to deep-right cache route as the Pass 07 hazard/navigation pressure segment.

Selected segment:

```text
lower_loop_to_deep_cache_pressure
from: salvage_lower_loop at tile (30, 67)
through: hazard_right_branch at tile (57, 66)
to: salvage_deep_right_cache at tile (64, 75)
```

The route already asks the player to commit deeper after collecting `salvage_lower_loop`. It then passes close to `hazard_right_branch` before reaching the timed `salvage_deep_right_cache`. This makes the player decide whether to continue toward a higher-payoff timed target or return with safer cargo.

## Why This Segment

- It connects the existing deep-route payoff pair, `salvage_lower_loop` and `salvage_deep_right_cache`.
- It uses the existing timed-salvage target as the payoff, so the pass deepens current gameplay instead of adding a new system.
- The shortest open-water path from `salvage_lower_loop` to `salvage_deep_right_cache` passes one tile from `hazard_right_branch`, which should create warning/contact pressure without requiring enemies or moving hazards.
- It is covered by the existing `production_slice_lower_loop` camera view and deep-route smoke context.
- It keeps the short safe route untouched, so safe/deep route comparison can remain meaningful.

## Reachability Confirmation

Source-grid path checks from `maps/production_slice_01.greybox.json`:

- Boat entry `(33, 0)` to `salvage_lower_loop` `(30, 67)`: reachable, 100 tile steps.
- `salvage_lower_loop` `(30, 67)` to `salvage_deep_right_cache` `(64, 75)`: reachable, 42 tile steps.
- `salvage_deep_right_cache` `(64, 75)` back to boat entry `(33, 0)`: reachable, 130 tile steps.

Nearest hazard distances along the selected segment:

- `hazard_right_branch` `(57, 66)`: 1 tile from the direct lower-loop to deep-cache path.
- `hazard_lower_bend` `(36, 61)`: 6 tiles from the direct lower-loop to deep-cache path.

This means the selected pressure is primarily `hazard_right_branch`, while `hazard_lower_bend` remains approach/return context.

## Affected Objects

Salvage:

- `salvage_lower_loop`
- `salvage_deep_right_cache`

Hazards:

- primary: `hazard_right_branch`
- supporting context: `hazard_lower_bend`

Camera/capture views:

- normal camera test: `production_slice_lower_loop`
- likely focused review capture: new Pass 07 hazard/navigation capture around `hazard_right_branch`

Smoke coverage:

- existing `--smoke-safe-deep-route-choice`
- existing `--smoke-hazard-pressure`
- planned Pass 07 route-pressure smoke from #175

## Source Recommendation

Existing hazard placement is strong enough for the first Pass 07 pressure target. Do not change terrain topology for this pass.

Recommended #173 source work:

- preserve the current `hazard_right_branch` and `salvage_deep_right_cache` relationship unless visual/runtime review proves it unfair
- add a narrow source annotation or marker for `lower_loop_to_deep_cache_pressure` if useful for capture/smoke selection
- regenerate JSON/SVG only through `tools/create_production_slice_map.py`
- keep `salvage_lower_loop` and `salvage_deep_right_cache` route metadata stable

If #173 finds that a source change is necessary, prefer a one- or two-tile hazard placement tweak over terrain edits.

## Non-Goals

- no new map
- no moving hazards
- no enemies or health system
- no broad HUD change
- no terrain topology change unless later source validation proves the selected route cannot work
- no slice-03 work

## Verification

Commands for this decision:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
git diff --check
```
