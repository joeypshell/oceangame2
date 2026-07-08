# Controlled Gameplay Pass 14 Objective Cue Contract

Date: 2026-07-08

Issue: #279 `Document Pass 14 objective cue source and text contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_14_PLAN.md`

## Decision

Pass 14 should use the existing `deep_cache_route_objective` record in `route_objectives` to show one compact start-of-run objective cue at the boat/extraction area.

No new source metadata is required for Pass 14.

The existing fields are enough:

- `id`: selects `deep_cache_route_objective`.
- `label`: supplies the display name. Runtime currently normalizes `Deep cache route` to `Deep cache`.
- `required_banked_targets`: supplies the denominator and completion rule.
- `supporting_marker_ids`: remains useful for smoke/capture framing, but is not needed to decide start-cue text.

## Source Rule

The map source remains:

```text
maps/production_slice_01.greybox.json
```

The selected objective remains:

```text
deep_cache_route_objective
```

Required targets remain:

- `salvage_lower_loop`
- `salvage_deep_right_cache`

Start/extraction entity remains:

```text
surface_boat_entry
```

Do not add coordinates, score values, oxygen values, cargo limits, objective progress, cue visibility state, result state, or persistent history to map data.

## Visibility Rule

The start cue is an overlay objective line in the existing compact status surface.

Show the new 0/2 cue only when all are true:

- the map has `deep_cache_route_objective`
- the run is not complete or failed
- the player is inside the boat/extraction area
- no required target is held or banked

Hide the 0/2 cue when the player leaves the boat/extraction area with no required-target progress. This preserves the Pass 13 rule that normal objective text stays quiet until the player touches the route objective.

If any required target is held or banked, use the existing Pass 13 objective progress states regardless of whether the player is inside extraction.

## Overlay Text States

Use these exact overlay states:

```text
Objective: Deep cache 0/2
Objective: Deep cache 1/2
Objective: Deep cache 2/2 - bank
Objective: Deep cache 1/2 banked
Objective complete: Deep cache
```

State mapping:

- Start/extraction area, no required target held or banked: `Objective: Deep cache 0/2`
- Away from extraction, no required target held or banked: show no objective line
- One required target held and neither required target banked: `Objective: Deep cache 1/2`
- Both required targets held before extraction: `Objective: Deep cache 2/2 - bank`
- One required target banked and the other not held or banked: `Objective: Deep cache 1/2 banked`
- One required target banked and the other held: `Objective: Deep cache 2/2 - bank`
- Both required targets banked: `Objective complete: Deep cache`

The objective line should remain separate from prompt text such as cargo-full, hazard, oxygen-rest, pre-pickup cue, return-to-extraction, or run-complete prompts.

## Result Panel States

Pass 14 does not change Pass 13 result text.

Use these exact result states:

```text
Objective: Deep cache complete
Objective: Deep cache incomplete
```

State mapping:

- Both required targets banked before run completion: `Objective: Deep cache complete`
- Successful extraction without both required targets banked: `Objective: Deep cache incomplete`
- Oxygen failure before both targets are banked: `Objective: Deep cache incomplete`

The result line should be omitted only when the map has no authored `deep_cache_route_objective`.

## Runtime Boundary

Runtime may derive the start cue from:

- current player position relative to extraction
- current run completion/failure state
- objective metadata from `world.get_route_objectives()`
- held and banked required-target ids

Runtime must not duplicate objective target coordinates, route topology, source marker rectangles, scoring values, oxygen values, cargo limits, or objective completion state outside the existing route-commitment feedback flow.

The smallest expected implementation is to extend the route-commitment feedback path so it can return the 0/2 start cue when the caller says the player is in the start/extraction context.

## Existing Semantics Preserved

Pass 14 must not change:

- objective completion: both required targets still must be banked at extraction
- salvage score or oxygen bonus
- cargo capacity
- timed-salvage duration, progress, cancellation, or completion
- hazard warning, penalty, reset, or tint behavior
- oxygen rest-pocket refill, cap, or feedback
- return-pressure and pre-pickup route cue prompts
- route outcome selection and result text
- extraction/completion requirements
- session best score or reset behavior

## Smoke Expectations

The Pass 14 smoke should verify:

- start of run at `surface_boat_entry`: overlay includes `Objective: Deep cache 0/2`
- after moving away from extraction with no objective progress: overlay omits objective text
- after holding one required target: overlay includes `Objective: Deep cache 1/2`
- with both required targets held before banking: overlay includes `Objective: Deep cache 2/2 - bank`
- after banking one required target: overlay includes `Objective: Deep cache 1/2 banked`
- after banking both required targets: overlay includes `Objective complete: Deep cache`
- safe-route completion still produces `Objective: Deep cache incomplete`
- complete deep-cache run still produces `Objective: Deep cache complete`
- hazard reset and oxygen failure do not create persistent objective history

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
