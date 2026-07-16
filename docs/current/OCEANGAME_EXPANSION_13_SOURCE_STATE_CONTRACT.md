# OceanGame Expansion 13 Source And State Contract

Date: 2026-07-16

Status: Locked by #960 for implementation in #961-#969.

## Decision

Expansion 13 resolves the committed abyssal clue with one distant southeast
wreck journey. The unchanged route crosses the existing abyssal pressure zone
and ends at a cutter-opened recorder whose clearance exposes one scanner
survey. Both recorder cargo and the pending finding return to the canonical
surface boat.

This is a content payoff for existing capabilities. It adds no project,
recipe, material, capability, purchase, terrain, transition, or mutable oxygen
owner.

## Stable IDs

| Role | ID |
| --- | --- |
| prerequisite discovery | `abyssal_basin_harmonic_source_discovery` |
| route | `southeast_wreck_archive_route` |
| landmark | `southeast_wreck_archive_landmark` |
| backdrop | `southeast_wreck_archive_backdrop` |
| cutter target | `southeast_wreck_recorder` |
| survey | `southeast_wreck_archive_survey` |
| committed discovery | `southeast_wreck_archive_discovery` |
| canonical return | `surface_boat_entry` |

Required existing capabilities are `pressure_suit_1`, `salvage_cutter`, and
`survey_scanner_1`. The optional session `oxygen_tank_1` is never a source
prerequisite.

## Authored Source Contract

A focused `tools/production_level_01_expansion_13.py` helper owns the route,
landmark, backdrop, recorder, survey, cameras, and review metadata. The helper
may select exact footprint-clear cells around the measured southeast endpoint
near tile `(150.5, 149.5)`, then the validator must recompute the final route
budget from those authored coordinates.

The recorder remains normal valuable tool-target salvage:

```json
{
  "id": "southeast_wreck_recorder",
  "type": "tool_target",
  "kind": "crate",
  "tier": "valuable",
  "interaction": "cutter_salvage",
  "interaction_seconds": 2.0,
  "interaction_label": "wreck recorder",
  "required_tool_id": "salvage_cutter",
  "unlocks_survey_target_id": "southeast_wreck_archive_survey",
  "durable_clearance": true
}
```

`unlocks_survey_target_id` is the single source of truth for the dependency.
The survey does not duplicate a reciprocal target id. Validation and runtime
resolve the recorder by finding the one tool target that names the survey.

The survey reuses the regional survey contract:

- `target_type`: `regional`
- interaction: `survey`, 3.0 seconds, explicit `Q/SCAN`
- required capability: `survey_scanner_1`
- required pressure capability: `pressure_suit_1`
- required route and route context: `southeast_wreck_archive_route`
- committed discovery: `southeast_wreck_archive_discovery`
- commit map: `production_level_01`
- commit entry: `surface_boat_entry`

The route names the prerequisite discovery, existing pressure-zone entry,
landmark, recorder, survey, and boat return. It may expose a broad southeast
wreck clue, but it must not author an exact path marker or a transition.

No source record may change `terrain`, collision metadata, the top opening,
`abyssal_basin_pressure_zone`, or any production-slice source.

## Dependency States

| State | Recorder | Survey | Durable state |
| --- | --- | --- | --- |
| before cut | visible and available | visible, zero progress, cutter guidance | none |
| cutting | in-range progress; leaving cancels | zero progress | none |
| cleared, unbanked | held cargo and absent from world | immediately available | none |
| recorder banked | absent from world | available after map/profile reload | recorder id in profile |
| survey pending | recorder state unchanged | unavailable for a second result; return guidance | pending remains sortie-local |
| failure before boat | recorder restored unless already banked | progress and pending finding cleared | banked recorder/profile capabilities remain |
| boat commitment | recorder banks if held; finding commits once | completed result | recorder clearance and discovery persist |

Cargo-full state blocks recorder completion before it disappears. Scanner use
does not consume cargo capacity, so a player may survey while recorder cargo
fills the last slot. Banking the recorder before scanning is legal and must
not relock the survey.

## Durable State Contract

