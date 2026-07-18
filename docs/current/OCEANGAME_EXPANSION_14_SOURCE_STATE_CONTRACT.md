# OceanGame Expansion 14 Source And State Contract

Date: 2026-07-18

Status: Locked by #1031 for implementation in #1032-#1040.

## Decision

Expansion 14 turns the committed southeast wreck archive into the existing
Current Stabilizer project and one earned return to an upper-left wreck relay
pocket. The player banks the exact recipe, builds once during night debrief,
then swims through a passive advanced current in continuous
`production_level_01`. The pocket contains one valuable relay core and one
explicit scanner survey whose finding commits at the canonical surface boat.

This milestone reuses the current, material-project, cargo, survey, failure,
and boat-commit systems. It adds no terrain, transition, activation key,
material type, recipe family, profile inventory, or second progression owner.

## Stable IDs

| Role | ID or value |
| --- | --- |
| prerequisite discovery | `southeast_wreck_archive_discovery` |
| project | `current_stabilizer_project` |
| prerequisite project | `salvage_cutter_project` |
| capability | `current_stabilizer` |
| recipe | `titanium_scrap: 2`, `conductive_coil: 1` |
| route | `upper_left_wreck_relay_route` |
| current gate | `upper_left_wreck_relay_current` |
| landmark | `upper_left_wreck_relay_landmark` |
| valuable cargo | `upper_left_wreck_relay_core` |
| survey | `upper_left_wreck_relay_survey` |
| committed discovery | `upper_left_wreck_relay_discovery` |
| canonical return | `surface_boat_entry` |
| next lead | `Next lead: deeper wreck relay still transmitting` |

These ids are canonical for `production_level_01`. The existing
`lower_left_loop_current` id and its slice/provenance relationship remain
valid legacy fixtures; they are not aliases for the new gate.

## Locked Current Boundary

The provisional broad eastern approach in the planning note is bypassable
through another upper-left-sector entrance. The capability boundary is
therefore the single interior throat leading into the relay pocket:

```json
{
  "id": "upper_left_wreck_relay_current",
  "type": "marker",
  "x": 53,
  "y": 57,
  "w": 3,
  "h": 4,
  "current_gate": true,
  "current_direction": "left",
  "current_strength": 3.2,
  "required_capability_id": "current_stabilizer",
  "route_context": "upper_left_wreck_relay_route"
}
```

Collision-aware evidence uses the existing 8 px navigation grid and the
player's 26 x 18 px footprint:

- all 12 authored gate tiles are in-bounds water with no solid overlap
- the open route from `surface_boat_entry` reaches the pocket near tile
  `(60, 60)` before capability blocking is applied
- treating the gate rectangle as blocked removes every player-clear route to
  that target and isolates 20 clear cells within `(56, 57)` through `(60, 60)`
- the measured clear route approaches through `(52, 57)`, crosses the gate at
  `(53, 57)` through `(55, 58)`, and enters the isolated pocket at `(56, 58)`
- `left` pushes an unequipped diver back toward the central route while the
  diver is trying to travel right/east into the pocket

`3.2` reuses the established advanced-current strength. Validation must prove
that normal movement cannot cross before ownership and that ordinary two-way
swimming works after ownership. `full_level_upper_left_anchor` remains a
review anchor for the sector; it is not the capability boundary.

## Authored Source Contract

A focused `tools/production_level_01_expansion_14.py` helper owns only the
full-level project override, current, route, landmark, relay core, survey,
camera tests, and review questions. `tools/create_production_level_01_map.py`
composes the helper. The generated JSON, SVG, and review renders remain
outputs, not hand-edited sources.

The helper must preserve the full-sketch topology, terrain, collision, map
bounds, canonical boat, and every production-slice source. The relay landmark,
core, and survey use distinct player-clear positions inside the isolated
pocket around tile `(60, 60)`. Their relationship is authored by ids and route
metadata, never inferred from proximity or display text.

The route must connect the archive prerequisite, project, current gate,
landmark, relay core, survey, resulting discovery, and canonical return. The
core is ordinary valuable cargo. The survey reuses the existing regional
survey contract with explicit `Q/SCAN`, a required `survey_scanner_1`, the
route id/context, `production_level_01` as commit map, and
`surface_boat_entry` as commit entry.

No source record may author mutable progress, held state, oxygen, profile
state, HUD state, or runtime completion flags.

## Canonical And Legacy Project Rules

The full-level definition of `current_stabilizer_project` is:

- required discovery: `southeast_wreck_archive_discovery`
- required project: `salvage_cutter_project`
- required banked materials: Ti2/Coil1
- unlocked capability: `current_stabilizer`
- target gate: `upper_left_wreck_relay_current`
- build phase: `night_debrief`

The historical slice definition may retain
`lower_right_anomaly_discovery` and `lower_left_loop_current`. Validators and
runtime rules must accept these as one explicitly scoped legacy pairing, not
as alternatives that can be mixed. In particular, the archive prerequisite
may not target the legacy gate, and the anomaly prerequisite may not target
the full-level gate.

