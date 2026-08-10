# Living Expedition 05 Source And State Contract

Status: locked implementation contract for milestone #49.

## Purpose

Living Expedition 05 adds exactly one named Silt Hound and one deliberate
physical resource payoff without creating a generic detector, digging system,
or new economy:

- Marl is rescued through physical aid and committed at the canonical boat;
- the compact profile/habitat migrates from two to at most three individuals;
- exactly one active companion still launches per sortie; and
- selected Marl may deliberately excavate one visible authored mound that
  exposes one normal `titanium_scrap` pickup.

The material is an optional alternative source. No required project, rescue,
access edge, or future milestone may depend on it.

Titanium is already consumed by the Fins, Scanner, Cutter, Shock Prod, Dive
Light, Pressure Suit, Current Stabilizer, and Rebreather projects. The isolated
excavation checkpoint must leave at least one existing titanium-consuming
project unfinished so the physical payoff has an immediately inspectable use.

## Stable IDs

| Role | ID |
| --- | --- |
| Species | `silt_hound` |
| Individual | `silt_hound_juvenile_01` |
| Callsign | `Marl` |
| Rescue | `silt_hound_rescue_01` |
| Boat habitat | `companion_habitat_01` |
| Base action | `excavate` |
| Excavation context | `silt_hound_excavate_context_01` |
| Buried material candidate | `silt_hound_buried_titanium_01` |
| Optional material pool | `silt_hound_excavation_pool` |
| Material | `titanium_scrap` |
| Fresh rescue checkpoint | `living_expedition_05_start` |
| Excavation-ready checkpoint | `living_expedition_05_excavate_ready` |
| Rescue camera | `living_expedition_05_rescue_review_01` |
| Excavation camera | `living_expedition_05_excavate_review_01` |
| Input action | `companion_command` / `B/BOND` |

These ids become immutable when catalog, source, profile, progression, smoke,
capture, or checkpoint fixtures use them. Display copy and focused visuals may
change only through review without renaming source relationships.

## Immutable Source

`config/creature_catalog.json` advances to catalog version 3 and owns:

- `silt_hound`, display name `Silt Hound`, independent-only role, and no rider
  footprint;
- `silt_hound_juvenile_01`, default callsign `Marl`;
- base action `excavate`, effect kind `material_reveal`, and `damaging: false`;
  and
- empty memory/adaptation lists for this proof.

`tools/production_level_01_living_expedition_05.py` is the intended scoped
source module. Through the normal generator it owns:

- one `physical_aid` Cutter rescue in existing reachable geography;
- canonical `production_level_01` / `surface_boat_entry` commitment;
- Marl's membership in the existing canonical-boat habitat;
- one material-candidate entity for the visible buried mound and hidden pickup;
- one `optional_bonus` material pool containing only that candidate;
- one companion context linking species, individual, `excavate`, and candidate;
- the two review cameras and source provenance.

The rescue fiction is a juvenile caught in discarded dredge cable beside a
disturbed brood stone. It reuses deliberate held Cutter aid rather than adding
a rescue-only input. Exact source cells are selected in #1345 and must be
reachable from and returnable to the canonical boat with declared existing
access; terrain and collision do not change.

The candidate remains a normal entity with `interaction: material_collect`,
`material_id: titanium_scrap`, `material_quantity: 1`, and
`candidate_pool_id: silt_hound_excavation_pool`. Its bounded excavation fields
are:

```json
{
  "buried_deposit": true,
  "required_companion_action_id": "excavate",
  "companion_context_id": "silt_hound_excavate_context_01",
  "presentation_kind": "buried_mineral_mound"
}
```

The optional pool uses the existing daily selection strategy, selects its one
candidate, and uses `pool_role: optional_bonus`. Selection makes the opportunity
available to the excavation owner; it does not make the pickup visible or
collectible and does not contribute to validator material guarantees.

Source never owns commitment, active selection, rescue progress, reveal state,
dig progress, cargo, depletion, banked inventory, cooldowns, or UI visibility.
Generated JSON and SVG files are regenerated, never edited by hand.

## Profile Schema V3

Schema v3 retains the schema-v2 shape:

```json
{
  "schema_version": 3,
  "individuals": [],
  "active_individual_id": ""
}
```

Rules:

- `individuals` contains zero to three unique committed records in canonical
  catalog order: Kite, Mica, then Marl when each is committed.
- Individual records keep `individual_id`, `species_id`, `callsign`,
  `rescue_committed`, `earned_memory_ids`, and `selected_adaptation_id`.
- An active id is empty or references exactly one committed record.
- Marl has no supported memories or adaptations in this milestone; non-empty
  values on those fields are invalid.
- Ride availability remains derived from the selected species. Marl is not
  ride-capable.
- First-ever commitment may fill an empty active id as existing behavior does.
  Committing Marl to a profile with an active partner never changes selection.

## Migration

Migration and validation support legacy schema v1, current schema v2, and new
schema v3 explicitly:

1. Valid empty and Kite-only v1 payloads migrate exactly as before, then save as
   schema v3.
2. Valid v2 payloads preserve zero, one, or two records, callsigns, memories,
   adaptations, canonical order, and active id exactly.
3. Migration never creates, commits, selects, or assigns history to Marl.
4. Valid v3 payloads may contain Marl only with the catalog-matched species and
   supported empty growth fields.
5. Repeated load/save is idempotent and cannot duplicate or reorder records.
6. Malformed, over-capacity, duplicate, unknown, mismatched, or invalid-growth
   data remains rejected rather than repaired silently.

