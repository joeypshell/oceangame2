# OceanGame Expansion 16 Source And State Contract

Date: 2026-07-28

Issue: #1124

Plan: `docs/current/OCEANGAME_EXPANSION_16_PLAN.md`

## Decision

Expansion 16 turns the committed Northwest Wreck Relay signal into one
far-west deeper-wreck return in continuous `production_level_01`.

The player can physically scout the route before owning the new capability.
One source-authored confined-wreck zone accelerates oxygen consumption rather
than blocking movement. The base tank and optional session `O2 tank +15`
cannot complete the cutter, scanner, and boat-return contract with reserve
while that acceleration is active. A night-built closed-circuit rebreather
normalizes only that zone and makes the same operation returnable.

This milestone adds no terrain, connector, teleport, hard collision gate,
global tank increase, global drain reduction, material family, enemy, tool,
inventory, or broad HUD.

## Stable IDs

| Role | ID or value |
| --- | --- |
| prerequisite discovery | `upper_left_wreck_relay_discovery` |
| project | `closed_circuit_rebreather_project` |
| capability | `closed_circuit_rebreather` |
| route | `far_west_deeper_wreck_route` |
| oxygen zone | `far_west_confined_wreck_oxygen_zone` |
| landmark | `far_west_deeper_wreck_landmark` |
| background | `far_west_deeper_wreck_backdrop` |
| cutter target | `far_west_wreck_data_recorder` |
| survey | `far_west_deeper_wreck_survey` |
| committed discovery | `far_west_deeper_wreck_discovery` |
| canonical return | `surface_boat_entry` |
| review checkpoint | `expansion_16_start` |
| route review bounds | tiles `x=12..32`, `y=90..121` |
| cutter tool | `salvage_cutter` |
| scanner capability | `survey_scanner_1` |

These ids are canonical for `production_level_01`. Exact clear cells inside
the review bounds belong to #1126 and must be selected by footprint-aware
validation, not by hand-tuning generated JSON.

## Project Contract

`closed_circuit_rebreather_project` owns:

```json
{
  "required_discovery_id": "upper_left_wreck_relay_discovery",
  "required_materials": {
    "titanium_scrap": 1,
    "rubber_sheet": 1,
    "conductive_coil": 1,
    "insulating_gel": 1
  },
  "unlocks_capability_id": "closed_circuit_rebreather",
  "target_id": "far_west_confined_wreck_oxygen_zone",
  "build_phase": "night_debrief",
  "project_label": "Closed-circuit rebreather",
  "completion_label": "Rebreather built"
}
```

The committed relay discovery is knowledge, not a score threshold. Only
banked materials pay the recipe. The build spends each quantity once, records
the project, and grants the capability in one profile transaction.

Held material cargo, salvage value, the session wallet, active-day input, and
source-array order cannot pay or infer the project. Repeated requests, reload,
failure, and later nights cannot spend again or duplicate the capability.

The four ingredients already exist in guaranteed pre-route sources. Validation
must reject a source change that makes any one unavailable before the project.

## Oxygen-Zone Source Contract

The zone uses one marker record:

```json
{
  "id": "far_west_confined_wreck_oxygen_zone",
  "type": "marker",
  "oxygen_consumption_zone": true,
  "oxygen_consumption_label": "Confined wreck air",
  "required_capability_id": "closed_circuit_rebreather",
  "warning_grace_seconds": 1.0,
  "unprotected_oxygen_drain_multiplier": 8.0,
  "route_context": "far_west_deeper_wreck_route"
}
```

`x`, `y`, `w`, and `h` are source-owned after #1126 proves the route
inequalities. The rectangle may overlap cave terrain for presentation, but
its measured navigable segment, target cells, and approach must be water and
player-footprint clear.

The marker is non-solid and never changes collision. It cannot contain damage,
health, teleport, connector, completion, progress, oxygen, capability-owned,
profile, or UI visibility state.

Before capability ownership:

- entering starts one second of readable warning at normal drain
- remaining exposure uses the exact source multiplier
- leaving resets exposure and multiplier
- the player can turn around and leave through ordinary movement

With capability ownership:

