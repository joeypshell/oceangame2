# Controlled Gameplay Pass 08 Segment Decision

Date: 2026-07-08

Issue: #181 `Select production_slice_01 route extension segment for Pass 08`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_08_PLAN.md`

## Decision

Select the southwest return pocket near the lower-loop route as the Pass 08 route-scale expansion segment.

Selected segment:

```text
southwest_return_pocket_extension
from: salvage_return_branch at tile (17, 58)
through: lower-left return pocket around tiles (3-22, 67-82)
target/cue candidate: southwest_return_cache near tile (12, 78)
return context: lower_loop_route and boat extraction
```

The intended player decision is: after entering the lower-loop route, briefly detour into a small southwest return pocket for a modest payoff or route cue, or skip it and continue toward `salvage_lower_loop`, `hazard_right_branch`, and the timed `salvage_deep_right_cache`.

## Why This Segment

- It grows route scale from an already readable lower-loop area instead of adding a new map.
- It uses an underused pocket that is already close to the accepted lower-loop camera context.
- It can create a small remembered-place beat without changing the boat entry, safe route, timed-salvage target, or Pass 07 hazard-pressure segment.
- It can support a modest common salvage payoff or return cue without expanding economy, inventory, tools, enemies, or procedural maps.
- It should be implementable through the existing `tools/create_production_slice_map.py` source/generator path.

## Current Source Context

Relevant existing source objects:

- `salvage_return_branch` at `(17, 58)`
- `salvage_lower_loop` at `(30, 67)`
- `hazard_lower_bend` at `(36, 61)`
- `lower_loop_route` marker at `(12, 55, 52, 24)`
- existing `production_slice_lower_loop` camera view centered at `(36, 66)`

The current JSON grid already contains open lower-left pocket space below and left of `salvage_return_branch`. Pass 08 should activate this as a small optional route beat rather than introduce a broad new topology region.

## Implementation Recommendation

Recommended #183 source annotation:

- add a marker zone named `southwest_return_pocket_extension`
- add a focused camera test only if `production_slice_lower_loop` does not frame the pocket clearly enough
- keep the annotation non-gameplay by itself

Recommended #184 source work:

- prefer a tiny source-driven cleanup or alcove extension if needed for readability
- avoid changes that alter the main lower-loop/deep-cache route
- avoid opening a crop-edge escape or implying whole-map continuation

Recommended #185 payoff/cue:

- prefer one common salvage target or marker-style return cue near the pocket
- avoid adding a second timed salvage target or a new valuable deep-route reward unless a later plan explicitly chooses that

## Alternatives Not Selected

- Entry shaft expansion: too close to the safe route and boat, so it would not test route-scale growth meaningfully.
- Central crossing expansion: already busy with salvage and hazard readability; adding topology there risks clutter.
- Deep-right bottom expansion: too close to `salvage_deep_right_cache` and the Pass 07 hazard-pressure beat, so it risks blurring the timed-salvage payoff.
- Slice-03 camera/topology polish: still deferred under #52/#53 unless slice-03 presentation becomes the selected goal.
- Whole full-sketch expansion: explicitly out of scope for Pass 08.

## Affected Review Areas

Likely affected assets and source areas:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`
- normal/debug production-slice-01 lower-loop captures
- accepted production-slice-01 baseline only after visual review

Expected smoke/capture needs:

- new `--smoke-pass-08-route-extension`
- new focused route-extension capture
- existing `--smoke-production-slice-route`
- existing `--smoke-safe-deep-route-choice`
- existing `--smoke-pass-07-hazard-route-pressure`

## Non-Goals

- no default-map switch
- no production slices 02-04 changes
- no economy, upgrades, inventory, enemies, procedural generation, or save files
- no broad art replacement
- no hand-edited Godot scene geometry or collision

## Verification

Commands for this decision:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
git diff --check
python tools/check_file_lengths.py
```