There is no separate persistent habitat, excavation, or deposit payload.

## Rescue, Habitat, And Selection

- The existing rescue runtime owns held Cutter progress, cancellation, pending
  companion instantiation, and failure cleanup.
- Full cargo does not block rescue, consume cargo, or convert Marl into an item.
- Returning together to the canonical boat commits Marl exactly once.
- The existing habitat source lists all three named ids; presentation derives
  only committed profile records.
- Three compact rows show callsign, species, relevant history, and one clear
  next-sortie selection. The panel does not add storage, release, or care state.
- BOND at the boat routes the existing sequential selector. Selection cannot
  hot-swap a live companion in open water.
- Only the selected committed individual receives a live sortie instance. An
  inactive Marl grants no material, detection, or passive effect.

## Excavation Runtime

A focused Silt Hound excavation owner coordinates one source relationship. It
owns only:

- eligible context lookup;
- transient approach target and path result;
- `idle`, `approaching`, `anticipating`, `digging`, `revealed`, `canceled`, and
  invalid-result states;
- bounded anticipation/dig progress and one action-local completion guard; and
- requests to reveal or conceal the linked material candidate.

`Excavate` appears only when Marl is the committed active live companion, the
candidate is selected for the day, the mound is unrevealed and undepleted, and
the player/companion are within the contracted actionable context. Opening BOND
still pauses the whole simulation. Choosing the action closes the palette,
resumes simulation, and makes Marl approach and dig visibly.

The action cancels with explicit feedback if its context, path, companion,
distance, day, failure, or map becomes invalid. It cannot auto-fire, target any
other material, reveal the map, collect the pickup, award score, complete a
project, grant a capability, damage an entity, or bypass access equipment.

The existing material-candidate world owner adds only bounded reveal/conceal
operations for source candidates that declare the contracted excavation fields.
Before reveal, the selected candidate is hidden and unavailable to proximity
collection. After reveal, it becomes an ordinary available candidate.

## Material, Cargo, And Day Ownership

- `ExpeditionDayState` remains the day-scoped selected/depleted-id owner.
- `MaterialRuntimeController` remains the only pickup, cargo-capacity,
  restoration, and boat-commit coordinator.
- `MaterialCargoState` remains the held candidate/quantity owner.
- `ExpansionProfileState` remains the banked material-inventory owner.
- The canonical boat remains the only material-banking authority.

The selected optional pool resets with the normal fresh day. The mound begins
closed every day even though its candidate id is selected. One successful dig
reveals it for the live day/world state:

- cargo full does not block excavation and leaves the revealed pickup present;
- normal movement away or boat return does not hide an already revealed pickup;
- collecting it marks the candidate depleted for the day and consumes one cargo
  slot through existing rules;
- banking clears held cargo into one banked `titanium_scrap`; the candidate
  remains depleted for that day;
- beginning the next day clears day depletion and closes the mound for another
  deliberate excavation;
- the optional pool is excluded from every mandatory recipe floor.

## Failure, Retry, Reload, And Isolation

- Failure before rescue commitment discards rescue progress/pending Marl and
  restores the rescue source to available.
- Failure after commitment preserves all profile records and active selection.
- Hazard, oxygen failure, Retry, or explicit run reset cancels approach/dig,
  clears reveal state, closes the mound, and restores any unbanked candidate
  through existing material/day owners. The next attempt requires excavation.
- A revealed cargo-blocked or uncollected pickup is never deleted silently; on
  failure it returns to the closed authored mound state.
- Reload derives profile records from schema v3 and world/day state from source;
  it cannot persist partial dig or reveal state accidentally.
- Map/day transition clears action-local state. Fresh-day source selection then
  decides availability again.
- Review checkpoints use isolated in-memory profiles and cannot write normal
  progress. The excavation-ready checkpoint commits/selects Marl and supplies a
  relevant uncompleted project state only as an isolated review fixture.

## Presentation Boundary

- Source owns `buried_mineral_mound`; focused runtime owns its closed, disturbed,
  digging, opened, and empty projection.
- Marl must show floor attention, approach, anticipation, digging motion, and an
  impact/reveal response distinct from Kite and Mica.
- The exposed titanium uses the existing material sprite and pickup feedback.
- BOND rows and compact status text may name `Excavate`, invalid context,
  progress, cargo full, and result, but cannot be the only evidence.
- Desktop and landscape-mobile keep sequential BOND selection and existing
  diver `TOOL`/`USE` controls. No new input or held chord is added.

## Validation Contract

Schema/source checks must reject unknown or duplicate ids, mismatched species,
unsupported actions/materials, missing relationship endpoints, excavation
fields on unrelated entities, wrong pool role, mandatory-yield contribution,
runtime/profile fields in source, solid/out-of-bounds placements, unreachable
rescue/deposit routes, and a missing canonical-boat return.

Runtime checks must prove v1/v2/v3 migration, exact rescue/commitment, three-row
selection, Marl-only launch, context eligibility, physical action progression,
one reveal, cargo-full preservation, exact pickup/banking, daily reset,
failure/Retry/reload restoration, no duplication, no passive effect, existing
Kite/Mica behavior, and equipment-gate protection.

Focused captures review rescue, pending return, habitat selection, follow,
closed mound, BOND anticipation, digging, opened pickup, cargo-full state, and
successful pickup at desktop and landscape-mobile sizes. Accepted production
baselines are compared but not changed for unrelated drift.

The final owner gate remains the question in
`LIVING_EXPEDITION_05_PLAN.md`. Automation cannot claim that Marl feels useful
or creates another-day motivation.
