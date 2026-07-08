# Controlled Gameplay Pass 13 Source Rules

Date: 2026-07-08

Issue: #237 `Document Pass 13 route commitment source rules and target route chain`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_13_PLAN.md`

## Decision

Pass 13 should add exactly one source-authored route commitment objective to
`production_slice_01`.

Selected objective:

```text
deep_cache_route_objective
```

Selected route context:

```text
deep_cache_commitment
```

The objective is complete only when the player banks both selected deep-route
salvage targets at extraction during the run. It should make the existing
lower-loop/deep-cache chain read as one intentional expedition target without
moving terrain, changing salvage behavior, adding a new map segment, or adding
quest/economy/inventory systems.

## Target Route Chain

Expected player chain:

```text
surface_boat_entry
-> lower_loop_route
-> salvage_lower_loop
-> lower_loop_to_deep_cache_pressure
-> salvage_deep_right_cache
-> lower_loop_oxygen_rest_pocket / return_pressure_to_boat
-> surface_boat_entry
```

Required banked targets:

- `salvage_lower_loop`
- `salvage_deep_right_cache`

Supporting source markers:

- `lower_loop_route`
- `lower_loop_to_deep_cache_pressure`
- `lower_loop_oxygen_rest_pocket`
- `return_pressure_to_boat`

Related but not required:

- `salvage_entry_shaft`: safe-route comparison target; must not complete the objective.
- `salvage_return_branch`: return-pressure pickup; must remain normal cargo/banking pressure.
- `salvage_southwest_return_cache`: southwest-pocket detour; must remain separate from the objective.

No new terrain topology or marker rectangle is required for Pass 13 source
authoring. The objective should reference the existing source ids above.

## Source Metadata

Author the objective through the production-slice source path in
`tools/create_production_slice_map.py`. The generated map should eventually
include one metadata record shaped like:

```json
{
  "id": "deep_cache_route_objective",
  "route_context": "deep_cache_commitment",
  "label": "Deep cache route",
  "required_banked_targets": [
    "salvage_lower_loop",
    "salvage_deep_right_cache"
  ],
  "supporting_marker_ids": [
    "lower_loop_route",
    "lower_loop_to_deep_cache_pressure",
    "lower_loop_oxygen_rest_pocket",
    "return_pressure_to_boat"
  ],
  "intent": "Pass 13 route commitment objective requiring the player to bank the lower-loop payoff and timed deep-right cache in one committed route chain."
}
```

Recommended container for #238/#239:

```text
route_objectives
```

This should be map metadata, not an entity that creates collision, extraction,
pickup behavior, score, oxygen, or visual art by itself.

## Source Versus Runtime State

Map source data should own:

- objective id
- display label
- route context
- required banked target ids
- supporting marker ids for validation, smoke setup, and capture framing
- intent text explaining the player decision

Runtime should derive:

- whether each required target is uncollected, held, or banked
- compact objective progress such as `Objective: Deep cache 1/2`
- objective completion only after all required targets are banked at extraction
- result-panel text for complete or incomplete objective state
- reset/failure cleanup from existing run state

Map source data must not author:

- current objective progress
- held or banked runtime state
- cargo capacity
- salvage score or oxygen bonus
- result text state
- timers, cooldowns, or retry history
- economy, upgrades, inventory, quests, achievements, saves, enemies, or procedural data

## Interaction With Existing Systems

The objective must preserve existing semantics:

- Safe-route banking via `salvage_entry_shaft` remains valid but does not complete the deep-cache objective.
- `salvage_lower_loop` by itself gives at most partial objective progress.
- `salvage_deep_right_cache` still requires its `timed_salvage` interaction before pickup.
- Held targets do not count as objective completion until banked at `surface_boat_entry`.
- Two-item cargo capacity remains the pressure point for carrying both required targets back.
- Hazard contact restores held/unbanked salvage normally and must not count restored targets as banked.
- Oxygen depletion ends the run through the existing failed expedition result path and leaves the objective incomplete unless both targets were already banked.
- The Pass 12 `lower_loop_oxygen_rest_pocket` can help oxygen planning but must not complete, bank, score, or reset objective progress by itself.
- `return_pressure_to_boat` and `salvage_return_branch` keep their existing return/banking pressure role.
- Existing route outcome text may coexist with objective result text, but source metadata should not replace route outcome semantics.

## Validation Expectations

Issue #238 should add validation rules for the new metadata before #239 authors
it in `production_slice_01`.

Expected validation rules:

- `route_objectives`, when present, is a list.
- Each objective id is unique and lower_snake_case.
- `route_context` is lower_snake_case.
- `label` is compact display-safe text.
- `required_banked_targets` is a non-empty list of unique salvage ids.
- Each required target exists in `entities`, has `type: "salvage"`, is not a `stress_marker`, is in bounds, non-solid, and reachable.
- Supporting marker ids, when present, exist in `zones` with `type: "marker"`.
- The objective record must not contain coordinates, score values, oxygen values, cargo limits, or runtime progress.
- `production_slice_01` should author only one Pass 13 route commitment objective.

## Source Authoring Verification

After #239 authors the objective through the generator, run:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
```

Later runtime/smoke issues should preserve:

- `--smoke-safe-deep-route-choice`
- `--smoke-timed-salvage`
- `--smoke-cargo-capacity`
- `--smoke-hazard-pressure`
- `--smoke-pass-12-oxygen-rest-pressure`

The new Pass 13 smoke should prove safe-route completion, partial completion,
full completion, hazard reset, oxygen failure, cargo pressure, timed salvage,
and rest-pocket behavior without widening this source-rules issue.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes
the selected goal.
