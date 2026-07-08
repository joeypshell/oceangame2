# Controlled Gameplay Pass 13 Text Contract

Date: 2026-07-08

Issue: #247 `Document Pass 13 objective feedback/result text contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_13_PLAN.md`
Depends on: #237 Pass 13 source-rules doc

## Purpose

Pass 13 adds one compact route commitment objective for the existing deep-cache
route. This contract defines the exact overlay and result-panel text before
runtime work begins.

The objective text must stay inside the existing compact overlay and result
panel surfaces. Do not add a quest log, tutorial panel, achievement system,
inventory screen, save state, or persistent objective history.

## Objective

Objective id:

```text
deep_cache_route_objective
```

Display name:

```text
Deep cache
```

Required targets:

- `salvage_lower_loop`
- `salvage_deep_right_cache`

Completion rule:

```text
Both required targets must be banked at extraction during the run.
```

Held cargo is progress feedback, not completion.

## Overlay Text States

The overlay should show no objective line before the player has touched the
deep-cache route objective. The existing salvage, oxygen, route, cargo, hazard,
timed-salvage, rest-pocket, and return-pressure lines stay unchanged.

Use these exact compact text states:

```text
Objective: Deep cache 1/2
Objective: Deep cache 2/2 - bank
Objective: Deep cache 1/2 banked
Objective complete: Deep cache
```

State mapping:

- No required target held or banked: show no objective line.
- One required target is held and neither required target is banked: `Objective: Deep cache 1/2`
- Both required targets are held before extraction: `Objective: Deep cache 2/2 - bank`
- One required target is banked and the other is not banked: `Objective: Deep cache 1/2 banked`
- Both required targets are banked: `Objective complete: Deep cache`

If one target is banked and the other is held, use:

```text
Objective: Deep cache 2/2 - bank
```

This makes the remaining action clear: return to extraction and bank the held
target.

## Result Panel Text States

The result panel should add one objective line below existing score/salvage
summary text and near the existing route outcome line.

Use these exact result text states:

```text
Objective: Deep cache complete
Objective: Deep cache incomplete
```

State mapping:

- Both required targets banked before run completion: `Objective: Deep cache complete`
- Successful extraction without both required targets banked: `Objective: Deep cache incomplete`
- Oxygen failure before both targets are banked: `Objective: Deep cache incomplete`

The objective line should be omitted only when the map has no authored
`deep_cache_route_objective` metadata.

## Route Outcome Relationship

Objective text should coexist with existing route outcome text. It should not
replace or rename the current route outcome line.

Expected completed deep-route result layout:

```text
Route: Deep route
Objective: Deep cache complete
```

Expected incomplete deep-route result layout:

```text
Route: Deep route
Objective: Deep cache incomplete
```

If a safe-route run does not produce `Route: Deep route`, the objective line can
still say `Objective: Deep cache incomplete` when the objective exists on the
map. This creates the retry target without changing safe-route banking.

## Reset And Failure Behavior

Normal reset:

- Clear all temporary overlay objective text.
- Keep no persistent objective history.
- The next run starts with no objective line until the player touches a required target.

Hazard reset:

- Restored held targets no longer count as held or banked.
- If no required target remains banked, return to no objective line after the hazard feedback clears.
- If one required target was already banked before the hazard, show `Objective: Deep cache 1/2 banked` after the hazard feedback clears.
- Hazard reset must not produce result-panel objective text unless the hazard penalty also triggers oxygen failure.

Oxygen failure:

- Stop updating overlay objective text when the failed expedition result panel appears.
- Show `Objective: Deep cache incomplete` unless both required targets were already banked before the run ended.
- Preserve existing oxygen failure score and session-best semantics.

Run completion:

- Stop updating overlay objective text when the completion result panel appears.
- Show the complete or incomplete result text based only on banked required targets.

## Existing System Boundaries

The objective text must not change:

- salvage score or oxygen bonus
- cargo capacity
- timed-salvage duration or cancellation
- hazard warning, penalty, reset, or tint behavior
- oxygen rest-pocket refill, cap, or feedback
- return-pressure feedback at `salvage_return_branch`
- route outcome selection
- extraction/completion requirements
- session best score or reset behavior

## Runtime Implementation Notes

Later runtime work should derive text from current run state:

- required target ids from source metadata
- whether each required target is uncollected, held, restored, or banked
- whether the result panel is showing completion or failure

Do not duplicate target positions or route topology in runtime UI code.

## Smoke Expectations

The Pass 13 smoke should assert these text states:

- safe-route completion: result includes `Objective: Deep cache incomplete`
- one required target held: overlay includes `Objective: Deep cache 1/2`
- both required targets held before extraction: overlay includes `Objective: Deep cache 2/2 - bank`
- one required target banked: overlay includes `Objective: Deep cache 1/2 banked`
- both required targets banked: overlay includes `Objective complete: Deep cache`
- completed result: result includes `Objective: Deep cache complete`
- hazard reset before banking: objective overlay clears or returns to the banked-only state
- oxygen failure before completion: result includes `Objective: Deep cache incomplete`

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes
the selected goal.
