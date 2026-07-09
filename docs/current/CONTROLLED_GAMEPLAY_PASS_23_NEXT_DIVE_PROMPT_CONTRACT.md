# Controlled Gameplay Pass 23 Next-Dive Prompt Contract

Date: 2026-07-09

Issue: #524 `Document Pass 23 next-dive objective prompt source contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_23_PLAN.md`

## Decision

Pass 23 adds one source-authored next-dive prompt to `production_slice_01`.

The prompt appears after the player completes the current primary deep-cache dive objective and returns to the boat. It gives the result flow one compact next-run direction:

```text
Next dive: Investigate lower-left relay
```

This is a result prompt, not a quest log, mission selector, persistent save flag, new connector, or cross-slice objective chain.

## Source Rule

The source path remains:

```text
tools/create_production_slice_map.py
maps/production_slice_01.greybox.json
```

Add exactly one top-level record:

```json
{
  "next_dive_objective_prompts": [
    {
      "id": "deep_cache_next_dive_prompt",
      "trigger": "primary_objective_complete",
      "objective_id": "deep_cache_route_objective",
      "target_id": "lower_left_loop_connector",
      "label": "Next dive: Investigate lower-left relay",
      "route_context": "lower_left_loop",
      "intent": "Pass 23 result prompt pointing the next dive toward the lower-left relay after Deep cache completion."
    }
  ]
}
```

If `next_dive_objective_prompts` is omitted, the map keeps current behavior and shows no Pass 23 next-dive prompt.

## Field Contract

- `id`: required lower_snake_case prompt id. For Pass 23: `deep_cache_next_dive_prompt`.
- `trigger`: required enum. Pass 23 supports only `primary_objective_complete`.
- `objective_id`: required lower_snake_case route objective id. For Pass 23: `deep_cache_route_objective`.
- `target_id`: optional lower_snake_case authored marker/entity id. For Pass 23: `lower_left_loop_connector`.
- `label`: required compact display-safe text. For Pass 23: `Next dive: Investigate lower-left relay`.
- `route_context`: optional lower_snake_case route grouping. For Pass 23: `lower_left_loop`.
- `intent`: optional human-authored note for review docs/source readability.

Do not author score values, oxygen values, cargo limits, wallet rewards, upgrade state, completion state, result state, save state, or prompt visibility state in this metadata.

## Trigger Contract

`primary_objective_complete` means all of these are true:

- the loaded map has `primary_route_objective_id`
- `objective_id` matches that primary route objective
- the primary objective has been completed through normal runtime rules
- the player returned to extraction and entered the existing completed-result flow

The prompt should not appear during normal exploration before result completion. It should not appear for failed runs, oxygen failures, hazard resets, manual resets before completion, or partial banking that does not complete the primary objective.

## Placement And Target Contract

The prompt itself is top-level metadata, not a marker rectangle.

`target_id` should point to an authored source record that already exists. For Pass 23, use the existing `lower_left_loop_connector` marker so smoke/capture/review code can verify the prompt points to a real remembered place.

The target reference does not create a connector, move a connector, unlock travel, move the player, add a map screen, or change route validation. It is context for text, smoke output, and review.

## Runtime Boundaries

Runtime may:

- read `next_dive_objective_prompts`
- show the prompt in the existing result/status flow after the selected trigger
- include prompt id, objective id, target id, and label in smoke/capture diagnostics

Runtime must not:

- add a quest journal or objective picker
- persist prompt completion to disk
- change primary objective completion requirements
- change salvage score, cargo, oxygen, upgrades, hazards, connector travel, map topology, collision, spawn, extraction, or camera tests
- show stale next-dive text on failed or reset runs

## Validation Rules

Validation should catch:

- `next_dive_objective_prompts` that is not a list
- more than one prompt in the first Pass 23 scope
- missing or non-lower_snake_case `id`
- duplicate prompt ids
- unsupported `trigger`
- missing or dangling `objective_id`
- `objective_id` that does not match `primary_route_objective_id` for `primary_objective_complete`
- non-string or overly broad `label`
- invalid optional `target_id` or `route_context`
- destination/context target that does not exist as an authored entity or marker

Normal map validation still applies to route objectives, markers, salvage, hazards, spawn, extraction, and reachability.

## Smoke And Capture Expectations

`--smoke-pass-23-next-dive-objective` should verify:

- prompt metadata is discovered from source
- prompt is hidden before primary objective completion
- prompt appears after the primary objective result flow
- prompt label is `Next dive: Investigate lower-left relay`
- prompt target id is `lower_left_loop_connector`
- failed or reset runs do not leave stale prompt text

`--capture-pass-23-next-dive-objective` should frame the completed-result prompt clearly. It is a review artifact, not baseline acceptance.

## Non-Goals

Pass 23 does not add:

- new terrain, collision, connector topology, or destination payoff
- persistent objective history
- mission selection
- inventory/loadout UI
- broad economy or new upgrade rules
- enemies, combat, procedural generation, or full-map productionization
- broad visual replacement or baseline acceptance

Keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal.