`ExpansionProfileState` advances one schema version with a supported
`banked_tool_target_ids` array. Initially the only supported durable tool
target is `southeast_wreck_recorder`.

The profile owns only the banked identity. It does not own cutter progress,
held cargo, survey progress, pending findings, oxygen, daylight, health, or
world-node visibility. Existing profiles migrate with an empty array. Banking
is exact-once and atomic with normal profile persistence; load validation
rejects unsupported or duplicate ids.

`CutterSalvageController` keeps current interaction progress and applies both
its existing session bank set and durable profile bank set to the world. It
persists a target only when source metadata opts into `durable_clearance`.
The historical sealed-wreck target retains its existing behavior.

## Runtime Ownership

| Owner | Responsibility |
| --- | --- |
| production-level source helper | all Expansion 13 authored records and provenance |
| map/progression validators | legal relationship, prerequisites, reachability, route budget, unchanged boundaries |
| `CutterSalvageController` | cutter progress, cargo blocking, completion, failure restoration, bank notification |
| focused survey-dependency helper | resolve source relationship and report blocked/available state |
| existing survey runtime | explicit activation, progress, cancel-on-leave, pending result |
| `ExpansionProfileState` | durable recorder bank id and committed discovery |
| expedition discovery state | unbanked finding until canonical-boat commitment |
| `SortieState` | sole mutable oxygen and held-cargo owner |
| offload controller | normal recorder banking and exact-once discovery commit path |

`main.gd` remains orchestration only. The implementation must use these focused
owners instead of adding Expansion 13 state directly to the shell.

## Feedback Contract

Contextual text uses the existing overlay priority:

- promise: `Abyssal chart | Southeast wreck echo`
- arrival before cut: `Wreck recorder | Cutter required`
- cutter progress: `Cutting wreck recorder`
- exposed survey: `Archive exposed | Q: Scan`
- survey progress: `Survey wreck archive`
- pending result: `Wreck archive charted | Return to surface boat`
- result: `Discovery logged: Southeast wreck archive`

Full cargo keeps `Cargo full - bank salvage at boat` for the recorder, while a
nearby exposed survey keeps scanner guidance visible. Do not add a permanent
route arrow, inventory panel, second oxygen display, or broad HUD redesign.

## Route Budget Contract

The planning measurement is about 7,368 px one way at 200 px/s. With a 2-second
cut and 3-second survey, minimum ideal demand is about 78.7 oxygen-seconds:

- base 90-second margin: about 11.3 seconds
- optional 105-second margin: about 26.3 seconds

Final source validation must use collision-aware player-footprint paths and
the authored interaction durations. It must prove:

- the route crosses `abyssal_basin_pressure_zone`
- the suit restores normal drain on that crossing
- the base tank remains viable with positive but tight margin
- `oxygen_tank_1` improves margin without becoming mandatory
- the direct return ends at `surface_boat_entry`

Do not tune global oxygen, pressure, speed, or interaction timing merely to
force these numbers.

## Failure And Reload Rules

- Leaving recorder or survey range cancels only current partial progress.
- Hazard, oxygen, combat defeat, manual reset, and day transition restore an
  unbanked recorder and clear uncommitted survey/pending state.
- A banked recorder remains cleared across map load, day transition, and
  profile reload; its survey remains available until the discovery commits.
- Durable capabilities, the banked recorder, and committed discovery survive
  failure and reload.
- The discovery commits exactly once at `surface_boat_entry`.

## Validation Obligations

#961-#965 must prove unique supported ids, the one-way dependency, no cycle,
exact existing prerequisites, source repeatability, footprint reachability,
pressure crossing, oxygen margins, cargo-full safety, failure restoration,
profile migration/reload, explicit scanner activation, pending return, and
exact-once commitment. Slices 01-04 and all terrain/collision records must be
byte-stable or structurally identical according to their existing checks.

## Non-Goals

No new upgrade, recipe, material, purchase, pressure tier, terrain, interior,
teleport, prompted connector, map menu, enemy, weapon, vehicle, inventory,
global rebalance, or broad art replacement. #52/#53 remain deferred slice-03
polish, and #849 remains separate bookkeeping.
