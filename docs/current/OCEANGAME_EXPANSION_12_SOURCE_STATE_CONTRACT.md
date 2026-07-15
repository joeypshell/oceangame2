# OceanGame Expansion 12 Source And State Contract

Date: 2026-07-15

Status: Locked by #932 for implementation in #933-#941.

## Decision

Expansion 12 resolves the committed deep-harmonic clue with one recipe-built
pressure suit and one source-authored return to the existing lower-central
basin. The terrain stays continuously swimmable. Pressure changes oxygen cost;
it does not create collision, teleport the player, or damage health.

## Stable IDs

| Role | ID |
| --- | --- |
| prerequisite discovery | `signal_reef_deep_harmonic_discovery` |
| project | `pressure_suit_1_project` |
| durable capability | `pressure_suit_1` |
| route | `deep_harmonic_abyssal_basin_route` |
| pressure zone | `abyssal_basin_pressure_zone` |
| landmark | `abyssal_basin_landmark` |
| survey | `abyssal_basin_harmonic_source_survey` |
| committed discovery | `abyssal_basin_harmonic_source_discovery` |
| canonical return | `surface_boat_entry` |

## Project Contract

`pressure_suit_1_project` is revealed only after
`signal_reef_deep_harmonic_discovery` commits at the boat. Its source record is:

- build phase: `night_debrief`
- titanium scrap: 2
- rubber sheet: 1
- insulating gel: 1
- unlocked capability: `pressure_suit_1`
- target: `abyssal_basin_harmonic_source_survey`
- project label: `Pressure suit project`
- completion label: `Pressure suit built`

Construction uses the existing atomic material-project transaction. It spends
banked profile materials exactly once and persists the completed project and
capability together. Score, held cargo, and `oxygen_tank_1` cannot satisfy or
replace any ingredient.

The project is appended after the durable light project in production-level
source order. Earlier incomplete projects retain their existing selection
order; this project becomes actionable when its discovery and materials are
ready.

## Authored Map Contract

The focused Expansion 12 source helper owns these records without changing
`terrain`:

- pressure zone: `x=60, y=126, w=77, h=30`
- landmark marker: `x=81, y=141, w=33, h=15`
- survey: `x=95, y=149, w=2, h=2`
- survey center/review target: tile `(96, 150)`
- interaction: `survey`, 3.0 seconds, cancel current progress on leave
- required tools: `survey_scanner_1` and `pressure_suit_1`
- route and pending result commit only at `surface_boat_entry` on
  `production_level_01`

The pressure-zone record uses this narrow metadata:

```json
{
  "pressure_zone": true,
  "pressure_level": "abyssal",
  "pressure_label": "Abyssal pressure",
  "required_capability_id": "pressure_suit_1",
  "warning_grace_seconds": 1.0,
  "unprotected_oxygen_drain_multiplier": 8.0,
  "route_context": "deep_harmonic_abyssal_basin_route"
}
```

The route record reuses `regional_journeys`. Its promise is the existing
`signal_reef_deep_harmonic_dark_zone`, its entry gate is the pressure zone, its
capability is `pressure_suit_1`, and its landmark, survey, and boat return use
the stable IDs above.

The source helper may add procedural landmark/background and review-camera
records, but it must not add a new bitmap asset. Capture IDs should cover:

- `expansion_12_pre_suit_pressure_warning`
- `expansion_12_pressure_suit_project`
- `expansion_12_protected_crossing`
- `expansion_12_abyssal_survey`
- `expansion_12_pending_boat_return`

## Route Budget Contract

The current collision-aware route from the canonical boat to tile `(96, 150)`
measures about 5,579.8 px one way at 200 px/s. With the 3-second survey:

- protected round trip: about 58.8 oxygen-seconds
- base 90-second tank margin: about 31.2 seconds
- optional 105-second tank margin: about 46.2 seconds
- travel inside the selected pressure rectangle: about 8.0 seconds round trip
- unprotected pressure travel plus survey: about 11.0 seconds
- unprotected demand at 8x with one 1-second grace: about 128.9 seconds
- optional-tank shortfall: about 23.9 seconds

The grace belongs to one continuous zone exposure and does not restart while
the player remains inside. Oxygen continues draining during the survey. On the
deterministic shortest route, the 105-second configuration is effectively
empty at the pressure threshold on return, so the distant lower-loop rest
pocket cannot rescue the attempt.

Validation must also choose a shallow threshold scout point and prove a fresh
base-tank player can see the warning, turn around, and return to the boat. The
zone therefore teaches retreat without allowing the full unprotected payoff.

## Runtime Ownership

| Owner | Responsibility |
| --- | --- |
| production-level source helper | route, zone, project, landmark, survey, cameras, provenance |
| map validators/progression audit | schema, crossings, recipe guarantees, dependency graph, route budgets |
| `ExpansionProfileState` | durable discovery, completed project, capability, banked materials, reload |
| `MaterialProjectRuntime` | night-only selection, readiness, build transaction, compact project text |
| focused pressure controller | current overlap, warning/grace state, drain multiplier, contextual note |
| `SortieState` | sole mutable oxygen value and oxygen failure |
| existing survey runtime | in-range progress, cancel-on-leave, pending finding, failure cleanup |
| expedition discovery state | unbanked finding until canonical-boat commitment |

The pressure controller returns a multiplier to the normal oxygen update. It
does not write a second oxygen value, own project state, or change player
position. The suit changes only that multiplier from 8.0 to 1.0 while inside
this zone.

## Feedback Contract

Feedback stays contextual and uses existing overlay priority:

- project: `Pressure suit | Ti 0/2 | Rubber 0/1 | Gel 0/1`
- night-ready: `P: Build pressure suit`
- warning/grace: `Abyssal pressure | Retreat`
- unprotected drain: `Pressure critical | Oxygen x8`
- protected entry: `Pressure suit active`
- blocked survey: `Abyssal signal | Pressure suit required`
- active survey: `Survey abyssal source`
- pending result: `Abyssal source charted | Return to boat`

Do not add a permanent depth meter, inventory panel, pressure bar, or second
oxygen display.

## Lifecycle And Failure Rules

- Leaving the pressure zone clears warning/grace exposure state.
- Leaving survey range cancels only current survey progress.
- Oxygen failure, hazard reset, combat defeat, manual reset, and day transition
  clear unbanked survey/pending state through existing owners.
- Those failures never remove the durable suit, completed project, committed
  discoveries, or banked materials.
- Cargo banking, surface oxygen refill, boat-only offload, and end-day behavior
  remain unchanged.
- The abyssal discovery becomes durable exactly once at the canonical boat.

## Validation Obligations

#933-#937 must prove:

- all IDs and references are unique and supported
- the recipe is guaranteed and non-circular
- the zone and survey are in bounds, footprint-clear, and boat-returnable
- every collision-clear route to the survey crosses the pressure zone
- pre-suit warning/retreat succeeds
- base and optional tanks cannot finish the unprotected survey and boat return
- the suit restores normal drain and useful base-tank return margin
- profile reload, failure cleanup, and exact-once boat commitment remain stable
- source regeneration is repeatable and slices 01-04 do not change

## Non-Goals

No global depth simulation, decompression, health damage, suit durability,
pressure tiers, terrain edits, connector travel, teleport, new material type,
inventory screen, economy pass, enemy, vehicle, or broad visual replacement.
#52/#53 remain deferred slice-03 polish.
