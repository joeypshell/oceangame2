# Controlled Gameplay Pass 10 Source Rules

Date: 2026-07-08

Issue: #202 `Document Pass 10 return-pressure source rules and target route segment`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_10_PLAN.md`

## Decision

Pass 10 should use the existing lower-loop return path in `production_slice_01` to make cargo banking pressure readable.

Selected pressure target:

```text
salvage_return_branch
```

Selected route context:

```text
lower_loop_route -> salvage_lower_loop -> salvage_deep_right_cache -> salvage_return_branch -> surface_boat_entry
```

The intended player decision is: after collecting the lower-loop valuable salvage and completing the timed deep-right cache, the two-item cargo hold is full. When the player reaches the return branch, the remaining pickup should read as something to bank for, not silently vanish or invite over-collection. The sensible choice is to return to `surface_boat_entry`, bank held cargo, and then decide whether to make another push.

## Source Metadata

Author the Pass 10 decision through the production-slice source path, not through Godot scene edits.

Recommended entity annotation for #203:

```json
{
  "id": "salvage_return_branch",
  "route_choice_id": "return_branch_bank_prompt",
  "validation_route": "return_pressure_decision",
  "route_order": 0
}
```

Recommended marker annotation for #203:

```json
{
  "id": "return_pressure_to_boat",
  "type": "marker"
}
```

The marker should cover the small return-pressure area around `salvage_return_branch` and the lower-loop route back toward the boat. It is a review/smoke annotation only; it must not change collision, extraction, spawn, salvage scoring, oxygen, hazards, or terrain topology.

## Target IDs

- Entry/extraction: `surface_boat_entry`
- Carry-pressure pickups: `salvage_lower_loop`, `salvage_deep_right_cache`
- Pass 10 pressure target: `salvage_return_branch`
- Existing nearby optional detour: `salvage_southwest_return_cache`
- Existing lower-loop marker: `lower_loop_route`
- New marker: `return_pressure_to_boat`
- New validation route: `return_pressure_decision`
- New route choice id: `return_branch_bank_prompt`

## Reachability

The selected target is already part of the reachable default slice:

- `salvage_return_branch` is in bounds at tile `(17, 58)`.
- It is non-solid in the current source map.
- The current validator reaches it from `surface_boat_entry`.
- Because the map is a connected open-water graph, the same validated route is returnable to the boat extraction rectangle.

No terrain topology change is required for this pass.

## Runtime Meaning

The metadata should let runtime, smoke, and capture code identify the return-pressure state without changing general salvage semantics.

Expected behavior stays within existing systems:

- `salvage_return_branch` remains normal common salvage.
- Cargo capacity stays two pickups.
- Completing `salvage_deep_right_cache` after `salvage_lower_loop` fills cargo.
- A full-cargo player near or trying `salvage_return_branch` should receive compact return/bank feedback.
- The target must remain available while cargo is full.
- Banking at `surface_boat_entry` frees capacity and preserves normal score semantics.

## Validation And Smoke Expectations

Pass 10 smoke should report:

- target id: `salvage_return_branch`
- validation route: `return_pressure_decision`
- route choice id: `return_branch_bank_prompt`
- held cargo before banking
- banked score after returning to `surface_boat_entry`
- whether the target remains available while cargo is full
- compact feedback text
- oxygen before/after the return-pressure moment

Existing smokes should remain stable, especially:

- `--smoke-cargo-capacity`
- `--smoke-timed-salvage`
- `--smoke-safe-deep-route-choice`
- `--smoke-pass-09-southwest-pocket-decision`

## Deferred

Do not use this pass to:

- move or resize terrain
- change cargo capacity
- convert the whole full sketch
- add inventory/economy/upgrades
- replace broad art assets
- work on #52 or #53 slice-03 polish
