# Controlled Gameplay Pass 15 Objective Step Cue Contract

Date: 2026-07-08

Issue: #299 `Document Pass 15 objective step cue source and text contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_15_PLAN.md`

## Decision

Pass 15 should add one source-authored marker for the first in-route step of the existing `deep_cache_route_objective`.

Existing route-objective metadata is enough to define the objective and required targets, but it is not enough to place a precise in-route follow-through cue without hard-coding coordinates in runtime. Pass 15 therefore needs one marker zone authored through the production-slice source path.

This is still a cue, not a new objective system.

## Source Rule

The map source remains:

```text
maps/production_slice_01.greybox.json
```

The generator/source path remains:

```text
tools/create_production_slice_map.py
```

Add exactly one marker zone:

```json
{
  "id": "deep_cache_first_step_cue",
  "type": "marker",
  "x": 0,
  "y": 0,
  "w": 1,
  "h": 1,
  "objective_step_cue": true,
  "objective_id": "deep_cache_route_objective",
  "target_id": "salvage_lower_loop",
  "route_context": "deep_cache_commitment",
  "objective_step_label": "Lower loop",
  "intent": "Pass 15 objective follow-through cue for the first required deep-cache route target."
}
```

The coordinates above are placeholders for the contract only. #301 should choose the marker rectangle in source data.

The marker should also be added to `deep_cache_route_objective.supporting_marker_ids` so smoke/capture tooling can discover the cue as part of the objective context.

## Field Contract

- `objective_step_cue`: required boolean `true` for the selected marker.
- `objective_id`: required lower_snake_case route objective id. For Pass 15: `deep_cache_route_objective`.
- `target_id`: required playable salvage id. For Pass 15: `salvage_lower_loop`.
- `route_context`: required lower_snake_case route grouping. For Pass 15: `deep_cache_commitment`.
- `objective_step_label`: required short display-safe label. For Pass 15: `Lower loop`.

Do not add authored coordinates, score values, oxygen values, cargo limits, objective progress, cue visibility state, completion state, result state, or persistent history outside the marker rectangle.

## Placement Contract

#301 should place the marker so it is:

- in bounds
- non-solid
- reachable from `surface_boat_entry`
- near the lower-loop route context before or around `salvage_lower_loop`
- not inside the boat/extraction area
- not overlapping the timed deep-cache target cue
- not changing terrain topology, collision, spawn, extraction, camera tests, or salvage placement

The marker is invisible in normal gameplay except for the compact overlay cue. Debug overlays may still show marker rectangles as part of existing review tooling.

## Overlay Text

Use this exact cue text:

```text
Objective route: Lower loop
```

The text is intentionally shorter than a tutorial and does not mention controls, quest logs, maps, or external instructions.

## Visibility Rule

Show `Objective route: Lower loop` only when all are true:

- the map has `deep_cache_route_objective`
- the map has marker `deep_cache_first_step_cue`
- the marker references `deep_cache_route_objective`
- the marker references target `salvage_lower_loop`
- the run is active, not complete, and not failed
- the player is inside the marker rectangle
- `salvage_lower_loop` is not currently held
- `salvage_lower_loop` is not banked
- the full objective is not complete

Hide the cue when any are true:

- the player is outside the marker rectangle
- the player is inside the boat/extraction area where Pass 14 start cue owns the no-progress state
- `salvage_lower_loop` is held or banked
- both objective targets are held or banked
- the run is complete or failed
- required marker/objective/target metadata is missing or invalid

If a stronger existing prompt is active, such as cargo-full, hazard, oxygen, rest-pocket, pickup, or result feedback, preserve that prompt. The objective step cue should live in the objective line path, not replace higher-priority prompt text.

## Existing States Preserved

Pass 15 must not change:

- Pass 14 `Objective: Deep cache 0/2` at the boat/extraction area
- Pass 13 objective progress and result text
- objective completion requiring both `salvage_lower_loop` and `salvage_deep_right_cache` to be banked
- instant or timed salvage collection
- cargo capacity and banking
- salvage score or oxygen bonus
- oxygen drain, refill, rest-pocket cap, or failure
- hazard warning, penalty, reset, or tint behavior
- route outcome result text
- camera tests, terrain, collision, spawn, extraction, or accepted baselines

## Fallback Behavior

If the marker or metadata is absent, invalid, unreachable, or not linked to the selected objective, runtime should show no Pass 15 step cue and should preserve existing Pass 13/14 behavior.

Validation should catch authored source mistakes before runtime whenever practical.

## Smoke Expectations

The Pass 15 smoke should verify:

- the cue appears inside `deep_cache_first_step_cue` before `salvage_lower_loop` is collected
- the cue does not appear at the boat/extraction start area
- the cue disappears after `salvage_lower_loop` is held
- the cue stays hidden after `salvage_lower_loop` is banked
- Pass 14 start cue still appears at run start
- Pass 13 objective progress/result text still reports partial, complete, and incomplete states correctly
- hazard reset and oxygen failure do not leave stale cue state

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