- the zone uses the ordinary `1.0` oxygen multiplier
- entry may show `Rebreather active` briefly
- ordinary water, surface refill, tank capacity, low/critical thresholds,
  pressure-suit zones, hazard penalties, and drowning remain unchanged

The existing abyssal pressure zone and `pressure_suit_1` retain their current
ids, source fields, runtime owner, and behavior. They are not aliases for this
confined-wreck zone.

## Route-Margin Contract

The source validator measures the real player footprint, 8 px navigation grid,
runtime swim speed, tank constants, zone rectangle, and authored interaction
times. It reports these terms:

```text
normal_round_trip_seconds
zone_warning_seconds
zone_critical_seconds
cutter_seconds
scanner_seconds
return_reserve_seconds
protected_demand_seconds
unprotected_demand_seconds
scout_demand_seconds
```

The fixed contract values are:

```text
base_tank_seconds = runtime OXYGEN_MAX_SECONDS (currently 90)
optional_tank_seconds = base + session O2 tank bonus (currently 105)
return_reserve_seconds = 12
cutter_seconds = source interaction time (target contract: 2)
scanner_seconds = source interaction time (target contract: 3)
unprotected multiplier = 8
warning grace = 1 second per zone entry
```

For the selected target and route:

```text
protected_demand =
  normal_round_trip_seconds + cutter_seconds + scanner_seconds

unprotected_demand =
  protected_demand
  + zone_critical_seconds * (unprotected_multiplier - 1)

protected_demand + return_reserve_seconds <= base_tank_seconds
unprotected_demand + return_reserve_seconds > optional_tank_seconds
scout_demand_seconds + return_reserve_seconds <= base_tank_seconds
```

`zone_critical_seconds` includes outbound and return exposure after each
entry's warning grace. The optional tank may improve the retreat margin but
cannot satisfy the complete operation-and-return equation. The rebreather
removes only the multiplier term; it does not add oxygen.

If no clear target/zone placement inside the selected review bounds satisfies
all three inequalities, #1126 must report HOLD. It may tune clear source cells
inside the bounds, but it may not reduce the reserve, expand the tank, add a
refill, add a transition, or change terrain to force a pass.

## Journey Source Contract

`far_west_deeper_wreck_route` relates:

- required discovery `upper_left_wreck_relay_discovery`
- required capability `closed_circuit_rebreather`
- entry zone `far_west_confined_wreck_oxygen_zone`
- landmark `far_west_deeper_wreck_landmark`
- cutter target `far_west_wreck_data_recorder`
- survey target `far_west_deeper_wreck_survey`
- canonical return `surface_boat_entry`
- route context equal to its own id

The route capability is preparation metadata, not a collision lock. The player
may enter before ownership. Runtime oxygen pressure, rather than a hidden
interaction rejection, enforces the operation margin.

The focused source helper owns the project, zone, journey, landmark, target,
survey, background, camera tests, review questions, and provenance. The
generated JSON and SVG are outputs and are never hand-edited.

No Expansion 16 record may author a destination map, connector, teleport,
interior, map transition, mutable progress, selected state, profile state, or
runtime completion flag.

## Cutter, Scanner, And Discovery Contract

The data recorder reuses `cutter_salvage`:

- `interaction_seconds` is `2.0`
- `required_tool_id` is `salvage_cutter`
- `tool_project_id` is `salvage_cutter_project`
- `unlocks_survey_target_id` is the far-west survey
- `durable_clearance` is true
- proximity alone never advances it

The revealed survey reuses the existing held scanner:

- `required_capability_id` is `survey_scanner_1`
- `interaction` is `survey`
- `interaction_seconds` is `3.0`
- leaving range or releasing the active scanner cancels partial progress
- the rebreather is not a second explicit interaction requirement
- completing the scan creates one pending finding

The finding commits only when the player reaches `surface_boat_entry` on
`production_level_01`. Cutter completion and pending survey state cannot each
grant separate progression. The committed discovery is the payoff; optional
salvage value remains secondary and is not required by this milestone.

## Ownership

