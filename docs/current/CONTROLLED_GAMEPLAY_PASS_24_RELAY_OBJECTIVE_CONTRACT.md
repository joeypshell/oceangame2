# Controlled Gameplay Pass 24 Relay Objective Contract

Date: 2026-07-09

Issue: #543 `Document Pass 24 relay follow-through objective source contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_24_PLAN.md`

## Decision

Pass 24 adds one source-authored relay follow-through objective to `production_slice_04`.

The objective pays off the Pass 23 result prompt:

```text
Next dive: Investigate lower-left relay
```

It should confirm that the player reached or completed the lower-left relay lead through the existing connector/destination context. This is a compact objective beat, not a quest log, mission picker, persistent save flag, new connector, or broad cross-slice objective system.

## Source Rule

The source path remains:

```text
tools/create_production_slice_04_map.py
maps/production_slice_04.greybox.json
```

Add exactly one top-level record:

```json
{
  "relay_follow_through_objectives": [
    {
      "id": "lower_left_relay_follow_through",
      "trigger": "destination_payoff_banked",
      "connector_id": "lower_left_loop_connector",
      "entry_id": "relay_sub_entry",
      "target_id": "slice_04_destination_cache",
      "label": "Relay lead confirmed",
      "result_label": "Lower-left relay investigated",
      "route_context": "lower_left_loop",
      "source_prompt_id": "deep_cache_next_dive_prompt",
      "intent": "Pass 24 follow-through for the Pass 23 next-dive prompt after reaching the lower-left relay destination cache."
    }
  ]
}
```

If `relay_follow_through_objectives` is omitted, the map keeps current behavior and shows no Pass 24 follow-through feedback.

## Field Contract

- `id`: required lower_snake_case objective id. For Pass 24: `lower_left_relay_follow_through`.
- `trigger`: required enum. Pass 24 supports only `destination_payoff_banked`.
- `connector_id`: required lower_snake_case connector id from the source map that led here. For Pass 24: `lower_left_loop_connector`.
- `entry_id`: required lower_snake_case destination entry id. For Pass 24: `relay_sub_entry`.
- `target_id`: required lower_snake_case authored salvage/entity id. For Pass 24: `slice_04_destination_cache`.
- `label`: required compact display-safe feedback text.
- `result_label`: optional compact display-safe result text.
- `route_context`: optional lower_snake_case route grouping. For Pass 24: `lower_left_loop`.
- `source_prompt_id`: optional lower_snake_case id of the prompt that pointed here. For Pass 24: `deep_cache_next_dive_prompt`.
- `intent`: optional human-authored note for review docs/source readability.

Do not author score values, oxygen values, cargo limits, wallet rewards, upgrade state, save state, completion flags, result-panel visibility state, connector unlock state, or new travel behavior in this metadata.

## Trigger Contract

`destination_payoff_banked` means all of these are true:

- the loaded map has a valid relay follow-through objective record
- `target_id` references playable salvage in the loaded map
- the referenced salvage is banked through normal cargo/extraction rules
- the target is associated with the connector/destination context named by `connector_id`, `entry_id`, and `route_context`

The follow-through feedback should not appear when the player first spawns, before the target is banked, after cargo-full blocking without banking, after hazard reset that restores held salvage, after oxygen failure, or on maps without metadata.

## Placement And Target Contract

The objective itself is top-level metadata, not a marker rectangle.

`target_id` must point to an authored playable entity that already satisfies normal salvage validation. For Pass 24, use the existing destination payoff salvage `slice_04_destination_cache`.

`entry_id` should point to an authored spawn/entry context that already exists. For Pass 24, use `relay_sub_entry`.

These references do not create a connector, move a connector, move the player, add a map screen, alter extraction, or change route validation. They provide context for compact feedback, smoke output, capture setup, and review docs.

## Runtime Boundaries

Runtime may:

- read `relay_follow_through_objectives`
- show compact status/result feedback after the selected trigger
- include objective id, connector id, entry id, target id, and label in smoke/capture diagnostics

Runtime must not:

- add a quest journal or objective picker
- persist completion to disk
- change primary objective requirements
- change salvage score, cargo, oxygen, upgrades, hazards, connector travel, map topology, collision, spawn, extraction, or camera tests
- show stale follow-through text on failed, reset, cargo-full-blocked, or metadata-omitted paths

## Validation Rules

Validation should catch:

- `relay_follow_through_objectives` that is not a list
- more than one record in the first Pass 24 scope
- missing or non-lower_snake_case `id`
- duplicate objective ids
- unsupported `trigger`
- missing or dangling `connector_id`, `entry_id`, or `target_id`
- `target_id` that is not playable salvage
- referenced target that is out of bounds, solid, unreachable, or invalid under normal salvage rules
- non-string or overly broad `label` or `result_label`
- invalid optional `route_context`, `source_prompt_id`, or `intent`

Normal map validation still applies to route objectives, next-dive prompts, connectors, markers, salvage, hazards, spawn, extraction, and reachability.

## Smoke And Capture Expectations

`--smoke-pass-24-relay-follow-through` should verify:

- metadata is discovered from source
- feedback is hidden before the destination payoff is banked
- feedback appears after the selected target is banked
- source ids and labels match metadata
- cargo-full blocking, hazard reset, oxygen failure, and metadata-omitted paths do not show stale follow-through text

`--capture-pass-24-relay-follow-through` should frame the relay follow-through feedback clearly. It is a review artifact, not baseline acceptance.

## Non-Goals

Pass 24 does not add:

- new terrain, collision, connector topology, or destination slice
- persistent objective history
- mission selection
- inventory/loadout UI
- broad economy or new upgrade rules
- enemies, combat, procedural generation, or full-map productionization
- broad visual replacement or baseline acceptance

Keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal.
