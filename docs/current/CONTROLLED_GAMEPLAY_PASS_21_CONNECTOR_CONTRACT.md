# Controlled Gameplay Pass 21 Connector Contract

Date: 2026-07-09

Issue: #421 `Document Pass 21 connector metadata contract and boundaries`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_21_PLAN.md`

## Decision

Pass 21 supports exactly one prompted world-slice connector:

```text
production_slice_01 -> production_slice_04
```

The connector proves that an existing reference slice can become reachable through source-authored data and runtime transition code. It is not a generalized world map, fast-travel system, or full-map merge.

## Connector Identity

Use one connector zone id:

```text
lower_left_loop_connector
```

Recommended display label:

```text
Lower-left loop
```

Origin:

```text
map id: production_slice_01
map path: res://maps/production_slice_01.greybox.json
```

Destination:

```text
map id: production_slice_04
map path: res://maps/production_slice_04.greybox.json
entry entity id: relay_sub_entry
```

## Source Metadata

Connector metadata belongs on marker zones. The marker rectangle is the source-authored discovery/trigger area.

Recommended origin marker shape:

```json
{
  "id": "lower_left_loop_connector",
  "type": "marker",
  "x": 0,
  "y": 0,
  "w": 1,
  "h": 1,
  "world_connector": true,
  "connector_label": "Lower-left loop",
  "destination_map_id": "production_slice_04",
  "destination_map_path": "res://maps/production_slice_04.greybox.json",
  "destination_entry_id": "relay_sub_entry",
  "connector_direction": "forward",
  "intent": "Pass 21 connector from the default boat hub toward the lower-left loop reference slice."
}
```

Pass 21 may also author a destination-side return marker in `production_slice_04` if the implementation chooses a two-way pair, but runtime is only required to support the forward transition for this pass.

## Validation Rules

Validator support should ensure:

- Connector metadata appears only on `type: "marker"` zones.
- Connector zone ids are unique and lower_snake_case.
- `world_connector` is `true` when connector fields are present.
- `connector_label` is compact display-safe text.
- `destination_map_id` is lower_snake_case.
- `destination_map_path` points to a committed `.greybox.json` map under `res://maps/`.
- `destination_entry_id` references an existing `spawn` or `boat_spawn` entity in the destination map.
- `connector_direction`, when present, is `forward`, `return`, or `bidirectional`.
- The connector marker rectangle is in bounds, non-solid, and reachable from the origin entry.

Connector metadata must not validate by relying on debug-only overlays or hand-tuned Godot scene placement.

## Trigger And UI Rules

Use a prompted transition, not automatic overlap travel.

Allowed compact text examples:

```text
E: Enter lower-left loop
Entering lower-left loop
Arrived: Lower-left loop
Connector unavailable
```

Runtime may use `E` or a project-local equivalent input check. The prompt should appear only while the player is inside the connector zone and the run is active.

The connector prompt should lose priority to urgent feedback:

- oxygen failure
- hazard contact
- cargo-full banking prompt
- timed/pry salvage progress
- route-objective cue
- completion/failure result panel

## Transition Rules

For Pass 21, the transition may reset local expedition state when loading the destination map.

Preserve:

- session wallet
- purchased oxygen upgrade
- purchased cargo upgrade
- purchased light upgrade
- current app session state

Reset or rederive for the destination map:

- player position from `relay_sub_entry`
- local salvage availability
- held cargo and held score
- banked run score
- oxygen amount, using current upgraded capacity
- route objective state for the destination map
- timed/pry interaction progress
- hazard state
- result panel state

This means Pass 21 is a connected-slice proof, not a full continuous expedition across areas. Continuous cross-slice cargo, oxygen, objectives, and world-state persistence are deferred.

## Runtime Boundaries

Runtime may:

- read source-authored connector marker metadata
- show connector prompt/status text
- load `production_slice_04` through the existing map-loading path
- place the player at `relay_sub_entry`
- preserve session progression
- expose small helper methods for smoke/capture verification

Runtime must not:

- add a map screen or travel menu
- add persistent save data
- add inventory, loadouts, or broad equipment management
- change salvage values, cargo capacity, oxygen drain, objective rules, or upgrade costs
- stitch the full sketch into one production map
- hand-place transition geometry in Godot scenes

## Reset And Failure Rules

Manual reset after transition resets the current loaded map only and keeps session progression, matching the existing Pass 18-20 session behavior.

Hazard hit or oxygen failure after transition uses the destination map's normal reset/failure semantics.

Origin-map unbanked state does not need to persist after transition in Pass 21.

## Smoke Contract

`--smoke-pass-21-world-connector` should verify:

- origin map id is `production_slice_01`
- connector id is `lower_left_loop_connector`
- connector prompt appears in range
- triggering the connector loads `production_slice_04`
- player arrives near `relay_sub_entry`
- session wallet and Pass 18-20 upgrades persist
- held cargo, banked run score, oxygen, and overlay/result state are reinitialized for the destination map

Existing route, progression, player-facing, and production-slice smokes should remain green.

## Non-Goals

Pass 21 must not add:

- full-map productionization
- seamless world streaming
- broad fast travel
- a world map screen
- persistent save files
- multi-area objective chains
- cross-slice cargo or oxygen persistence
- inventory/loadout systems
- enemies or procedural generation
- broad art replacement

## Deferred Work

Keep #52 and #53 deferred unless slice 03 becomes an explicitly selected Milestone 05 target.
