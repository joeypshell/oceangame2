# OceanGame Expansion 10 Source Contract

Date: 2026-07-13

Issue: #880

Plan: `docs/current/OCEANGAME_EXPANSION_10_PLAN.md`

## Decision

Expansion 10 authors one regional journey inside `production_level_01`. The
existing `upper_right_current_pocket_gate` remains the first visible promise and
keeps its current coordinates, propulsion-fins requirement, passive traversal,
and opening-region payoff. Two new source-authored current rectangles form the
actual lower-right regional seam. Both use the same `propulsion_fins` capability.

The destination is **Signal Reef**, a restrained background-rock landmark around
the existing lower-right sector anchor. One regional scanner target there creates
a pending discovery that commits only at `surface_boat_entry`.

## Stable Ids

| Role | Id | Display text |
| --- | --- | --- |
| Regional journey | `east_current_signal_reef_route` | Signal Reef route |
| Existing promise | `upper_right_current_pocket_gate` | Strong east current |
| West entry current | `lower_right_west_current_gate` | Signal Reef current |
| East entry current | `lower_right_east_current_gate` | Signal Reef current |
| Landmark zone | `lower_right_signal_reef_landmark` | Signal Reef |
| Landmark backdrop | `lower_right_signal_reef_backdrop` | n/a |
| Scanner target | `lower_right_signal_reef_survey` | Survey Signal Reef |
| Discovery | `lower_right_signal_reef_discovery` | Signal Reef chart |
| Boat payoff | source label | Discovery logged: Signal Reef chart |
| Next lead | source label | Next lead: deeper harmonic below reef |

These ids are full-level-only. Slices 01-04 and their stable ids do not change.

## Regional Journey Record

Add one top-level `regional_journeys` record through the production-level source
helper:

```json
{
  "id": "east_current_signal_reef_route",
  "route_label": "Signal Reef route",
  "promise_gate_id": "upper_right_current_pocket_gate",
  "entry_gate_ids": [
    "lower_right_west_current_gate",
    "lower_right_east_current_gate"
  ],
  "required_capability_id": "propulsion_fins",
  "landmark_zone_id": "lower_right_signal_reef_landmark",
  "survey_target_id": "lower_right_signal_reef_survey",
  "commit_entry_id": "surface_boat_entry",
  "route_context": "east_current_signal_reef_route",
  "intent": "Reuse the taught east-current language to gate one meaningful lower-right region and boat-return discovery."
}
```

The record is immutable source relationship data. It must not contain current
player position, capability ownership, pending/completed state, oxygen, day,
cargo, score, or seed results.

## Regional Current Seam

Keep `upper_right_current_pocket_gate` unchanged at global `(123, 40)`, size
`2 x 2`. It is the remembered promise, not a claim that the old pocket already
contains Signal Reef.

Add these full-level-only marker zones:

```json
{
  "id": "lower_right_west_current_gate",
  "type": "marker",
  "x": 109,
  "y": 81,
  "w": 3,
  "h": 6,
  "current_gate": true,
  "current_direction": "up",
  "current_strength": 2.2,
  "required_capability_id": "propulsion_fins",
  "current_gate_label": "Signal Reef current",
  "current_affordance_role": "barrier",
  "route_context": "east_current_signal_reef_route"
}
```

```json
{
  "id": "lower_right_east_current_gate",
  "type": "marker",
  "x": 145,
  "y": 75,
  "w": 4,
  "h": 4,
  "current_gate": true,
  "current_direction": "up",
  "current_strength": 2.2,
  "required_capability_id": "propulsion_fins",
  "current_gate_label": "Signal Reef current",
  "current_affordance_role": "barrier",
  "route_context": "east_current_signal_reef_route"
}
```

Both rectangles are open in the accepted Expansion 09 topology. Together they
cover the two source-authored entrances into the lower-right component. With
their cells treated as blocked, the boat-reachable set must exclude both the
landmark and `full_level_lower_right_anchor`. With fins, both remain ordinary
collision-active water and at least one route reaches the landmark and returns.

