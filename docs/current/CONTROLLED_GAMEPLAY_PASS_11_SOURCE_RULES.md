# Controlled Gameplay Pass 11 Source Rules

Date: 2026-07-08

Issue: #215 `Document Pass 11 source rules and target route segment`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_11_PLAN.md`

## Decision

Pass 11 should use a new source-authored marker on the approach to the southwest return-pocket payoff in `production_slice_01`.

Selected cue marker:

```text
southwest_pocket_pre_pickup_cue
```

Selected target payoff:

```text
salvage_southwest_return_cache
```

Selected route context:

```text
surface_boat_entry -> lower_loop_route -> southwest_pocket_pre_pickup_cue -> southwest_return_pocket_extension -> salvage_southwest_return_cache -> surface_boat_entry
```

The intended player decision is: before collecting the valuable southwest pocket payoff, the player sees compact feedback that the pocket is an optional detour. This makes the remembered-place route readable before the reward fires, while preserving the existing Pass 09 payoff feedback after collection.

## Source Metadata

Author the Pass 11 cue through the production-slice source path, not through Godot scene edits.

Recommended marker annotation for #216:

```json
{
  "id": "southwest_pocket_pre_pickup_cue",
  "type": "marker",
  "x": 12,
  "y": 65,
  "w": 16,
  "h": 9,
  "route_cue_id": "southwest_pocket_pre_pickup_cue",
  "cue_target_id": "salvage_southwest_return_cache",
  "cue_text": "Optional pocket ahead",
  "cue_condition": "target_uncollected"
}
```

This marker should be a review/smoke/runtime annotation only. It must not change collision, extraction, spawn, salvage scoring, cargo capacity, oxygen tuning, hazard behavior, camera tests, or terrain topology.

The target salvage should keep its existing Pass 09 metadata:

```json
{
  "id": "salvage_southwest_return_cache",
  "route_choice_id": "southwest_pocket_detour",
  "validation_route": "southwest_pocket_decision",
  "route_order": 0
}
```

## Target IDs

- Entry/extraction: `surface_boat_entry`
- Existing lower-loop marker: `lower_loop_route`
- Existing pocket marker: `southwest_return_pocket_extension`
- New cue marker: `southwest_pocket_pre_pickup_cue`
- Cue target: `salvage_southwest_return_cache`
- Existing route choice id: `southwest_pocket_detour`
- Existing payoff validation route: `southwest_pocket_decision`
- New cue text: `Optional pocket ahead`

## Reachability

The selected cue area is within the already reachable lower-loop route:

- The marker rectangle is in bounds.
- It sits above and left of `salvage_southwest_return_cache`, so it can trigger before the pickup.
- The current validator reaches every open tile in `production_slice_01` from `surface_boat_entry`.
- The same connected open-water graph makes the route returnable to the boat extraction rectangle.

No terrain topology change is required.

## Runtime Meaning

The marker should let runtime, smoke, and capture code identify the pre-pickup cue without changing salvage semantics.

Expected behavior stays within existing systems:

- The cue appears only while `salvage_southwest_return_cache` is still available.
- `salvage_southwest_return_cache` remains an instant `valuable` salvage target.
- Existing `Southwest pocket payoff +300` collection feedback remains the pickup payoff text.
- Cargo, banking, oxygen, hazard reset, oxygen failure, and result-panel behavior remain unchanged.

## Validation And Smoke Expectations

Pass 11 smoke should report:

- cue marker id: `southwest_pocket_pre_pickup_cue`
- target id: `salvage_southwest_return_cache`
- cue text: `Optional pocket ahead`
- target availability before cue and after pickup
- held/banked cargo state
- oxygen before/after the cue moment
- whether the cue clears or no longer applies after collection

Existing smokes should remain stable, especially:

- `--smoke-pass-09-southwest-pocket-decision`
- `--smoke-pass-10-return-pressure`
- `--smoke-safe-deep-route-choice`
- `--smoke-timed-salvage`
- `--smoke-hazard-pressure`

## Deferred

Do not use this pass to:

- move or resize terrain
- move `salvage_southwest_return_cache`
- change cargo capacity, scoring, oxygen tuning, hazards, or extraction
- convert the whole full sketch
- add inventory/economy/upgrades/tools
- replace broad art assets
- work on #52 or #53 slice-03 polish