| Owner | Responsibility |
| --- | --- |
| Expansion 16 source helper | immutable project, zone, journey, landmark, target, survey, labels, and relationships |
| map/progression validators | schema, references, dependency order, reachability, route equations, and no-transition proof |
| `GreyboxWorld` | source loading, non-solid marker/target rendering, and read-only queries |
| `SortieState` | mutable oxygen, drain, refill, and failure state |
| focused oxygen-zone controller | overlap, grace, multiplier, warning, and capability normalization report |
| `ExpansionProfileState` | completed project, capability, durable cutter clearance, and committed discovery |
| `MaterialProjectRuntime` | exact recipe readiness and night transaction |
| active-tool/cutter owners | explicit selected-cutter activation, timing, cancellation, and clearance |
| scanner/survey owners | held scan timing, target eligibility, cancellation, and pending finding |
| expedition discovery state | pending finding and canonical-boat commit |
| regional journey presentation | broad promise, preparation, nearby, pending, and result text |
| review profile/checkpoint owner | isolated prerequisite/material fixture only |
| `main.gd` | initialization, delegation, and presentation refresh only |

The new controller owns no oxygen amount, profile data, project state,
interaction progress, map mutation, or HUD node. `main.gd` must not become the
behavior owner.

## Failure And Persistence

| Event | Durable state | Oxygen/zone | Cutter/survey/finding |
| --- | --- | --- | --- |
| leave zone | unchanged | multiplier/grace reset | unchanged |
| hazard or combat hit | unchanged | existing penalty/reset rules | existing local cancellation rules |
| oxygen failure | project/capability persist | existing surface/reset rules | partial cutter/scan and pending finding clear; unfinished target restores; durable clearance persists |
| manual retry | profile persists | fresh sortie oxygen | local target/progress/pending restore to authoritative state |
| night transition | completed project persists | normal next-day reset | no uncommitted finding survives forced failure semantics |
| canonical boat return | profile persists | normal refill/offload | pending discovery commits once |
| reload | completed project/capability/discovery persist | no in-progress exposure persists | durable clearance persists; partial/pending state does not |

Profile schema remains generic and versioned; the new ids use existing
collections and do not require a parallel save format.

## Presentation And Input

No input action is added:

- `Tab` / `TOOL` selects the existing Cutter or Scanner
- `Q` / `USE` activates the selected tool
- movement and retreat remain ordinary swim controls
- night project selection/build uses the current project controls

Context text is compact and temporary:

- unprotected entry: `Confined wreck air | Retreat`
- critical exposure: `Air cycling failed | Oxygen x8`
- protected entry: `Rebreather active`
- cutter ready/progress: existing cutter surface with `wreck data recorder`
- scanner progress: existing scanner target surface
- pending finding: existing return-to-boat surface

The rebreather is passive equipment, not an active-tool slot. Existing
equipment/cargo presentation may show its compact owned state, but this
milestone adds no permanent recipe panel or explanatory HUD.

## Review Checkpoint

`expansion_16_start` is an isolated review profile. It may establish:

- the prerequisite relay discovery
- scanner and cutter ownership
- the four recipe materials banked
- the rebreather project not yet completed
- the far-west target, survey, and discovery unresolved

It cannot mutate the normal profile, grant the rebreather automatically,
commit the target discovery, change terrain, or bypass the night build. The
exact Web checklist should use this fixture to cover scout, build, return, and
boat commitment without replaying earlier expansions.

## Validation And Review Obligations

Issues #1125-#1132 must prove:

- exact ids, recipe, prerequisite, fields, references, and forbidden metadata
- guaranteed ingredients and acyclic progression order
- clear continuous boat/zone/target/boat traversal with collision active
- all three route-margin inequalities and unchanged ordinary oxygen behavior
- exact-once night spending and profile persistence
- explicit cutter and held-scanner input with correct cancellation
- pending-finding failure cleanup and exact-once boat commit
- isolated checkpoint state
- deterministic smoke output and CI registration
- focused desktop/mobile captures with no control or HUD overlap
- no unrelated terrain, camera, player, boat, prop, or slice baseline drift
- exact-SHA Web initialization before owner review

Issue #1133 remains open until the owner decides GO or HOLD on the verified
candidate. #52/#53 remain deferred optional slice-03 presentation work.