## Landmark And Survey

Add a marker zone at `(132, 108)`, size `10 x 10`, with:

```json
{
  "id": "lower_right_signal_reef_landmark",
  "type": "marker",
  "regional_landmark": true,
  "regional_journey_id": "east_current_signal_reef_route",
  "landmark_label": "Signal Reef"
}
```

`lower_right_signal_reef_backdrop` uses the same rectangle in `background` so
the existing background-rock renderer creates one recognizable silhouette. It
adds no collision and introduces no new asset.

Add this survey rectangle at `(136, 112)`, size `2 x 2`:

```json
{
  "id": "lower_right_signal_reef_survey",
  "target_type": "regional",
  "x": 136,
  "y": 112,
  "w": 2,
  "h": 2,
  "required_capability_id": "survey_scanner_1",
  "required_route_id": "east_current_signal_reef_route",
  "interaction": "survey",
  "interaction_seconds": 3.0,
  "interaction_label": "Survey Signal Reef",
  "clue_label": "Signal Reef | Harmonic pattern unresolved",
  "finding_label": "Discovery logged: Signal Reef chart",
  "next_lead_label": "Next lead: deeper harmonic below reef",
  "discovery_id": "lower_right_signal_reef_discovery",
  "route_context": "east_current_signal_reef_route",
  "commit_map_id": "production_level_01",
  "commit_map_path": "res://maps/production_level_01.greybox.json",
  "commit_entry_id": "surface_boat_entry"
}
```

`regional` is a focused scanner target type. It does not require the opening
anomaly lead and does not fund or unlock another capability in this milestone.
The physical current seam plus journey relationship supplies the fins dependency.

## State Semantics

- A fresh profile can explore normally but cannot enter Signal Reef without
  recipe-built propulsion fins.
- The existing current-pocket cache and scanner acquisition stay unchanged.
- Leaving survey range cancels partial interaction progress.
- Completing the survey creates only pending expedition state.
- Reset, hazard contact, oxygen failure, and combat defeat clear the pending
  Signal Reef discovery through existing cleanup paths.
- Pending state survives only transitions already preserved by the shared
  expedition owner; Expansion 10 adds no transition.
- Only return to `surface_boat_entry` on `production_level_01` commits the
  discovery, shows the finding plus next-lead labels, and persists it to profile.
- Repeated survey/commit is idempotent. New days and profile reload retain the
  committed discovery and never recreate the pending result.

## Ownership And Validation

- `tools/production_level_01_expansion_10.py` owns the human-authored records;
  `tools/create_production_level_01_map.py` composes them.
- Generated JSON/SVG, scenes, collision, and captures are never hand-authored.
- `validate_regional_journeys.py` should validate ids, references, supported
  capability, route context, source-only fields, seam coverage, no-fins denial,
  unlocked reachability, and return.
- Survey validation must support the exact `regional` fields and reject runtime
  state, arbitrary rewards, coordinates in labels, or unsupported capabilities.
- The direct full-level progression view must include:
  `propulsion_fins -> east_current_signal_reef_route ->
  lower_right_signal_reef_survey -> lower_right_signal_reef_discovery ->
  surface_boat_entry`.
- Add focused camera tests for the existing current promise, lower-right entry,
  and Signal Reef destination. Existing overview and slice cameras remain stable.
- `CurrentGateController`, `AnomalySurveyRuntime`, `ExpeditionDiscoveryState`,
  `ExpansionProfileState`, the world survey owner, and the background renderer
  remain the runtime owners. Generalize them only where the new source record
  requires it; do not add a parallel regional-state system.

## Non-Goals

No teleport, connector, map menu, `E`-prompted current crossing, current
stabilizer requirement, pressure capability, second traversal capability,
inventory/economy expansion, broad map population, new landmark asset, terrain
redesign, or slice-03 work belongs to this contract.