Profiles that already contain both completed `current_stabilizer_project` and
owned `current_stabilizer` remain valid and immediately pass either gate. They
are never downgraded, charged again, or forced to acquire the new archive
discovery. Profiles that own neither follow the map definition currently
loaded. A project/capability mismatch remains an inconsistent profile rather
than being silently repaired by this milestone.

## State Ownership

| Owner | Responsibility |
| --- | --- |
| Expansion 14 source helper | canonical relationships and presentation metadata |
| map/progression validators | legal pairings, provenance, reachability, boundary isolation, graph order |
| `ExpansionProfileState` | banked materials, project completion, capability, committed discovery |
| `MaterialProjectRuntime` | source project selection and night-only build request |
| material runtime | current-sortie typed material cargo and boat deposit |
| `SortieState` and cargo controllers | oxygen, salvage capacity, held relay core, offload, failure restoration |
| current controller | passive push before capability and pass-through after capability |
| existing survey runtime | explicit scan progress, leave-range cancellation, pending finding |
| expedition discovery state | uncommitted relay finding until boat return |
| bounded cargo-strip presenter | read-only projection of current-sortie cargo owners |

`main.gd` remains orchestration only. No Expansion 14 mutable state belongs in
the source helper, world renderer, cargo-strip controls, or presentation text.

## Project Transaction

Construction is available only during night debrief after the canonical
archive discovery and cutter project are complete and at least two banked
titanium plus one banked coil exist. It consumes exactly those banked
quantities, records project completion, and grants the capability in one
persistent transaction.

Held current-sortie cargo never pays the recipe. Active-day build requests do
not spend materials or grant capability. Repeated night requests, reloads,
map changes, failures, and day transitions cannot spend again or duplicate
the capability.

## Journey And Failure States

| State | Current | Core | Survey/finding |
| --- | --- | --- | --- |
| archive not committed | blocks; project unavailable | present in pocket | visible only as authored distant content, zero progress |
| project known, not built | blocks; night-project guidance | present | zero progress |
| capability owned | passive two-way traversal | collectible if capacity permits | explicit scan available |
| cargo full | traversal unchanged | remains present and uncompleted | scanner remains usable |
| core held | traversal unchanged | absent and consumes normal capacity | scan remains usable |
| survey pending | traversal unchanged | held/banked state unchanged | cannot produce a second result; boat-return guidance |
| failure before boat | capability persists | unbanked core restores | partial progress and pending finding clear |
| canonical boat return | capability persists | held core banks through normal offload | discovery commits exactly once |

Leaving survey range cancels only partial scan progress. Current traversal has
no progress state to cancel. Hazard, oxygen, combat defeat, manual reset, and
day transition preserve durable project/capability state while applying the
existing restoration rules to unbanked material, salvage, and discovery
state. A banked core follows existing day/session salvage reset semantics; this
contract adds no profile-persistent core id. An uncommitted pending finding
does not survive failure.

## Bounded Held-Cargo Strip

The top-center strip is a read-only, current-sortie summary:

- named material/special-component icons and compact held counts
- held valuable-salvage count or icon state, including the relay core
- used and available capacity from the same calculation that blocks pickup
- deterministic slots and readable fallbacks at desktop and landscape-mobile
  sizes

It must clear or update only when the existing cargo owners collect, bank,
restore, or discard state. It must not contain banked profile materials,
project recipes, discoveries, score, persistent inventory, or selectable
tools. Active-tool selection retains its current controller, input, and
surface; vitals/objectives remain edge-owned; contextual prompts remain
temporary. Minor placement adjustment is allowed only to prevent overlap.

This is not an inventory grid, item-use bar, crafting screen, equipment panel,
or broad HUD replacement.

## Validation Obligations

#1032-#1036 must prove:

- canonical and legacy project/gate pairs validate, while mixed pairs fail
- already-owned profiles remain valid and exact-once
- the generated full-level source is deterministic and slices 01-04 do not
  change
- gate cells are water-only, the blocked footprint graph isolates the relay
  pocket, and the owned route is two-way and returns directly to the boat
- exact banked Ti2/Coil1 night spending with no held-cargo spending
- core cargo-full safety, failure restoration, banking, and no duplication
- explicit scan progress/cancellation, pending failure, and exact-once commit
- the cargo strip matches authoritative held state through collect, full,
  bank, failure, reload, and mobile-layout cases

Run the complete release candidate suite once after the journey and cargo
strip are integrated in #1036. Later capture, baseline, Web, and closeout
issues use focused checks unless their own change requires broader evidence.

## Non-Goals

No terrain expansion, connector, teleport, map menu, current activation key,
new tool, weapon, enemy, material, recipe, oxygen/pressure tier, economy,
inventory, crafting grid, production HUD, broad art/audio pass, or save-system
redesign. #52/#53 remain deferred slice-03 polish, and #849 remains separate
bookkeeping.
