# Controlled Gameplay Pass 22 Destination Payoff Contract

Date: 2026-07-09

Issue: #503 `Document Pass 22 destination payoff source contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_22_PLAN.md`

## Decision

Pass 22 adds one source-authored destination payoff in `production_slice_04` so the Pass 21 connector from `production_slice_01` has a concrete player-facing reason to exist.

This contract stays narrow. A destination payoff is normal salvage with a small amount of metadata for validation, feedback, smoke, and capture discovery. It is not a new inventory item, persistent world-state record, connector, save flag, or cross-slice objective system.

## Selected Payoff

Use one target:

```text
entity id: slice_04_destination_cache
map id: production_slice_04
payoff id: slice_04_destination_payoff
source connector id: lower_left_loop_connector
```

Recommended display label:

```text
Destination cache
```

The target should be reachable from `production_slice_04`'s relay entry and should sit on a route that makes sense after arriving through the Pass 21 connector.

## Source Metadata

Destination payoff metadata belongs on one `type: "salvage"` entity in the destination map.

Recommended metadata:

```json
{
  "id": "slice_04_destination_cache",
  "type": "salvage",
  "x": 0,
  "y": 0,
  "kind": "relic",
  "tier": "valuable",
  "route_choice_id": "slice_04_destination_cache",
  "validation_route": "slice_04_destination_payoff",
  "destination_payoff_id": "slice_04_destination_payoff",
  "destination_payoff_label": "Destination cache",
  "destination_payoff_connector_id": "lower_left_loop_connector",
  "intent": "Pass 22 destination-side payoff for using the lower-left connector into production_slice_04."
}
```

Fields:

- `destination_payoff_id`: required for the Pass 22 payoff target; lower_snake_case.
- `destination_payoff_label`: optional compact display-safe text for overlay/capture review.
- `destination_payoff_connector_id`: required when `destination_payoff_id` is present; lower_snake_case connector id from the origin map.

Existing route metadata should also be used:

- `validation_route`: use `slice_04_destination_payoff` so smoke/capture tooling can find the target deterministically.
- `route_choice_id`: use the selected target role, recommended `slice_04_destination_cache`.

## Defaults And Scope

If `destination_payoff_id` is omitted, the salvage is normal salvage and has no Pass 22 destination-payoff role.

Pass 22 supports exactly one destination payoff target in `production_slice_04`. Future passes can generalize the pattern only after this narrow proof is verified.

Destination payoff metadata is supported only on playable salvage entities. It is not supported on:

- marker zones
- hazards
- spawn or boat_spawn entities
- progression containers
- route objectives
- generated stress-test salvage

## Relationship To Connector

The payoff is associated with the existing Pass 21 connector:

```text
production_slice_01 lower_left_loop_connector -> production_slice_04 relay_sub_entry
```

`destination_payoff_connector_id` records that association for validation, smoke output, and review docs. It does not create a new transition and does not change connector runtime behavior.

Runtime should continue to use the Pass 21 connector metadata for travel. The payoff only makes the destination leg more meaningful once the player is already in `production_slice_04`.

## Validation Rules

Validation should catch:

- destination payoff metadata on non-salvage records
- missing or non-lower_snake_case `destination_payoff_id`
- missing or non-lower_snake_case `destination_payoff_connector_id`
- invalid non-string `destination_payoff_label`
- more than one destination payoff in the first Pass 22 map
- target placement outside bounds, inside solid terrain, or unreachable from the player entry
- target using `kind: "stress_marker"` or non-playable salvage semantics
- connector association that does not refer to a committed connector into `production_slice_04`

Normal salvage validation still applies: valid `kind`, optional valid `tier`, in-bounds coordinates, non-solid placement, reachability, cargo capacity handling, banking, hazard reset, and oxygen failure semantics.

## Runtime Boundaries

Runtime may:

- read destination payoff metadata from the loaded map
- show compact feedback such as `Destination cache +300` when the payoff is collected or discovered
- include payoff id and connector id in smoke/capture diagnostics
- reuse existing salvage collection, route-choice, score, and banking paths

Runtime must not:

- add a new connector, map screen, or fast-travel UI
- add inventory/loadout UI
- persist cross-slice cargo, oxygen, or objective state
- change salvage score values, oxygen timing, cargo limits, upgrade costs, player movement, or collision
- complete a multi-area objective unless a later objective/run-structure issue explicitly adds one

## Smoke And Capture Contract

`--smoke-pass-22-destination-payoff` should verify:

- current map can reach `production_slice_04` through the existing connector or a deterministic equivalent setup
- target id is `slice_04_destination_cache`
- payoff id is `slice_04_destination_payoff`
- connector id is `lower_left_loop_connector`
- target is collected or discovered through normal runtime paths
- held cargo, banked score, oxygen, and compact feedback match existing semantics

Focused capture should frame the target in `production_slice_04` with the compact payoff feedback visible. It is a review artifact, not baseline acceptance.

## Non-Goals

Pass 22 does not add:

- a second connector
- full-map productionization
- seamless world streaming
- persistent save files
- cross-slice objective chains
- broad economy or inventory systems
- enemies or procedural generation
- broad art replacement
- accepted visual baseline changes unrelated to the destination payoff

Keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal.
