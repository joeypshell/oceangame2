# Controlled Gameplay Pass 25 Final-Dive Objective Contract

Date: 2026-07-09

Issue: #563 `Document Pass 25 final-dive objective source contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_25_PLAN.md`

## Decision

Pass 25 adds one source-authored final-dive objective seed after the Pass 24 lower-left relay follow-through.

The seed is intentionally narrow:

```text
Lower-left relay investigated -> Final dive signal discovered
```

It is not a quest log, mission picker, save-state system, new connector, terrain change, or full final mission. It is a compact source-authored objective clue that lets Milestone 06 decide whether the objective/run-structure lane is complete enough to move to Milestone 07 presentation and game feel.

## Source Rule

The first Pass 25 record should be authored in the source path for the map that contains the relay follow-through payoff:

```text
tools/create_production_slice_04_map.py
maps/production_slice_04.greybox.json
```

Add at most one top-level record in this pass:

```json
{
  "final_dive_objective_seeds": [
    {
      "id": "lower_left_final_dive_signal",
      "trigger": "relay_follow_through_complete",
      "source_objective_id": "lower_left_relay_follow_through",
      "target_id": "slice_04_destination_cache",
      "label": "Final dive signal discovered",
      "result_label": "Final dive signal found",
      "route_context": "final_dive_seed",
      "intent": "Pass 25 capstone seed after confirming the lower-left relay lead."
    }
  ]
}
```

If `final_dive_objective_seeds` is omitted, the map keeps current behavior and shows no Pass 25 final-dive feedback.

## Field Contract

- `id`: required lower_snake_case seed id. For Pass 25: `lower_left_final_dive_signal`.
- `trigger`: required enum. Pass 25 supports only `relay_follow_through_complete`.
- `source_objective_id`: required lower_snake_case id of an existing `relay_follow_through_objectives` record.
- `target_id`: required lower_snake_case playable salvage id that anchors the seed trigger.
- `label`: required compact display-safe overlay text.
- `result_label`: optional compact display-safe result text.
- `route_context`: optional lower_snake_case grouping for smoke/capture diagnostics.
- `intent`: optional human-authored note for review docs and source readability.

Do not author coordinates, terrain, collision, score values, oxygen values, cargo limits, wallet rewards, upgrade state, save state, completion flags, result-panel visibility state, connector unlock state, destination loading behavior, or UI layout in this metadata.

## Trigger Contract

`relay_follow_through_complete` means all of these are true:

- the loaded map has a valid final-dive objective seed record
- `source_objective_id` references a valid relay follow-through objective
- the referenced relay follow-through objective has completed through its normal runtime trigger
- `target_id` references the same playable salvage target, or another valid playable salvage target explicitly chosen by the source contract

The final-dive seed feedback should not appear when the player first spawns, before the relay follow-through is complete, after cargo-full blocking without banking, after hazard reset that restores held salvage, after oxygen failure, or on maps without metadata.

## Placement And Target Contract

The seed is top-level metadata, not a marker rectangle.

For Pass 25, `target_id` should reference the existing `slice_04_destination_cache` salvage target. The seed should not add another pickup or route by default. It provides a capstone clue for compact feedback, smoke output, capture setup, review docs, and the Milestone 06 closeout decision.

If a later pass wants a separate physical capstone marker, it should create a new issue and source contract instead of expanding this one.

## Runtime Boundaries

Runtime may:

- read `final_dive_objective_seeds`
- show compact status/result feedback after the selected trigger
- include seed id, source objective id, target id, route context, and labels in smoke/capture diagnostics

Runtime must not:

- add a quest journal or mission picker
- persist completion to disk
- change primary objective requirements
- change salvage score, cargo, oxygen, upgrades, hazards, connector travel, map topology, collision, spawn, extraction, or camera tests
- show stale final-dive text on failed, reset, cargo-full-blocked, or metadata-omitted paths

## Validation Rules

Validation should catch:

- `final_dive_objective_seeds` that is not a list
- more than one record in the first Pass 25 scope
- missing, duplicate, or non-lower_snake_case `id`
- unsupported `trigger`
- missing or dangling `source_objective_id`
- missing or dangling `target_id`
- `target_id` that is not playable salvage
- referenced target that is out of bounds, solid, unreachable, or invalid under normal salvage rules
- mismatched source objective and target ids for the first relay-follow-through trigger
- non-string or overly broad `label` or `result_label`
- invalid optional `route_context` or `intent`

Normal map validation still applies to route objectives, next-dive prompts, relay follow-through objectives, connectors, markers, salvage, hazards, spawn, extraction, and reachability.

## Smoke And Capture Expectations

`--smoke-pass-25-final-dive-objective` should verify:

- metadata is discovered from source
- feedback is hidden before the relay follow-through completes
- feedback/result text appears after the selected trigger
- source ids and labels match metadata
- cargo-full blocking, hazard reset, oxygen failure, and metadata-omitted paths do not show stale final-dive text

`--capture-pass-25-final-dive-objective` should frame the final-dive seed feedback clearly. It is a review artifact, not baseline acceptance.

## Non-Goals

Pass 25 does not add:

- new terrain, collision, connector topology, or destination slices
- persistent objective history
- mission selection
- inventory/loadout UI
- broad economy or new upgrade rules
- enemies, combat, procedural generation, or full-map productionization
- broad visual replacement or baseline acceptance

Keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal.
